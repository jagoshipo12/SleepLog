import SwiftUI
import SwiftData

struct ProfileView: View {
    @Query private var logs: [SleepLog]
    
    // 테마 색상
    let darkBackground = Color(red: 0.05, green: 0.05, blue: 0.15)
    let cardBackground = Color(red: 0.1, green: 0.1, blue: 0.2)
    let textPrimary = Color.white
    let textSecondary = Color.gray
    
    var body: some View {
        NavigationView {
            ZStack {
                darkBackground.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 30) {
                        // 1. 프로필 섹션
                        VStack(alignment: .leading, spacing: 20) {
                            Text("내 프로필")
                                .font(.title2)
                                .bold()
                                .foregroundColor(textPrimary)
                            
                            VStack(spacing: 15) {
                                // 사용자 정보 (예시)
                                HStack {
                                    Circle()
                                        .fill(Color.gray.opacity(0.3))
                                        .frame(width: 60, height: 60)
                                        .overlay(
                                            Image(systemName: "person.fill")
                                                .font(.system(size: 30))
                                                .foregroundColor(.white)
                                        )
                                    
                                    VStack(alignment: .leading, spacing: 5) {
                                        Text("사용자")
                                            .font(.headline)
                                            .foregroundColor(textPrimary)
                                        Text("SleepLog와 함께 건강한 수면을 만드세요")
                                            .font(.caption)
                                            .foregroundColor(textSecondary)
                                    }
                                    Spacer()
                                }
                                .padding(.bottom, 10)
                                
                                Divider().background(Color.gray.opacity(0.3))
                                
                                // 통계 그리드
                                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 15) {
                                    ProfileStatItem(title: "평균 취침 시간", value: calculateAverageBedtime(), icon: "moon.stars.fill", color: .purple)
                                    ProfileStatItem(title: "평균 수면 질", value: calculateAverageQuality(), icon: "star.fill", color: .yellow)
                                    ProfileStatItem(title: "평균 수면 시간", value: calculateAverageDuration(), icon: "clock.fill", color: .blue)
                                }
                                
                                Divider().background(Color.gray.opacity(0.3))
                                
                                // 워치 연동 상태
                                HStack {
                                    Image(systemName: "applewatch")
                                        .foregroundColor(textPrimary)
                                    Text("스마트 워치 연동")
                                        .foregroundColor(textPrimary)
                                    Spacer()
                                    Text("연결됨")
                                        .font(.subheadline)
                                        .foregroundColor(.green)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 5)
                                        .background(Color.green.opacity(0.2))
                                        .cornerRadius(10)
                                }
                            }
                            .padding()
                            .background(cardBackground)
                            .cornerRadius(20)
                        }
                        .padding(.horizontal)
                        
                        // 2. 설정 섹션
                        VStack(alignment: .leading, spacing: 20) {
                            Text("설정")
                                .font(.title2)
                                .bold()
                                .foregroundColor(textPrimary)
                            
                            VStack(spacing: 0) {
                                NavigationLink(destination: SleepGoalView()) {
                                    SettingRow(icon: "target", title: "수면 목표", value: "\(UserDefaults.standard.integer(forKey: "sleepGoalHours"))시간")
                                }
                                
                                Divider().background(Color.gray.opacity(0.3))
                                
                                NavigationLink(destination: WatchSettingsView()) {
                                    SettingRow(icon: "watchface.applewatch.case", title: "워치", value: UserDefaults.standard.bool(forKey: "isWatchConnected") ? "연결됨" : "연결 안 됨")
                                }
                                
                                Divider().background(Color.gray.opacity(0.3))
                                
                                NavigationLink(destination: WeeklySummaryView()) {
                                    SettingRow(icon: "chart.bar.doc.horizontal", title: "주간 요약", value: "보기")
                                }
                            }
                            .background(cardBackground)
                            .cornerRadius(20)
                        }
                        .padding(.horizontal)
                        
                        // 앱 버전 등 기타 정보
                        Text("SleepLog v1.0.0")
                            .font(.caption)
                            .foregroundColor(textSecondary)
                            .padding(.top)
                    }
                    .padding(.top)
                    .padding(.bottom, 50)
                }
            }
            .navigationTitle("프로필")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    // MARK: - Logic
    
    func calculateAverageBedtime() -> String {
        let dates = logs.map { $0.sleepTime }
        guard !dates.isEmpty else { return "-" }
        
        var xTotal: Double = 0
        var yTotal: Double = 0
        
        for date in dates {
            let calendar = Calendar.current
            let hour = calendar.component(.hour, from: date)
            let minute = calendar.component(.minute, from: date)
            let totalMinutes = Double(hour * 60 + minute)
            
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
        
        let isPM = avgHour >= 12
        let displayHour = avgHour > 12 ? avgHour - 12 : (avgHour == 0 ? 12 : avgHour)
        let ampm = isPM ? "오후" : "오전"
        
        return String(format: "%@ %d시 %02d분", ampm, displayHour, avgMinute)
    }
    
    func calculateAverageQuality() -> String {
        guard !logs.isEmpty else { return "-" }
        let totalScore = logs.reduce(0) { $0 + $1.sleepScore }
        let avgScore = totalScore / logs.count
        
        // 점수에 따른 텍스트 평가
        switch avgScore {
        case 85...100: return "매우 좋음 (\(avgScore)점)"
        case 75..<85: return "좋음 (\(avgScore)점)"
        case 60..<75: return "보통 (\(avgScore)점)"
        default: return "나쁨 (\(avgScore)점)"
        }
    }
    
    func calculateAverageDuration() -> String {
        guard !logs.isEmpty else { return "-" }
        let totalDuration = logs.reduce(0) { $0 + $1.sleepDuration }
        let avgDuration = totalDuration / Double(logs.count)
        
        let hours = Int(avgDuration) / 3600
        let minutes = (Int(avgDuration) % 3600) / 60
        
        return "\(hours)시간 \(minutes)분"
    }
}

struct ProfileStatItem: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Spacer()
            }
            
            Text(value)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.white.opacity(0.05))
        .cornerRadius(15)
    }
}

struct SettingRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .frame(width: 25)
                .foregroundColor(.gray)
            Text(title)
                .foregroundColor(.white)
            Spacer()
            Text(value)
                .foregroundColor(.gray)
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding()
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: SleepLog.self, configurations: config)
    
    ProfileView()
        .modelContainer(container)
}
