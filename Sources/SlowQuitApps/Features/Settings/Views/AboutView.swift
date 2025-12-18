import SwiftUI

/// 关于页面视图
struct AboutView: View {
    var body: some View {
        VStack(spacing: 20) {
            // 应用图标
            Image(systemName: "hand.raised.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(.linearGradient(
                    colors: [.blue, .purple],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
            
            // 应用名称和版本
            VStack(spacing: 4) {
                Text(Constants.App.name)
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("版本 \(Constants.App.version)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            // 应用描述
            Text("防止意外按下 ⌘Q 导致应用退出的小工具")
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            Divider()
                .padding(.horizontal, 40)
            
            // 功能说明
            VStack(alignment: .leading, spacing: 10) {
                FeatureRow(icon: "keyboard", text: "监听 ⌘Q 快捷键")
                FeatureRow(icon: "timer", text: "需要长按才能退出应用")
                FeatureRow(icon: "list.bullet", text: "支持应用白名单")
                FeatureRow(icon: "gearshape", text: "自定义长按时间")
            }
            
            // 版权信息
            Text("© 2025 Slow Quit Apps")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .padding(.top, 8)
        }
        .padding()
    }
}

/// 功能行
struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.accentColor)
                .frame(width: 24)
            
            Text(text)
                .font(.system(size: 13))
        }
    }
}
