import SwiftUI
import SwiftData
import Charts

/// 수면 통계를 보여주는 뷰입니다.
/// 최근 7일간의 수면 시간을 막대 그래프로 시각화하여 보여줍니다.
struct StatisticsView: View {
    @Query(sort: \SleepLog.sleepTime, order: .forward) private var logs: [SleepLog]
    
    // 테마 색상
    let darkBackground = Color(red: 0.05, green: 0.05, blue: 0.15)
    let cardBackground = Color(red: 0.1, green: 0.1, blue: 0.2)
    let accentPurple = Color(red: 0.5, green: 0.3, blue: 0.9)
    let textPrimary = Color.white
    
    // 최근 7일간의 데이터만 필터링
    var recentLogs: [SleepLog] {
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return logs.filter { $0.sleepTime >= sevenDaysAgo }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                darkBackground.ignoresSafeArea()
                
                VStack(alignment: .leading, spacing: 20) {
                    Text("최근 7일 수면 분석")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(textPrimary)
                        .padding(.horizontal)
                        .padding(.top)
                    
                    if recentLogs.isEmpty {
                        // 데이터가 없을 때
                        VStack {
                            Spacer()
                            Image(systemName: "chart.bar.xaxis")
                                .font(.system(size: 50))
                                .foregroundColor(.gray)
                            Text("표시할 데이터가 없습니다.")
                                .foregroundColor(.gray)
                                .padding()
                            Spacer()
                        }
                        .frame(maxWidth: .infinity)
                    } else {
                        // 차트 영역
                        Chart {
                            ForEach(recentLogs) { log in
                                BarMark(
                                    x: .value("날짜", log.sleepTime, unit: .day),
                                    y: .value("수면 시간(시간)", log.sleepDuration / 3600)
                                )
                                .foregroundStyle(accentPurple)
                                .cornerRadius(5)
                            }
                        }
                        .chartYAxis {
                            AxisMarks(position: .leading, values: .automatic) { value in
                                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [5, 5]))
                                    .foregroundStyle(.gray.opacity(0.5))
                                AxisValueLabel() {
                                    if let intValue = value.as(Int.self) {
                                        Text("\(intValue)h")
                                            .foregroundColor(.gray)
                                    }
                                }
                            }
                        }
                        .chartXAxis {
                            AxisMarks(values: .stride(by: .day)) { value in
                                AxisValueLabel(format: .dateTime.weekday(), centered: true)
                                    .foregroundStyle(.gray)
                            }
                        }
                        .frame(height: 300)
                        .padding()
                        .background(cardBackground)
                        .cornerRadius(20)
                        .padding(.horizontal)
                    }
                    
                    Spacer()
                }
            }
            .navigationTitle("통계")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

#Preview {
    StatisticsView()
}
