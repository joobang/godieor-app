import Foundation

@main struct DocumentaryChecks {
    static func main() throws {
        // Authored synthetic API input, not an implementation-generated fixture.
        let json = #"{"id":"synthetic-doc","kind":"ott_season_premiere","ottCategory":"documentary","title":"가상 다큐","contentId":"synthetic-work","status":"scheduled","time":{"type":"date_only","date":"2026-11-13"},"releaseMarket":"KR","venueCountry":null,"services":["netflix"],"devices":[],"dataOrigin":"fixture","updatedAt":"2026-11-13T00:00:00Z"}"#
        let event = try JSONDecoder().decode(ReleaseEvent.self, from: Data(json.utf8))
        precondition(event.categoryTitle == "OTT · 다큐")
        precondition(event.time.date == "2026-11-13")
        precondition(event.time.instantUtc == nil)
        precondition(event.services == ["netflix"])
        print("PASS synthetic documentary API decoding, category label and date-only preservation")
    }
}
