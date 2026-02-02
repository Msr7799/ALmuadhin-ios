import SwiftUI

// MARK: - Theme Colors
extension Color {
    static let islamicGold = Color(red: 0.831, green: 0.686, blue: 0.216)
    static let islamicGoldDark = Color(red: 0.722, green: 0.525, blue: 0.043)
    static let warmBeige = Color(red: 1.0, green: 0.973, blue: 0.906)
    static let warmCream = Color(red: 1.0, green: 0.984, blue: 0.941)
    static let deepBrown = Color(red: 0.365, green: 0.251, blue: 0.216)
}

// MARK: - Main Content View
struct ContentView: View {
    @State private var selectedTab = 0
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Image(systemName: "building.columns")
                    Text("الصلاة")
                }
                .tag(0)
            
            CalendarView()
                .tabItem {
                    Image(systemName: "calendar")
                    Text("التقويم")
                }
                .tag(1)
            
            QiblaView()
                .tabItem {
                    Image(systemName: "safari")
                    Text("القبلة")
                }
                .tag(2)
            
            AzkarView()
                .tabItem {
                    Image(systemName: "book")
                    Text("الأذكار")
                }
                .tag(3)
            
            SettingsView()
                .tabItem {
                    Image(systemName: "gear")
                    Text("الإعدادات")
                }
                .tag(4)
        }
        .tint(Color.islamicGold)
        .onAppear {
            // Configure tab bar appearance
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor.white
            
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}

#Preview {
    ContentView()
}
