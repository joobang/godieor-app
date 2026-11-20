import Foundation

@main
struct ReleaseCardChecks {
    static func main() throws {
        func event(_ id: String, device: String, day: String = "2026-11-20",
                   market: String = "WORLD", status: String = "scheduled", kind: String = "game_release",
                   content: String = "one", origin: String = "provider") throws -> ReleaseEvent {
            let row: [String: Any] = [
                "id": id, "title": "Synthetic title", "kind": kind, "contentId": content,
                "status": status, "time": ["type": "date_only", "date": day], "releaseMarket": market,
                "services": [], "devices": [device], "dataOrigin": origin, "updatedAt": "2026-11-20T12:00:00Z"
            ]
            return try JSONDecoder().decode(ReleaseEvent.self, from: JSONSerialization.data(withJSONObject: row))
        }
        let cards = ReleaseCard.group(try [
            event("pc", device: "pc"),
            event("ott", device: "ios", kind: "ott_season_premiere"),
            event("switch", device: "switch"),
            event("xbox", device: "xbox"),
            event("later", device: "xbox", day: "2026-11-21"),
            event("kr", device: "playstation", market: "KR"),
            event("cancelled", device: "switch", status: "cancelled"),
            event("same-name", device: "ios", content: "two"),
            event("fixture", device: "android", origin: "fixture")
        ])
        precondition(cards.map(\.id) == ["ott", "switch", "later", "cancelled", "same-name", "fixture"])
        precondition(cards[1].variants.map(\.id) == ["switch", "xbox", "kr"])
        precondition(Set(cards[1].devices) == ["playstation", "switch", "xbox"])
        precondition(cards[1].markets == ["WORLD", "KR"])
        precondition(cards[1].commonMarket == nil)
        precondition(cards[2].commonMarket == "WORLD")
        print("Release card grouping checks passed")
    }
}
