import SwiftUI

struct ContentView: View {
    @State private var month = CalendarDay.iso.date(from: DateComponents(year: 2026, month: 11, day: 1))!
    @State private var selectedDate: String?
    @State private var activeCategories: Set<String> = ["movie", "ott"]
    @State private var calendar: ReleaseCalendar?
    @State private var events: [ReleaseEvent] = []
    @State private var loading = false
    @State private var loadingDay = false
    @State private var errorText: String?
    @State private var dayError: String?
    @State private var selectedEvent: ReleaseEvent?
    @State private var conflictRetries = 0
    private let api = PublicAPI()
    private let options = [("movie", "영화"), ("ott", "OTT"), ("game", "게임"), ("epl", "EPL")]

    private var monthKey: String {
        let c = CalendarDay.iso.dateComponents([.year, .month], from: month)
        return String(format: "%04d-%02d", c.year!, c.month!)
    }
    private var categories: [String] { options.map { $0.0 }.filter { activeCategories.contains($0) } }
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
                                if activeCategories.contains(option.0) { activeCategories.remove(option.0) }
                                else { activeCategories.insert(option.0) }
                            }
                            .buttonStyle(.bordered)
                            .tint(activeCategories.contains(option.0) ? .accentColor : .gray)
                        }
                    }
                    Text("한국 · Asia/Seoul · 비로그인 공개 일정")
                        .font(.caption).foregroundStyle(.secondary)
                    if categories.isEmpty {
                        ContentUnavailableView("표시할 분야가 없어요", systemImage: "calendar", description: Text("분야를 하나 이상 선택해 주세요."))
                    } else {
                        if loading { ProgressView("달력 불러오는 중") }
                        if let errorText {
                            ContentUnavailableView("연결 실패", systemImage: "wifi.exclamationmark", description: Text(errorText))
                            Button("다시 시도") { Task { await loadMonth() } }
                        }
                        monthGrid
                        if let calendar {
                            if calendar.freshness.contains(where: { $0.dataOrigin == "fixture" }) {
                                Label("가상 일정이 포함되어 있어요", systemImage: "exclamationmark.circle")
                                    .font(.caption).foregroundStyle(.orange)
                            }
                            if calendar.freshness.contains(where: { $0.coverage != "complete" }) {
                                Text("제공처 일정이 일부만 수집되었을 수 있어요.").font(.caption).foregroundStyle(.secondary)
                            }
                        }
                        if let selectedDate { dayList(selectedDate) }
                    }
                }.padding(16)
            }
            .navigationTitle("GODIEOR")
            .sheet(item: $selectedEvent) { event in
                NavigationStack { EventDetailView(event: event, api: api) }
            }
            .task(id: monthKey + ":" + categories.joined(separator: ",")) { await loadMonth() }
        }
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
                            Task { await loadDay(date) }
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
                Button("다시 시도") { Task { await loadDay(date) } }
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

    @MainActor private func loadMonth() async {
        calendar = nil
        events = []
        errorText = nil
        dayError = nil
        guard !categories.isEmpty else { return }
        loading = true
        defer { loading = false }
        do {
            calendar = try await api.calendar(month: monthKey, categories: categories)
            conflictRetries = 0
            if let selectedDate { await loadDay(selectedDate) }
        } catch is CancellationError { return }
        catch { errorText = error.localizedDescription }
    }

    @MainActor private func loadDay(_ date: String) async {
        guard let revision = calendar?.catalogRevision else { return }
        events = []
        dayError = nil
        loadingDay = true
        defer { loadingDay = false }
        do { events = try await api.events(date: date, categories: categories, revision: revision) }
        catch PublicAPIError.catalogChanged {
            if conflictRetries < 1 {
                conflictRetries += 1
                calendar = nil
                do {
                    calendar = try await api.calendar(month: monthKey, categories: categories)
                    if let freshRevision = calendar?.catalogRevision {
                        events = try await api.events(date: date, categories: categories, revision: freshRevision)
                    }
                } catch { dayError = error.localizedDescription }
            } else { dayError = PublicAPIError.catalogChanged.localizedDescription }
        }
        catch is CancellationError { return }
        catch { dayError = error.localizedDescription }
    }
}

private struct EventDetailView: View {
    let event: ReleaseEvent
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
            do { detail = try await api.detail(id: event.id) }
            catch { self.error = "상세 조회 실패: \(error.localizedDescription)" }
        }
    }
}
