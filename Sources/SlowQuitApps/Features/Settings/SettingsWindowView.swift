import SwiftUI

/// 设置窗口主视图
/// 使用 Apple 官方推荐的 TabView 设置模式，自动适配 Liquid Glass 效果
struct SettingsWindowView: View {
    @State private var i18n = I18n.shared
    
    var body: some View {
        // 通过访问 currentLanguage 确保语言变化时视图刷新
        let _ = i18n.currentLanguage
        
        settingsContent
            .scenePadding()
    }
    
    // MARK: - 版本自适应 TabView
    
    @ViewBuilder
    private var settingsContent: some View {
        if #available(macOS 15.0, *) {
            // macOS 15+ 使用新 Tab API
            TabView {
                Tab(t("settings.tabs.general"), systemImage: "gearshape") {
                    GeneralSettingsView()
                        .fixedSize()
                }
                
                Tab(t("settings.tabs.appList"), systemImage: "app.badge.checkmark") {
                    AppListSettingsView()
                        .frame(minWidth: 450, minHeight: 300)
                }
                
                Tab(t("settings.tabs.about"), systemImage: "info.circle") {
                    AboutView()
                        .fixedSize()
                }
            }
        } else {
            // macOS 14 使用旧版 tabItem API
            TabView {
                GeneralSettingsView()
                    .fixedSize()
                    .tabItem {
                        Label(t("settings.tabs.general"), systemImage: "gearshape")
                    }
                
                AppListSettingsView()
                    .frame(minWidth: 450, minHeight: 300)
                    .tabItem {
                        Label(t("settings.tabs.appList"), systemImage: "app.badge.checkmark")
                    }
                
                AboutView()
                    .fixedSize()
                    .tabItem {
                        Label(t("settings.tabs.about"), systemImage: "info.circle")
                    }
            }
        }
    }
}

