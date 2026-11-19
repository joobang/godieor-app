import SwiftUI

private enum DiscoveryPalette {
    static let ink = Color(red: 0.054, green: 0.059, blue: 0.090)
    static let lime = Color(red: 0.84, green: 0.98, blue: 0.54)
    static let panel = Color(red: 0.096, green: 0.104, blue: 0.153)
    static let text = Color(red: 0.97, green: 0.96, blue: 0.93)
    static let muted = Color(red: 0.68, green: 0.70, blue: 0.76)
    static let line = Color.white.opacity(0.095)

    static func accent(_ key: String) -> Color {
        switch key {
        case "movie", "theatrical_release": Color(red: 1, green: 0.72, blue: 0.55)
        case "ott", "ott_season_premiere": Color(red: 0.78, green: 0.71, blue: 1)
        case "epl", "epl_match": Color(red: 0.53, green: 0.82, blue: 0.99)
        default: lime
        }
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
    private let ink = DiscoveryPalette.ink
    private let lime = DiscoveryPalette.lime
    private let panel = DiscoveryPalette.panel

    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var account = AccountState()
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
    @State private var selection: DetailSelection?
    private struct DetailSelection: Identifiable {
        let event: ReleaseEvent
        let filters: PublicFilters
        var id: String { event.id }
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
    private var activeDevices: Set<String> { Set(storedDevices.split(separator: ",").map(String.init)) }
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
        return ([monthKey, filters.country, filters.timeZone] + filters.categories + ["services"] + filters.services + ["devices"] + filters.devices).joined(separator: ":")
    }
    private var daySelectionKey: String {
        [selectedDate ?? "", selectionKey, calendar?.month ?? "", calendar?.catalogRevision ?? ""].joined(separator: ":")
    }
    private var days: [String: ReleaseDay] { Dictionary(uniqueKeysWithValues: (calendar?.days ?? []).map { ($0.date, $0) }) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    dashboardHeader
                    VStack(alignment: .leading, spacing: 10) {
                        categoryFilters
                        if activeCategories.contains("ott") || !activeServices.isEmpty {
                            serviceChips
                        }
                    }
                    calendarContent
                }
                .frame(maxWidth: 600)
                .padding(.horizontal, 18)
                .padding(.top, 8)
                .padding(.bottom, 36)
                .frame(maxWidth: .infinity)
            }
            .background {
                ink.overlay(alignment: .topTrailing) {
                    RadialGradient(
                        colors: [Color(red: 0.21, green: 0.17, blue: 0.38), ink],
                        center: .topTrailing, startRadius: 0, endRadius: 370
                    )
                }
                .ignoresSafeArea()
            }
            .foregroundStyle(DiscoveryPalette.text)
            .tint(lime)
            .toolbar(.hidden, for: .navigationBar)
            .preferredColorScheme(.dark)
            .sheet(item: $selection) { selected in
                NavigationStack {
                    EventDetailView(event: selected.event, filters: selected.filters, api: api)
                }
            }
            .sheet(isPresented: $showingFilters) { filterSheet }
            .sheet(isPresented: $showingAccount) {
                NavigationStack {
                    ScrollView { accountPanel.padding() }
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
                if previous != nil && previous != current { resetDeviceFilters() }
                if current != nil { applyAccountSettings() }
            }
            .task { await initializeAccount() }
            .onChange(of: scenePhase) { _, phase in
                guard phase == .active, account.hasRestorableSession else { return }
                Task {
                    await account.refresh()
                    applyAccountSettings()
                }
            }
            .task(id: selectionKey) { await loadMonth(selection: selectionKey) }
            .task(id: daySelectionKey) {
                if let selectedDate { await loadDay(selectedDate, selection: selectionKey) }
            }
        }
    }

    private var dashboardHeader: some View {
        HStack(spacing: 8) {
            HStack(spacing: 9) {
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(ink)
                    .frame(width: 32, height: 32)
                    .background(lime, in: RoundedRectangle(cornerRadius: 10))
                    .accessibilityHidden(true)
                Text("고디어")
                    .font(.system(.title, design: .rounded, weight: .black))
                    .accessibilityAddTraits(.isHeader)
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
            .background(.white.opacity(0.07), in: Circle())
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
                let accent = DiscoveryPalette.accent(option.0)
                Button {
                    var next = activeCategories
                    if !next.insert(option.0).inserted { next.remove(option.0) }
                    storedCategories = options.map(\.0).filter { next.contains($0) }.joined(separator: ",")
                } label: {
                    Label(option.1, systemImage: DiscoveryPalette.symbol(option.0))
                        .font(.subheadline.weight(.semibold))
                        .fixedSize()
                        .foregroundStyle(selected ? accent : DiscoveryPalette.muted)
                        .padding(.horizontal, 10)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .background(selected ? accent.opacity(0.13) : panel, in: RoundedRectangle(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(selected ? accent.opacity(0.35) : DiscoveryPalette.line))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(option.1) \(selected ? "선택됨" : "선택 안 됨")")
                .accessibilityAddTraits(selected ? [.isSelected] : [])
            }
        }
    }

    private var serviceChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 7) {
                if !activeServices.isEmpty {
                    Button { storedServices = "" } label: {
                        Image(systemName: "xmark")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(lime)
                            .frame(width: 44, height: 44)
                            .background(lime.opacity(0.1), in: Circle())
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
                            .foregroundStyle(.orange)
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
                    .font(.caption).foregroundStyle(.orange)
            }
            calendarPanel
            if let calendar {
                if calendar.freshness.contains(where: { $0.dataOrigin == "fixture" }) {
                    Label("가상 일정이 포함되어 있어요", systemImage: "exclamationmark.circle")
                        .font(.caption).foregroundStyle(.orange)
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
                        ForEach(catalogOptions.devices, id: \.self) { device in
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

    private var todaySelection: (date: String, month: Date) {
        var displayCalendar = CalendarDay.iso
        if let timeZone = TimeZone(identifier: filters?.timeZone ?? storedTimeZone) {
            displayCalendar.timeZone = timeZone
        }
        let parts = displayCalendar.dateComponents([.year, .month, .day], from: .now)
        let date = String(format: "%04d-%02d-%02d", parts.year!, parts.month!, parts.day!)
        let monthStart = CalendarDay.iso.date(from: DateComponents(year: parts.year, month: parts.month))!
        return (date, monthStart)
    }

    private var calendarPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
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
            .padding(.horizontal, 14)
            if let filters {
                Label("\(filters.country) · \(filters.timeZone)", systemImage: "globe.asia.australia")
                    .font(.caption2)
                    .foregroundStyle(DiscoveryPalette.muted)
                    .padding(.horizontal, 14)
            }
            Divider().overlay(DiscoveryPalette.line).padding(.horizontal, 9)
            if loading && calendar == nil {
                ProgressView("달력 불러오는 중")
                    .frame(maxWidth: .infinity, minHeight: 185)
            } else if calendar?.month == monthKey {
                monthGrid
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 14)
        .background {
            RoundedRectangle(cornerRadius: 25)
                .fill(LinearGradient(
                    colors: [Color(red: 0.139, green: 0.132, blue: 0.220), panel],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                ))
        }
        .overlay(RoundedRectangle(cornerRadius: 25).strokeBorder(DiscoveryPalette.line))
    }

    private var monthHeading: some View {
        let parts = CalendarDay.iso.dateComponents([.year, .month], from: month)
        return VStack(alignment: .leading, spacing: 1) {
            Text(verbatim: "\(parts.year!)")
                .font(.caption.monospacedDigit().weight(.semibold))
                .foregroundStyle(DiscoveryPalette.muted)
            Text("\(parts.month!)월")
                .font(.system(.largeTitle, design: .rounded, weight: .heavy))
                .tracking(-1)
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
            .foregroundStyle(lime)
            .background(lime.opacity(0.1), in: Capsule())
            Button { moveMonth(-1) } label: { monthArrow("chevron.left") }
                .accessibilityLabel("이전 달")
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
                                    .font(.system(.subheadline, design: .rounded, weight: .bold).monospacedDigit())
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.65)
                                Text(total > 99 ? "99+" : "\(total)")
                                    .font(.system(.caption2, design: .monospaced, weight: .semibold))
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.65)
                                    .foregroundStyle(selected ? ink.opacity(0.72) : DiscoveryPalette.muted)
                                    .opacity(total > 0 ? 1 : 0)
                            }
                            .padding(.vertical, 3)
                            .frame(maxWidth: .infinity, minHeight: 44)
                            .foregroundStyle(selected ? ink : DiscoveryPalette.text)
                            .background(selected ? lime : (total > 0 ? .white.opacity(0.035) : .clear),
                                        in: RoundedRectangle(cornerRadius: 10))
                            .overlay(RoundedRectangle(cornerRadius: 10)
                                .strokeBorder(date == today && !selected ? lime : .clear))
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("\(date), \(total)개 일정\(date == today ? ", 오늘" : "")")
                        .accessibilityAddTraits(selected ? [.isSelected] : [])
                    }
                }
            }
        }
    }

    private func selectDay(_ date: String) {
        shouldSelectToday = false
        guard date != selectedDate else { return }
        selectedDate = date
        events = days[date]?.previews ?? []
        dayError = nil
        loadingDay = true
    }

    private func dayList(_ date: String) -> some View {
        LazyVStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(dateLabel(date))
                    .font(.system(.title2, design: .rounded, weight: .heavy))
                    .accessibilityAddTraits(.isHeader)
                Spacer(minLength: 4)
                Text("\(days[date]?.total ?? 0)개 일정")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(lime)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(lime.opacity(0.12), in: Capsule())
            }
            .padding(.top, 5)
            if loadingDay {
                HStack(spacing: 8) {
                    ProgressView().tint(lime)
                    Text(events.isEmpty ? "일정을 불러오는 중" : "전체 일정 확인 중 · 미리보기 표시")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.68))
                }
                .padding(.vertical, 7)
            }
            if let dayError {
                Text(dayError).foregroundStyle(.red).font(.footnote)
                Button("다시 시도") { Task { await loadDay(date, selection: selectionKey) } }
            }
            if !loadingDay && dayError == nil && events.isEmpty {
                ContentUnavailableView("이날은 일정이 없어요", systemImage: "calendar.badge.clock",
                    description: Text("다른 날짜를 선택하거나 분야·플랫폼 필터를 조정해 보세요."))
                    .frame(maxWidth: .infinity)
            }
            ForEach(events) { item in
                HStack(spacing: 8) {
                    Button {
                        if let filters { selection = DetailSelection(event: item, filters: filters) }
                    } label: {
                        HStack(alignment: .top, spacing: 12) {
                            EventPosterThumbnail(contentId: item.contentId, kind: item.kind, api: api)
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(item.categoryTitle)
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(DiscoveryPalette.accent(item.kind))
                                    if item.dataOrigin == "fixture" {
                                        Text("가상").font(.caption).foregroundStyle(.orange)
                                    }
                                    if item.status != "scheduled" {
                                        Text(item.statusTitle).font(.caption).foregroundStyle(.red)
                                    }
                                }
                                Text(item.title)
                                    .font(.system(.body, design: .rounded, weight: .bold))
                                    .foregroundStyle(.white)
                                    .lineLimit(2)
                                    .multilineTextAlignment(.leading)
                                if item.kind == "ott_season_premiere" {
                                    HStack(spacing: 5) {
                                        ForEach(item.services, id: \.self) { service in
                                            PlatformIcon(key: service, size: 22)
                                                .accessibilityLabel(ottName(service))
                                        }
                                    }
                                }
                                if !item.devices.isEmpty {
                                    HStack(spacing: 6) {
                                        ForEach(item.devices, id: \.self) { device in
                                            PlatformIcon(key: device, size: 22)
                                                .accessibilityLabel(gameDeviceLabel(device))
                                        }
                                    }
                                }
                                Text(item.time.description)
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.55))
                                    .lineLimit(2)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            Image(systemName: "chevron.right")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.white.opacity(0.42))
                                .padding(.top, 4)
                                .accessibilityHidden(true)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                        .background(panel, in: RoundedRectangle(cornerRadius: 16))
                        .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(DiscoveryPalette.line))
                        .accessibilityElement(children: .combine)
                    }
                    .buttonStyle(.plain)
                if account.user != nil {
                    let saved = item.contentId.map { account.favoriteContentIDs.contains($0) } ?? account.favoriteEventIDs.contains(item.id)
                    Button {
                        Task {
                            if let contentId = item.contentId {
                                await account.toggleFavorite(type: "content", id: contentId)
                            } else {
                                await account.toggleFavorite(type: "event", id: item.id)
                            }
                        }
                    } label: {
                        Image(systemName: saved ? "heart.fill" : "heart")
                            .foregroundStyle(saved ? .red : .secondary)
                    }
                    .accessibilityLabel(saved ? "찜 해제" : "찜")
                    .frame(width: 44, height: 44)
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
        guard let next = CalendarDay.iso.date(byAdding: .month, value: offset, to: month),
              next >= CalendarDay.iso.date(from: DateComponents(year: 2026, month: 1, day: 1))! else { return }
        shouldSelectToday = false
        month = next
        selectedDate = nil
    }

    @MainActor private func loadMonth(selection: String) async {
        guard let filters, !filters.categories.isEmpty else {
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
        calendar = lastCalendars[selection]
        showingCachedCalendar = calendar != nil
        events = []
        errorText = nil
        dayError = nil
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

private func gameDeviceLabel(_ device: String) -> String {
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

private func ottName(_ service: String) -> String {
    switch service {
    case "netflix": "넷플릭스"
    case "disney_plus": "디즈니플러스"
    case "tving": "티빙"
    case "coupang_play": "쿠팡플레이"
    default: service
    }
}

private struct EventDetailView: View {
    let event: ReleaseEvent
    let filters: PublicFilters
    let api: PublicAPI
    @Environment(\.dismiss) private var dismiss
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
        case "postponed": .orange
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
        .background(DiscoveryPalette.ink.ignoresSafeArea())
        .foregroundStyle(DiscoveryPalette.text)
        .tint(accent)
        .navigationTitle("일정 상세")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(DiscoveryPalette.ink, for: .navigationBar)
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
        VStack(alignment: .leading, spacing: 13) {
            posterStage

            Label(displayedEvent.categoryTitle, systemImage: DiscoveryPalette.symbol(displayedEvent.kind))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(accent)
                .padding(.top, 4)
            Text(displayedEvent.title)
                .font(.system(.largeTitle, design: .rounded, weight: .heavy))
                .tracking(-0.6)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
            if displayedEvent.dataOrigin == "fixture" {
                Text("가상 데이터")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.orange)
            }
            releaseStrip
        }
    }

    private var posterStage: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 22)
                .fill(LinearGradient(
                    colors: [accent.opacity(0.33), DiscoveryPalette.panel, accent.opacity(0.24)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                ))
            GeometryReader { space in
                ForEach(0..<5) { index in
                    RoundedRectangle(cornerRadius: 44)
                        .strokeBorder(accent.opacity(0.16), lineWidth: 1)
                        .frame(width: space.size.width + CGFloat(index) * 35,
                               height: 140 + CGFloat(index) * 30)
                        .rotationEffect(.degrees(-32))
                        .position(x: space.size.width * 0.5, y: space.size.height * 0.51)
                }
            }
            .accessibilityHidden(true)

            PosterArtwork(
                urlString: content?.posterUrl,
                isLoading: isContentLoading,
                lookupFailed: contentFailed,
                imageLabel: "\(displayedEvent.title) 포스터",
                symbol: DiscoveryPalette.symbol(displayedEvent.kind),
                accent: accent
            )
            .frame(width: 137, height: 205)
            .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(.white.opacity(0.19)))
            .shadow(color: .black.opacity(0.5), radius: 12, y: 9)
            .padding(.vertical, 17)
        }
        .frame(height: 239)
        .frame(maxWidth: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .overlay(RoundedRectangle(cornerRadius: 22).strokeBorder(accent.opacity(0.27)))
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
        .padding(12)
        .background(accent.opacity(0.085), in: RoundedRectangle(cornerRadius: 15))
        .overlay(RoundedRectangle(cornerRadius: 15).strokeBorder(accent.opacity(0.23)))
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
                detailRow("공개 지역", value: Locale(identifier: "ko_KR").localizedString(forRegionCode: market) ?? market)
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

private struct EventPosterThumbnail: View {
    let contentId: String?
    let kind: String
    let api: PublicAPI
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
        .frame(width: 62, height: 88)
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

private struct PosterArtwork: View {
    let urlString: String?
    var isLoading = false
    var compact = false
    var lookupFailed = false
    var imageLabel = ""
    var symbol = "photo"
    var accent = DiscoveryPalette.lime

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
                colors: [accent.opacity(0.16), DiscoveryPalette.ink],
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
private struct PlatformIcon: View {
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
        .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: size * 0.25))
        .clipShape(RoundedRectangle(cornerRadius: size * 0.25))
    }

    private var fallback: some View {
        Image(systemName: "play.square.fill")
            .resizable()
            .scaledToFit()
            .foregroundStyle(.white.opacity(0.65))
    }
}
