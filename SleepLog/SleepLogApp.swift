import SwiftUI
import SwiftData

/// 앱의 진입점(Entry Point)입니다.
/// SwiftData 컨테이너를 초기화하고, 앱 전반에 걸쳐 사용할 ViewModel을 주입합니다.
@main
struct SleepLogApp: App {
    // SwiftData 모델 컨테이너
    let container: ModelContainer
    // 앱 전체에서 공유할 ViewModel
    @State private var manager = SleepLogManager()

    init() {
        do {
            // SleepLog 모델을 위한 컨테이너 생성
            container = try ModelContainer(for: SleepLog.self)
        } catch {
            fatalError("Failed to create ModelContainer for SleepLog.")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                // ViewModel을 환경 객체로 주입
                .environment(manager)
                .onAppear {
                    // ViewModel에 ModelContext 설정
                    manager.setContext(container.mainContext)
                }
        }
        // SwiftData 컨테이너 주입
        .modelContainer(container)
    }
}
