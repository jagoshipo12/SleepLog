import SwiftUI
import SwiftData
import Charts

/// 수면 통계를 보여주는 뷰입니다.
/// 주간, 월간, 연간 통계를 제공하며 수면 단계별 상세 분석을 포함합니다.
struct StatisticsView: View {
    @Query(sort: \SleepLog.sleepTime, order: .forward) private var logs: [SleepLog]
    
    // 기간 선택 열거형
    enum TimeRange: String, CaseIterable, Identifiable {
        case weekly = "주간"
        case monthly = "월간"
        case yearly = "연간"
        var id: String { self.rawValue }
    }
    @State private var selectedRange: TimeRange = .weekly
    
    // 테마 색상
    let darkBackground = Color(red: 0.05, green: 0.05, blue: 0.15)
    let cardBackground = Color(red: 0.1, green: 0.1, blue: 0.2)
    let textPrimary = Color.white
    let textSecondary = Color.gray
    
    // 필터링된 로그
    var filteredLogs: [SleepLog] {
        let calendar = Calendar.current
        let now = Date()
        
        switch selectedRange {
        case .weekly:
            let oneWeekAgo = calendar.date(byAdding: .day, value: -7, to: now)!
            return logs.filter { $0.sleepTime >= oneWeekAgo }
        case .monthly:
            let oneMonthAgo = calendar.date(byAdding: .month, value: -1, to: now)!
            return logs.filter { $0.sleepTime >= oneMonthAgo }
        case .yearly:
            let oneYearAgo = calendar.date(byAdding: .year, value: -1, to: now)!
            return logs.filter { $0.sleepTime >= oneYearAgo }
        }
    }
    
    // 통계 데이터 계산
    var statistics: SleepStatistics {
        calculateStatistics(logs: filteredLogs)
    }
    
    struct SleepStatistics {
        var dateRange: String
        var averageDuration: String
        var averageBedtime: String
        var averageWakeTime: String
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                darkBackground.ignoresSafeArea()
                
                VStack(spacing: 20) {
                    timeRangePicker
                    
                    ScrollView {
                        VStack(spacing: 20) {
                            summarySection
                            chartSection
                            legendSection
                        }
                    }
                }
            }
            .navigationTitle("통계")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    // MARK: - Subviews
    
    private var timeRangePicker: some View {
        Picker("Time Range", selection: $selectedRange) {
            ForEach(TimeRange.allCases) { range in
                Text(range.rawValue).tag(range)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal)
        .padding(.top)
    }
    
    private var summarySection: some View {
        VStack(spacing: 10) {
            Text(statistics.dateRange)
                .font(.headline)
                .foregroundColor(textSecondary)
            
            Text("평균 수면 시간 \(statistics.averageDuration)")
                .font(.title2)
                .bold()
                .foregroundColor(textPrimary)
            
            HStack {
                Text("평균 취침: \(statistics.averageBedtime)")
                Text("|")
                    .foregroundColor(textSecondary)
                Text("평균 기상: \(statistics.averageWakeTime)")
            }
            .font(.subheadline)
            .foregroundColor(textSecondary)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(cardBackground)
        .cornerRadius(15)
        .padding(.horizontal)
    }
    
    private var chartSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("수면 단계 분석")
                .font(.headline)
                .foregroundColor(textPrimary)
            
            if filteredLogs.isEmpty {
                Text("표시할 데이터가 없습니다.")
                    .foregroundColor(textSecondary)
                    .frame(height: 300)
                    .frame(maxWidth: .infinity)
            } else {
                chartView
            }
        }
        .padding()
        .background(cardBackground)
        .cornerRadius(15)
        .padding(.horizontal)
    }
    
    private var chartView: some View {
        Chart {
            if selectedRange == .yearly {
                // 연간: 월별 평균 데이터
                ForEach(monthlyAggregatedData, id: \.month) { data in
                    ForEach(data.stages, id: \.stage) { stageData in
                        BarMark(
                            x: .value("Month", data.month, unit: .month),
                            y: .value("Duration", stageData.duration / 3600)
                        )
                        .foregroundStyle(by: .value("Stage", stageData.stage))
                    }
                }
            } else {
                // 주간/월간: 일별 데이터
                ForEach(filteredLogs) { log in
                    ForEach(log.sleepStages) { stage in
                        BarMark(
                            x: .value("Date", log.sleepTime, unit: .day),
                            y: .value("Duration", stage.duration / 3600)
                        )
                        .foregroundStyle(by: .value("Stage", stage.stage))
                    }
                }
            }
        }
        .chartForegroundStyleScale([
            SleepLog.SleepStage.awake: Color.red,
            SleepLog.SleepStage.rem: Color.blue,
            SleepLog.SleepStage.light: Color.green,
            SleepLog.SleepStage.deep: Color.purple
        ])
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisValueLabel {
                    if let doubleValue = value.as(Double.self) {
                        Text("\(Int(doubleValue))h")
                            .foregroundColor(textSecondary)
                    }
                }
            }
        }
        .chartXAxis {
            AxisMarks(values: .automatic) { value in
                if selectedRange == .yearly {
                    AxisValueLabel(format: .dateTime.month())
                        .foregroundStyle(textSecondary)
                } else {
                    AxisValueLabel(format: .dateTime.day())
                        .foregroundStyle(textSecondary)
                }
            }
        }
        .frame(height: 300)
    }
    
    private var legendSection: some View {
        HStack(spacing: 15) {
            LegendItem(color: .red, label: "깸")
            LegendItem(color: .blue, label: "렘")
            LegendItem(color: .green, label: "얕은")
            LegendItem(color: .purple, label: "깊은")
        }
        .padding(.bottom)
    }
    
    // MARK: - Logic
    
    func calculateStatistics(logs: [SleepLog]) -> SleepStatistics {
        guard !logs.isEmpty else {
            return SleepStatistics(dateRange: "-", averageDuration: "-", averageBedtime: "-", averageWakeTime: "-")
        }
        
        // 날짜 범위
        let sortedLogs = logs.sorted { $0.sleepTime < $1.sleepTime }
        let start = sortedLogs.first?.sleepTime ?? Date()
        let end = sortedLogs.last?.sleepTime ?? Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "M월 d일"
        let dateRange = "\(formatter.string(from: start)) - \(formatter.string(from: end))"
        
        // 평균 수면 시간
        let totalDuration = logs.reduce(0) { $0 + $1.sleepDuration }
        let avgDuration = totalDuration / Double(logs.count)
        let avgH = Int(avgDuration) / 3600
        let avgM = (Int(avgDuration) % 3600) / 60
        let averageDuration = "\(avgH)시간 \(avgM)분 / 일"
        
        // 평균 취침/기상 시간 (초 단위 변환 후 평균)
        let avgBedtime = calculateAverageTime(dates: logs.map { $0.sleepTime })
        let avgWakeTime = calculateAverageTime(dates: logs.map { $0.wakeTime })
        
        return SleepStatistics(
            dateRange: dateRange,
            averageDuration: averageDuration,
            averageBedtime: avgBedtime,
            averageWakeTime: avgWakeTime
        )
    }
    
    func calculateAverageTime(dates: [Date]) -> String {
        guard !dates.isEmpty else { return "-" }
        
        // 모든 시간을 초 단위로 변환 (자정 기준)
        // 주의: 취침 시간은 23시, 01시 등이 섞여 있을 수 있음.
        // 이를 해결하기 위해 정오(12:00 PM)를 기준으로 하루의 흐름을 계산하거나,
        // 단순히 시/분을 초로 변환하고 벡터 평균을 사용할 수도 있음.
        // 여기서는 원형 평균(Circular Mean)을 사용하여 정확하게 계산합니다.
        
        // 취침 시간의 경우 22:00(79200)와 02:00(7200)의 평균은 00:00여야 함.
        // 이를 위해 원형 평균(Circular Mean)을 사용하는 것이 가장 정확함.
        
        var xTotal: Double = 0
        var yTotal: Double = 0
        
        for date in dates {
            let calendar = Calendar.current
            let hour = calendar.component(.hour, from: date)
            let minute = calendar.component(.minute, from: date)
            let totalMinutes = Double(hour * 60 + minute)
            
            // 하루 1440분을 360도로 매핑
            let angle = (totalMinutes / 1440.0) * 2 * .pi
            xTotal += cos(angle)
            yTotal += sin(angle)
        }
        
        let avgX = xTotal / Double(dates.count)
        let avgY = yTotal / Double(dates.count)
        
        var avgAngle = atan2(avgY, avgX)
        if avgAngle < 0 { avgAngle += 2 * .pi }
        
        let avgTotalMinutes = (avgAngle / (2 * .pi)) * 1440.0
        let avgHour = Int(avgTotalMinutes) / 60
        let avgMinute = Int(avgTotalMinutes) % 60
        
        // 오전/오후 포맷팅
        let isPM = avgHour >= 12
        let displayHour = avgHour > 12 ? avgHour - 12 : (avgHour == 0 ? 12 : avgHour)
        let ampm = isPM ? "오후" : "오전"
        
        return String(format: "%@ %d시 %02d분", ampm, displayHour, avgMinute)
    }
    
    // 연간 데이터 집계 (월별)
    struct MonthlyData {
        var month: Date
        var stages: [StageData]
    }
    struct StageData {
        var stage: SleepLog.SleepStage
        var duration: TimeInterval
    }
    
    var monthlyAggregatedData: [MonthlyData] {
        let calendar = Calendar.current
        // 월별로 그룹화
        let grouped = Dictionary(grouping: filteredLogs) { log in
            calendar.date(from: calendar.dateComponents([.year, .month], from: log.sleepTime))!
        }
        
        return grouped.map { (month, logs) in
            // 해당 월의 단계별 총 지속시간 계산 후 일평균으로 나눔
            let totalDays = Double(logs.count)
            var stages: [StageData] = []
            
            for stage in SleepLog.SleepStage.allCases {
                let totalDuration = logs.flatMap { $0.sleepStages }
                    .filter { $0.stage == stage }
                    .reduce(0) { $0 + $1.duration }
                stages.append(StageData(stage: stage, duration: totalDuration / totalDays))
            }
            return MonthlyData(month: month, stages: stages)
        }.sorted { $0.month < $1.month }
    }
}

struct LegendItem: View {
    let color: Color
    let label: String
    
    var body: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(color)
                .frame(width: 10, height: 10)
            Text(label)
                .font(.caption)
                .foregroundColor(.gray)
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: SleepLog.self, configurations: config)
    let manager = SleepLogManager()
    
    StatisticsView()
        .environment(manager)
        .modelContainer(container)
}

extension SleepLog.SleepStage: Plottable {
    public var primitivePlottable: String { rawValue }
    public init?(primitivePlottable: String) {
        self.init(rawValue: primitivePlottable)
    }
}
