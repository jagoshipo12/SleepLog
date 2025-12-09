import SwiftUI
import SwiftData

/// 탭 기반의 메인 네비게이션을 관리하는 뷰입니다.
/// 홈, 기록, 통계 탭으로 구성되어 있습니다.
struct ContentView: View {
    // 현재 선택된 탭 인덱스
    @State private var selection = 0
    
    // 테마 색상 (전역적으로 사용될 수 있음)
    let darkBackground = Color(red: 0.05, green: 0.05, blue: 0.15) // 깊은 미드나잇 블루
    let accentPurple = Color(red: 0.5, green: 0.3, blue: 0.9)
    
    init() {
        // 탭바(TabBar) 모양 및 색상 설정
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(red: 0.05, green: 0.05, blue: 0.15, alpha: 1.0)
        
        // 선택된 탭 아이템 색상
        appearance.stackedLayoutAppearance.selected.iconColor = UIColor(red: 0.5, green: 0.3, blue: 0.9, alpha: 1.0)
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor(red: 0.5, green: 0.3, blue: 0.9, alpha: 1.0)]
        
        // 선택되지 않은 탭 아이템 색상
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor.gray
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.gray]
        
        // 설정 적용
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }

    var body: some View {
        TabView(selection: $selection) {
            // 1. 홈 탭
            HomeView(tabSelection: $selection)
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("홈")
                }
                .tag(0)
            
            // 2. 기록 탭
            SleepListView()
                .tabItem {
                    Image(systemName: "list.bullet")
                    Text("기록")
                }
                .tag(1)
            
            // 3. 통계 탭
            StatisticsView()
                .tabItem {
                    Image(systemName: "chart.bar.fill")
                    Text("통계")
                }
                .tag(2)
            
            // 4. 프로필 탭
            ProfileView()
                .tabItem {
                    Image(systemName: "person.crop.circle.fill")
                    Text("프로필")
                }
                .tag(3)
        }
        .accentColor(accentPurple) // 탭바 강조 색상
        .preferredColorScheme(.dark) // 다크 모드 강제 적용
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: SleepLog.self, configurations: config)
    let manager = SleepLogManager()
    
    ContentView()
        .environment(manager)
        .modelContainer(container)
        .onAppear {
            manager.setContext(container.mainContext)
        }
}
