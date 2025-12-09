import SwiftUI

struct SleepGoalView: View {
    @AppStorage("sleepGoalHours") private var hours: Int = 8
    @AppStorage("sleepGoalMinutes") private var minutes: Int = 0
    
    // 테마 색상
    let darkBackground = Color(red: 0.05, green: 0.05, blue: 0.15)
    let cardBackground = Color(red: 0.1, green: 0.1, blue: 0.2)
    let textPrimary = Color.white
    
    var body: some View {
        ZStack {
            darkBackground.ignoresSafeArea()
            
            VStack(spacing: 30) {
                Text("수면 목표 설정")
                    .font(.title2)
                    .bold()
                    .foregroundColor(textPrimary)
                    .padding(.top)
                
                Text("매일 목표로 하는 수면 시간을 설정하세요.")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                HStack {
                    Picker("시간", selection: $hours) {
                        ForEach(4...12, id: \.self) { hour in
                            Text("\(hour)시간").tag(hour)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(width: 100)
                    .clipped()
                    
                    Picker("분", selection: $minutes) {
                        ForEach(stride(from: 0, to: 60, by: 10).map { $0 }, id: \.self) { minute in
                            Text("\(minute)분").tag(minute)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(width: 100)
                    .clipped()
                }
                .background(cardBackground)
                .cornerRadius(20)
                .padding()
                
                Spacer()
            }
        }
        .navigationTitle("수면 목표")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    SleepGoalView()
}
