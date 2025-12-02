import Foundation
import SwiftData

/// 수면 기록을 저장하는 SwiftData 모델 클래스입니다.
/// 취침 시간, 기상 시간, 그리고 계산된 수면 시간을 저장합니다.
@Model
final class SleepLog {
    /// 각 수면 기록의 고유 식별자
    var id: UUID
    /// 취침 시간
    var sleepTime: Date
    /// 기상 시간
    var wakeTime: Date
    /// 총 수면 시간 (초 단위)
    var sleepDuration: TimeInterval
    
    // 수면 단계 데이터
    var sleepStages: [SleepStageItem] = []
    
    // 건강 데이터 샘플 구조체
    struct HealthSample: Identifiable, Codable {
        var id = UUID()
        var date: Date
        var value: Double
    }
    
    // 건강 지표 데이터
    var bloodOxygenSamples: [HealthSample] = []
    var heartRateSamples: [HealthSample] = []
    var respiratoryRate: Double = 0.0
    
    /// 초기화 메서드
    /// - Parameters:
    ///   - sleepTime: 잠자리에 든 시간
    ///   - wakeTime: 일어난 시간
    init(sleepTime: Date, wakeTime: Date) {
        self.id = UUID()
        self.sleepTime = sleepTime
        self.wakeTime = wakeTime
        // 기상 시간에서 취침 시간을 뺀 차이를 계산하여 저장
        self.sleepDuration = wakeTime.timeIntervalSince(sleepTime)
        self.sleepStages = Self.generateRandomSleepStages(start: sleepTime, end: wakeTime)
        
        // 건강 데이터 생성
        let healthData = Self.generateRandomHealthData(start: sleepTime, end: wakeTime)
        self.bloodOxygenSamples = healthData.oxygen
        self.heartRateSamples = healthData.heartRate
        self.respiratoryRate = healthData.respiratory
    }
    
    // 수면 단계 열거형
    enum SleepStage: String, Codable, CaseIterable {
        case awake = "수면 중 깰"
        case rem = "렘 수면"
        case light = "얕은 수면"
        case deep = "깊은 수면"
        
        var color: String {
            switch self {
            case .awake: return "red"
            case .rem: return "blue"
            case .light: return "green"
            case .deep: return "purple"
            }
        }
    }
    
    // 수면 단계 아이템 구조체
    struct SleepStageItem: Identifiable, Codable {
        var id = UUID()
        var stage: SleepStage
        var startTime: Date
        var endTime: Date
        var duration: TimeInterval {
            endTime.timeIntervalSince(startTime)
        }
    }
    
    // 랜덤 수면 단계 생성 로직
    static func generateRandomSleepStages(start: Date, end: Date) -> [SleepStageItem] {
        var stages: [SleepStageItem] = []
        var currentTime = start
        
        while currentTime < end {
            // 15분 ~ 90분 사이 랜덤 지속 시간
            let duration = Double.random(in: 900...5400)
            let nextTime = min(currentTime.addingTimeInterval(duration), end)
            
            // 랜덤 단계 선택 (가중치 적용 가능)
            let stage = SleepStage.allCases.randomElement() ?? .light
            
            stages.append(SleepStageItem(stage: stage, startTime: currentTime, endTime: nextTime))
            currentTime = nextTime
        }
        
        return stages
    }
    
    // 랜덤 건강 데이터 생성 로직
    static func generateRandomHealthData(start: Date, end: Date) -> (oxygen: [HealthSample], heartRate: [HealthSample], respiratory: Double) {
        var oxygenSamples: [HealthSample] = []
        var heartRateSamples: [HealthSample] = []
        var currentTime = start
        
        // 30분 간격으로 샘플 생성
        while currentTime <= end {
            // 혈중 산소: 90% ~ 100%
            let oxygenValue = Double.random(in: 90...100)
            oxygenSamples.append(HealthSample(date: currentTime, value: oxygenValue))
            
            // 심박수: 50 ~ 80 BPM
            let heartRateValue = Double.random(in: 50...80)
            heartRateSamples.append(HealthSample(date: currentTime, value: heartRateValue))
            
            currentTime = currentTime.addingTimeInterval(1800) // 30분
        }
        
        // 호흡수: 12 ~ 18 회/분 (평균값)
        let respiratoryRate = Double.random(in: 12...18)
        
        return (oxygenSamples, heartRateSamples, respiratoryRate)
    }
    
    /// 수면 시간을 "N시간 N분" 형식의 문자열로 반환하는 계산 속성입니다.
    /// UI에 직접 표시하기 위해 사용됩니다.
    var durationString: String {
        let hours = Int(sleepDuration) / 3600
        let minutes = (Int(sleepDuration) % 3600) / 60
        
        if hours == 0 && minutes == 0 {
            let seconds = Int(sleepDuration) % 60
            return "\(seconds)초"
        }
        
        return "\(hours)시간 \(minutes)분"
    }
    /// 수면 점수 (0~100점)
    /// 8시간 수면을 100점으로 기준으로 하고, 차이에 따라 감점합니다.
    var sleepScore: Int {
        let targetDuration: TimeInterval = 8 * 3600 // 8시간
        let difference = abs(sleepDuration - targetDuration)
        let hoursDifference = difference / 3600.0
        
        // 1시간 차이당 10점 감점
        let score = 100 - Int(hoursDifference * 10)
        return max(0, min(100, score))
    }
    
    /// 수면 점수에 따른 이모티콘
    var scoreEmoji: String {
        switch sleepScore {
        case 85...100: return "😃"
        case 75..<85: return "🙂"
        case 60..<75: return "😐"
        default: return "😟"
        }
    }
    
    /// 수면 점수에 따른 상태 설명
    var scoreDescription: String {
        switch sleepScore {
        case 85...100: return "매우 좋음"
        case 75..<85: return "좋음"
        case 60..<75: return "보통"
        default: return "관심 필요"
        }
    }
}
