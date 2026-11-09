import SwiftUI

struct ContentView: View {
    @State private var month = CalendarDay.iso.date(from: CalendarDay.iso.dateComponents([.year, .month], from: .now))!
    @State private var selectedDate: String?
    @AppStorage("temporaryVisibleCategories") private var storedCategories = "movie,ott"
    @AppStorage("temporaryCountry") private var storedCountry = ""
    @AppStorage("temporaryTimeZone") private var storedTimeZone = ""
    @AppStorage("temporaryServices") private var storedServices = ""
    @AppStorage("temporaryDevices") private var storedDevices = ""
    @State private var catalogOptions: CatalogOptions?
    @State private var optionsError: String?
    @State private var showingFilters = false
    @State private var calendar: ReleaseCalendar?
    @State private var lastCalendars: [String: ReleaseCalendar] = [:]
    @State private var showingCachedCalendar = false
    @State private var events: [ReleaseEvent] = []
    @State private var loading = false
    @State private var loadingDay = false
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
    private var days: [String: ReleaseDay] { Dictionary(uniqueKeysWithValues: (calendar?.days ?? []).map { ($0.date, $0) }) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("곧이어, 만날 즐거움").font(.title2.bold())
                    HStack {
                        Button { moveMonth(-1) } label: { Image(systemName: "chevron.left") }
                            .accessibilityLabel("이전 달")
                        Spacer()
                        Text(monthKey.replacingOccurrences(of: "-", with: "년 ") + "월").font(.headline)
                        Spacer()
                        Button { moveMonth(1) } label: { Image(systemName: "chevron.right") }
                            .accessibilityLabel("다음 달")
                        Button("오늘") {
                            month = CalendarDay.iso.date(from: CalendarDay.iso.dateComponents([.year, .month], from: .now))!
                            selectedDate = nil
                        }.font(.caption)
                    }.buttonStyle(.bordered)
                    HStack(spacing: 6) {
                        ForEach(options, id: \.0) { option in
                            Button(option.1) {
                                var selected = activeCategories
                                if !selected.insert(option.0).inserted { selected.remove(option.0) }
                                storedCategories = options.map(\.0).filter { selected.contains($0) }.joined(separator: ",")
                            }
                            .buttonStyle(.bordered)
                            .tint(activeCategories.contains(option.0) ? .accentColor : .gray)
                        }
                    }
                    HStack {
                        Text("\(filters?.country ?? "지역 확인 중") · \(filters?.timeZone ?? "시간대 확인 중") · 비로그인 공개 일정")
                            .font(.caption).foregroundStyle(.secondary)
                        Spacer()
                        Button("필터") { showingFilters = true }.disabled(catalogOptions == nil)
                    }
                    Text("필터 설정은 이 기기에 임시 저장돼요.")
                        .font(.caption).foregroundStyle(.secondary)
                    calendarContent
                }.padding(16)
            }
            .navigationTitle("GODIEOR")
            .sheet(item: $selectedEvent) { event in
                if let filters { NavigationStack { EventDetailView(event: event, filters: filters, api: api) } }
            }
            .sheet(isPresented: $showingFilters) { filterSheet }
            .task { await loadOptions() }
            .task(id: selectionKey) { await loadMonth(selection: selectionKey) }
            .task(id: (selectedDate ?? "") + ":" + selectionKey + ":" + (calendar?.catalogRevision ?? "")) {
                if let selectedDate { await loadDay(selectedDate, selection: selectionKey) }
            }
        }
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
                ForEach(calendar.freshness, id: \.providerKey) { source in
                    if source.lastAttemptStatus != "succeeded" || source.coverage != "available" {
                        Text("\(source.providerKey): \(source.lastAttemptStatus) · 마지막 성공 \(source.lastSuccessfulAt ?? "확인되지 않음")")
                            .font(.caption2).foregroundStyle(.secondary)
                    }
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
                            Toggle(device, isOn: storedSetBinding(device, key: "devices"))
                        }
                    }
                    Text("OTT 서비스 필터는 OTT에, 게임 기기 필터는 게임에 적용됩니다. 계정 동기화 전까지 이 기기에만 저장됩니다.")
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

    private var monthGrid: some View {
        let offset = CalendarDay.iso.component(.weekday, from: month) - 1
        let count = CalendarDay.iso.range(of: .day, in: .month, for: month)!.count
        let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)
        return VStack(spacing: 8) {
            HStack {
                ForEach(["일", "월", "화", "수", "목", "금", "토"], id: \.self) { label in
                    Text(label).font(.caption.bold()).frame(maxWidth: .infinity)
                }
            }
            LazyVGrid(columns: columns, spacing: 5) {
                ForEach(0..<(offset + count), id: \.self) { index in
                    if index < offset { Color.clear.frame(height: 76) }
                    else {
                        let number = index - offset + 1
                        let date = String(format: "%@-%02d", monthKey, number)
                        let day = days[date]
                        Button {
                            selectedDate = date
                        } label: {
                            VStack(alignment: .leading, spacing: 3) {
                                Text("\(number)").font(.caption.bold())
                                if let day, day.total > 0 {
                                    ForEach(day.previews.prefix(2)) { item in
                                        Text(item.title).font(.system(size: 9)).lineLimit(1)
                                    }
                                    if day.total > day.previews.count {
                                        Text("+\(day.total - day.previews.count)").font(.caption2.bold())
                                    }
                                }
                                Spacer(minLength: 0)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .frame(height: 70, alignment: .top)
                            .padding(3)
                            .background(selectedDate == date ? Color.accentColor.opacity(0.2) : Color.gray.opacity(0.08), in: RoundedRectangle(cornerRadius: 7))
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("\(date), \(day?.total ?? 0)개 일정")
                    }
                }
            }
        }
    }

    private func dayList(_ date: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("\(date) · \(days[date]?.total ?? 0)건").font(.headline)
            if loadingDay { ProgressView("일정 불러오는 중") }
            if let dayError {
                Text(dayError).foregroundStyle(.red).font(.footnote)
                Button("다시 시도") { Task { await loadDay(date, selection: selectionKey) } }
            }
            if !loadingDay && dayError == nil && events.isEmpty {
                Text("확인된 일정이 없어요.").foregroundStyle(.secondary)
            }
            ForEach(events) { item in
                Button { selectedEvent = item } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(item.categoryTitle).font(.caption.bold())
                            if item.dataOrigin == "fixture" { Text("가상").font(.caption).foregroundStyle(.orange) }
                            if item.status != "scheduled" { Text(item.statusTitle).font(.caption).foregroundStyle(.red) }
                        }
                        Text(item.title).font(.body.bold())
                        Text(item.time.description).font(.caption).foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .background(.quaternary, in: RoundedRectangle(cornerRadius: 10))
                }.buttonStyle(.plain)
            }
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
        events = []
        dayError = nil
        loadingDay = true
        defer { if selectedDate == date && selection == selectionKey { loadingDay = false } }
        do {
            let result = try await api.events(date: date, filters: filters, revision: revision)
            guard !Task.isCancelled, selectedDate == date, selection == selectionKey else { return }
            events = result
        }
        catch PublicAPIError.catalogChanged {
            guard !Task.isCancelled, selectedDate == date, selection == selectionKey else { return }
            do {
                let updated = try await api.calendar(month: monthKey, filters: filters)
                let result = try await api.events(date: date, filters: filters, revision: updated.catalogRevision)
                guard !Task.isCancelled, selectedDate == date, selection == selectionKey else { return }
                calendar = updated
                lastCalendars[selection] = updated
                showingCachedCalendar = false
                events = result
            } catch {
                if !Task.isCancelled && selectedDate == date && selection == selectionKey { dayError = error.localizedDescription }
            }
        }
        catch is CancellationError { return }
        catch {
            if !Task.isCancelled && selectedDate == date && selection == selectionKey { dayError = error.localizedDescription }
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

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(event.title).font(.title2.bold())
                LabeledContent("분야", value: event.categoryTitle)
                LabeledContent("일정", value: (detail?.event ?? event).time.description)
                LabeledContent("상태", value: event.statusTitle)
                if let market = event.releaseMarket { LabeledContent("공개 지역", value: market) }
                if !event.services.isEmpty { LabeledContent("OTT", value: event.services.joined(separator: ", ")) }
                if !event.devices.isEmpty { LabeledContent("기기", value: event.devices.joined(separator: ", ")) }
                LabeledContent("데이터", value: event.dataOrigin == "fixture" ? "가상 데이터" : "제공처 반영 데이터")
                LabeledContent("최종 수정", value: event.updatedAt)
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
    }
}
