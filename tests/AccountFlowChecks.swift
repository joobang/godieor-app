import Foundation

private struct CheckFailure: Error { let message: String }
@MainActor private func check(_ value: @autoclosure () -> Bool, _ message: String) throws {
    if !value() { throw CheckFailure(message: message) }
}
@MainActor private func until(_ predicate: () -> Bool) async throws {
    for _ in 0..<5000 { if predicate() { return }; await Task.yield() }
    throw CheckFailure(message: "synthetic scheduling condition not reached")
}
@MainActor private final class Gate {
    var waiting = false
    private var released = false
    private var continuation: CheckedContinuation<Void, Never>?
    func wait() async { if released { return }; await withCheckedContinuation { continuation = $0; waiting = true } }
    func release() { released = true; continuation?.resume(); continuation = nil }
}
@MainActor private final class MemoryStore {
    var token: String? = "test-a"
    var saves = 0
    var removals = 0
    var storage: AccountSessionStore {
        .init(load: { self.token }, save: { self.token = $0; self.saves += 1 }, remove: { self.token = nil; self.removals += 1 })
    }
}
@MainActor private final class Server {
    typealias Reply = (Data, URLResponse)
    var requests: [URLRequest] = []
    var settings: [String: [String: Any]] = [:]
    var favorites: [String: [String: String]] = ["test-a": ["event-a": "event"], "test-b": ["content-b": "content"]]
    var versions = ["test-a": 1, "test-b": 1]
    var intercept: ((URLRequest) async throws -> Reply?)?
    init() {
        for token in ["test-a", "test-b"] {
            settings[token] = ["version":"1", "country":"KR", "timeZone":"Asia/Seoul", "enabledCategories":["movie","ott"], "services":[], "devices":[], "view":"calendar"]
        }
    }
    func reply(_ request: URLRequest, _ status: Int = 200, _ object: [String: Any] = [:]) throws -> Reply {
        let data = status == 204 ? Data() : try JSONSerialization.data(withJSONObject: object)
        return (data, HTTPURLResponse(url: request.url!, statusCode: status, httpVersion: nil, headerFields: nil)!)
    }
    func send(_ request: URLRequest) async throws -> Reply {
        requests.append(request)
        if let intercepted = try await intercept?(request) { return intercepted }
        return try defaultReply(request)
    }
    func defaultReply(_ r: URLRequest) throws -> Reply {
        let path = r.url!.path, method = r.httpMethod ?? "GET"
        if path == "/v1/auth/google" {
            try check(r.value(forHTTPHeaderField:"Authorization") == nil, "login must be unauthenticated")
            let body = try JSONSerialization.jsonObject(with:r.httpBody!) as! [String: Any]
            try check(body["idToken"] as? String == "test-id", "authorization result must reach API")
            return try reply(r, 200, ["accessToken":"test-b", "expiresAt":"2099-01-01T00:00:00Z", "user":["id":"user-b", "displayName":"Synthetic B"]])
        }
        let token = String((r.value(forHTTPHeaderField:"Authorization") ?? "").dropFirst(7))
        guard settings[token] != nil else { return try reply(r,401) }
        if path == "/v1/auth/session" { return try reply(r,204) }
        if path == "/v1/me" { return try reply(r,200,["id":token == "test-a" ? "user-a":"user-b", "displayName":"Synthetic account"]) }
        if path == "/v1/me/settings" {
            if method == "PUT" {
                var body = try JSONSerialization.jsonObject(with:r.httpBody!) as! [String: Any]
                guard body["expectedVersion"] as? String == settings[token]!["version"] as? String else { return try reply(r,409) }
                body.removeValue(forKey:"expectedVersion")
                body["version"] = String(Int(settings[token]!["version"] as! String)! + 1)
                settings[token] = body
            }
            return try reply(r,200,settings[token]!)
        }
        if path == "/v1/me/favorites" {
            let items = favorites[token, default:[:]].sorted { $0.key < $1.key }.map { ["targetId":$0.key,"targetType":$0.value] }
            return try reply(r,200,["favoritesVersion":String(versions[token]!), "items":items,"nextCursor":NSNull()])
        }
        if path.hasPrefix("/v1/me/favorites/") {
            let id = r.url!.lastPathComponent
            if method == "DELETE" { favorites[token]?.removeValue(forKey:id) }
            else { favorites[token,default:[:]][id] = path.contains("/events/") ? "event":"content" }
            versions[token, default:1] += 1
            return try reply(r,204)
        }
        throw CheckFailure(message:"unexpected synthetic request path")
    }
    func state(_ store: MemoryStore) -> AccountState {
        AccountState(transport:{ try await self.send($0) }, endpoint:{ URL(string:"https://account-check.invalid/v1")! }, sessionStore:store.storage, authorize:{ "test-id" })
    }
}
@main struct AccountFlowChecks {
    @MainActor static func save(_ state: AccountState, services: [String] = ["tving"]) async {
        await state.saveSettings(country:"KR",timeZone:"Asia/Seoul",categories:["ott"],services:services,devices:["ios"])
    }
    @MainActor static func main() async {
        let scenarios: [(String, @MainActor () async throws -> Void)] = [
            ("restore settings and both favorite types", {
                let s=Server(), store=MemoryStore(); s.favorites["test-a"]=["event-a":"event","content-a":"content"]
                let a=s.state(store);await a.restore()
                try check(a.user?.id == "user-a" && a.settings?.version == "1", "restored account and settings")
                try check(a.favoriteEventIDs == ["event-a"] && a.favoriteContentIDs == ["content-a"], "both favorite types")
                try check(a.lastSyncedAt != nil && !a.isSyncing && !a.syncFailed, "successful sync status")
            }),
            ("login saves issued session and loads account", {
                let s=Server(), store=MemoryStore();store.token=nil;let a=s.state(store);await a.signIn()
                try check(store.token == "test-b" && store.saves == 1 && a.user?.id == "user-b", "issued session saved")
                try check(a.favoriteContentIDs == ["content-b"] && !a.busy, "new account snapshot")
            }),
            ("failed authorization does not create a session", {
                let s=Server(), store=MemoryStore();store.token=nil
                let a=AccountState(transport:{try await s.send($0)},endpoint:{URL(string:"https://account-check.invalid/v1")!},sessionStore:store.storage,authorize:{throw URLError(.cancelled)})
                await a.signIn();try check(a.user == nil && store.token == nil && s.requests.isEmpty && !a.busy && a.errorText != nil,"failed auth has no session side effects")
            }),
            ("new account failed refresh never retains old snapshot", {
                let s=Server(), store=MemoryStore();let a=s.state(store);await a.restore()
                s.intercept={r in if r.httpMethod == "GET" && r.value(forHTTPHeaderField:"Authorization") == "Bearer test-b" {throw URLError(.notConnectedToInternet)};return nil}
                await a.signIn();try check(a.user?.id == "user-b" && a.settings == nil && a.favoriteEventIDs.isEmpty && a.favoriteContentIDs.isEmpty && a.lastSyncedAt == nil,"new account cannot display old settings or favorites")
            }),
            ("logout server failure still clears local session", {
                let s=Server(),store=MemoryStore();let a=s.state(store);await a.restore()
                s.intercept={r in r.url!.path == "/v1/auth/session" ? try s.reply(r,500):nil}
                await a.signOut();try check(a.user == nil && a.settings == nil && a.favoriteEventIDs.isEmpty && store.token == nil && a.errorText?.contains("로그아웃") == true,"remote failure must not resurrect local session")
            }),
            ("offline restore retains recoverable session", {
                let s=Server(), store=MemoryStore();s.intercept={_ in throw URLError(.notConnectedToInternet)}
                let a=s.state(store);await a.restore()
                try check(store.token == "test-a" && a.hasRestorableSession && a.syncFailed, "offline must not erase session")
                s.intercept=nil;await a.refresh();try check(a.user?.id == "user-a" && !a.syncFailed, "retry uses saved session")
            }),
            ("expired restore clears local account", {
                let s=Server(), store=MemoryStore();s.intercept={r in try s.reply(r,401)}
                let a=s.state(store);await a.restore()
                try check(store.token == nil && a.user == nil && a.settings == nil && !a.hasRestorableSession, "401 clears expired session")
            }),
            ("settings conflict reloads version and preserves error", {
                let s=Server(), store=MemoryStore();let a=s.state(store);await a.restore();s.settings["test-a"]!["version"]="2"
                await save(a);try check(a.settings?.version == "2" && a.errorText?.contains("다시 확인") == true, "conflict reload and message")
            }),
            ("favorite conflict retries entire snapshot", {
                let s=Server(), store=MemoryStore();var calls=0
                s.intercept={r in
                    guard r.url!.path == "/v1/me/favorites" else{return nil};calls += 1
                    if calls == 1{return try s.reply(r,200,["favoritesVersion":"1","items":[["targetType":"event","targetId":"discard-me"]],"nextCursor":"page-two"])}
                    if calls == 2{return try s.reply(r,409)}
                    return try s.reply(r,200,["favoritesVersion":"2","items":[["targetType":"content","targetId":"kept"]],"nextCursor":NSNull()])
                }
                let a=s.state(store);await a.restore();try check(calls == 3 && a.favoriteEventIDs.isEmpty && a.favoriteContentIDs == ["kept"], "discard stale first page")
            }),
            ("favorite repeated cursor fails without erasing prior state", {
                let s=Server(), store=MemoryStore();let a=s.state(store);await a.restore();let synced=a.lastSyncedAt
                s.intercept={r in guard r.url!.path == "/v1/me/favorites" else{return nil};return try s.reply(r,200,["favoritesVersion":"1","items":[],"nextCursor":"cycle"])}
                await a.refresh();try check(a.syncFailed && a.favoriteEventIDs == ["event-a"] && a.lastSyncedAt == synced, "invalid paging must preserve last successful snapshot")
            }),
            ("favorite writes and retries after failure", {
                let s=Server(), store=MemoryStore();let a=s.state(store);await a.restore()
                s.intercept={r in r.httpMethod == "PUT" ? try s.reply(r,500):nil}
                await a.toggleFavorite(type:"event",id:"new-event");try check(!a.favoriteEventIDs.contains("new-event") && a.errorText != nil, "failed write is not optimistic success")
                s.intercept=nil;await a.toggleFavorite(type:"event",id:"new-event")
                try await until { s.requests.filter{$0.url!.path == "/v1/me/favorites"}.count >= 2 && !a.isSyncing }
                try check(a.favoriteEventIDs.contains("new-event"), "pending operation released for retry")
            }),
            ("old account 401 cannot clear restored account", {
                let s=Server(), store=MemoryStore();let a=s.state(store);await a.restore();let gate=Gate()
                s.intercept={r in if r.httpMethod == "PUT" && r.value(forHTTPHeaderField:"Authorization") == "Bearer test-a" {await gate.wait();return try s.reply(r,401)};return nil}
                let old=Task {await a.toggleFavorite(type:"event",id:"late")};try await until{gate.waiting}
                await a.signOut();store.token="test-b";await a.restore();gate.release();await old.value
                try check(a.user?.id == "user-b" && store.token == "test-b" && a.favoriteContentIDs == ["content-b"] && a.errorText == nil, "old 401 must not clear new account")
            }),
            ("logout releases busy while old save is pending", {
                let s=Server(), store=MemoryStore();let a=s.state(store);await a.restore();let gate=Gate()
                s.intercept={r in if r.httpMethod == "PUT" && r.url!.path == "/v1/me/settings" {let result=try s.defaultReply(r);await gate.wait();return result};return nil}
                let old=Task{await save(a)};try await until{gate.waiting};await a.signOut()
                let released = !a.busy && a.user == nil && store.token == nil
                gate.release();await old.value;try check(released,"logout must unblock login immediately")
            }),
            ("older settings response cannot overwrite newer save", {
                let s=Server(), store=MemoryStore();let a=s.state(store);await a.restore();let gate=Gate();var puts=0
                s.intercept={r in if r.httpMethod == "PUT" && r.url!.path == "/v1/me/settings" {puts += 1;let result=try s.defaultReply(r);if puts == 1 {await gate.wait()};return result};return nil}
                let old=Task{await save(a,services:["tving"])};try await until{gate.waiting};await a.refresh();await save(a,services:["netflix"])
                gate.release();await old.value
                try check(a.settings?.version == "3" && a.settings?.services == ["netflix"],"late v2 must not replace acknowledged v3")
            }),
            ("old operation cannot release new account busy state", {
                let s=Server(), store=MemoryStore();let a=s.state(store);await a.restore();let first=Gate(), second=Gate()
                s.intercept={r in if r.httpMethod == "PUT" && r.url!.path == "/v1/me/settings" {let result=try s.defaultReply(r);if r.value(forHTTPHeaderField:"Authorization") == "Bearer test-a" {await first.wait()}else{await second.wait()};return result};return nil}
                let old=Task{await save(a)};try await until{first.waiting};await a.signOut();store.token="test-b";await a.restore()
                let newer=Task{await save(a)};try await until{second.waiting};first.release();await old.value;let preserved=a.busy
                second.release();await newer.value;try check(preserved && !a.busy && a.user?.id == "user-b", "old defer must not unlock newer write")
            })
        ]
        var failures:[String]=[]
        for (name, run) in scenarios {
            do {try await run();print("PASS \(name)")} catch {failures.append(name);print("FAIL \(name): \(error)")}
        }
        print("Account flow scenarios: \(scenarios.count-failures.count)/\(scenarios.count) passed; synthetic transport/store/auth only")
        if CommandLine.arguments.contains("--expect-known-failures") {
            let expected:Set<String>=["new account failed refresh never retains old snapshot","logout releases busy while old save is pending","older settings response cannot overwrite newer save","old operation cannot release new account busy state"]
            if Set(failures) != expected {exit(1)}
        } else if !failures.isEmpty {exit(1)}
    }
}
