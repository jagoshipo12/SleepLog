import Foundation
import SwiftData
import SwiftUI

/// 앱의 비즈니스 로직과 데이터 처리를 담당하는 ViewModel 클래스입니다.
/// SwiftData의 ModelContext를 관리하고 수면 기록의 추가/삭제 기능을 제공합니다.
@Observable
@MainActor
class SleepLogManager {
    /// SwiftData의 데이터베이스 컨텍스트 (저장, 삭제 등을 수행)
    var modelContext: ModelContext? = nil
    
    init() {}
    
    /// View에서 전달받은 ModelContext를 설정합니다.
    /// - Parameter context: 앱의 메인 ModelContext
    func setContext(_ context: ModelContext) {
        self.modelContext = context
        print("SleepLogManager: Context set")
    }
    
    /// 새로운 수면 기록을 추가합니다.
    /// - Parameters:
    ///   - sleepTime: 취침 시간
    ///   - wakeTime: 기상 시간
    func addLog(sleepTime: Date, wakeTime: Date) {
        guard let context = modelContext else {
            print("SleepLogManager Error: Context is nil")
            return
        }
        // 새로운 SleepLog 객체 생성
        let newLog = SleepLog(sleepTime: sleepTime, wakeTime: wakeTime)
        // 컨텍스트에 삽입 (자동으로 저장됨)
        context.insert(newLog)
        try? context.save()
        print("SleepLogManager: Log added")
    }
    
    /// 기존 수면 기록을 삭제합니다.
    /// - Parameter log: 삭제할 SleepLog 객체
    func deleteLog(_ log: SleepLog) {
        guard let context = modelContext else { return }
        context.delete(log)
        try? context.save()
    }
    
    /// 수면 기록들의 평균 수면 시간을 계산합니다.
    /// - Parameter logs: 평균을 계산할 수면 기록 배열
    /// - Returns: "N시간 N분" 형식의 문자열
    func calculateAverageSleep(logs: [SleepLog]) -> String {
        guard !logs.isEmpty else { return "0시간 0분" }
        
        // 모든 기록의 수면 시간 합계 계산
        let totalDuration = logs.reduce(0) { $0 + $1.sleepDuration }
        // 평균 계산
        let average = totalDuration / Double(logs.count)
        
        let hours = Int(average) / 3600
        let minutes = (Int(average) % 3600) / 60
        
        if hours == 0 && minutes == 0 {
            let seconds = Int(average) % 60
            return "\(seconds)초"
        }
        
        return "\(hours)시간 \(minutes)분"
    }
    
    /// 최근 수면 점수 변화량을 계산합니다.
    /// - Parameter logs: 최신순으로 정렬된 수면 기록 배열
    /// - Returns: 변화량 문자열 (예: "^15", "v5", "-")
    func calculateScoreChange(logs: [SleepLog]) -> String {
        guard logs.count >= 2 else { return "-" }
        
        let todayScore = logs[0].sleepScore
        let yesterdayScore = logs[1].sleepScore
        let diff = todayScore - yesterdayScore
        
        if diff > 0 {
            return "^\(diff)"
        } else if diff < 0 {
            return "v\(abs(diff))"
        } else {
            return "-"
        }
    }
    
    // MARK: - Automatic Sleep Tracking
    
    /// 현재 수면 중인지 여부
    var isSleeping: Bool = false
    
    /// 수면 시작 시간
    var sleepStartTime: Date? = nil
    
    /// 수면을 시작합니다.
    func startSleep() {
        isSleeping = true
        sleepStartTime = Date()
    }
    
    /// 현재 수면 시간을 계산하여 반환합니다. (수면 상태를 변경하지 않음)
    func getCurrentSleepData() -> (start: Date, end: Date)? {
        guard let startTime = sleepStartTime else { return nil }
        return (startTime, Date())
    }
    
    /// 수면을 완전히 종료합니다.
    /// - Parameters:
    ///   - save: 저장 여부. true이면 저장, false이면 기록하지 않고 종료.
    ///   - endTime: 수면 종료 시간. nil이면 현재 시간 사용.
    func stopSleep(save: Bool, endTime: Date? = nil) {
        guard let startTime = sleepStartTime else { return }
        
        if save {
            let end = endTime ?? Date()
            addLog(sleepTime: startTime, wakeTime: end)
        }
        
        isSleeping = false
        sleepStartTime = nil
    }
    
    /// 테스트를 위한 샘플 데이터를 생성합니다.
    /// 8월부터 11월까지의 임의의 수면 기록을 추가합니다.
    func createSampleData() {
        guard let context = modelContext else {
            print("SleepLogManager Error: Context is nil in createSampleData")
            return
        }
        
        print("SleepLogManager: Creating sample data...")
        let calendar = Calendar.current
        let today = Date()
        
        // 8월 1일부터 11월 30일까지 데이터 생성
        // 현재 날짜 기준이 아니라 고정된 기간으로 설정
        let year = calendar.component(.year, from: today)
        
        for month in 8...11 {
            let range = calendar.range(of: .day, in: .month, for: calendar.date(from: DateComponents(year: year, month: month))!)!
            
            for day in range {
                // 30% 확률로 기록 누락 (자연스럽게 보이도록)
                if Int.random(in: 1...100) <= 30 { continue }
                
                let dateComponents = DateComponents(year: year, month: month, day: day)
                guard let date = calendar.date(from: dateComponents) else { continue }
                
                // 미래 날짜는 제외
                if date > today { continue }
                
                // 취침 시간: 밤 10시 ~ 새벽 2시 사이
                let startHour = [22, 23, 0, 1, 2].randomElement()!
                let startMinute = Int.random(in: 0...59)
                
                // 수면 시간: 4시간 ~ 10시간
                let sleepDuration = Double.random(in: 4...10) * 3600
                
                var sleepTime = calendar.date(bySettingHour: startHour, minute: startMinute, second: 0, of: date)!
                
                // 새벽 0~2시에 잠든 경우, 날짜를 다음날로 넘기지 않도록 주의 (데이터 날짜 기준)
                // 하지만 여기서는 '해당 날짜의 밤'에 잠든 것으로 처리하기 위해,
                // 0~2시인 경우 날짜를 하루 더해줌 (다음날 새벽)
                if startHour < 12 {
                    sleepTime = calendar.date(byAdding: .day, value: 1, to: sleepTime)!
                }
                
                let wakeTime = sleepTime.addingTimeInterval(sleepDuration)
                
                let log = SleepLog(sleepTime: sleepTime, wakeTime: wakeTime)
                context.insert(log)
            }
        }
        
        do {
            try context.save()
            print("SleepLogManager: Sample data saved successfully")
        } catch {
            print("SleepLogManager Error: Failed to save sample data - \(error)")
        }
    }
    // MARK: - Local Sleep Coach Integration
    
    private let sleepCoachService = SleepCoachService()
    
    /// AI 코치가 생성한 수면 피드백
    var sleepFeedback: String = "수면 데이터를 분석하고 있어요..."
    
    /// 수면 피드백을 요청합니다.
    func fetchSleepFeedback(logs: [SleepLog]) {
        // 로컬 연산이지만, 사용자가 '분석 중'이라는 느낌을 받을 수 있도록 약간의 지연을 줍니다.
        sleepFeedback = "수면 데이터를 분석하고 있어요..."
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self = self else { return }
            self.sleepFeedback = self.sleepCoachService.generateFeedback(logs: logs)
        }
    }
}
