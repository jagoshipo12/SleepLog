import SwiftUI
import SwiftData

/// 저장된 모든 수면 기록을 리스트 형태로 보여주는 뷰입니다.
/// 최신순으로 정렬되며, 스와이프하여 삭제할 수 있습니다.
import Charts

/// 저장된 모든 수면 기록을 리스트 형태로 보여주는 뷰입니다.
/// 최신순으로 정렬되며, 스와이프하여 삭제할 수 있습니다.
import Charts

/// 저장된 모든 수면 기록을 리스트 형태로 보여주는 뷰입니다.
/// 최신순으로 정렬되며, 스와이프하여 삭제할 수 있습니다.
struct SleepListView: View {
    @Environment(SleepLogManager.self) private var manager
    // SwiftData Query: 수면 시간을 기준으로 내림차순 정렬 (최신순)
    @Query(sort: \SleepLog.sleepTime, order: .reverse) private var logs: [SleepLog]
    
    // 뷰 모드 상태
    enum ViewMode: String, CaseIterable, Identifiable {
        case list = "리스트"
        case graph = "그래프"
        var id: String { self.rawValue }
    }
    @State private var viewMode: ViewMode = .list
    
    // 리스트 선택 상태 (다중 삭제용)
    @State private var selectedLogIds = Set<UUID>()
    
    // 그래프 상태
    @State private var selectedLog: SleepLog?
    @State private var navigateToDetail = false
    @State private var scrollPosition: Date = Date()
    
    // 테마 색상
    let darkBackground = Color(red: 0.05, green: 0.05, blue: 0.15)
    let cardBackground = Color(red: 0.1, green: 0.1, blue: 0.2)
    let textPrimary = Color.white
    let textSecondary = Color.gray
    
    var body: some View {
        NavigationView {
            ZStack {
                darkBackground.ignoresSafeArea()
                
                // 네비게이션 링크 (그래프에서 선택 시 이동용)
                NavigationLink(isActive: $navigateToDetail) {
                    if let log = selectedLog {
                        SleepDetailView(log: log)
                    }
                } label: {
                    EmptyView()
                }
                
                if logs.isEmpty {
                    emptyView
                } else {
                    VStack {
                        if viewMode == .list {
                            listView
                        } else {
                            graphView
                        }
                    }
                }
            }
            .navigationTitle("수면 기록")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Picker("View Mode", selection: $viewMode) {
                        ForEach(ViewMode.allCases) { mode in
                            Image(systemName: mode == .list ? "list.bullet" : "chart.bar.fill")
                                .tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 100)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if viewMode == .list {
                        HStack {
                            // 선택된 항목이 있을 때만 삭제 버튼 표시
                            if !selectedLogIds.isEmpty {
                                Button(action: deleteSelectedLogs) {
                                    Image(systemName: "trash")
                                        .foregroundColor(.red)
                                }
                            }
                            EditButton()
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Subviews
    
    var emptyView: some View {
        VStack {
            Image(systemName: "moon.zzz")
                .font(.system(size: 50))
                .foregroundColor(textSecondary)
                .padding()
            Text("아직 수면 기록이 없습니다.")
                .foregroundColor(textSecondary)
        }
    }
    
    var listView: some View {
        List(selection: $selectedLogIds) {
            ForEach(logs) { log in
                NavigationLink(destination: SleepDetailView(log: log)) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(log.sleepTime.formatted(date: .numeric, time: .omitted))
                                .font(.caption)
                                .foregroundColor(textSecondary)
                            
                            HStack {
                                Text(log.sleepTime.formatted(date: .omitted, time: .shortened))
                                Text("~")
                                Text(log.wakeTime.formatted(date: .omitted, time: .shortened))
                            }
                            .font(.headline)
                            .foregroundColor(textPrimary)
                        }
                        
                        Spacer()
                        
                        Text(log.scoreEmoji)
                            .font(.title2)
                        
                        Text(log.durationString)
                            .font(.subheadline)
                            .bold()
                            .foregroundColor(.yellow)
                    }
                    .padding(.vertical, 5)
                }
                .listRowBackground(cardBackground)
            }
            .onDelete(perform: deleteLogs)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }
    
    var graphView: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("최근 수면 패턴")
                .font(.headline)
                .foregroundColor(textPrimary)
                .padding(.horizontal)
                .padding(.top)
            
            // 시간순 정렬 (과거 -> 최신)
            let sortedLogs = logs.sorted(by: { $0.sleepTime < $1.sleepTime })
            
            // 차트 너비 계산 (날짜 범위 기반)
            let minDate = sortedLogs.first?.sleepTime ?? Date()
            let maxDate = sortedLogs.last?.sleepTime ?? Date()
            let days = Calendar.current.dateComponents([.day], from: minDate, to: maxDate).day ?? 1
            // 화면 너비의 1/6.5 정도를 하루 너비로 설정 (자이가르닉 효과)
            let dayWidth: CGFloat = UIScreen.main.bounds.width / 6.5
            let totalWidth = max(UIScreen.main.bounds.width, CGFloat(days + 2) * dayWidth)
            
            ScrollView(.horizontal, showsIndicators: false) {
                Chart {
                    ForEach(sortedLogs) { log in
                        BarMark(
                            x: .value("Date", log.sleepTime, unit: .day),
                            y: .value("Duration", log.sleepDuration / 3600) // 시간 단위
                        )
                        .foregroundStyle(Color.blue.gradient)
                        .cornerRadius(5)
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisValueLabel {
                            if let doubleValue = value.as(Double.self) {
                                Text("\(Int(doubleValue))h")
                                    .foregroundColor(textSecondary)
                            }
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day)) { value in
                        AxisValueLabel(format: .dateTime.month().day())
                            .foregroundStyle(textSecondary)
                    }
                }
                .chartOverlay { proxy in
                    GeometryReader { geometry in
                        Rectangle().fill(.clear).contentShape(Rectangle())
                            .onTapGesture { location in
                                let origin = geometry[proxy.plotAreaFrame].origin
                                let xPosition = location.x - origin.x
                                
                                if let date: Date = proxy.value(atX: xPosition) {
                                    if let tappedLog = logs.first(where: { Calendar.current.isDate($0.sleepTime, inSameDayAs: date) }) {
                                        self.selectedLog = tappedLog
                                        self.navigateToDetail = true
                                    }
                                }
                            }
                    }
                }
                .frame(width: totalWidth, height: 300)
                .padding(.horizontal)
            }
            .defaultScrollAnchor(.trailing) // 초기 위치를 끝(최신)으로 설정
            .background(cardBackground)
            .cornerRadius(15)
            .padding(.horizontal)
            
            Text("그래프 막대를 누르면 상세 정보를 볼 수 있습니다.")
                .font(.caption)
                .foregroundColor(textSecondary)
                .padding(.horizontal)
            
            Spacer()
        }
    }
    
    // 개별 삭제 (스와이프)
    func deleteLogs(at offsets: IndexSet) {
        for index in offsets {
            let log = logs[index]
            manager.deleteLog(log)
        }
    }
    
    // 다중 삭제 (선택된 항목)
    func deleteSelectedLogs() {
        for id in selectedLogIds {
            if let log = logs.first(where: { $0.id == id }) {
                manager.deleteLog(log)
            }
        }
        selectedLogIds.removeAll()
        // 편집 모드 종료는 환경 변수 제어가 까다로우므로, 선택 해제만 수행
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: SleepLog.self, configurations: config)
    let manager = SleepLogManager()
    
    SleepListView()
        .environment(manager)
        .modelContainer(container)
        .onAppear {
            manager.setContext(container.mainContext)
        }
}
