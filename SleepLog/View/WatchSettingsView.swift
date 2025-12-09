import SwiftUI

struct WatchSettingsView: View {
    @AppStorage("isWatchConnected") private var isConnected: Bool = true
    
    // 테마 색상
    let darkBackground = Color(red: 0.05, green: 0.05, blue: 0.15)
    let cardBackground = Color(red: 0.1, green: 0.1, blue: 0.2)
    let textPrimary = Color.white
    
    var body: some View {
        ZStack {
            darkBackground.ignoresSafeArea()
            
            VStack(spacing: 30) {
                VStack(spacing: 20) {
                    Image(systemName: "applewatch.watchface")
                        .font(.system(size: 60))
                        .foregroundColor(isConnected ? .green : .gray)
                    
                    Text(isConnected ? "Apple Watch Series 9" : "연결된 워치 없음")
                        .font(.title2)
                        .bold()
                        .foregroundColor(textPrimary)
                    
                    if isConnected {
                        Text("연결됨")
                            .font(.subheadline)
                            .foregroundColor(.green)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color.green.opacity(0.2))
                            .cornerRadius(10)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(cardBackground)
                .cornerRadius(20)
                .padding(.horizontal)
                
                Toggle("워치 연결", isOn: $isConnected)
                    .padding()
                    .background(cardBackground)
                    .cornerRadius(15)
                    .padding(.horizontal)
                    .foregroundColor(textPrimary)
                
                Spacer()
            }
            .padding(.top)
        }
        .navigationTitle("워치 설정")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    WatchSettingsView()
}
