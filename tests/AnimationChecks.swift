import Foundation

@main struct AnimationChecks {
    static func main() throws {
        // Independently authored synthetic contract example; no provider data.
        let json = #"{"id":"synthetic-animation","kind":"ott_season_premiere","ottCategory":"animation","title":"가상 애니","contentId":"synthetic-work","status":"scheduled","time":{"type":"date_only","date":"2026-11-27"},"releaseMarket":"KR","venueCountry":null,"services":["netflix"],"devices":[],"dataOrigin":"fixture","updatedAt":"2026-11-16T00:00:00Z"}"#
        let event = try JSONDecoder().decode(ReleaseEvent.self, from: Data(json.utf8))
        precondition(event.categoryTitle == "OTT · 애니")
        precondition(event.time.date == "2026-11-27")
        precondition(event.time.instantUtc == nil)
        precondition(event.services == ["netflix"])
        print("PASS synthetic animation contract decoding/label/date-only")
    }
}
