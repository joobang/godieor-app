import SwiftUI

struct PosterFeedCard: View {
    let card: ReleaseCard
    let api: PublicAPI
    let dateText: String
    let saved: Bool
    let canSave: Bool
    let open: () -> Void
    let save: () -> Void

    @ScaledMetric(relativeTo: .title) private var posterHeight: CGFloat = 314
    @State private var posterURL: String?
    @State private var loadingPoster = false

    private var event: ReleaseEvent { card.event }
    private var platformNames: [String] {
        if event.kind == "game_release" { return card.devices.map(gameDeviceLabel) }
        if !event.services.isEmpty { return event.services.map(ottName) }
        return event.kind == "theatrical_release" ? ["극장"] : []
    }

    private var shareText: String {
        let date = event.time.type == "instant" ? event.time.description : (event.time.civilDate ?? event.time.description)
        let fields = [event.title, date, event.status == "scheduled" ? nil : event.statusTitle,
                      event.dataOrigin == "fixture" ? "가상 일정" : nil,
                      platformNames.isEmpty ? nil : platformNames.joined(separator: " · ")]
        return fields.compactMap { $0 }.joined(separator: "\n")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button(action: open) {
                VStack(alignment: .leading, spacing: 10) {
                    PosterArtwork(
                        urlString: posterURL, isLoading: loadingPoster,
                        imageLabel: "\(event.title) 포스터",
                        symbol: DiscoveryPalette.symbol(event.kind),
                        accent: event.kind == "game_release" ? DiscoveryPalette.feedGameAccent : DiscoveryPalette.accent(event.kind)
                    )
                    .frame(height: min(posterHeight, 342))
                    .overlay(alignment: .topLeading) {
                        ViewThatFits(in: .horizontal) {
                            HStack(spacing: 5) {
                                Label(dateText, systemImage: "calendar")
                                Text("·").accessibilityHidden(true)
                                Text(event.categoryTitle).foregroundStyle(DiscoveryPalette.muted)
                            }
                            VStack(alignment: .leading, spacing: 4) { feedBadge }
                        }
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 9)
                        .padding(.vertical, 6)
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 9))
                        .padding(10)
                    }
                    Text(event.title)
                        .font(.title2.weight(.heavy))
                        .tracking(-0.45)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    if event.status != "scheduled" || event.dataOrigin == "fixture" {
                        Text([event.status == "scheduled" ? nil : event.statusTitle,
                              event.dataOrigin == "fixture" ? "가상 일정" : nil].compactMap { $0 }.joined(separator: " · "))
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(DiscoveryPalette.primary)
                    }
                }
            }
            .buttonStyle(.plain)
            .accessibilityElement(children: .combine)
            .accessibilityHint("일정 상세 열기")

            ViewThatFits(in: .horizontal) {
                HStack(spacing: 6) { platforms; Spacer(minLength: 0); actions }
                VStack(alignment: .leading, spacing: 7) { platforms; actions }
            }
            .padding(.bottom, 4)
        }
        .task(id: event.contentId) {
            posterURL = nil
            guard let id = event.contentId else { return }
            loadingPoster = true
            defer { loadingPoster = false }
            if let content = try? await api.content(id: id), !Task.isCancelled {
                posterURL = content.posterUrl
            }
        }
    }

    @ViewBuilder private var feedBadge: some View {
        Label(dateText, systemImage: "calendar")
        Text(event.categoryTitle).foregroundStyle(DiscoveryPalette.muted)
    }

    private var platforms: some View {
        HStack(spacing: 5) {
            if event.kind == "game_release" {
                ForEach(card.devices, id: \.self) { GamePlatformIcon(device: $0) }
            } else if !event.services.isEmpty {
                ForEach(event.services, id: \.self) { key in
                    PlatformIcon(key: key, size: 23).accessibilityLabel(ottName(key))
                }
            } else {
                Label(event.kind == "theatrical_release" ? "극장" : event.categoryTitle,
                      systemImage: DiscoveryPalette.symbol(event.kind))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(DiscoveryPalette.muted)
            }
        }
    }

    private var actions: some View {
        HStack(spacing: 1) {
            Button(action: save) {
                Image(systemName: saved ? "bookmark.fill" : "bookmark")
                    .foregroundStyle(saved ? DiscoveryPalette.primary : DiscoveryPalette.text)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .accessibilityLabel(saved ? "찜 해제" : "찜")
            .disabled(!canSave)
            ShareLink(item: shareText) {
                Image(systemName: "square.and.arrow.up")
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .accessibilityLabel("공유")
        }
        .font(.system(size: 19, weight: .medium))
        .buttonStyle(.plain)
    }
}

struct SavedReleaseRow: View {
    enum Target: String { case content, event }

    let id: String
    let type: Target
    let filters: PublicFilters?
    let api: PublicAPI
    let openContent: (CatalogContent) -> Void
    let openEvent: (ReleaseCard) -> Void
    let remove: () -> Void
    @State private var content: CatalogContent?
    @State private var event: ReleaseEvent?
    @State private var failed = false
    @State private var attempt = 0

    var body: some View {
        HStack(spacing: 5) {
            Group {
                if let content {
                    Button { openContent(content) } label: {
                        row(title: content.title, detail: nil,
                            artwork: PosterArtwork(urlString: content.posterUrl, compact: true))
                    }
                    .buttonStyle(.plain)
                } else if let event {
                    Button { openEvent(.individual(event)) } label: {
                        row(title: event.title, detail: event.time.description,
                            artwork: EventPosterThumbnail(contentId: event.contentId, kind: event.kind, api: api))
                    }
                    .buttonStyle(.plain)
                } else if failed {
                    Button { attempt += 1 } label: {
                        Label("찜 항목 다시 불러오기", systemImage: "arrow.clockwise")
                    }
                } else {
                    ProgressView("찜 항목 불러오는 중")
                }
            }
            Spacer(minLength: 0)
            Button(action: remove) {
                Image(systemName: "bookmark.slash")
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("찜 해제")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .task(id: "\(filters?.timeZone ?? "")|\(attempt)") {
            failed = false
            do {
                switch type {
                case .content:
                    let result = try await api.content(id: id)
                    if !Task.isCancelled { content = result }
                case .event:
                    guard let filters else { failed = true; return }
                    let result = try await api.detail(id: id, filters: filters)
                    if !Task.isCancelled { event = result.event }
                }
            } catch { if !Task.isCancelled { failed = true } }
        }
    }

    private func row<Art: View>(title: String, detail: String?, artwork: Art) -> some View {
        HStack(spacing: 12) {
            artwork.frame(width: 58, height: 82).accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 5) {
                Text(title).font(.headline)
                if let detail { Text(detail).font(.caption).foregroundStyle(DiscoveryPalette.muted) }
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right").font(.caption).accessibilityHidden(true)
        }
        .padding(10)
        .background(DiscoveryPalette.panel, in: RoundedRectangle(cornerRadius: 14))
        .accessibilityElement(children: .combine)
    }
}

struct SavedContentDetail: View {
    let content: CatalogContent
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 15) {
                PosterArtwork(urlString: content.posterUrl, imageLabel: "\(content.title) 포스터")
                    .frame(height: 260)
                Text(content.title).font(.largeTitle.weight(.heavy)).accessibilityAddTraits(.isHeader)
                if let synopsis = content.synopsis, !synopsis.isEmpty {
                    Text(synopsis).foregroundStyle(DiscoveryPalette.muted)
                }
            }
            .frame(maxWidth: 560)
            .padding(18)
        }
        .background(DiscoveryPalette.background.ignoresSafeArea())
        .navigationTitle("찜한 작품")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("닫기") { dismiss() } } }
    }
}
