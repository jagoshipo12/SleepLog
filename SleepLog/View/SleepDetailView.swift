import SwiftUI
import Charts

struct SleepDetailView: View {
    let log: SleepLog
    @Environment(\.dismiss) var dismiss
    
    // 색상 정의
    let backgroundStart = Color(red: 0.1, green: 0.1, blue: 0.3) // Midnight Blue
    let backgroundEnd = Color(red: 0.05, green: 0.05, blue: 0.2) // Darker Blue
    let cardBackground = Color.white.opacity(0.1)
    let textPrimary = Color.white
    let textSecondary = Color.white.opacity(0.7)
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 1. 헤더 (점수 및 이모티콘)
                VStack(spacing: 10) {
                    Text(log.scoreEmoji)
                        .font(.system(size: 80))
                    
                    Text("\(log.sleepScore)점")
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .foregroundColor(textPrimary)
                    
                    Text(log.scoreDescription)
                        .font(.system(size: 20, weight: .medium, design: .rounded))
                        .foregroundColor(textSecondary)
                }
                .padding(.top, 20)
                
                // 2. 수면 시간 정보
                HStack {
                    VStack {
                        Text("취침")
                            .font(.caption)
                            .foregroundColor(textSecondary)
                        Text(log.sleepTime.formatted(date: .omitted, time: .shortened))
                            .font(.title3)
                            .bold()
                            .foregroundColor(textPrimary)
                    }
                    Spacer()
                    VStack {
                        Text("총 수면 시간")
                            .font(.caption)
                            .foregroundColor(textSecondary)
                        Text(log.durationString)
                            .font(.title2)
                            .bold()
                            .foregroundColor(.yellow)
                    }
                    Spacer()
                    VStack {
                        Text("기상")
                            .font(.caption)
                            .foregroundColor(textSecondary)
                        Text(log.wakeTime.formatted(date: .omitted, time: .shortened))
                            .font(.title3)
                            .bold()
                            .foregroundColor(textPrimary)
                    }
                }
                .padding()
                .background(cardBackground)
                .cornerRadius(15)
                .padding(.horizontal)
                
                // 3. 하이포노그래프 (수면 단계 차트)
                VStack(alignment: .leading, spacing: 15) {
                    Text("수면 단계 (Hypnogram)")
                        .font(.headline)
                        .foregroundColor(textPrimary)
                    
                    Chart {
                        ForEach(log.sleepStages) { item in
                            BarMark(
                                xStart: .value("Start", item.startTime),
                                xEnd: .value("End", item.endTime),
                                y: .value("Stage", item.stage.rawValue)
                            )
                            .foregroundStyle(Color(stageColor(item.stage)))
                        }
                    }
                    .chartYAxis {
                        AxisMarks(position: .leading) { _ in
                            AxisValueLabel()
                                .foregroundStyle(textSecondary)
                        }
                    }
                    .chartXAxis {
                        AxisMarks(values: .automatic) { _ in
                            AxisValueLabel(format: .dateTime.hour().minute())
                                .foregroundStyle(textSecondary)
                        }
                    }
                    .frame(height: 200)
                }
                .padding()
                .background(cardBackground)
                .cornerRadius(15)
                .padding(.horizontal)
                
                // 4. 수면 단계별 통계
                VStack(alignment: .leading, spacing: 15) {
                    Text("수면 단계별 시간")
                        .font(.headline)
                        .foregroundColor(textPrimary)
                    
                    ForEach(SleepLog.SleepStage.allCases, id: \.self) { stage in
                        HStack {
                            Circle()
                                .fill(Color(stageColor(stage)))
                                .frame(width: 10, height: 10)
                            Text(stage.rawValue)
                                .foregroundColor(textSecondary)
                            Spacer()
                            Text(durationForStage(stage))
                                .bold()
                                .foregroundColor(textPrimary)
                        }
                    }
                }
                .padding()
                .background(cardBackground)
                .cornerRadius(15)
                .padding(.horizontal)
            }
            .padding(.bottom, 30)
            
            // 5. 혈중 산소 (Line Chart)
            VStack(alignment: .leading, spacing: 15) {
                Text("혈중 산소")
                    .font(.headline)
                    .foregroundColor(textPrimary)
                
                Chart {
                    ForEach(log.bloodOxygenSamples) { sample in
                        LineMark(
                            x: .value("Time", sample.date),
                            y: .value("Oxygen", sample.value)
                        )
                        .foregroundStyle(.cyan)
                        .interpolationMethod(.catmullRom) // 부드러운 곡선
                    }
                }
                .chartYScale(domain: 90...100) // Y축 범위 설정
                .chartYAxis {
                    AxisMarks(position: .leading) { _ in
                        AxisValueLabel()
                            .foregroundStyle(textSecondary)
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .automatic) { _ in
                        AxisValueLabel(format: .dateTime.hour().minute())
                            .foregroundStyle(textSecondary)
                    }
                }
                .frame(height: 200)
            }
            .padding()
            .background(cardBackground)
            .cornerRadius(15)
            .padding(.horizontal)
            
            // 6. 심박수 (Bar + Line Mixed Chart)
            VStack(alignment: .leading, spacing: 15) {
                Text("심박수 (BPM)")
                    .font(.headline)
                    .foregroundColor(textPrimary)
                
                Chart {
                    ForEach(log.heartRateSamples) { sample in
                        // 막대 그래프
                        BarMark(
                            x: .value("Time", sample.date),
                            y: .value("BPM", sample.value),
                            width: 8
                        )
                        .foregroundStyle(.red.opacity(0.6))
                        
                        // 라인 그래프 (추세선)
                        LineMark(
                            x: .value("Time", sample.date),
                            y: .value("BPM", sample.value)
                        )
                        .foregroundStyle(.red)
                        .interpolationMethod(.catmullRom)
                    }
                }
                .chartYScale(domain: 40...100)
                .chartYAxis {
                    AxisMarks(position: .leading) { _ in
                        AxisValueLabel()
                            .foregroundStyle(textSecondary)
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .automatic) { _ in
                        AxisValueLabel(format: .dateTime.hour().minute())
                            .foregroundStyle(textSecondary)
                    }
                }
                .frame(height: 200)
            }
            .padding()
            .background(cardBackground)
            .cornerRadius(15)
            .padding(.horizontal)
            
            // 7. 호흡수 (평균)
            HStack {
                VStack(alignment: .leading) {
                    Text("평균 호흡수")
                        .font(.headline)
                        .foregroundColor(textSecondary)
                    
                    HStack(alignment: .lastTextBaseline) {
                        Text(String(format: "%.1f", log.respiratoryRate))
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                            .foregroundColor(.mint)
                        Text("회/분")
                            .font(.subheadline)
                            .foregroundColor(textSecondary)
                    }
                }
                Spacer()
                Image(systemName: "lungs.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.mint.opacity(0.8))
            }
            .padding()
            .background(cardBackground)
            .cornerRadius(15)
            .padding(.horizontal)
            
            Spacer().frame(height: 30) // 하단 여백 추가
        }
        .background(
            LinearGradient(gradient: Gradient(colors: [backgroundStart, backgroundEnd]), startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
        )
        .navigationTitle(log.sleepTime.formatted(date: .numeric, time: .omitted))
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // 단계별 색상 매핑
    func stageColor(_ stage: SleepLog.SleepStage) -> String {
        switch stage {
        case .awake: return "red"
        case .rem: return "blue"
        case .light: return "green"
        case .deep: return "purple"
        }
    }
    
    // 단계별 지속 시간 계산
    func durationForStage(_ stage: SleepLog.SleepStage) -> String {
        let totalSeconds = log.sleepStages.filter { $0.stage == stage }.reduce(0) { $0 + $1.duration }
        let hours = Int(totalSeconds) / 3600
        let minutes = (Int(totalSeconds) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)시간 \(minutes)분"
        } else {
            return "\(minutes)분"
        }
    }
}

// 색상 확장 (문자열로 색상 반환을 위해 임시 사용, 실제로는 Asset Color 사용 권장)
extension Color {
    init(_ name: String) {
        switch name {
        case "red": self = .red
        case "blue": self = .blue
        case "green": self = .green
        case "purple": self = .purple
        default: self = .gray
        }
    }
}

#Preview {
    SleepDetailView(log: SleepLog(sleepTime: Date(), wakeTime: Date().addingTimeInterval(28800)))
}
