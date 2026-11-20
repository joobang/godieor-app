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
        precondition(query["from"] == (singleDay ? "2027-01-01" : "2026-12-30"))
        precondition(query["to"] == "2027-01-02")
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
        let data = try! JSONSerialization.data(withJSONObject: page)
        let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: data)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}

@main private struct PosterFeedChecks {
    static func main() async throws {
        precondition(CalendarDay.offset("2027-01-01", by: -2) == "2026-12-30")
        precondition(CalendarDay.offset("2028-03-01", by: -2) == "2028-02-28")
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [FeedProtocol.self]
        let session = URLSession(configuration: config)
        let filters = PublicFilters(categories: ["game"], services: [], devices: [], country: "KR", timeZone: "Asia/Seoul")
        let feed = PublicAPI(baseURL: URL(string: "https://feed.invalid/v1"), session: session)
        let rows = try await feed.events(from: "2026-12-30", to: "2027-01-02", filters: filters)
        precondition(rows.map(\.id) == ["first", "next"])
        precondition(rows.compactMap { $0.time.civilDate } == ["2026-12-31", "2027-01-01"])
        let calendar = PublicAPI(baseURL: URL(string: "https://calendar.invalid/v1"), session: session)
        let day = try await calendar.events(date: "2027-01-01", filters: filters, revision: "fixture-revision")
        precondition(day.count == 1)
        let changed = PublicAPI(baseURL: URL(string: "https://changed.invalid/v1"), session: session)
        do {
            _ = try await changed.events(from: "2026-12-30", to: "2027-01-02", filters: filters)
            preconditionFailure("A request must reject a page from a different catalog revision")
        } catch PublicAPIError.catalogChanged {}
        print("Poster feed checks passed: calendar date boundaries, paging, and catalog revision")
    }
}
