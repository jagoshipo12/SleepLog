import Foundation
import SwiftData

import GoogleGenerativeAI

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
    
    /// Google Gemini API를 사용하여 주간 수면 분석을 생성합니다.
    func fetchWeeklyAnalysis(logs: [SleepLog]) async throws -> String {
        guard !logs.isEmpty else { return "분석할 데이터가 충분하지 않습니다." }
        
        let model = GenerativeModel(name: "gemini-pro", apiKey: APIKey.key)
        
        // 프롬프트 구성
        var prompt = "다음은 사용자의 최근 7일간 수면 기록입니다. 이 데이터를 바탕으로 수면 패턴을 분석하고, 건강한 수면을 위한 구체적인 조언을 한국어로 해주세요.\n\n"
        
        for log in logs {
            prompt += "- 날짜: \(log.sleepTime.formatted()), 수면 시간: \(Int(log.sleepDuration/60))분, 수면 점수: \(log.sleepScore)점\n"
        }
        
        prompt += "\n분석 내용에는 다음을 포함해주세요:\n1. 평균 취침/기상 시간 및 규칙성 평가\n2. 수면 부족 여부 및 개선 제안\n3. 따뜻한 차, 가벼운 운동 등 구체적인 행동 지침\n4. 어조는 친절하고 격려하는 톤으로 해주세요."
        
        let response = try await model.generateContent(prompt)
        return response.text ?? "분석을 생성할 수 없습니다."
    }
    
    /// 주간 수면 기록을 분석하여 상세 리포트를 생성합니다.
    /// - Parameter logs: 분석할 수면 기록 배열 (보통 최근 7일)
    /// - Returns: 분석 결과 텍스트
    func generateWeeklyAnalysis(logs: [SleepLog]) -> String {
        guard !logs.isEmpty else {
            return "분석할 데이터가 충분하지 않습니다. 꾸준히 기록해보세요!"
        }
        
        var analysis = ""
        
        // 1. 수면 패턴 분석 (평균 취침/기상 시간)
        let avgBedtime = calculateAverageTime(dates: logs.map { $0.sleepTime })
        let avgWakeTime = calculateAverageTime(dates: logs.map { $0.wakeTime })
        
        analysis += "평소 \(avgBedtime) 즈음에 잠드시고, \(avgWakeTime) 즈음에 일어나시는군요.\n\n"
        
        // 2. 건강 데이터 분석 (심박수, 혈중 산소)
        // 간단한 평균 계산
        let allHeartRates = logs.flatMap { $0.heartRateSamples }.map { $0.value }
        let avgHeartRate = allHeartRates.isEmpty ? 0 : allHeartRates.reduce(0, +) / Double(allHeartRates.count)
        
        let allOxygen = logs.flatMap { $0.bloodOxygenSamples }.map { $0.value }
        let avgOxygen = allOxygen.isEmpty ? 0 : allOxygen.reduce(0, +) / Double(allOxygen.count)
        
        if avgHeartRate > 0 && avgOxygen > 0 {
            analysis += "평균 심박수는 \(Int(avgHeartRate))bpm, 혈중 산소 농도는 \(Int(avgOxygen))%로 "
            if avgHeartRate < 60 || avgHeartRate > 100 {
                analysis += "주의가 필요해 보입니다.\n"
            } else {
                analysis += "안정적인 상태입니다.\n"
            }
        }
        
        // 3. 조언 제공
        let avgScore = logs.reduce(0) { $0 + $1.sleepScore } / logs.count
        
        analysis += "\n💡 AI 코치의 조언:\n"
        if avgScore < 70 {
            analysis += "수면 시간이 부족합니다. 취침 시간을 30분만 앞당겨보세요. 잠들기 전 따뜻한 차나 가벼운 스트레칭이 도움이 될 수 있습니다."
        } else if avgScore < 85 {
            analysis += "좋은 수면 습관을 가지고 계시네요! 낮 동안 가벼운 산책을 통해 수면의 질을 더 높일 수 있습니다."
        } else {
            analysis += "완벽한 수면 관리 중이시네요! 지금처럼 규칙적인 생활을 유지하세요."
        }
        
        return analysis
    }
    
    // 평균 시간 계산 헬퍼 (StatisticsView 로직 재사용)
    private func calculateAverageTime(dates: [Date]) -> String {
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
    
}
