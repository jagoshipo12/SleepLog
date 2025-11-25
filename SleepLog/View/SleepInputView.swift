import SwiftUI

/// 수면 기록을 입력하거나 수정하는 모달 뷰입니다.
/// DatePicker를 사용하여 취침 시간과 기상 시간을 선택할 수 있습니다.
struct SleepInputView: View {
    // 뷰를 닫기 위한 환경 변수
    @Environment(\.dismiss) private var dismiss
    // 데이터 저장을 위한 ViewModel
    @Environment(SleepLogManager.self) private var manager
    
    // 입력 상태 변수
    @State private var sleepTime = Date()
    @State private var wakeTime = Date()
    
    // 테마 색상
    let darkBackground = Color(red: 0.05, green: 0.05, blue: 0.15)
    let cardBackground = Color(red: 0.1, green: 0.1, blue: 0.2)
    let accentPurple = Color(red: 0.5, green: 0.3, blue: 0.9)
    let textPrimary = Color.white
    
    var body: some View {
        NavigationView {
            ZStack {
                darkBackground.ignoresSafeArea()
                
                VStack(spacing: 25) {
                    // 안내 문구
                    Text("수면 시간을 기록해주세요")
                        .font(.system(size: 18, weight: .medium, design: .rounded))
                        .foregroundColor(textPrimary.opacity(0.8))
                        .padding(.top, 20)
                    
                    // 시간 선택 영역 (카드 형태)
                    VStack(spacing: 0) {
                        // 취침 시간 선택기
                        HStack {
                            Image(systemName: "moon.stars.fill")
                                .foregroundColor(accentPurple)
                            Text("취침 시간")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundColor(textPrimary)
                            Spacer()
                            DatePicker("", selection: $sleepTime, displayedComponents: [.date, .hourAndMinute])
                                .labelsHidden()
                                .colorScheme(.dark)
                        }
                        .padding()
                        
                        Divider().background(Color.gray.opacity(0.3))
                        
                        // 기상 시간 선택기
                        HStack {
                            Image(systemName: "sun.max.fill")
                                .foregroundColor(Color.orange)
                            Text("기상 시간")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundColor(textPrimary)
                            Spacer()
                            DatePicker("", selection: $wakeTime, displayedComponents: [.date, .hourAndMinute])
                                .labelsHidden()
                                .colorScheme(.dark)
                        }
                        .padding()
                    }
                    .background(cardBackground)
                    .cornerRadius(20)
                    .padding(.horizontal)
                    
                    // 예상 수면 시간 표시
                    let duration = wakeTime.timeIntervalSince(sleepTime)
                    if duration > 0 {
                        let hours = Int(duration) / 3600
                        let minutes = (Int(duration) % 3600) / 60
                        Text("총 수면 시간: \(hours)시간 \(minutes)분")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(accentPurple)
                    } else {
                        Text("기상 시간이 취침 시간보다 빨라야 합니다")
                            .font(.system(size: 14, weight: .regular, design: .rounded))
                            .foregroundColor(Color.red.opacity(0.8))
                    }
                    
                    Spacer()
                    
                    // 저장 버튼
                    Button(action: {
                        manager.addLog(sleepTime: sleepTime, wakeTime: wakeTime)
                        dismiss()
                    }) {
                        Text("저장하기")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(accentPurple)
                            .cornerRadius(20)
                            .shadow(color: accentPurple.opacity(0.4), radius: 10, x: 0, y: 5)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle("수면 기록")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") {
                        dismiss()
                    }
                    .foregroundColor(textPrimary)
                }
            }
        }
    }
}

#Preview {
    SleepInputView()
        .environment(SleepLogManager())
}
