import SwiftUI

/// 设置窗口主视图
/// 使用 Apple 官方推荐的 TabView 设置模式，自动适配 Liquid Glass 效果
struct SettingsWindowView: View {
    var body: some View {
        TabView {
            Tab("通用", systemImage: "gearshape") {
                GeneralSettingsView()
                    .fixedSize()
            }
            
            Tab("应用列表", systemImage: "app.badge.checkmark") {
                AppListSettingsView()
                    .frame(minWidth: 450, minHeight: 300)
            }
            
            Tab("关于", systemImage: "info.circle") {
                AboutView()
                    .fixedSize()
            }
        }
        .scenePadding()
    }
}
