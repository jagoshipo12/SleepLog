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
    /// 지난 7일간의 임의의 수면 기록을 추가합니다.
    func createSampleData() {
        guard let context = modelContext else {
            print("SleepLogManager Error: Context is nil in createSampleData")
            return
        }
        
        print("SleepLogManager: Creating sample data...")
        let calendar = Calendar.current
        let today = Date()
        
        for i in 1...7 {
            // i일 전의 날짜 계산
            guard let date = calendar.date(byAdding: .day, value: -i, to: today) else { continue }
            
            // 취침 시간: 전날 밤 10시 ~ 12시 사이
            // 기상 시간: 다음날 아침 6시 ~ 9시 사이
            let startHour = Int.random(in: 22...23)
            let startMinute = Int.random(in: 0...59)
            let sleepDuration = Double.random(in: 6...9) * 3600 // 6~9시간
            
            guard let sleepTime = calendar.date(bySettingHour: startHour, minute: startMinute, second: 0, of: date) else { continue }
            let wakeTime = sleepTime.addingTimeInterval(sleepDuration)
            
            let log = SleepLog(sleepTime: sleepTime, wakeTime: wakeTime)
            context.insert(log)
            print("SleepLogManager: Inserted log for \(date)")
        }
        
        do {
            try context.save()
            print("SleepLogManager: Sample data saved successfully")
        } catch {
            print("SleepLogManager Error: Failed to save sample data - \(error)")
        }
    }
}
