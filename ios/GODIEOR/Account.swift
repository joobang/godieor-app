import AuthenticationServices
import CryptoKit
import Foundation
import Security
import SwiftUI
import UIKit

struct AccountUser: Decodable {
    let id: String
    let displayName: String?
}

struct AccountSession: Decodable {
    let accessToken: String
    let expiresAt: Date
    let user: AccountUser
}

struct AccountSettings: Codable {
    let version: String
    let country: String
    let timeZone: String
    let enabledCategories: [String]
    let services: [String]
    let devices: [String]
    let view: String
}

struct FavoritePage: Decodable {
    struct Item: Decodable {
        let targetType: String
        let targetId: String
    }
    let favoritesVersion: String
    let items: [Item]
    let nextCursor: String?
}

private enum AccountFailure: LocalizedError {
    case notConfigured, apiNotConfigured, invalidCallback, oauthFailure, sessionExpired, invalidResponse(Int)

    var errorDescription: String? {
        switch self {
        case .notConfigured: "Google OAuth 클라이언트 설정이 필요합니다."
        case .apiNotConfigured: "계정 서버 HTTPS 주소를 설정해 주세요."
        case .invalidCallback: "Google 인증 결과를 확인하지 못했습니다."
        case .oauthFailure: "Google 로그인을 완료하지 못했습니다."
        case .sessionExpired: "로그인 세션이 만료되었습니다. 다시 로그인해 주세요."
        case .invalidResponse(let status): "서버 응답 오류 (\(status))"
        }
    }
}

private enum SessionKeychain {
    private static let service = "com.joobang.godieor.session"
    private static let account = "service-bearer"

    static func load() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    static func save(_ token: String) throws {
        remove()
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
            kSecValueData as String: Data(token.utf8)
        ]
        let code = SecItemAdd(query as CFDictionary, nil)
        guard code == errSecSuccess else { throw AccountFailure.oauthFailure }
    }

    static func remove() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(query as CFDictionary)
    }
}

@MainActor
private final class GoogleAuthorization: NSObject, ASWebAuthenticationPresentationContextProviding {
    private var session: ASWebAuthenticationSession?

    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows).first { $0.isKeyWindow } ?? ASPresentationAnchor()
    }

    func idToken() async throws -> String {
        guard let clientID = Bundle.main.object(forInfoDictionaryKey: "GODIEORGoogleClientID") as? String,
              !clientID.isEmpty, !clientID.contains("YOUR_") else { throw AccountFailure.notConfigured }
        guard let callbackScheme = Bundle.main.object(forInfoDictionaryKey: "GODIEORGoogleCallbackScheme") as? String,
              !callbackScheme.isEmpty, !callbackScheme.contains("YOUR_") else { throw AccountFailure.notConfigured }

        let redirect = "\(callbackScheme):/oauth2redirect"
        let verifier = Self.randomURLSafe(48)
        let challenge = Data(SHA256.hash(data: Data(verifier.utf8))).base64URLEncoded
        let state = Self.randomURLSafe(24)
        let nonce = Self.randomURLSafe(24)
        var authorization = URLComponents(string: "https://accounts.google.com/o/oauth2/v2/auth")!
        authorization.queryItems = [
            .init(name: "client_id", value: clientID),
            .init(name: "redirect_uri", value: redirect),
            .init(name: "response_type", value: "code"),
            .init(name: "scope", value: "openid profile"),
            .init(name: "state", value: state),
            .init(name: "nonce", value: nonce),
            .init(name: "code_challenge", value: challenge),
            .init(name: "code_challenge_method", value: "S256")
        ]
        let callback: URL = try await withCheckedThrowingContinuation { continuation in
            let auth = ASWebAuthenticationSession(url: authorization.url!, callbackURLScheme: callbackScheme) { url, error in
                if let error { continuation.resume(throwing: error) }
                else if let url { continuation.resume(returning: url) }
                else { continuation.resume(throwing: AccountFailure.invalidCallback) }
            }
            auth.presentationContextProvider = self
            auth.prefersEphemeralWebBrowserSession = true
            self.session = auth
            if !auth.start() {
                continuation.resume(throwing: AccountFailure.oauthFailure)
            }
        }
        session = nil
        guard callback.scheme == callbackScheme,
              let items = URLComponents(url: callback, resolvingAgainstBaseURL: false)?.queryItems,
              items.first(where: { $0.name == "state" })?.value == state,
              let code = items.first(where: { $0.name == "code" })?.value else {
            throw AccountFailure.invalidCallback
        }
        var tokenRequest = URLRequest(url: URL(string: "https://oauth2.googleapis.com/token")!)
        tokenRequest.httpMethod = "POST"
        tokenRequest.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        let parameters = ["client_id":clientID,"code":code,"redirect_uri":redirect,"grant_type":"authorization_code","code_verifier":verifier]
        tokenRequest.httpBody = parameters.map { "\($0.key.formEncoded)=\($0.value.formEncoded)" }.joined(separator: "&").data(using: .utf8)
        let (data, response) = try await URLSession.shared.data(for: tokenRequest)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else { throw AccountFailure.oauthFailure }
        struct Token: Decodable { let id_token: String }
        let result = try JSONDecoder().decode(Token.self, from: data)
        // Bind the token returned by Google to this specific browser authorization.
        // Backend verifies its cryptographic signature, issuer, audience and expiry.
        let parts = result.id_token.split(separator: ".")
        guard parts.count == 3 else { throw AccountFailure.invalidCallback }
        var encoded = String(parts[1]).replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        encoded += String(repeating: "=", count: (4 - encoded.count % 4) % 4)
        guard let payload = Data(base64Encoded: encoded),
              let claims = try? JSONSerialization.jsonObject(with: payload) as? [String: Any],
              claims["nonce"] as? String == nonce,
              claims["aud"] as? String == clientID else { throw AccountFailure.invalidCallback }
        return result.id_token
    }

    private static func randomURLSafe(_ count: Int) -> String {
        var bytes = [UInt8](repeating: 0, count: count)
        let status = SecRandomCopyBytes(kSecRandomDefault, count, &bytes)
        precondition(status == errSecSuccess)
        return Data(bytes).base64URLEncoded
    }
}

private extension Data {
    var base64URLEncoded: String {
        base64EncodedString().replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}
private extension String {
    var formEncoded: String {
        addingPercentEncoding(withAllowedCharacters: CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._~")) ?? self
    }
}

@MainActor
final class AccountState: ObservableObject {
    @Published private(set) var user: AccountUser?
    @Published private(set) var settings: AccountSettings?
    @Published private(set) var favoriteEventIDs = Set<String>()
    @Published private(set) var favoriteContentIDs = Set<String>()
    @Published private(set) var busy = false
    @Published var errorText: String?
    private var token: String?
    private var sessionGeneration = 0
    private var pendingFavorites = [String: UUID]()
    private var favoriteMutationRevision = 0
    private let google = GoogleAuthorization()
    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()
    private var baseURL: URL? {
        let configured = ProcessInfo.processInfo.environment["GODIEOR_API_BASE_URL"]
            ?? (Bundle.main.object(forInfoDictionaryKey: "GODIEORAPIBaseURL") as? String)
        guard let configured, !configured.contains("YOUR_"),
              let url = URL(string: configured), url.scheme == "https", url.host != nil,
              url.user == nil, url.password == nil, url.query == nil, url.fragment == nil
        else { return nil }
        return url
    }

    private func request<T: Decodable>(_ path: String, method: String = "GET", body: Data? = nil, authenticated: Bool = true, sessionToken: String? = nil, query: [URLQueryItem] = []) async throws -> T {
        guard let baseURL else { throw AccountFailure.apiNotConfigured }
        var components = URLComponents(url: baseURL.appending(path: path), resolvingAgainstBaseURL: false)!
        components.queryItems = query.isEmpty ? nil : query
        var request = URLRequest(url: components.url!)
        request.httpMethod = method
        request.timeoutInterval = 12
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if body != nil { request.setValue("application/json", forHTTPHeaderField: "Content-Type") }
        if authenticated {
            guard let token = sessionToken ?? token else { throw AccountFailure.sessionExpired }
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        request.httpBody = body
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let status = (response as? HTTPURLResponse)?.statusCode else { throw AccountFailure.invalidResponse(0) }
        if status == 401 { throw AccountFailure.sessionExpired }
        guard (200..<300).contains(status) else { throw AccountFailure.invalidResponse(status) }
        return try decoder.decode(T.self, from: data)
    }

    private func update(_ path: String, method: String, sessionToken: String? = nil) async throws {
        guard let baseURL else { throw AccountFailure.apiNotConfigured }
        var request = URLRequest(url: baseURL.appending(path: path))
        request.httpMethod = method
        guard let token = sessionToken ?? token else { throw AccountFailure.sessionExpired }
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        let (_, response) = try await URLSession.shared.data(for: request)
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        if status == 401 { throw AccountFailure.sessionExpired }
        guard status == 204 else { throw AccountFailure.invalidResponse(status) }
    }

    func restore() async {
        guard let token = SessionKeychain.load() else { return }
        sessionGeneration += 1
        self.token = token
        await refresh()
    }

    func signIn() async {
        guard !busy else { return }
        busy = true
        defer { busy = false }
        let generation = sessionGeneration
        do {
            let idToken = try await google.idToken()
            guard generation == sessionGeneration else { return }
            let body = try JSONSerialization.data(withJSONObject: ["idToken": idToken])
            let session: AccountSession = try await request("auth/google", method: "POST", body: body, authenticated: false)
            guard generation == sessionGeneration else { return }
            try SessionKeychain.save(session.accessToken)
            sessionGeneration += 1
            token = session.accessToken
            user = session.user
            errorText = nil
            await refresh()
        } catch {
            if generation == sessionGeneration { errorText = error.localizedDescription }
        }
    }

    func refresh() async {
        guard let activeToken = token else { return }
        let generation = sessionGeneration
        let mutationRevision = favoriteMutationRevision
        do {
            let profile: AccountUser = try await request("me", sessionToken: activeToken)
            guard generation == sessionGeneration, token == activeToken else { return }
            let remote: AccountSettings = try await request("me/settings", sessionToken: activeToken)
            guard generation == sessionGeneration, token == activeToken else { return }
            var allFavorites: [FavoritePage.Item] = []
            // Another device may update favorites while this device is paging.
            // Retry the complete snapshot once on a version conflict.
            for attempt in 0..<2 {
                do {
                    allFavorites = try await loadFavoriteSnapshot(sessionToken: activeToken)
                    break
                } catch AccountFailure.invalidResponse(409) where attempt == 0 {
                    continue
                }
            }
            guard generation == sessionGeneration, token == activeToken else { return }
            user = profile
            settings = remote
            // A snapshot started before a favorite write must not undo its newer UI state.
            if mutationRevision == favoriteMutationRevision && pendingFavorites.isEmpty {
                favoriteEventIDs = Set(allFavorites.filter { $0.targetType == "event" }.map(\.targetId))
                favoriteContentIDs = Set(allFavorites.filter { $0.targetType == "content" }.map(\.targetId))
            }
            errorText = nil
        } catch {
            guard generation == sessionGeneration, token == activeToken else { return }
            if case AccountFailure.sessionExpired = error { clearLocal() }
            errorText = error.localizedDescription
        }
    }

    private func loadFavoriteSnapshot(sessionToken: String) async throws -> [FavoritePage.Item] {
        var items: [FavoritePage.Item] = []
        var cursor: String?
        var version: String?
        var seen = Set<String>()
        repeat {
            var query = [URLQueryItem(name: "limit", value: "100")]
            if let cursor { query.append(.init(name: "cursor", value: cursor)) }
            if let version { query.append(.init(name: "favoritesVersion", value: version)) }
            let page: FavoritePage = try await request("me/favorites", sessionToken: sessionToken, query: query)
            if let version, page.favoritesVersion != version { throw AccountFailure.invalidResponse(409) }
            version = page.favoritesVersion
            items.append(contentsOf: page.items)
            cursor = page.nextCursor
            if let cursor, !seen.insert(cursor).inserted { throw AccountFailure.invalidResponse(409) }
        } while cursor != nil
        return items
    }

    func saveSettings(country: String, timeZone: String, categories: [String], services: [String], devices: [String]) async {
        guard let version = settings?.version, let activeToken = token else { return }
        let generation = sessionGeneration
        busy = true
        defer { busy = false }
        do {
            let payload: [String: Any] = [
                "expectedVersion": version, "country": country, "timeZone": timeZone,
                "enabledCategories": categories, "services": services, "devices": devices,
                "view": settings?.view ?? "calendar"
            ]
            let body = try JSONSerialization.data(withJSONObject: payload)
            let updated: AccountSettings = try await request("me/settings", method: "PUT", body: body, sessionToken: activeToken)
            guard generation == sessionGeneration, token == activeToken else { return }
            settings = updated
            errorText = nil
        } catch {
            guard generation == sessionGeneration, token == activeToken else { return }
            let message = error.localizedDescription
            // Reload the latest version but preserve the conflict message for the user.
            await refresh()
            if generation == sessionGeneration, token == activeToken {
                errorText = message + " 계정 설정을 다시 확인한 뒤 저장해 주세요."
            }
        }
    }

    func toggleFavorite(type: String, id: String) async {
        guard user != nil, let activeToken = token, type == "event" || type == "content" else { return }
        let pendingKey = "\(type):\(id)"
        guard pendingFavorites[pendingKey] == nil else { return }
        let operationID = UUID()
        pendingFavorites[pendingKey] = operationID
        favoriteMutationRevision += 1
        defer {
            if pendingFavorites[pendingKey] == operationID {
                pendingFavorites.removeValue(forKey: pendingKey)
                favoriteMutationRevision += 1
            }
        }
        let generation = sessionGeneration
        let saved = type == "event" ? favoriteEventIDs.contains(id) : favoriteContentIDs.contains(id)
        do {
            try await update("me/favorites/\(type == "event" ? "events" : "contents")/\(id)", method: saved ? "DELETE" : "PUT", sessionToken: activeToken)
            guard generation == sessionGeneration, token == activeToken else { return }
            if type == "event" {
                if saved { favoriteEventIDs.remove(id) } else { favoriteEventIDs.insert(id) }
            } else {
                if saved { favoriteContentIDs.remove(id) } else { favoriteContentIDs.insert(id) }
            }
            errorText = nil
            // Reconcile concurrent changes made by another device after this write.
            Task { await refresh() }
        } catch {
            if generation == sessionGeneration, token == activeToken {
                errorText = error.localizedDescription
            }
        }
    }

    func signOut() async {
        let departingToken = token
        clearLocal()
        errorText = nil
        let generation = sessionGeneration
        if let departingToken {
            do { try await update("auth/session", method: "DELETE", sessionToken: departingToken) }
            catch {
                if generation == sessionGeneration {
                    errorText = "서버에서 로그아웃을 확인하지 못했습니다: \(error.localizedDescription)"
                }
            }
        }
    }

    private func clearLocal() {
        sessionGeneration += 1
        pendingFavorites.removeAll()
        favoriteMutationRevision += 1
        SessionKeychain.remove()
        token = nil
        user = nil
        settings = nil
        favoriteEventIDs.removeAll()
        favoriteContentIDs.removeAll()
    }
}
