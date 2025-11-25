import SwiftUI
import SwiftData

/// 저장된 모든 수면 기록을 리스트 형태로 보여주는 뷰입니다.
/// 최신순으로 정렬되며, 스와이프하여 삭제할 수 있습니다.
struct SleepListView: View {
    @Environment(SleepLogManager.self) private var manager
    // SwiftData Query: 수면 시간을 기준으로 내림차순 정렬
    @Query(sort: \SleepLog.sleepTime, order: .reverse) private var logs: [SleepLog]
    
    // 테마 색상
    let darkBackground = Color(red: 0.05, green: 0.05, blue: 0.15)
    let cardBackground = Color(red: 0.1, green: 0.1, blue: 0.2)
    let textPrimary = Color.white
    let textSecondary = Color.gray
    
    var body: some View {
        NavigationView {
            ZStack {
                darkBackground.ignoresSafeArea()
                
                if logs.isEmpty {
                    // 기록이 없을 때 표시되는 빈 화면
                    VStack {
                        Image(systemName: "moon.zzz")
                            .font(.system(size: 50))
                            .foregroundColor(textSecondary)
                            .padding()
                        Text("아직 수면 기록이 없습니다.")
                            .foregroundColor(textSecondary)
                    }
                } else {
                    // 수면 기록 리스트
                    List {
                        ForEach(logs) { log in
                            HStack {
                                VStack(alignment: .leading, spacing: 5) {
                                    // 날짜 및 시간 범위 표시 (예: 11/25 오전 1시 - 오전 9시)
                                    Text("\(log.sleepTime.formatted(.dateTime.month().day())) \(log.sleepTime.formatted(date: .omitted, time: .shortened)) - \(log.wakeTime.formatted(date: .omitted, time: .shortened))")
                                        .font(.system(size: 16, weight: .medium, design: .rounded))
                                        .foregroundColor(textPrimary)
                                    
                                    // 총 수면 시간 표시 (예: 총 8시간)
                                    Text("총 \(log.durationString)")
                                        .font(.system(size: 14, weight: .regular, design: .rounded))
                                        .foregroundColor(Color(red: 0.5, green: 0.3, blue: 0.9))
                                }
                                
                                Spacer()
                            }
                            .listRowBackground(cardBackground) // 리스트 셀 배경색
                            .listRowSeparator(.hidden) // 구분선 숨김
                            .padding(.vertical, 8)
                        }
                        // 스와이프 삭제 동작
                        .onDelete { indexSet in
                            for index in indexSet {
                                manager.deleteLog(logs[index])
                            }
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden) // 리스트 기본 배경 숨김
                }
            }
            .navigationTitle("수면 기록")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

#Preview {
    SleepListView()
        .environment(SleepLogManager())
}
