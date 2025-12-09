import SwiftUI
import SwiftData

struct WeeklySummaryView: View {
    @Query(sort: \SleepLog.sleepTime, order: .forward) private var logs: [SleepLog]
    private let coachService = SleepCoachService()
    
    @State private var analysisText: String = "AI가 수면 기록을 분석 중입니다..."
    
    // 테마 색상
    let darkBackground = Color(red: 0.05, green: 0.05, blue: 0.15)
    let cardBackground = Color(red: 0.1, green: 0.1, blue: 0.2)
    let textPrimary = Color.white
    
    var recentLogs: [SleepLog] {
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return logs.filter { $0.sleepTime >= sevenDaysAgo }
    }
    
    var body: some View {
        ZStack {
            darkBackground.ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("주간 수면 분석")
                        .font(.title2)
                        .bold()
                        .foregroundColor(textPrimary)
                        .padding(.top)
                    
                    // AI 분석 카드
                    VStack(alignment: .leading, spacing: 15) {
                        HStack {
                            Image(systemName: "sparkles")
                                .foregroundColor(.yellow)
                            Text("AI 수면 코치 리포트")
                                .font(.headline)
                                .foregroundColor(textPrimary)
                        }
                        
                        Divider().background(Color.gray.opacity(0.5))
                        
                        Text(analysisText)
                            .font(.body)
                            .foregroundColor(textPrimary)
                            .lineSpacing(5)
                    }
                    .padding()
                    .background(cardBackground)
                    .cornerRadius(20)
                    
                    // 추가 팁 카드 (고정)
                    VStack(alignment: .leading, spacing: 10) {
                        Text("💡 수면 팁")
                            .font(.headline)
                            .foregroundColor(textPrimary)
                        
                        Text("• 규칙적인 수면 시간을 유지하세요.")
                        Text("• 잠들기 1시간 전에는 스마트폰 사용을 자제하세요.")
                        Text("• 카페인 섭취는 오후 2시 이전에 끝내는 것이 좋습니다.")
                    }
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(cardBackground.opacity(0.5))
                    .cornerRadius(15)
                }
                .padding()
            }
        }
        .navigationTitle("주간 요약")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            do {
                // API 호출 시도
                analysisText = try await coachService.fetchWeeklyAnalysis(logs: recentLogs)
            } catch {
                // 실패 시 로컬 분석으로 대체
                print("Gemini API Error: \(error)")
                analysisText = coachService.generateWeeklyAnalysis(logs: recentLogs)
            }
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: SleepLog.self, configurations: config)
    
    WeeklySummaryView()
        .modelContainer(container)
}
