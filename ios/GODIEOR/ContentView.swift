import SwiftUI

enum DiscoveryPalette {
    static let background = Color(red: 0.965, green: 0.965, blue: 0.949)
    static let primary = Color(red: 0.76, green: 0.19, blue: 0.12)
    static let panel = Color.white
    static let text = Color(red: 0.09, green: 0.09, blue: 0.085)
    static let muted = Color(red: 0.35, green: 0.35, blue: 0.33)
    static let line = Color.black.opacity(0.13)
    static let surface = Color(red: 0.933, green: 0.933, blue: 0.913)
    static let highlight = Color(red: 1, green: 0.94, blue: 0.91)
    static let feedGameAccent = Color(red: 0.74, green: 0.52, blue: 0.14)

    static func accent(_ key: String) -> Color {
        key == "movie" || key == "theatrical_release" ? primary : text
    }

    static func symbol(_ key: String) -> String {
        switch key {
        case "movie", "theatrical_release": "film"
        case "ott", "ott_season_premiere": "play.rectangle"
        case "game", "game_release": "gamecontroller"
        case "epl", "epl_match": "soccerball"
        default: "calendar"
        }
    }
}

struct ContentView: View {
    private let backdrop = DiscoveryPalette.background
    private let primary = DiscoveryPalette.primary
    private let panel = DiscoveryPalette.panel

    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.dynamicTypeSize) private var typeSize
    @StateObject private var account = AccountState()
    @State private var clock = Date.now
    @State private var loadedCalendarKey = ""
    @State private var month = CalendarDay.iso.date(from: CalendarDay.iso.dateComponents([.year, .month], from: .now))!
    @State private var selectedDate: String?
    @State private var shouldSelectToday = true
    @AppStorage("temporaryVisibleCategories") private var storedCategories = "movie,ott,game"
    @AppStorage("temporaryCountry") private var storedCountry = ""
    @AppStorage("temporaryTimeZone") private var storedTimeZone = ""
    @AppStorage("temporaryServices") private var storedServices = ""
    @AppStorage("temporaryDevices") private var storedDevices = ""
    @AppStorage("temporaryFiltersAccountOwner") private var storedFilterOwner = ""
    @State private var catalogOptions: CatalogOptions?
    @State private var optionsError: String?
    @State private var showingFilters = false
    @State private var showingAccount = false
    @State private var calendar: ReleaseCalendar?
    @State private var lastCalendars: [String: ReleaseCalendar] = [:]
    @State private var showingCachedCalendar = false
    @State private var events: [ReleaseEvent] = []
    @State private var loading = false
    @State private var loadingDay = false
    @State private var dayRequestID = UUID()
    @State private var dayCache: [String: [ReleaseEvent]] = [:]
    @State private var errorText: String?
    @State private var dayError: String?
    private enum DashboardTab: Hashable { case home, calendar, saved }
    @State private var tab: DashboardTab = .home
    @State private var feed = FeedState()
    @State private var selection: DetailSelection?
    @State private var selectedContent: CatalogContent?
    private struct FeedState {
        var key = ""
        var requestID = UUID()
        var cards: [ReleaseCard] = []
        var loading = false
        var error: String?
    }
    private struct DetailSelection: Identifiable {
        let card: ReleaseCard
        let filters: PublicFilters
        var ownerID: String? = nil
        var id: String { card.id }
    }
    private let api = PublicAPI()
    private let options = [("movie", "영화"), ("ott", "OTT"), ("game", "게임"), ("epl", "EPL")]

    private var monthKey: String {
        let c = CalendarDay.iso.dateComponents([.year, .month], from: month)
        return String(format: "%04d-%02d", c.year!, c.month!)
    }
    private var activeCategories: Set<String> { Set(storedCategories.split(separator: ",").map(String.init)) }
    private var categories: [String] { options.map { $0.0 }.filter { activeCategories.contains($0) } }
    private var activeServices: Set<String> { Set(storedServices.split(separator: ",").map(String.init)) }
    private var activeDevices: Set<String> {
        Set(storedDevices.split(separator: ",").map(String.init)).intersection(GamePlatform.supported)
    }
    private var filters: PublicFilters? {
        guard let catalogOptions else { return nil }
        return PublicFilters(
            categories: categories,
            services: catalogOptions.services.filter { activeServices.contains($0) },
            devices: catalogOptions.devices.filter { activeDevices.contains($0) },
            country: catalogOptions.countries.contains(storedCountry) ? storedCountry : catalogOptions.queryDefaults.country,
            timeZone: catalogOptions.timeZones.contains(storedTimeZone) ? storedTimeZone : catalogOptions.queryDefaults.timeZone
        )
    }
    private var selectionKey: String {
        guard let filters else { return monthKey + ":options-unavailable" }
        return ([monthKey, historyStart, filters.country, filters.timeZone] + filters.categories + ["services"] + filters.services + ["devices"] + filters.devices).joined(separator: ":")
    }
    private var daySelectionKey: String {
        [selectedDate ?? "", selectionKey, calendar?.month ?? "", calendar?.catalogRevision ?? ""].joined(separator: ":")
    }
    private var days: [String: ReleaseDay] { Dictionary(uniqueKeysWithValues: (calendar?.days ?? []).map { ($0.date, $0) }) }

    var body: some View {
        TabView(selection: $tab) {
            dashboardPage {
                posterFeed
                    .task(id: feedKey) { await loadFeed() }
            }
            .refreshable { await loadFeed() }
            .tabItem { Label("홈", systemImage: "house") }
            .tag(DashboardTab.home)

            dashboardPage {
                VStack(alignment: .leading, spacing: 10) {
                    categoryFilters
                    if activeCategories.contains("ott") || !activeServices.isEmpty { serviceChips }
                }
                .padding(.horizontal, 18)
                calendarContent.padding(.horizontal, 18)
            }
            .task(id: selectionKey) { await loadMonth(selection: selectionKey) }
            .task(id: daySelectionKey) {
                if let selectedDate { await loadDay(selectedDate, selection: selectionKey) }
            }
            .tabItem { Label("달력", systemImage: "calendar") }
            .tag(DashboardTab.calendar)

            dashboardPage { savedPage.id(account.user?.id).padding(.horizontal, 18) }
                .tabItem { Label("찜", systemImage: "bookmark") }
                .tag(DashboardTab.saved)
        }
        .background(backdrop.ignoresSafeArea())
        .foregroundStyle(DiscoveryPalette.text)
        .tint(primary)
        .preferredColorScheme(.light)
        .sheet(item: $selection) { selected in
            NavigationStack {
                ReleaseCardDetail(card: selected.card, filters: selected.filters, api: api)
            }
        }
        .sheet(item: $selectedContent) { content in
            NavigationStack { SavedContentDetail(content: content) }
        }
        .sheet(isPresented: $showingFilters) { filterSheet }
        .sheet(isPresented: $showingAccount) {
            NavigationStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        accountPanel
                        Divider()
                        tmdbCredits
                    }
                    .padding()
                }
                    .navigationTitle("계정 및 동기화")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("완료") { showingAccount = false }
                        }
                    }
            }
        }
        .onChange(of: account.settings?.version) { _, _ in applyAccountSettings() }
        .onChange(of: account.user?.id) { previous, current in
            if previous != current {
                selectedContent = nil
                if selection?.ownerID != nil { selection = nil }
                if previous != nil { resetDeviceFilters() }
            }
            if current != nil { applyAccountSettings() }
        }
        .task { await initializeAccount() }
        .task(id: "\(displayCalendar.timeZone.identifier)|\(scenePhase)") {
            if scenePhase == .active { await updateDateAtMidnight(calendar: displayCalendar) }
        }
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active, account.hasRestorableSession else { return }
            Task {
                await account.refresh()
                applyAccountSettings()
            }
        }
    }

    private func dashboardPage<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 17) {
                dashboardHeader.padding(.horizontal, 18)
                content()
            }
            .frame(maxWidth: 600)
            .padding(.top, 8)
            .padding(.bottom, 24)
            .frame(maxWidth: .infinity)
        }
        .background(backdrop.ignoresSafeArea())
    }

    private var feedKey: String {
        guard let filters else { return "waiting" }
        return ([todaySelection.date] + filters.query.compactMap(\.value)).joined(separator: "|")
    }

    private var posterFeed: some View {
        let window = PosterFeedWindow(today: todaySelection.date)
        return VStack(alignment: .leading, spacing: 13) {
            VStack(alignment: .leading, spacing: 3) {
                Text("\(dateLabel(window.yesterday)) – \(dateLabel(window.tomorrow))")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(DiscoveryPalette.muted)
                Text("공개 피드")
                    .font(.system(.largeTitle, weight: .black))
                    .tracking(-1)
                    .accessibilityAddTraits(.isHeader)
            }
            .padding(.horizontal, 18)

            if let optionsError {
                feedMessage("필터 정보를 불러오지 못했어요", detail: optionsError, icon: "wifi.exclamationmark")
                Button("다시 시도") { Task { await loadOptions() } }.padding(.horizontal, 18)
            } else if filters != nil && categories.isEmpty {
                feedMessage("표시할 분야를 선택해 주세요", detail: "필터에서 영화, OTT, 게임, EPL을 고를 수 있어요.", icon: "slider.horizontal.3")
                Button("필터 열기") { showingFilters = true }.padding(.horizontal, 18)
            } else if filters == nil || feed.key != feedKey || (feed.loading && feed.cards.isEmpty) {
                ProgressView("공개 일정 불러오는 중").frame(maxWidth: .infinity).padding(.vertical, 44)
            } else {
                if !feed.cards.isEmpty {
                    ScrollView(.horizontal) {
                        LazyHStack(alignment: .top, spacing: 12) {
                            ForEach(feed.cards) { card in
                                PosterFeedCard(card: card, api: api,
                                               dateText: feedDate(card.event.time, window: window),
                                               saved: isFavorite(card.event),
                                               canSave: account.user == nil || account.favoritesReady || account.syncFailed,
                                               open: { open(card) },
                                               save: { toggleFavorite(card.event) })
                                    .containerRelativeFrame(.horizontal) { width, _ in
                                        width * (typeSize.isAccessibilitySize ? 1 : 0.89)
                                    }
                            }
                        }
                        .scrollTargetLayout()
                    }
                    .safeAreaPadding(.horizontal, 18)
                    .scrollTargetBehavior(.viewAligned)
                    .scrollIndicators(.hidden)
                    .accessibilityIdentifier("poster-feed")
                }
                if feed.error == nil || !feed.cards.isEmpty {
                    feedDateLinks(window)
                }
                if let error = feed.error {
                    feedMessage("공개 일정을 불러오지 못했어요", detail: error, icon: "wifi.exclamationmark")
                    Button("다시 시도") { Task { await loadFeed() } }.padding(.horizontal, 18)
                } else if feed.cards.isEmpty {
                    feedMessage("최근 공개 일정이 없어요", detail: "달력에서 다른 날짜를 찾아볼 수 있어요.", icon: "rectangle.stack")
                    Button("달력 열기") { tab = .calendar }.padding(.horizontal, 18)
                }
            }
        }
    }

    @MainActor private func updateDateAtMidnight(calendar: Calendar) async {
        while !Task.isCancelled {
            clock = .now
            guard let tomorrow = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: clock)) else { return }
            do { try await Task.sleep(for: .seconds(max(0.1, tomorrow.timeIntervalSinceNow))) }
            catch { return }
        }
    }

    private func feedDateLinks(_ window: PosterFeedWindow) -> some View {
        let counts = Dictionary(grouping: feed.cards, by: { $0.event.time.civilDate ?? "" }).mapValues(\.count)
        return VStack(alignment: .leading, spacing: 9) {
            Divider()
            Text("날짜별 일정")
                .font(.headline)
                .accessibilityAddTraits(.isHeader)
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 7) { feedDateButtons(window, counts: counts) }
                VStack(alignment: .leading, spacing: 6) { feedDateButtons(window, counts: counts) }
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 15)
    }

    private func feedDateButtons(_ window: PosterFeedWindow, counts: [String: Int]) -> some View {
        ForEach(window.chronologicalDates.filter { $0 >= historyStart }, id: \.self) { date in
            let label = window.label(for: date) ?? dateLabel(date)
            Button {
                let monthParts = date.split(separator: "-").prefix(2).compactMap { Int($0) }
                guard monthParts.count == 2,
                      let monthStart = CalendarDay.iso.date(from: DateComponents(year: monthParts[0], month: monthParts[1])) else { return }
                month = monthStart
                selectDay(date)
                tab = .calendar
            } label: {
                HStack(spacing: 4) {
                    Text(label)
                    Text("\(counts[date, default: 0])").foregroundStyle(DiscoveryPalette.muted)
                }
                .font(.subheadline.weight(.semibold))
                .fixedSize(horizontal: true, vertical: false)
                .padding(.horizontal, 10)
                .frame(minHeight: 44)
                .background(DiscoveryPalette.surface, in: Capsule())
            }
            .accessibilityLabel("\(label), \(dateLabel(date)) 일정 \(counts[date, default: 0])건")
            .buttonStyle(.plain)
        }
    }

    private func feedMessage(_ title: String, detail: String, icon: String) -> some View {
        ContentUnavailableView(title, systemImage: icon, description: Text(detail)).padding(.horizontal, 18)
    }

    private func feedDate(_ time: ReleaseTime, window: PosterFeedWindow) -> String {
        guard let day = time.civilDate else { return time.description }
        let label = window.label(for: day) ?? dateLabel(day)
        if let clock = time.displayTime { return "\(label) · \(clock)" }
        return label
    }

    @MainActor private func loadFeed() async {
        guard let filters, !filters.categories.isEmpty else { feed = FeedState(); return }
        let key = feedKey
        let window = PosterFeedWindow(today: todaySelection.date)
        let start = max(historyStart, window.yesterday)
        let end = window.exclusiveEnd
        let requestID = UUID()
        if feed.key != key { feed = FeedState(key: key) }
        feed.requestID = requestID
        feed.loading = true
        feed.error = nil
        defer { if feed.requestID == requestID { feed.loading = false } }
        do {
            let records: [ReleaseEvent]
            do {
                records = try await api.events(from: start, to: end, filters: filters)
            } catch PublicAPIError.catalogChanged {
                records = try await api.events(from: start, to: end, filters: filters)
            }
            guard !Task.isCancelled, feedKey == key, feed.requestID == requestID else { return }
            feed.cards = window.cards(from: records)
        } catch {
            guard !Task.isCancelled, feedKey == key, feed.requestID == requestID else { return }
            feed.error = error.localizedDescription
        }
    }

    private func open(_ card: ReleaseCard) {
        guard let filters else { return }
        selection = DetailSelection(card: card, filters: filters)
    }

    private func isFavorite(_ event: ReleaseEvent) -> Bool {
        event.contentId.map { account.favoriteContentIDs.contains($0) } ?? account.favoriteEventIDs.contains(event.id)
    }

    private func toggleFavorite(_ event: ReleaseEvent) {
        guard account.user != nil, account.favoritesReady else { showingAccount = true; return }
        Task {
            if let id = event.contentId { await account.toggleFavorite(type: "content", id: id) }
            else { await account.toggleFavorite(type: "event", id: event.id) }
        }
    }

    private var savedPage: some View {
        LazyVStack(alignment: .leading, spacing: 12) {
            Text("찜").font(.largeTitle.weight(.black)).accessibilityAddTraits(.isHeader)
            if account.user == nil {
                ContentUnavailableView("계정 연결", systemImage: "bookmark", description: Text("로그인하면 저장한 작품과 일정을 볼 수 있어요."))
                Button("계정 열기") { showingAccount = true }
            } else if account.isSyncing && account.favoriteContentIDs.isEmpty && account.favoriteEventIDs.isEmpty {
                ProgressView("찜 불러오는 중")
            } else if account.syncFailed && account.favoriteContentIDs.isEmpty && account.favoriteEventIDs.isEmpty {
                ContentUnavailableView("찜을 불러오지 못했어요", systemImage: "wifi.exclamationmark")
                Button("다시 시도") { Task { await account.refresh() } }
            } else if account.favoriteContentIDs.isEmpty && account.favoriteEventIDs.isEmpty {
                ContentUnavailableView("아직 찜한 작품이 없어요", systemImage: "bookmark")
            } else {
                ForEach(account.favoriteContentIDs.sorted(), id: \.self) { id in
                    savedRow(id: id, type: .content)
                }
                ForEach(account.favoriteEventIDs.sorted(), id: \.self) { id in
                    savedRow(id: id, type: .event)
                }
            }
        }
    }

    private func savedRow(id: String, type: SavedReleaseRow.Target) -> some View {
        let ownerID = account.user?.id
        return SavedReleaseRow(id: id, type: type, filters: filters, api: api,
            openContent: { content in
                if let ownerID, account.user?.id == ownerID { selectedContent = content }
            }, openEvent: { card in
                if let ownerID, account.user?.id == ownerID, let filters {
                    selection = DetailSelection(card: card, filters: filters, ownerID: ownerID)
                }
            }, remove: {
                Task {
                    guard let ownerID, account.user?.id == ownerID, account.favoritesReady else { return }
                    let exists = type == .content ? account.favoriteContentIDs.contains(id) : account.favoriteEventIDs.contains(id)
                    if exists { await account.toggleFavorite(type: type.rawValue, id: id) }
                }
            })
    }

    private var dashboardHeader: some View {
        HStack(spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("고디어")
                    .font(.system(.largeTitle, weight: .black))
                    .tracking(-2)
                    .accessibilityAddTraits(.isHeader)
                Image(systemName: "arrow.up.right")
                    .font(.title3.weight(.black))
                    .foregroundStyle(primary)
                    .accessibilityHidden(true)
            }
            Spacer(minLength: 0)
            Button { showingFilters = true } label: {
                dashboardIcon("slider.horizontal.3")
            }
            .accessibilityLabel("상세 필터")
            .disabled(catalogOptions == nil)
            Button { showingAccount = true } label: {
                dashboardIcon(account.user == nil ? "person.crop.circle" : "person.crop.circle.fill")
            }
            .accessibilityLabel("계정 및 동기화 설정")
        }
        .buttonStyle(.plain)
    }

    private func dashboardIcon(_ symbol: String) -> some View {
        Image(systemName: symbol)
            .font(.system(size: 17, weight: .semibold))
            .frame(width: 44, height: 44)
            .background(panel.opacity(0.84), in: Circle())
            .overlay(Circle().strokeBorder(DiscoveryPalette.line))
    }

    private var categoryFilters: some View {
        ViewThatFits(in: .horizontal) {
            categoryFilterRow
            ScrollView(.horizontal) { categoryFilterRow }
                .scrollIndicators(.hidden)
        }
    }

    private var categoryFilterRow: some View {
        HStack(spacing: 6) {
            ForEach(options, id: \.0) { option in
                let selected = activeCategories.contains(option.0)
                Button {
                    setCategory(option.0, enabled: !selected)
                } label: {
                    Label(option.1, systemImage: DiscoveryPalette.symbol(option.0))
                        .font(.subheadline.weight(.bold))
                        .fixedSize()
                        .foregroundStyle(selected ? .white : DiscoveryPalette.text)
                        .padding(.horizontal, 10)
                        .frame(minHeight: 44)
                        .frame(maxWidth: .infinity)
                        .background(selected ? DiscoveryPalette.text : panel, in: Capsule())
                        .overlay(Capsule().strokeBorder(selected ? .clear : DiscoveryPalette.line))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(option.1) \(selected ? "선택됨" : "선택 안 됨")")
                .accessibilityAddTraits(selected ? [.isSelected] : [])
            }
        }
    }

    private func setCategory(_ key: String, enabled: Bool) {
        var next = activeCategories
        if enabled { next.insert(key) } else { next.remove(key) }
        storedCategories = options.map(\.0).filter { next.contains($0) }.joined(separator: ",")
    }

    private var serviceChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 7) {
                if !activeServices.isEmpty {
                    Button { storedServices = "" } label: {
                        Image(systemName: "xmark")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(primary)
                            .frame(width: 44, height: 44)
                            .background(primary.opacity(0.1), in: Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("OTT 필터 초기화")
                }
                ForEach(["netflix", "disney_plus", "tving", "coupang_play"], id: \.self) { service in
                    let active = activeServices.contains(service)
                    Button {
                        var next = activeServices
                        if !next.insert(service).inserted { next.remove(service) }
                        storedServices = next.sorted().joined(separator: ",")
                    } label: {
                        HStack(spacing: 7) {
                            PlatformIcon(key: service, size: 17)
                            Text(ottName(service))
                                .font(.caption.weight(.semibold))
                        }
                        .foregroundStyle(active ? DiscoveryPalette.text : DiscoveryPalette.muted)
                        .padding(.horizontal, 10)
                        .frame(minHeight: 34)
                        .background(active ? DiscoveryPalette.accent("ott").opacity(0.14) : Color.clear, in: Capsule())
                        .overlay(Capsule().strokeBorder(active ? DiscoveryPalette.accent("ott").opacity(0.55) : DiscoveryPalette.line))
                        .padding(.vertical, 5)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(ottName(service)) \(active ? "필터 선택됨" : "필터 미선택")")
                    .accessibilityAddTraits(active ? [.isSelected] : [])
                }
            }
        }
    }

    private func initializeAccount() async {
        // Keychain restoration may fail or return 401; never expose a prior account's filters.
        if !storedFilterOwner.isEmpty { resetDeviceFilters() }
        await loadOptions()
        await account.restore()
        applyAccountSettings()
    }

    private var accountPanel: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let user = account.user {
                HStack {
                    Text("Google 계정 · \(user.displayName ?? "로그인됨")").font(.caption)
                    Spacer()
                    Button("로그아웃") { Task { await account.signOut() } }.font(.caption)
                }
                HStack {
                    Button("계정 설정 다시 불러오기") {
                        Task { await account.refresh(); applyAccountSettings() }
                    }
                    Button("현재 필터 저장") { Task { await saveAccountSettings() } }
                }.font(.caption).disabled(account.busy)
                HStack(spacing: 4) {
                    if account.isSyncing {
                        ProgressView().controlSize(.mini)
                        Text("계정 설정·찜 동기화 중")
                    } else if account.syncFailed {
                        Label("최근 동기화 실패", systemImage: "exclamationmark.triangle")
                            .foregroundStyle(DiscoveryPalette.primary)
                    } else if let lastSyncedAt = account.lastSyncedAt {
                        Text("마지막 서버 동기화: \(lastSyncedAt.formatted(date: .abbreviated, time: .shortened))")
                    } else {
                        Text("계정 동기화 확인 전")
                    }
                }.font(.caption2).foregroundStyle(.secondary)
                Text("현재 필터 변경은 ‘현재 필터 저장’을 눌러야 계정에 반영돼요.")
                    .font(.caption2).foregroundStyle(.secondary)
            } else if account.hasRestorableSession {
                Text(account.isSyncing ? "계정 연결을 확인하고 있어요." : "계정 연결을 확인하지 못했어요.")
                    .font(.caption)
                HStack {
                    Button("다시 시도") {
                        Task { await account.refresh(); applyAccountSettings() }
                    }.disabled(account.isSyncing || account.busy)
                    Button("로그아웃") { Task { await account.signOut() } }
                }.font(.caption)
            } else {
                HStack {
                    Text("로그인하면 설정과 찜을 계정에 저장할 수 있어요.").font(.caption)
                    Spacer()
                    Button("Google 로그인") {
                        Task { await account.signIn(); applyAccountSettings() }
                    }.disabled(account.busy)
                }
            }
            if let error = account.errorText {
                Text(error).font(.caption).foregroundStyle(.red)
            }
        }
    }

    private var tmdbCredits: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("정보 및 출처")
                .font(.headline)
                .accessibilityAddTraits(.isHeader)
            Link(destination: URL(string: "https://www.themoviedb.org")!) {
                Image("TMDBLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 84)
                    .frame(minHeight: 44, alignment: .leading)
                    .accessibilityLabel("TMDB 공식 사이트")
            }
            Text("일부 작품 정보와 포스터는 TMDB에서 제공됩니다.")
                .font(.subheadline)
            Text(verbatim: "This product uses the TMDB API but is not endorsed or certified by TMDB.")
                .font(.footnote)
                .foregroundStyle(.secondary)
            if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
               let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
                Text("버전 \(version) (\(build))")
                    .font(.footnote.monospacedDigit())
                    .foregroundStyle(DiscoveryPalette.muted)
                    .padding(.top, 8)
            }
        }
    }

    private func applyAccountSettings() {
        guard let user = account.user, let settings = account.settings else { return }
        storedCountry = settings.country
        storedTimeZone = settings.timeZone
        storedCategories = settings.enabledCategories.joined(separator: ",")
        storedServices = settings.services.joined(separator: ",")
        storedDevices = settings.devices.joined(separator: ",")
        storedFilterOwner = user.id
    }

    private func resetDeviceFilters() {
        storedCategories = "movie,ott,game"
        storedCountry = ""
        storedTimeZone = ""
        storedServices = ""
        storedDevices = ""
        storedFilterOwner = ""
    }

    private func saveAccountSettings() async {
        guard let filters else { return }
        await account.saveSettings(
            country: filters.country, timeZone: filters.timeZone,
            categories: categories, services: filters.services, devices: filters.devices
        )
    }

    private var calendarContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let optionsError {
                ContentUnavailableView("필터 정보 조회 실패", systemImage: "wifi.exclamationmark", description: Text(optionsError))
                Button("다시 시도") { Task { await loadOptions() } }
            }
            if categories.isEmpty { Text("선택한 분야가 없어요. 분야를 하나 이상 선택해 주세요.").font(.caption).foregroundStyle(.secondary) }
            if let errorText {
                ContentUnavailableView("연결 실패", systemImage: "wifi.exclamationmark", description: Text(errorText))
                Button("다시 시도") { Task { await loadMonth(selection: selectionKey) } }
            }
            if showingCachedCalendar {
                Label("이전에 조회한 달력을 표시해요. 최신 일정이 아닐 수 있어요.", systemImage: "clock.arrow.circlepath")
                    .font(.caption).foregroundStyle(DiscoveryPalette.primary)
            }
            calendarPanel
            if let calendar {
                if calendar.freshness.contains(where: { $0.dataOrigin == "fixture" }) {
                    Label("가상 일정이 포함되어 있어요", systemImage: "exclamationmark.circle")
                        .font(.caption).foregroundStyle(DiscoveryPalette.primary)
                }
                if calendar.freshness.contains(where: { $0.coverage != "available" }) {
                    Text("제공처 일정이 일부만 수집되었을 수 있어요.").font(.caption).foregroundStyle(.secondary)
                }
            }
            if calendar?.month == monthKey {
                if let selectedDate {
                    dayList(selectedDate)
                } else {
                    Label("날짜를 선택해 일정을 확인하세요", systemImage: "hand.tap")
                        .font(.subheadline)
                        .foregroundStyle(DiscoveryPalette.muted)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 8)
                }
            }
        }
    }

    private var filterSheet: some View {
        NavigationStack {
            Form {
                if let catalogOptions {
                    Section("분야") {
                        ForEach(options, id: \.0) { category in
                            Toggle(category.1, isOn: Binding(
                                get: { activeCategories.contains(category.0) },
                                set: { setCategory(category.0, enabled: $0) }
                            ))
                        }
                    }
                    Section("지역 및 시간대") {
                        Picker("국가", selection: $storedCountry) {
                            ForEach(catalogOptions.countries, id: \.self) { Text($0).tag($0) }
                        }
                        Picker("시간대", selection: $storedTimeZone) {
                            ForEach(catalogOptions.timeZones, id: \.self) { Text($0).tag($0) }
                        }
                    }
                    Section("OTT 서비스 · 선택 안 하면 전체") {
                        ForEach(catalogOptions.services, id: \.self) { service in
                            Toggle(service, isOn: storedSetBinding(service, key: "services"))
                        }
                    }
                    Section("게임 기기 · 선택 안 하면 전체") {
                        ForEach(catalogOptions.devices.filter(GamePlatform.supported.contains), id: \.self) { device in
                            Toggle(gameDeviceLabel(device), isOn: storedSetBinding(device, key: "devices"))
                        }
                    }
                    if account.user != nil {
                        Button("현재 필터를 계정에 저장") { Task { await saveAccountSettings() } }
                            .disabled(account.busy)
                    }
                    Text("OTT 서비스 필터는 OTT에, 게임 기기 필터는 게임에 적용됩니다. 로그인 후 계정에 저장할 수 있습니다.")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
            .navigationTitle("일정 필터")
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("완료") { showingFilters = false } } }
        }
    }

    private func storedSetBinding(_ value: String, key: String) -> Binding<Bool> {
        Binding(
            get: { (key == "services" ? activeServices : activeDevices).contains(value) },
            set: { enabled in
                var values = key == "services" ? activeServices : activeDevices
                if enabled { values.insert(value) } else { values.remove(value) }
                let next = values.sorted().joined(separator: ",")
                if key == "services" { storedServices = next } else { storedDevices = next }
            }
        )
    }

    @MainActor private func loadOptions() async {
        optionsError = nil
        do {
            let result = try await api.options()
            guard !Task.isCancelled else { return }
            catalogOptions = result
            if !result.countries.contains(storedCountry) { storedCountry = result.queryDefaults.country }
            if !result.timeZones.contains(storedTimeZone) { storedTimeZone = result.queryDefaults.timeZone }
        } catch is CancellationError { return }
        catch { if !Task.isCancelled { optionsError = error.localizedDescription } }
    }

    private var displayCalendar: Calendar {
        var calendar = CalendarDay.iso
        if let timeZone = TimeZone(identifier: filters?.timeZone ?? storedTimeZone) {
            calendar.timeZone = timeZone
        }
        return calendar
    }

    private var historyStart: String {
        let calendar = displayCalendar
        let cutoff = calendar.date(byAdding: .month, value: -1, to: clock)!
        let parts = calendar.dateComponents([.year, .month, .day], from: cutoff)
        return max("2026-10-01", String(format: "%04d-%02d-%02d", parts.year!, parts.month!, parts.day!))
    }

    private var canMoveToPreviousMonth: Bool {
        monthKey > String(historyStart.prefix(7))
    }

    private var todaySelection: (date: String, month: Date) {
        let parts = displayCalendar.dateComponents([.year, .month, .day], from: clock)
        let date = String(format: "%04d-%02d-%02d", parts.year!, parts.month!, parts.day!)
        let monthStart = CalendarDay.iso.date(from: DateComponents(year: parts.year, month: parts.month))!
        return (date, monthStart)
    }

    private var calendarPanel: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 7) {
                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .center) {
                        monthHeading
                        Spacer(minLength: 8)
                        monthControls
                    }
                    VStack(alignment: .leading, spacing: 8) {
                        monthHeading
                        monthControls
                    }
                }
                if let filters {
                    Label("\(filters.country) · \(filters.timeZone)", systemImage: "globe.asia.australia")
                        .font(.caption)
                        .foregroundStyle(DiscoveryPalette.muted)
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(panel)
            Divider().overlay(DiscoveryPalette.line).padding(.horizontal, 16)

            if loading && calendar == nil {
                ProgressView("달력 불러오는 중")
                    .frame(maxWidth: .infinity, minHeight: 185)
            } else if calendar?.month == monthKey {
                monthGrid
                    .padding(.horizontal, 10)
                    .padding(.vertical, 13)
            }
        }
        .background(panel)
        .clipShape(RoundedRectangle(cornerRadius: 25))
        .overlay(RoundedRectangle(cornerRadius: 25).strokeBorder(DiscoveryPalette.line))
        .shadow(color: DiscoveryPalette.text.opacity(0.055), radius: 16, y: 7)
    }

    private var monthHeading: some View {
        let parts = CalendarDay.iso.dateComponents([.year, .month], from: month)
        return VStack(alignment: .leading, spacing: 1) {
            Text(verbatim: "\(parts.year!)")
                .font(.caption.monospacedDigit().weight(.semibold))
                .foregroundStyle(DiscoveryPalette.muted)
            Text("\(parts.month!)월")
                .font(.system(.largeTitle, weight: .black))
                .tracking(-1.8)
        }
        .fixedSize()
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }

    private var monthControls: some View {
        HStack(spacing: 2) {
            Button("오늘") {
                let today = todaySelection
                month = today.month
                selectDay(today.date)
            }
            .font(.caption.weight(.bold))
            .fixedSize()
            .padding(.horizontal, 12)
            .frame(minHeight: 44)
            .foregroundStyle(primary)
            .background(DiscoveryPalette.highlight, in: Capsule())
            Button { moveMonth(-1) } label: { monthArrow("chevron.left") }
                .accessibilityLabel("이전 달")
                .disabled(!canMoveToPreviousMonth)
                .opacity(canMoveToPreviousMonth ? 1 : 0.35)
            Button { moveMonth(1) } label: { monthArrow("chevron.right") }
                .accessibilityLabel("다음 달")
        }
        .buttonStyle(.plain)
    }

    private func monthArrow(_ image: String) -> some View {
        Image(systemName: image)
            .font(.subheadline.weight(.semibold))
            .frame(width: 44, height: 44)
            .contentShape(Rectangle())
    }

    private var monthGrid: some View {
        let offset = CalendarDay.iso.component(.weekday, from: month) - 1
        let count = CalendarDay.iso.range(of: .day, in: .month, for: month)!.count
        let columns = Array(repeating: GridItem(.flexible(), spacing: 1), count: 7)
        let today = todaySelection.date
        let firstDay = historyStart
        return VStack(spacing: 5) {
            LazyVGrid(columns: columns, spacing: 3) {
                ForEach(Array(["일", "월", "화", "수", "목", "금", "토"].enumerated()), id: \.offset) { index, label in
                    Text(label)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(index == 0 ? DiscoveryPalette.accent("movie") : DiscoveryPalette.muted)
                        .frame(maxWidth: .infinity)
                }
                ForEach(0..<(offset + count), id: \.self) { index in
                    if index < offset {
                        Color.clear.frame(height: 44).accessibilityHidden(true)
                    } else {
                        let number = index - offset + 1
                        let date = String(format: "%@-%02d", monthKey, number)
                        let total = days[date]?.total ?? 0
                        let selected = selectedDate == date
                        Button { selectDay(date) } label: {
                            VStack(spacing: 1) {
                                Text(verbatim: "\(number)")
                                    .font(.system(.subheadline, weight: .bold).monospacedDigit())
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.65)
                                Circle()
                                    .fill(selected ? .white : primary)
                                    .frame(width: 4, height: 4)
                                    .opacity(total > 0 ? 1 : 0)
                                    .accessibilityHidden(true)
                            }
                            .padding(.vertical, 3)
                            .frame(maxWidth: .infinity, minHeight: 44)
                            .foregroundStyle(selected ? .white : DiscoveryPalette.text)
                            .background(selected ? primary : .clear, in: RoundedRectangle(cornerRadius: 15))
                            .overlay(RoundedRectangle(cornerRadius: 15)
                                .strokeBorder(date == today && !selected ? primary : .clear))
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .disabled(date < firstDay)
                        .opacity(date < firstDay ? 0.34 : 1)
                        .accessibilityLabel("\(date)\(date < firstDay ? ", 조회 범위 이전" : total > 0 ? ", 일정 있음" : ", 일정 없음")\(date == today ? ", 오늘" : "")")
                        .accessibilityAddTraits(selected ? [.isSelected] : [])
                    }
                }
            }
        }
    }

    private func selectDay(_ date: String) {
        shouldSelectToday = false
        guard date >= historyStart, date != selectedDate else { return }
        selectedDate = date
        events = days[date]?.previews ?? []
        dayError = nil
        loadingDay = true
    }

    private func gameCardTime(_ card: ReleaseCard) -> String {
        let event = card.event
        guard event.kind == "game_release", let market = card.commonMarket else { return event.time.description }
        return "\(gameMarketLabel(market)) · \(event.time.description)"
    }

    private func dayList(_ date: String) -> some View {
        let cards = ReleaseCard.group(events)
        let rowLayout = typeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 10))
            : AnyLayout(HStackLayout(alignment: .top, spacing: 12))
        return LazyVStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(date == todaySelection.date ? "오늘 일정" : dateLabel(date))
                    .font(.system(.title, weight: .black))
                    .tracking(-0.55)
                    .accessibilityAddTraits(.isHeader)
                Spacer(minLength: 4)
                Text(loadingDay || dayError != nil ? "일정" : "\(cards.count)개")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(primary)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(primary.opacity(0.12), in: Capsule())
            }
            .padding(.top, 5)
            if loadingDay {
                HStack(spacing: 8) {
                    ProgressView().tint(primary)
                    Text(events.isEmpty ? "일정을 불러오는 중" : "전체 일정 확인 중 · 미리보기 표시")
                        .font(.caption)
                        .foregroundStyle(DiscoveryPalette.muted)
                }
                .padding(.vertical, 7)
            }
            if let dayError {
                Text(dayError).foregroundStyle(.red).font(.footnote)
                Button("다시 시도") { Task { await loadDay(date, selection: selectionKey) } }
            }
            if !loadingDay && dayError == nil && cards.isEmpty {
                ContentUnavailableView("이날은 일정이 없어요", systemImage: "calendar.badge.clock",
                    description: Text("다른 날짜를 선택하거나 분야·플랫폼 필터를 조정해 보세요."))
                    .frame(maxWidth: .infinity)
            }
            ForEach(cards) { card in
                let item = card.event
                HStack(spacing: 8) {
                    Button {
                        if let filters { selection = DetailSelection(card: card, filters: filters) }
                    } label: {
                        rowLayout {
                            EventPosterThumbnail(contentId: item.contentId, kind: item.kind, api: api,
                                                 prominent: card.id == cards.first?.id)
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(item.categoryTitle)
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(DiscoveryPalette.accent(item.kind))
                                    if item.dataOrigin == "fixture" {
                                        Text("가상").font(.caption).foregroundStyle(DiscoveryPalette.primary)
                                    }
                                    if item.status != "scheduled" {
                                        Text(item.statusTitle).font(.caption).foregroundStyle(.red)
                                    }
                                }
                                Text(item.title)
                                    .font(.system(card.id == cards.first?.id ? .title3 : .body, weight: .heavy))
                                    .foregroundStyle(DiscoveryPalette.text)
                                    .lineLimit(typeSize.isAccessibilitySize ? nil : 2)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .multilineTextAlignment(.leading)
                                if item.kind == "ott_season_premiere" {
                                    HStack(spacing: 5) {
                                        ForEach(item.services, id: \.self) { service in
                                            PlatformIcon(key: service, size: 22)
                                                .accessibilityLabel(ottName(service))
                                        }
                                    }
                                }
                                if !card.devices.isEmpty {
                                    HStack(spacing: 6) {
                                        ForEach(card.devices, id: \.self) { device in
                                            GamePlatformIcon(device: device)
                                        }
                                    }
                                }
                                Text(gameCardTime(card))
                                    .font(.caption)
                                    .foregroundStyle(DiscoveryPalette.muted)
                                    .lineLimit(2)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            if !typeSize.isAccessibilitySize {
                                Image(systemName: "chevron.right")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(DiscoveryPalette.muted)
                                    .padding(.top, 4)
                                    .accessibilityHidden(true)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                        .background(panel, in: RoundedRectangle(cornerRadius: 18))
                        .overlay(RoundedRectangle(cornerRadius: 18)
                            .strokeBorder(card.id == cards.first?.id ? primary.opacity(0.40) : DiscoveryPalette.line))
                        .accessibilityElement(children: .combine)
                    }
                    .buttonStyle(.plain)
                    if account.user != nil && account.favoritesReady {
                        let saved = isFavorite(item)
                        Button { toggleFavorite(item) } label: {
                            Image(systemName: saved ? "heart.fill" : "heart")
                                .foregroundStyle(saved ? .red : .secondary)
                                .frame(width: 44, height: 44)
                        }
                        .accessibilityLabel(saved ? "찜 해제" : "찜")
                    }
                }
            }
        }
    }

    private func dateLabel(_ date: String) -> String {
        let parts = date.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3 else { return date }
        return "\(parts[1])월 \(parts[2])일"
    }

    private func moveMonth(_ offset: Int) {
        guard offset >= 0 || canMoveToPreviousMonth,
              let next = CalendarDay.iso.date(byAdding: .month, value: offset, to: month) else { return }
        shouldSelectToday = false
        month = next
        selectedDate = nil
    }

    @MainActor private func loadMonth(selection: String) async {
        guard let filters, !filters.categories.isEmpty else {
            loadedCalendarKey = ""
            calendar = nil
            events = []
            errorText = nil
            showingCachedCalendar = false
            loading = false
            return
        }
        if shouldSelectToday {
            let today = todaySelection
            if month != today.month {
                month = today.month
                return
            }
            selectDay(today.date)
        }
        let cached = lastCalendars[selection]
        if loadedCalendarKey != selection || calendar?.catalogRevision != cached?.catalogRevision {
            events = cached?.days.first { $0.date == selectedDate }?.previews ?? []
            dayError = nil
        }
        loadedCalendarKey = selection
        calendar = cached
        showingCachedCalendar = cached != nil
        errorText = nil
        loading = true
        defer { if selection == selectionKey { loading = false } }
        do {
            let result = try await api.calendar(month: monthKey, filters: filters)
            guard !Task.isCancelled, selection == selectionKey else { return }
            calendar = result
            lastCalendars[selection] = result
            showingCachedCalendar = false
        } catch is CancellationError { return }
        catch {
            guard !Task.isCancelled, selection == selectionKey else { return }
            errorText = error.localizedDescription
        }
    }

    @MainActor private func loadDay(_ date: String, selection: String) async {
        guard let filters, !filters.categories.isEmpty else { events = []; return }
        guard calendar?.month == monthKey, let revision = calendar?.catalogRevision else { return }
        let requestID = UUID()
        dayRequestID = requestID
        let cacheKey = [selection, revision, date].joined(separator: "|")
        dayError = nil
        if let cached = dayCache[cacheKey] {
            events = cached
            loadingDay = false
            return
        }
        events = days[date]?.previews ?? []
        loadingDay = true
        defer { if selectedDate == date && selection == selectionKey && dayRequestID == requestID && calendar?.catalogRevision == revision { loadingDay = false } }
        do {
            let result = try await api.events(date: date, filters: filters, revision: revision)
            guard !Task.isCancelled, selectedDate == date, selection == selectionKey, dayRequestID == requestID, calendar?.catalogRevision == revision else { return }
            dayCache[cacheKey] = result
            events = result
        }
        catch PublicAPIError.catalogChanged {
            guard !Task.isCancelled, selectedDate == date, selection == selectionKey, dayRequestID == requestID, calendar?.catalogRevision == revision else { return }
            do {
                let updated = try await api.calendar(month: monthKey, filters: filters)
                let result = try await api.events(date: date, filters: filters, revision: updated.catalogRevision)
                guard !Task.isCancelled, selectedDate == date, selection == selectionKey, dayRequestID == requestID, calendar?.catalogRevision == revision else { return }
                calendar = updated
                lastCalendars[selection] = updated
                showingCachedCalendar = false
                dayCache[[selection, updated.catalogRevision, date].joined(separator: "|")] = result
                events = result
            } catch {
                if !Task.isCancelled && selectedDate == date && selection == selectionKey && dayRequestID == requestID && calendar?.catalogRevision == revision { dayError = error.localizedDescription }
            }
        }
        catch is CancellationError { return }
        catch {
            if !Task.isCancelled && selectedDate == date && selection == selectionKey && dayRequestID == requestID && calendar?.catalogRevision == revision { dayError = error.localizedDescription }
        }
    }
}

func gameDeviceLabel(_ device: String) -> String {
    switch device {
    case "ios": return "iOS (아이폰·아이패드)"
    case "android": return "Android"
    case "pc": return "PC"
    case "playstation": return "PlayStation"
    case "xbox": return "Xbox"
    case "switch": return "Nintendo Switch"
    default: return device
    }
}

func ottName(_ service: String) -> String {
    switch service {
    case "netflix": "넷플릭스"
    case "disney_plus": "디즈니플러스"
    case "tving": "티빙"
    case "coupang_play": "쿠팡플레이"
    default: service
    }
}

private struct ReleaseCardDetail: View {
    let card: ReleaseCard
    let filters: PublicFilters
    let api: PublicAPI
    @State private var selectedID: String?

    var body: some View {
        let active = card.variants.first { $0.id == selectedID } ?? card.event
        EventDetailView(event: active, filters: filters, api: api, cardDevices: card.devices)
            .id(active.id)
            .toolbar {
                if card.variants.count > 1 {
                    ToolbarItem(placement: .topBarLeading) {
                        Menu {
                            Picker("플랫폼 일정", selection: Binding(
                                get: { active.id },
                                set: { selectedID = $0 }
                            )) {
                                ForEach(Array(card.variants.enumerated()), id: \.element.id) { offset, variant in
                                    Text(variantLabel(variant, index: offset)).tag(variant.id)
                                }
                            }
                        } label: {
                            Text("플랫폼")
                        }
                    }
                }
            }
    }

    private func variantLabel(_ event: ReleaseEvent, index: Int) -> String {
        let label = event.devices.map(gameDeviceLabel).joined(separator: ", ")
        if label.isEmpty { return "일정 \(index + 1)" }
        let sharesDevice = card.variants.filter { $0.devices == event.devices }.count > 1
        guard card.markets.count > 1 || sharesDevice else { return label }
        let market = gameMarketLabel(event.releaseMarket)
        let sameRegion = card.variants.filter { $0.devices == event.devices && $0.releaseMarket == event.releaseMarket }
        return sameRegion.count > 1 ? "\(label) · \(market) · \(index + 1)" : "\(label) · \(market)"
    }
}

private struct EventDetailView: View {
    let event: ReleaseEvent
    let filters: PublicFilters
    let api: PublicAPI
    var cardDevices: [String] = []
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var typeSize
    @State private var detail: ReleaseDetail?
    @State private var detailFailed = false
    @State private var retryCount = 0
    @State private var content: CatalogContent?
    @State private var isContentLoading = false
    @State private var contentFailed = false

    private var displayedEvent: ReleaseEvent { detail?.event ?? event }
    private var accent: Color { DiscoveryPalette.accent(displayedEvent.kind) }
    private var statusColor: Color {
        switch displayedEvent.status {
        case "cancelled": .red
        case "postponed": DiscoveryPalette.primary
        default: accent
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                hero
                if detailFailed {
                    detailSection("상세 정보", icon: "exclamationmark.circle") {
                        Text("일정의 최신 정보와 출처를 불러오지 못했어요.")
                            .foregroundStyle(.secondary)
                        Button("다시 시도") { retryCount += 1 }
                            .buttonStyle(.bordered)
                    }
                }
                schedule
                if let synopsis = content?.synopsis?.trimmingCharacters(in: .whitespacesAndNewlines),
                   !synopsis.isEmpty {
                    detailSection("작품 소개", icon: "text.alignleft") {
                        Text(synopsis)
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .lineSpacing(4)
                    }
                }
                sources
            }
            .frame(maxWidth: 560)
            .padding(.horizontal, 18)
            .padding(.top, 8)
            .padding(.bottom, 28)
            .frame(maxWidth: .infinity)
        }
        .background(DiscoveryPalette.background.ignoresSafeArea())
        .foregroundStyle(DiscoveryPalette.text)
        .tint(accent)
        .navigationTitle("일정 상세")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(DiscoveryPalette.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("닫기") { dismiss() } } }
        .task(id: retryCount) {
            detailFailed = false
            do {
                let result = try await api.detail(id: event.id, filters: filters)
                try Task.checkCancellation()
                detail = result
            } catch {
                if !Task.isCancelled { detailFailed = true }
            }
        }
        .task(id: displayedEvent.contentId) {
            content = nil
            contentFailed = false
            guard let id = displayedEvent.contentId else { isContentLoading = false; return }
            isContentLoading = true
            defer { if !Task.isCancelled { isContentLoading = false } }
            do {
                let result = try await api.content(id: id)
                try Task.checkCancellation()
                content = result
            } catch {
                if !Task.isCancelled { contentFailed = true }
            }
        }
    }

    private var hero: some View {
        let layout = typeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 15))
            : AnyLayout(HStackLayout(alignment: .center, spacing: 14))
        return VStack(alignment: .leading, spacing: 15) {
            layout {
                heroHeading.frame(maxWidth: .infinity, alignment: .leading)
                poster
            }
            Divider().overlay(DiscoveryPalette.line)
            releaseStrip
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DiscoveryPalette.panel, in: RoundedRectangle(cornerRadius: 23))
        .overlay(RoundedRectangle(cornerRadius: 23).strokeBorder(DiscoveryPalette.line))
    }

    private var heroHeading: some View {
        VStack(alignment: .leading, spacing: 9) {
            Label(displayedEvent.categoryTitle, systemImage: DiscoveryPalette.symbol(displayedEvent.kind))
                .font(.subheadline.weight(.bold))
                .foregroundStyle(accent)
            Text(displayedEvent.title)
                .font(.system(.largeTitle, weight: .black))
                .tracking(-1.1)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
            if !cardDevices.isEmpty {
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 6) {
                        ForEach(cardDevices, id: \.self) { GamePlatformIcon(device: $0) }
                    }
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(cardDevices, id: \.self) { GamePlatformIcon(device: $0) }
                    }
                }
            }
            if displayedEvent.dataOrigin == "fixture" {
                Text("가상 데이터")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(DiscoveryPalette.primary)
            }
        }
    }

    private var poster: some View {
        PosterArtwork(
            urlString: content?.posterUrl,
            isLoading: isContentLoading,
            lookupFailed: contentFailed,
            imageLabel: "\(displayedEvent.title) 포스터",
            symbol: DiscoveryPalette.symbol(displayedEvent.kind),
            accent: accent
        )
        .frame(width: 109, height: 162)
        .shadow(color: DiscoveryPalette.text.opacity(0.20), radius: 10, y: 5)
    }

    private var releaseStrip: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 12) {
                releaseDate.fixedSize()
                Spacer(minLength: 0)
                statusPill.fixedSize()
            }
            VStack(alignment: .leading, spacing: 8) {
                releaseDate
                statusPill
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 2)
    }

    private var releaseDate: some View {
        Label(displayedEvent.time.description, systemImage: "calendar")
            .font(.subheadline.weight(.semibold))
    }

    private var statusPill: some View {
        Text(displayedEvent.statusTitle)
            .font(.caption.weight(.bold))
            .foregroundStyle(statusColor)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(statusColor.opacity(0.13), in: Capsule())
    }

    private var schedule: some View {
        detailSection("공개 정보", icon: "info.circle") {
            if let market = displayedEvent.releaseMarket {
                detailRow("공개 지역", value: gameMarketLabel(market))
            }
            if let country = displayedEvent.venueCountry {
                detailRow("개최국", value: Locale(identifier: "ko_KR").localizedString(forRegionCode: country) ?? country)
            }
            if !displayedEvent.services.isEmpty {
                detailRow("OTT", value: displayedEvent.services.map(ottName).joined(separator: ", "))
            }
            if !displayedEvent.devices.isEmpty {
                detailRow("기기", value: displayedEvent.devices.map(gameDeviceLabel).joined(separator: ", "))
            }
            if let previous = detail?.previousTime {
                detailRow("이전 일정", value: previous.description)
            }
            detailRow("데이터", value: displayedEvent.dataOrigin == "fixture" ? "가상 데이터" : "제공처 반영 데이터")
            detailRow("최종 수정", value: updatedAtLabel)
        }
    }

    private var updatedAtLabel: String {
        let iso = ISO8601DateFormatter()
        iso.formatOptions.insert(.withFractionalSeconds)
        let hasFraction = iso.date(from: displayedEvent.updatedAt) != nil
        if !hasFraction {
            iso.formatOptions.remove(.withFractionalSeconds)
        }
        guard let date = iso.date(from: displayedEvent.updatedAt), let zone = TimeZone(identifier: filters.timeZone) else {
            return displayedEvent.updatedAt
        }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.timeZone = zone
        formatter.setLocalizedDateFormatFromTemplate(hasFraction ? "yMd HmsSSS" : "yMd Hms")
        return "\(formatter.string(from: date)) · \(zone.abbreviation(for: date) ?? zone.identifier)"
    }

    @ViewBuilder private var sources: some View {
        if let detail {
            detailSection("출처", icon: "link") {
                if detail.sources.isEmpty { Text("표시할 출처 없음").foregroundStyle(.secondary) }
                ForEach(Array(detail.sources.enumerated()), id: \.offset) { _, source in
                    if let url = URL(string: source.url), let scheme = url.scheme?.lowercased(),
                       ["http", "https"].contains(scheme), let host = url.host, !host.isEmpty {
                        Link(destination: url) {
                            HStack(spacing: 8) {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(sourceTitle(source.providerKey))
                                        .font(.subheadline.weight(.semibold))
                                    Text(host)
                                        .font(.caption)
                                        .foregroundStyle(DiscoveryPalette.muted)
                                }
                                Spacer(minLength: 12)
                                Image(systemName: "arrow.up.right")
                                    .font(.subheadline.weight(.semibold))
                                    .accessibilityHidden(true)
                            }
                            .frame(minHeight: 44)
                            .contentShape(Rectangle())
                        }
                    } else {
                        Text(sourceTitle(source.providerKey))
                    }
                }
            }
        } else if !detailFailed {
            ProgressView("최신 일정과 출처 확인 중")
                .font(.footnote)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
        }
    }

    private func sourceTitle(_ key: String) -> String {
        switch key {
        case "kobis": "영화관입장권통합전산망"
        case "ott_reviewed": "검토된 OTT 일정 출처"
        case "ott_fallback": "OTT 참고 일정 출처"
        case "igdb": "IGDB"
        default: key
        }
    }

    private func detailSection<Content: View>(
        _ title: String, icon: String, @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label {
                Text(title).font(.headline)
            } icon: {
                Image(systemName: icon)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(accent)
            }
            .accessibilityAddTraits(.isHeader)
            Divider().overlay(DiscoveryPalette.line).accessibilityHidden(true)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(DiscoveryPalette.panel, in: RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(DiscoveryPalette.line))
    }

    private func detailRow(_ label: String, value: String) -> some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .firstTextBaseline, spacing: 16) {
                Text(label).foregroundStyle(.secondary).fixedSize()
                Spacer(minLength: 4)
                Text(value).fixedSize()
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(label).foregroundStyle(.secondary)
                Text(value)
            }
        }
        .font(.subheadline)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}

struct EventPosterThumbnail: View {
    let contentId: String?
    let kind: String
    let api: PublicAPI
    var prominent = false
    @State private var posterURL: String?
    @State private var isLoading = false

    var body: some View {
        PosterArtwork(
            urlString: posterURL,
            isLoading: isLoading,
            compact: true,
            symbol: DiscoveryPalette.symbol(kind),
            accent: DiscoveryPalette.accent(kind)
        )
        .frame(width: prominent ? 82 : 58, height: prominent ? 112 : 82)
            .task(id: contentId) {
                posterURL = nil
                guard let contentId else { isLoading = false; return }
                isLoading = true
                defer { isLoading = false }
                do { posterURL = try await api.content(id: contentId).posterUrl }
                catch is CancellationError { return }
                catch { /* 서버에 이미지가 없어도 일정 텍스트를 표시한다. */ }
            }
    }
}

struct PosterArtwork: View {
    let urlString: String?
    var isLoading = false
    var compact = false
    var lookupFailed = false
    var imageLabel = ""
    var symbol = "photo"
    var accent = DiscoveryPalette.primary

    private var posterURL: URL? {
        guard let urlString, let url = URL(string: urlString),
              url.scheme?.lowercased() == "https", url.host != nil else { return nil }
        return url
    }

    var body: some View {
        GeometryReader { proxy in
            Group {
                if let posterURL {
                    AsyncImage(url: posterURL) { phase in
                        switch phase {
                        case .success(let image):
                            if compact {
                                image.resizable().scaledToFill()
                            } else {
                                image.resizable().scaledToFit().accessibilityLabel(imageLabel)
                            }
                        case .empty:
                            ProgressView()
                        case .failure:
                            placeholder("포스터 로딩 실패")
                        @unknown default:
                            placeholder("포스터 로딩 실패")
                        }
                    }
                } else if isLoading {
                    ProgressView()
                } else {
                    placeholder(lookupFailed ? "포스터 조회 실패" : "포스터 없음")
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
            .clipped()
        }
        .background {
            LinearGradient(
                colors: [accent.opacity(0.16), DiscoveryPalette.background],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
        }
        .clipShape(RoundedRectangle(cornerRadius: compact ? 8 : 12))
        .accessibilityHidden(compact)
    }

    private func placeholder(_ message: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: symbol)
                .font(compact ? .title3 : .largeTitle)
                .foregroundStyle(accent)
                .accessibilityHidden(true)
            if !compact {
                Text(message)
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 6)
            }
        }
        .foregroundStyle(.secondary)
    }
}


// Brand favicons are loaded from the actual platform domains. A readable fallback
// remains visible when the icon endpoint is offline.
private func gameMarketLabel(_ market: String?) -> String {
    guard let market else { return "지역 미정" }
    return market == "WORLD" ? "글로벌" :
        (Locale(identifier: "ko_KR").localizedString(forRegionCode: market) ?? market)
}

struct GamePlatformIcon: View {
    let device: String

    var body: some View {
        Group {
            switch device {
            case "playstation":
                Image(systemName: "playstation.logo")
            case "xbox":
                Image(systemName: "xbox.logo")
            case "ios":
                Image(systemName: "apple.logo")
            case "android":
                Image(systemName: "candybarphone")
            default:
                Image(systemName: "gamecontroller.fill")
            }
        }
        .font(.system(size: 15, weight: .semibold))
        .foregroundStyle(DiscoveryPalette.text)
        .frame(width: 26, height: 24)
        .background(DiscoveryPalette.surface, in: RoundedRectangle(cornerRadius: 6))
        .accessibilityLabel(gameDeviceLabel(device))
    }
}

struct PlatformIcon: View {
    let key: String
    var size: CGFloat = 24

    private var domain: String? {
        switch key.lowercased() {
        case "netflix": "netflix.com"
        case "disney_plus": "disneyplus.com"
        case "tving": "tving.com"
        case "coupang_play": "coupangplay.com"
        case "playstation": "playstation.com"
        case "xbox": "xbox.com"
        case "switch": "nintendo.com"
        case "ios": "apple.com"
        case "android": "android.com"
        case "pc": "microsoft.com"
        default: nil
        }
    }

    var body: some View {
        Group {
            if let domain, let url = URL(string: "https://www.google.com/s2/favicons?domain=\(domain)&sz=128") {
                AsyncImage(url: url) { phase in
                    if case let .success(image) = phase {
                        image.resizable().scaledToFit()
                    } else {
                        fallback
                    }
                }
            } else {
                fallback
            }
        }
        .frame(width: size, height: size)
        .background(DiscoveryPalette.background, in: RoundedRectangle(cornerRadius: size * 0.25))
        .clipShape(RoundedRectangle(cornerRadius: size * 0.25))
    }

    private var fallback: some View {
        let labels = ["netflix": "N", "disney_plus": "D+", "tving": "T", "coupang_play": "CP"]
        return Group {
            if let label = labels[key] {
                Text(label).font(.system(size: size * 0.49, weight: .heavy))
            } else {
                Image(systemName: "play.square.fill").resizable().scaledToFit()
            }
        }
            .foregroundStyle(DiscoveryPalette.muted)
    }
}
