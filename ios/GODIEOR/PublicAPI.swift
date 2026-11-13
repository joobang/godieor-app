import Foundation

// Matches backend contract 0.1.0-draft.2. Date-only values remain civil-date strings.
struct CatalogOptions: Decodable {
    struct QueryDefaults: Decodable {
        let country: String
        let timeZone: String
    }
    let contractVersion: String
    let categories: [String]
    let services: [String]
    let devices: [String]
    let countries: [String]
    let timeZones: [String]
    let queryDefaults: QueryDefaults
}

struct PublicFilters {
    let categories: [String]
    let services: [String]
    let devices: [String]
    let country: String
    let timeZone: String

    var query: [URLQueryItem] {
        [
            .init(name: "country", value: country),
            .init(name: "timeZone", value: timeZone),
            .init(name: "categories", value: categories.joined(separator: ",")),
            .init(name: "services", value: services.joined(separator: ",")),
            .init(name: "devices", value: devices.joined(separator: ","))
        ]
    }
}

struct ReleaseEvent: Decodable, Identifiable {
    let id: String
    let kind: String
    let ottCategory: String?
    let title: String
    let contentId: String?
    let status: String
    let time: ReleaseTime
    let releaseMarket: String?
    let venueCountry: String?
    let services: [String]
    let devices: [String]
    let dataOrigin: String
    let updatedAt: String

    var categoryTitle: String {
        switch kind {
        case "theatrical_release": "영화"
        case "ott_season_premiere":
            switch ottCategory {
            case "movie": "OTT · 영화"
            case "original_series": "OTT · 오리지널 시리즈"
            case "variety": "OTT · 예능"
            case "documentary": "OTT · 다큐"
            case "other": "OTT · 기타"
            default: "OTT · 시리즈"
            }
        case "game_release": "게임"
        case "epl_match": "EPL"
        default: kind
        }
    }

    var statusTitle: String {
        switch status {
        case "scheduled": "예정"
        case "postponed": "연기"
        case "cancelled": "취소"
        default: status
        }
    }
}

struct ReleaseTime: Decodable {
    let type: String
    let date: String?
    let instantUtc: String?
    let displayDate: String?
    let displayTime: String?
    let announcedYear: Int?
    let announcedPeriod: String?

    var description: String {
        switch type {
        case "date_only": date.map { "\($0) · 날짜만 확인" } ?? "날짜 확인 필요"
        case "instant": [displayDate, displayTime].compactMap { $0 }.joined(separator: " ")
        default: [announcedYear.map(String.init), announcedPeriod].compactMap { $0 }.joined(separator: " ").isEmpty ? "미정" : [announcedYear.map(String.init), announcedPeriod].compactMap { $0 }.joined(separator: " ")
        }
    }
}

struct ReleaseDay: Decodable, Identifiable {
    let date: String
    let total: Int
    let previews: [ReleaseEvent]
    var id: String { date }
}

struct ReleaseCalendar: Decodable {
    let month: String
    let catalogRevision: String
    let days: [ReleaseDay]
    let freshness: [SourceFreshness]
}

struct SourceFreshness: Decodable {
    let providerKey: String
    let coverage: String
    let lastAttemptStatus: String
    let lastSuccessfulAt: String?
    let dataOrigin: String
}

struct ReleasePage: Decodable {
    let catalogRevision: String
    let items: [ReleaseEvent]
    let nextCursor: String?
    let freshness: [SourceFreshness]
}

struct ReleaseDetail: Decodable {
    struct Source: Decodable {
        let providerKey: String
        let url: String
        let observedAt: String
    }
    let event: ReleaseEvent
    let sources: [Source]
    let previousTime: ReleaseTime?
}

enum PublicAPIError: LocalizedError {
    case invalidURL
    case unsupportedContract(String)
    case status(Int)
    case catalogChanged
    case tooManyPages

    var errorDescription: String? {
        switch self {
        case .invalidURL: "API 주소를 확인해 주세요."
        case .unsupportedContract(let version): "지원하지 않는 API 계약 버전(\(version))이에요."
        case .status(let code): "서버 요청 실패 (HTTP \(code)). 연결 및 서버 상태를 확인해 주세요."
        case .catalogChanged: "일정이 변경되어 새로 불러와야 해요."
        case .tooManyPages: "목록 페이지가 반복되어 조회를 중단했어요."
        }
    }
}

enum APIEndpointConfiguration {
    // Both clients use the same HTTPS configuration. Loopback HTTP is only
    // available to public browsing in Simulator, never account credentials.
    static func resolve(environment: [String: String], bundleValue: String?, allowSimulatorLoopback: Bool) -> URL? {
        let override = environment["GODIEOR_API_BASE_URL"]
        let raw = override ?? bundleValue
        let missing = raw == nil || (override == nil && (raw?.contains("YOUR_") == true || raw?.hasPrefix("$(") == true))
        if missing {
            return allowSimulatorLoopback ? URL(string: "http://localhost:3000/v1") : nil
        }
        guard let raw, !raw.isEmpty, raw == raw.trimmingCharacters(in: .whitespacesAndNewlines),
              !raw.contains("YOUR_"), !raw.contains("$("),
              let components = URLComponents(string: raw), let host = components.host, !host.isEmpty,
              components.user == nil, components.password == nil,
              components.query == nil, components.fragment == nil,
              let url = components.url else { return nil }
        if components.scheme?.lowercased() == "https" { return url }
        if allowSimulatorLoopback && components.scheme?.lowercased() == "http" && ["localhost", "127.0.0.1", "[::1]", "::1"].contains(host.lowercased()) { return url }
        return nil
    }

    static func current(allowSimulatorLoopback: Bool = false) -> URL? {
        resolve(environment: ProcessInfo.processInfo.environment,
                bundleValue: Bundle.main.object(forInfoDictionaryKey: "GODIEORAPIBaseURL") as? String,
                allowSimulatorLoopback: allowSimulatorLoopback)
    }

    static var publicURL: URL? {
        #if targetEnvironment(simulator)
        current(allowSimulatorLoopback: true)
        #else
        current()
        #endif
    }
}

struct PublicAPI {
    // Shared environment/bundle HTTPS setting; only Simulator public browsing permits loopback HTTP.
    private let baseURL: URL?
    private let session: URLSession

    init(baseURL: URL? = nil, session: URLSession = .shared) {
        self.baseURL = baseURL ?? APIEndpointConfiguration.publicURL
        self.session = session
    }

    private func get<T: Decodable>(_ path: String, query: [URLQueryItem] = []) async throws -> T {
        guard let baseURL, var components = URLComponents(url: baseURL.appending(path: path), resolvingAgainstBaseURL: false) else {
            throw PublicAPIError.invalidURL
        }
        components.queryItems = query.isEmpty ? nil : query
        guard let url = components.url else { throw PublicAPIError.invalidURL }
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 10
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw PublicAPIError.status(0) }
        if http.statusCode == 409 { throw PublicAPIError.catalogChanged }
        guard (200..<300).contains(http.statusCode) else { throw PublicAPIError.status(http.statusCode) }
        return try JSONDecoder().decode(T.self, from: data)
    }

    func options() async throws -> CatalogOptions {
        let options: CatalogOptions = try await get("catalog/options")
        guard options.contractVersion == "0.1.0-draft.2" else {
            throw PublicAPIError.unsupportedContract(options.contractVersion)
        }
        return options
    }

    func calendar(month: String, filters: PublicFilters) async throws -> ReleaseCalendar {
        try await get("calendar", query: [.init(name: "month", value: month)] + filters.query)
    }

    func events(date: String, filters: PublicFilters, revision: String) async throws -> [ReleaseEvent] {
        let next = CalendarDay.next(date)
        var query: [URLQueryItem] = [
            .init(name: "schedule", value: "dated"),
            .init(name: "from", value: date),
            .init(name: "to", value: next),
            .init(name: "catalogRevision", value: revision),
            .init(name: "limit", value: "100")
        ] + filters.query
        var items: [ReleaseEvent] = []
        var seen = Set<String>()
        while true {
            let page: ReleasePage = try await get("events", query: query)
            guard page.catalogRevision == revision else { throw PublicAPIError.catalogChanged }
            items.append(contentsOf: page.items)
            guard let cursor = page.nextCursor else { return items }
            guard seen.insert(cursor).inserted else { throw PublicAPIError.tooManyPages }
            query.removeAll { $0.name == "cursor" }
            query.append(.init(name: "cursor", value: cursor))
        }
    }

    func detail(id: String, filters: PublicFilters) async throws -> ReleaseDetail {
        try await get("events/\(id)", query: [
            .init(name: "timeZone", value: filters.timeZone)
        ])
    }
}

enum CalendarDay {
    static var iso: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Seoul")!
        return calendar
    }

    static func next(_ day: String) -> String {
        let components = day.split(separator: "-").compactMap { Int($0) }
        guard components.count == 3,
              let date = iso.date(from: DateComponents(year: components[0], month: components[1], day: components[2])),
              let next = iso.date(byAdding: .day, value: 1, to: date) else { return day }
        let result = iso.dateComponents([.year, .month, .day], from: next)
        return String(format: "%04d-%02d-%02d", result.year!, result.month!, result.day!)
    }
}
