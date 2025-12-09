import SwiftUI

struct SleepGoalView: View {
    @Environment(\.dismiss) var dismiss
    
    @AppStorage("sleepGoalHours") private var storedHours: Int = 8
    @AppStorage("sleepGoalMinutes") private var storedMinutes: Int = 0
    
    @State private var tempHours: Int = 8
    @State private var tempMinutes: Int = 0
    
    // 테마 색상
    let darkBackground = Color(red: 0.05, green: 0.05, blue: 0.15)
    let cardBackground = Color(red: 0.1, green: 0.1, blue: 0.2)
    let textPrimary = Color.white
    let accentPurple = Color(red: 0.5, green: 0.3, blue: 0.9)
    
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
                    Picker("시간", selection: $tempHours) {
                        ForEach(4...12, id: \.self) { hour in
                            Text("\(hour)시간").tag(hour)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(width: 100)
                    .clipped()
                    
                    Picker("분", selection: $tempMinutes) {
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
                
                HStack(spacing: 20) {
                    Button(action: {
                        dismiss()
                    }) {
                        Text("취소")
                            .font(.headline)
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(cardBackground)
                            .cornerRadius(15)
                    }
                    
                    Button(action: {
                        storedHours = tempHours
                        storedMinutes = tempMinutes
                        dismiss()
                    }) {
                        Text("저장")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(accentPurple)
                            .cornerRadius(15)
                    }
                }
                .padding(.horizontal)
                
                Spacer()
            }
        }
        .navigationTitle("수면 목표")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true) // 커스텀 버튼 사용을 위해 뒤로가기 숨김
        .onAppear {
            tempHours = storedHours
            tempMinutes = storedMinutes
        }
    }
}

#Preview {
    SleepGoalView()
}
