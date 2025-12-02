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
