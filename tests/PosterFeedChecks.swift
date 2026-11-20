import Foundation

private final class FeedProtocol: URLProtocol, @unchecked Sendable {
    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        let url = request.url!
        let items = URLComponents(url: url, resolvingAgainstBaseURL: false)!.queryItems!
        let query = Dictionary(uniqueKeysWithValues: items.compactMap { item in item.value.map { (item.name, $0) } })
        precondition(url.path == "/v1/events")
        precondition(query["schedule"] == "dated" && query["limit"] == "100")
        precondition(query["categories"] == "game" && query["timeZone"] == "Asia/Seoul")
        let singleDay = url.host == "calendar.invalid"
        precondition(query["from"] == (singleDay ? "2027-01-01" : "2026-12-31"))
        precondition(query["to"] == (singleDay ? "2027-01-02" : "2027-01-03"))
        let second = query["cursor"] != nil
        if second {
            precondition(query["cursor"] == "page-2" && query["catalogRevision"] == "fixture-revision")
        } else {
            precondition(query["catalogRevision"] == (singleDay ? "fixture-revision" : nil))
        }

        let visit = second ? "2027-01-01" : (singleDay ? "2027-01-01" : "2026-12-31")
        let revision = url.host == "changed.invalid" && second ? "new-revision" : "fixture-revision"
        let event: [String: Any] = [
            "id": second ? "next" : "first", "kind": "game_release", "title": "가상",
            "status": "scheduled", "time": ["type": "date_only", "date": visit], "services": [],
            "devices": ["playstation"], "dataOrigin": "fixture", "updatedAt": "2026-12-01T00:00:00Z"
        ]
        let page: [String: Any] = [
            "catalogRevision": revision, "items": [event],
            "nextCursor": second || singleDay ? NSNull() as Any : "page-2", "freshness": []
        ]
        var responsePage = page
        if second {
            var tomorrow = event
            tomorrow["id"] = "tomorrow"
            tomorrow["time"] = [
                "type": "instant", "instantUtc": "2027-01-01T15:00:00Z",
                "displayDate": "2027-01-02", "displayTime": "00:00"
            ]
            responsePage["items"] = [event, tomorrow]
        }
        let data = try! JSONSerialization.data(withJSONObject: responsePage)
        let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: data)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}

@main private struct PosterFeedChecks {
    static func main() async throws {
        let window = PosterFeedWindow(today: "2027-01-01")
        precondition(window.chronologicalDates == ["2026-12-31", "2027-01-01", "2027-01-02"])
        precondition(window.exclusiveEnd == "2027-01-03")
        precondition(window.chronologicalDates.map { window.label(for: $0) } == ["어제", "오늘", "내일"])
        let leapWindow = PosterFeedWindow(today: "2028-02-29")
        precondition(leapWindow.chronologicalDates == ["2028-02-28", "2028-02-29", "2028-03-01"])
        precondition(leapWindow.exclusiveEnd == "2028-03-02")
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [FeedProtocol.self]
        let session = URLSession(configuration: config)
        let filters = PublicFilters(categories: ["game"], services: [], devices: [], country: "KR", timeZone: "Asia/Seoul")
        let feed = PublicAPI(baseURL: URL(string: "https://feed.invalid/v1"), session: session)
        let rows = try await feed.events(from: window.yesterday, to: window.exclusiveEnd, filters: filters)
        precondition(rows.map(\.id) == ["first", "next", "tomorrow"])
        precondition(window.cards(from: rows).map(\.id) == ["next", "tomorrow", "first"])
        precondition(window.cards(from: rows.filter { $0.id != "next" }).map(\.id) == ["tomorrow", "first"])
        precondition(PosterFeedWindow(today: "2027-01-02").cards(from: rows).map(\.id) == ["tomorrow", "next"])
        let calendar = PublicAPI(baseURL: URL(string: "https://calendar.invalid/v1"), session: session)
        let day = try await calendar.events(date: "2027-01-01", filters: filters, revision: "fixture-revision")
        precondition(day.count == 1)
        let changed = PublicAPI(baseURL: URL(string: "https://changed.invalid/v1"), session: session)
        do {
            _ = try await changed.events(from: window.yesterday, to: window.exclusiveEnd, filters: filters)
            preconditionFailure("A request must reject a page from a different catalog revision")
        } catch PublicAPIError.catalogChanged {}
        print("Poster feed checks passed: calendar date boundaries, paging, and catalog revision")
    }
}
