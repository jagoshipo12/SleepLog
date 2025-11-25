import SwiftUI
import SwiftData

/// 앱의 메인 대시보드 화면입니다.
/// 오늘의 수면 요약 정보를 보여주고, 새로운 수면 기록을 시작할 수 있는 버튼을 제공합니다.
struct HomeView: View {
    // ViewModel 환경 객체 접근
    @Environment(SleepLogManager.self) private var manager
    // SwiftData에서 수면 기록을 최신순으로 가져옴
    @Query(sort: \SleepLog.sleepTime, order: .reverse) private var logs: [SleepLog]
    
    // 탭 전환을 위한 바인딩
    @Binding var tabSelection: Int
    
    // 수면 종료 시 저장/삭제 확인을 위한 Alert 상태
    @State private var showStopAlert = false
    @State private var tempSleepData: (start: Date, end: Date)? = nil
    
    // 수면 입력 모달 표시 여부 상태
    @State private var showInputSheet = false
    
    // 테마 색상 정의 (추후 Theme.swift로 분리 가능)
    let darkBackground = Color(red: 0.05, green: 0.05, blue: 0.15)
    let cardBackground = Color(red: 0.1, green: 0.1, blue: 0.2)
    let accentPurple = Color(red: 0.5, green: 0.3, blue: 0.9)
    let accentRed = Color(red: 0.9, green: 0.3, blue: 0.3) // 수면 끄기 버튼용 색상
    let textPrimary = Color.white
    let textSecondary = Color.gray
    
    var body: some View {
        ZStack {
            // 배경색 설정 (Safe Area 무시하고 전체 화면 채움)
            darkBackground.ignoresSafeArea()
            
            VStack(spacing: 30) {
                // 상단 헤더 영역
                HStack {
                    VStack(alignment: .leading) {
                        Text("좋은 아침입니다")
                            .font(.system(size: 18, weight: .medium, design: .rounded))
                            .foregroundColor(textSecondary)
                        Text("SleepLog")
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                            .foregroundColor(textPrimary)
                    }
                    Spacer()
                    
                    // 수동 기록 추가 버튼
                    Button(action: {
                        showInputSheet = true
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 30))
                            .foregroundColor(accentPurple)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 20)
                
                // 오늘의 수면 요약 카드
                VStack(spacing: 15) {
                    Text(manager.isSleeping ? "수면 중..." : "오늘의 수면")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(textSecondary)
                    
                    if manager.isSleeping {
                        // 수면 중일 때 표시
                        Text("Zzz...")
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundColor(accentPurple)
                    } else if let lastLog = logs.first, Calendar.current.isDateInToday(lastLog.wakeTime) {
                        // 오늘 기록이 있을 때
                        Text(lastLog.durationString)
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundColor(textPrimary)
                    } else {
                        // 오늘 기록이 없을 때
                        Text("-- 시간 -- 분")
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundColor(textPrimary.opacity(0.5))
                    }
                    
                    // 전체 평균 수면 시간 표시
                    Text("평균 수면 시간: \(manager.calculateAverageSleep(logs: logs))")
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .foregroundColor(accentPurple)
                }
                .frame(maxWidth: .infinity)
                .padding(30)
                .background(cardBackground)
                .cornerRadius(25)
                .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
                .padding(.horizontal)
                
                Spacer()
                
                // 수면 시작/종료 버튼
                Button(action: {
                    if manager.isSleeping {
                        // 수면 끄기 버튼 클릭 시 -> Alert 표시 (상태 변경 안 함)
                        if let data = manager.getCurrentSleepData() {
                            tempSleepData = data
                            showStopAlert = true
                        }
                    } else {
                        // 수면 시작 버튼 클릭 시
                        manager.startSleep()
                    }
                }) {
                    HStack {
                        Image(systemName: manager.isSleeping ? "stop.fill" : "moon.fill")
                        Text(manager.isSleeping ? "수면 끄기" : "수면 시작하기")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .background(
                        // 상태에 따른 버튼 색상 변경
                        manager.isSleeping
                        ? LinearGradient(gradient: Gradient(colors: [accentRed, Color.orange]), startPoint: .leading, endPoint: .trailing)
                        : LinearGradient(gradient: Gradient(colors: [accentPurple, Color.blue]), startPoint: .leading, endPoint: .trailing)
                    )
                    .cornerRadius(20)
                    .shadow(color: (manager.isSleeping ? accentRed : accentPurple).opacity(0.5), radius: 10, x: 0, y: 5)
                }
                .padding(.horizontal)
                .padding(.bottom, 30)
                
                // 임시: 샘플 데이터 추가 버튼 (테스트용)
                Button(action: {
                    manager.createSampleData()
                }) {
                    Text("샘플 데이터 추가 (테스트용)")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding(.bottom, 10)
            }
        }
        // 수면 종료 시 저장/삭제 확인 Alert
        .alert("수면 기록 저장", isPresented: $showStopAlert) {
            Button("저장", role: .none) {
                // 저장하고 종료 (Alert에 표시된 시간 그대로 저장)
                if let data = tempSleepData {
                    manager.stopSleep(save: true, endTime: data.end)
                } else {
                    manager.stopSleep(save: true)
                }
                // 기록 탭으로 이동
                tabSelection = 1
            }
            Button("삭제", role: .destructive) {
                // 저장하지 않고 종료
                manager.stopSleep(save: false)
            }
            Button("취소", role: .cancel) {
                // 아무 작업도 하지 않음 (수면 계속)
            }
        } message: {
            if let data = tempSleepData {
                let duration = data.end.timeIntervalSince(data.start)
                let hours = Int(duration) / 3600
                let minutes = (Int(duration) % 3600) / 60
                let seconds = Int(duration) % 60
                
                if hours == 0 && minutes == 0 {
                    Text("총 수면 시간: \(seconds)초\n(테스트를 위해 짧은 기록도 저장됩니다)\n이 기록을 저장하시겠습니까?")
                } else {
                    Text("총 수면 시간: \(hours)시간 \(minutes)분\n이 기록을 저장하시겠습니까?")
                }
            } else {
                Text("수면 기록을 저장하시겠습니까?")
            }
        }
        // 수면 입력 모달 연결
        .sheet(isPresented: $showInputSheet) {
            SleepInputView()
        }
    }
}

#Preview {
    HomeView(tabSelection: .constant(0))
        .environment(SleepLogManager())
}
