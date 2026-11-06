import SwiftUI

struct ContentView: View {
    private let categories = ["영화", "OTT 드라마", "게임", "EPL"]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("곧이어, 만날 즐거움")
                            .font(.largeTitle.bold())
                        Text("기다리는 일정을 한곳에서")
                            .foregroundStyle(.secondary)
                    }

                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 120))], spacing: 12) {
                        ForEach(categories, id: \.self) { category in
                            Text(category)
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(.quaternary, in: RoundedRectangle(cornerRadius: 12))
                        }
                    }
                    .accessibilityLabel("첫 지원 분야: 영화, OTT 드라마, 게임, EPL")

                    ContentUnavailableView(
                        "일정 연동 준비 중",
                        systemImage: "calendar",
                        description: Text("확인된 출처의 일정을 연결하고 있어요.")
                    )
                }
                .padding(24)
            }
            .navigationTitle("GODIEOR")
        }
    }
}
