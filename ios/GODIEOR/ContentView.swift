import SwiftUI

struct ContentView: View {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var account = AccountState()
    @State private var month = CalendarDay.iso.date(from: CalendarDay.iso.dateComponents([.year, .month], from: .now))!
    @State private var selectedDate: String?
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
    @State private var selectedEvent: ReleaseEvent?
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
        [selectedDate ?? "", selectionKey, calendar?.catalogRevision ?? ""].joined(separator: ":")
    }
    private var days: [String: ReleaseDay] { Dictionary(uniqueKeysWithValues: (calendar?.days ?? []).map { ($0.date, $0) }) }

    private let ink = Color(red: 0.067, green: 0.078, blue: 0.067)
    private let lime = Color(red: 0.86, green: 0.99, blue: 0.42)
    private let panel = Color(red: 0.12, green: 0.14, blue: 0.12)

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 23) {
                    HStack(alignment: .center) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("GODIEOR.")
                                .font(.system(size: 32, weight: .black, design: .rounded))
                                .tracking(-1.8)
                                .foregroundStyle(.white)
                            Text("좋아하는 순간이 곧 이어져요")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.52))
                        }
                        Spacer()
                        Button { showingAccount = true } label: {
                            Image(systemName: account.user == nil ? "person.crop.circle" : "person.crop.circle.fill")
                                .font(.title2)
                                .foregroundStyle(lime)
                                .frame(width: 47, height: 47)
                                .background(panel, in: Circle())
                        }
                        .accessibilityLabel("계정 및 동기화 설정")
                    }
                    HStack(spacing: 12) {
                        Text("DISCOVER")
                            .font(.system(size: 11, weight: .black, design: .rounded))
                            .tracking(2.5)
                            .foregroundStyle(lime)
                        Rectangle().fill(.white.opacity(0.16)).frame(height: 1)
                    }
                    categoryStories
                    serviceChips
                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(monthKey.replacingOccurrences(of: "-", with: "."))
                                .font(.system(size: 30, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                            Text("\(filters?.country ?? "지역 확인 중") · \(filters?.timeZone ?? "시간대 확인 중")")
                                .font(.caption2)
                                .foregroundStyle(.white.opacity(0.52))
                        }
                        Spacer()
                        Button { moveMonth(-1) } label: { Image(systemName: "chevron.left") }
                            .accessibilityLabel("이전 달")
                        Button { moveMonth(1) } label: { Image(systemName: "chevron.right") }
                            .accessibilityLabel("다음 달")
                        Button("오늘") {
                            month = CalendarDay.iso.date(from: CalendarDay.iso.dateComponents([.year, .month], from: .now))!
                            selectedDate = nil
                        }
                        .font(.caption.bold())
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.white)
                    calendarContent
                    HStack {
                        Label("캘린더", systemImage: "calendar")
                            .foregroundStyle(lime)
                        Spacer()
                        Button { showingFilters = true } label: {
                            Label("상세 필터", systemImage: "slider.horizontal.3")
                        }
                        .disabled(catalogOptions == nil)
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(17)
                    .background(panel, in: RoundedRectangle(cornerRadius: 20))
                }
                .padding(.horizontal, 18)
                .padding(.top, 18)
                .padding(.bottom, 42)
            }
            .background(ink.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
            .preferredColorScheme(.dark)
            .sheet(item: $selectedEvent) { event in
                if let filters { NavigationStack { EventDetailView(event: event, filters: filters, api: api) } }
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

    private var categoryStories: some View {
        HStack(spacing: 0) {
            ForEach(options, id: \.0) { option in
                let selected = activeCategories.contains(option.0)
                Button {
                    var next = activeCategories
                    if !next.insert(option.0).inserted { next.remove(option.0) }
                    storedCategories = options.map(\.0).filter { next.contains($0) }.joined(separator: ",")
                } label: {
                    VStack(spacing: 9) {
                        Image(systemName: categorySymbol(option.0))
                            .font(.system(size: 23, weight: .medium))
                            .foregroundStyle(selected ? ink : .white)
                            .frame(width: 64, height: 64)
                            .background(selected ? lime : panel, in: Circle())
                            .overlay(Circle().strokeBorder(selected ? lime : .white.opacity(0.16), lineWidth: 2))
                        Text(option.1)
                            .font(.caption.weight(selected ? .bold : .medium))
                            .foregroundStyle(selected ? .white : .white.opacity(0.5))
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(option.1) \(selected ? "선택됨" : "선택 안 됨")")
            }
        }
    }

    private func categorySymbol(_ category: String) -> String {
        switch category {
        case "movie": "film.stack"
        case "ott": "play.rectangle.on.rectangle"
        case "game": "gamecontroller"
        case "epl": "soccerball"
        default: "sparkles"
        }
    }

    private var serviceChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 9) {
                ForEach(["netflix", "disney_plus", "tving", "coupang_play"], id: \.self) { service in
                    let active = activeServices.contains(service)
                    Button {
                        var next = activeServices
                        if !next.insert(service).inserted { next.remove(service) }
                        storedServices = next.sorted().joined(separator: ",")
                    } label: {
                        HStack(spacing: 7) {
                            PlatformIcon(key: service, size: 22)
                            Text(ottName(service))
                                .font(.caption.weight(.semibold))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .frame(height: 39)
                        .background(active ? Color.white.opacity(0.2) : panel, in: Capsule())
                        .overlay(Capsule().strokeBorder(active ? lime : .white.opacity(0.1), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(ottName(service)) \(active ? "필터 선택됨" : "필터 미선택")")
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
            if loading { ProgressView("달력 불러오는 중") }
            if let errorText {
                ContentUnavailableView("연결 실패", systemImage: "wifi.exclamationmark", description: Text(errorText))
                Button("다시 시도") { Task { await loadMonth(selection: selectionKey) } }
            }
            if showingCachedCalendar {
                Label("이전에 조회한 달력을 표시해요. 최신 일정이 아닐 수 있어요.", systemImage: "clock.arrow.circlepath")
                    .font(.caption).foregroundStyle(.orange)
            }
            if calendar != nil { monthGrid }
            if let calendar {
                if calendar.freshness.contains(where: { $0.dataOrigin == "fixture" }) {
                    Label("가상 일정이 포함되어 있어요", systemImage: "exclamationmark.circle")
                        .font(.caption).foregroundStyle(.orange)
                }
                if calendar.freshness.contains(where: { $0.coverage != "available" }) {
                    Text("제공처 일정이 일부만 수집되었을 수 있어요.").font(.caption).foregroundStyle(.secondary)
                }
            }
            if let selectedDate { dayList(selectedDate) }
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

    private var monthGrid: some View {
        let offset = CalendarDay.iso.component(.weekday, from: month) - 1
        let count = CalendarDay.iso.range(of: .day, in: .month, for: month)!.count
        let columns = Array(repeating: GridItem(.flexible(), spacing: 2), count: 7)
        return VStack(spacing: 11) {
            HStack {
                ForEach(["일", "월", "화", "수", "목", "금", "토"], id: \.self) { label in
                    Text(label)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.44))
                        .frame(maxWidth: .infinity)
                }
            }
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(0..<(offset + count), id: \.self) { index in
                    if index < offset { Color.clear.frame(height: 57) }
                    else {
                        let number = index - offset + 1
                        let date = String(format: "%@-%02d", monthKey, number)
                        let day = days[date]
                        let selected = selectedDate == date
                        Button {
                            selectedDate = date
                            events = days[date]?.previews ?? []
                            dayError = nil
                            loadingDay = true
                        } label: {
                            VStack(spacing: 5) {
                                Text("\(number)")
                                    .font(.system(size: 15, weight: selected ? .black : .medium, design: .rounded))
                                    .foregroundStyle(selected ? ink : .white)
                                    .frame(width: 37, height: 37)
                                    .background(selected ? lime : .clear, in: Circle())
                                Circle()
                                    .fill((day?.total ?? 0) > 0 ? lime : .clear)
                                    .frame(width: 5, height: 5)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 57)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("\(date), \(day?.total ?? 0)개 일정")
                    }
                }
            }
        }
        .padding(.vertical, 18)
        .padding(.horizontal, 8)
        .background(panel, in: RoundedRectangle(cornerRadius: 24))
    }

    private func dayList(_ date: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("UP NEXT  ·  \(date)  ·  \(days[date]?.total ?? 0)건")
                .font(.system(size: 13, weight: .heavy, design: .rounded))
                .tracking(1.2)
                .foregroundStyle(lime)
            if loadingDay { ProgressView("전체 일정 불러오는 중 · 미리보기 표시 중") }
            if let dayError {
                Text(dayError).foregroundStyle(.red).font(.footnote)
                Button("다시 시도") { Task { await loadDay(date, selection: selectionKey) } }
            }
            if !loadingDay && dayError == nil && events.isEmpty {
                Text("확인된 일정이 없어요.").foregroundStyle(.secondary)
            }
            ForEach(events) { item in
                HStack(spacing: 8) {
                    Button { selectedEvent = item } label: {
                        HStack(alignment: .top, spacing: 12) {
                            EventPosterThumbnail(contentId: item.contentId, api: api)
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(item.categoryTitle).font(.caption.bold())
                                    if item.dataOrigin == "fixture" {
                                        Text("가상").font(.caption).foregroundStyle(.orange)
                                    }
                                    if item.status != "scheduled" {
                                        Text(item.statusTitle).font(.caption).foregroundStyle(.red)
                                    }
                                }
                                Text(item.title).font(.body.bold())
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
                                Text(item.time.description).font(.caption).foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                        .background(panel, in: RoundedRectangle(cornerRadius: 18))
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
                }
                }
            }
        }
    }

    private func ottMark(_ service: String) -> String {
        switch service {
        case "netflix": "N"
        case "disney_plus": "Disney+"
        case "tving": "TVING"
        case "coupang_play": "Coupang Play"
        default: service
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

    private func moveMonth(_ offset: Int) {
        guard let next = CalendarDay.iso.date(byAdding: .month, value: offset, to: month),
              next >= CalendarDay.iso.date(from: DateComponents(year: 2026, month: 1, day: 1))! else { return }
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
        guard let revision = calendar?.catalogRevision else { return }
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

private struct EventDetailView: View {
    let event: ReleaseEvent
    let filters: PublicFilters
    let api: PublicAPI
    @Environment(\.dismiss) private var dismiss
    @State private var detail: ReleaseDetail?
    @State private var error: String?
    @State private var content: CatalogContent?
    @State private var isContentLoading = false

    private var displayedEvent: ReleaseEvent { detail?.event ?? event }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(displayedEvent.title).font(.title2.bold())
                PosterArtwork(urlString: content?.posterUrl, isLoading: isContentLoading)
                    .frame(maxWidth: .infinity)
                    .frame(height: 290)
                    .accessibilityLabel("\(displayedEvent.title) 포스터")
                if let synopsis = content?.synopsis, !synopsis.isEmpty {
                    Text(synopsis).font(.subheadline).foregroundStyle(.secondary)
                }
                LabeledContent("분야", value: displayedEvent.categoryTitle)
                LabeledContent("일정", value: displayedEvent.time.description)
                LabeledContent("상태", value: displayedEvent.statusTitle)
                if let market = displayedEvent.releaseMarket { LabeledContent("공개 지역", value: market) }
                if let country = displayedEvent.venueCountry { LabeledContent("개최국", value: country) }
                if !displayedEvent.services.isEmpty { LabeledContent("OTT", value: displayedEvent.services.joined(separator: ", ")) }
                if !displayedEvent.devices.isEmpty { LabeledContent("기기", value: displayedEvent.devices.map { device in
                    switch device {
                    case "ios": return "iOS"
                    case "android": return "Android"
                    case "pc": return "PC"
                    case "playstation": return "PlayStation"
                    case "xbox": return "Xbox"
                    case "switch": return "Nintendo Switch"
                    default: return device
                    }
                }.joined(separator: ", ")) }
                LabeledContent("데이터", value: displayedEvent.dataOrigin == "fixture" ? "가상 데이터" : "제공처 반영 데이터")
                LabeledContent("최종 수정", value: displayedEvent.updatedAt)
                if let previous = detail?.previousTime { LabeledContent("이전 일정", value: previous.description) }
                if let detail {
                    Text("출처").font(.headline)
                    if detail.sources.isEmpty { Text("표시할 출처 없음").foregroundStyle(.secondary) }
                    ForEach(detail.sources, id: \.url) { source in
                        if let url = URL(string: source.url), ["http", "https"].contains(url.scheme) {
                            Link(source.providerKey, destination: url)
                        } else { Text(source.providerKey) }
                    }
                }
                if let error { Text(error).font(.caption).foregroundStyle(.red) }
            }.padding()
        }
        .navigationTitle("일정 상세")
        .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("닫기") { dismiss() } } }
        .task {
            do { detail = try await api.detail(id: event.id, filters: filters) }
            catch is CancellationError { return }
            catch { if !Task.isCancelled { self.error = "상세 조회 실패: \(error.localizedDescription)" } }
        }
        .task(id: displayedEvent.contentId) {
            content = nil
            guard let id = displayedEvent.contentId else { isContentLoading = false; return }
            isContentLoading = true
            defer { isContentLoading = false }
            do { content = try await api.content(id: id) }
            catch is CancellationError { return }
            catch { /* 포스터 조회 실패 시 일정 상세는 그대로 표시한다. */ }
        }
    }

}

private struct EventPosterThumbnail: View {
    let contentId: String?
    let api: PublicAPI
    @State private var posterURL: String?
    @State private var isLoading = false

    var body: some View {
        PosterArtwork(urlString: posterURL, isLoading: isLoading, compact: true)
            .frame(width: 70, height: 98)
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

    private var posterURL: URL? {
        guard let urlString, let url = URL(string: urlString),
              url.scheme?.lowercased() == "https", url.host != nil else { return nil }
        return url
    }

    var body: some View {
        Group {
            if let posterURL {
                AsyncImage(url: posterURL) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFill()
                    case .empty:
                        ProgressView()
                    case .failure:
                        placeholder
                    @unknown default:
                        placeholder
                    }
                }
            } else if isLoading {
                ProgressView()
            } else {
                placeholder
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.quaternary)
        .clipShape(RoundedRectangle(cornerRadius: compact ? 8 : 14))
        .accessibilityHidden(compact)
    }

    private var placeholder: some View {
        VStack(spacing: 4) {
            Image(systemName: "photo")
                .font(compact ? .title3 : .title)
            if !compact { Text("포스터 준비 중").font(.subheadline) }
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
