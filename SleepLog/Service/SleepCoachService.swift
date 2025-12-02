import Foundation

/// 로컬 규칙 기반으로 수면 피드백을 생성하는 서비스 클래스입니다.
/// 외부 API 없이 작동하며, 수면 점수와 변화량에 따라 맞춤형 메시지를 제공합니다.
class SleepCoachService {
    
    /// 수면 기록을 분석하여 피드백을 생성합니다.
    /// - Parameter logs: 최근 수면 기록 배열
    /// - Returns: AI 코치의 격려 메시지
    func generateFeedback(logs: [SleepLog]) -> String {
        guard let todayLog = logs.first else {
            return "수면 기록이 충분하지 않습니다. 오늘 밤부터 기록을 시작해보세요! 🌙"
        }
        
        var feedback = ""
        
        // 1. 점수 기반 기본 멘트
        switch todayLog.sleepScore {
        case 85...100:
            feedback = "완벽한 수면이에요! 오늘 하루도 활기차게 시작해보세요. 🌟"
        case 75..<85:
            feedback = "좋은 수면 패턴입니다. 이대로만 유지하면 건강해질 거예요! 💪"
        case 60..<75:
            feedback = "나쁘지 않아요. 조금만 더 일찍 잠자리에 들어보는 건 어떨까요? 🌙"
        default:
            feedback = "수면이 부족해 보여요. 오늘은 푹 쉬는 게 좋겠어요. 😴"
        }
        
        // 2. 변화량 기반 추가 멘트 (기록이 2개 이상일 때)
        if logs.count >= 2 {
            let yesterdayLog = logs[1]
            let diff = todayLog.sleepScore - yesterdayLog.sleepScore
            
            if diff >= 10 {
                feedback += "\n어제보다 훨씬 더 잘 주무셨네요! 아주 훌륭해요. 👏"
            } else if diff <= -10 {
                feedback += "\n어제보다는 조금 부족했네요. 오늘 밤은 더 편안하게 주무시길 바랄게요."
            }
        }
        
        return feedback
    }
}
