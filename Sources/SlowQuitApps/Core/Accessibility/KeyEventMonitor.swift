import Cocoa
import Carbon.HIToolbox

/// 键盘事件类型
enum KeyEventType: Sendable {
    case keyDown
    case keyUp
    case flagsChanged  // 修饰键变化
}

/// 键盘事件信息
struct KeyEvent: Sendable {
    let keyCode: UInt16
    let modifiers: UInt
    let type: KeyEventType
    let timestamp: Date
    
    /// 是否按住 Command 键
    var hasCommandModifier: Bool {
        (modifiers & NSEvent.ModifierFlags.command.rawValue) != 0
    }
    
    /// 是否是 Q 键
    var isQKey: Bool {
        keyCode == Constants.Keyboard.qKeyCode
    }
    
    /// 是否是 Command + Q 组合键按下
    var isCmdQDown: Bool {
        type == .keyDown && isQKey && hasCommandModifier
    }
}

/// 键盘事件回调协议
@MainActor
protocol KeyEventDelegate: AnyObject {
    /// 按键按下事件
    func keyEventMonitor(_ monitor: KeyEventMonitor, didReceiveKeyDown event: KeyEvent)
    /// 按键释放事件
    func keyEventMonitor(_ monitor: KeyEventMonitor, didReceiveKeyUp event: KeyEvent)
}

/// 全局键盘事件监听器
/// 使用 CGEvent Tap 监听全局键盘事件
@MainActor
final class KeyEventMonitor {
    /// 单例实例
    static let shared = KeyEventMonitor()
    
    /// 事件代理
    weak var delegate: KeyEventDelegate?
    
    /// 事件监听器引用
    private var eventTap: CFMachPort?
    
    /// 运行循环源
    private var runLoopSource: CFRunLoopSource?
    
    /// 是否正在监听
    private(set) var isMonitoring: Bool = false
    
    /// 是否正在进行 Cmd+Q 按压（Q键被按下且Cmd被按住）
    private var isCmdQPressed: Bool = false
    
    private init() {}
    
    // MARK: - 公开方法
    
    /// 开始监听键盘事件
    func startMonitoring() {
        guard !isMonitoring else {
            print("⚠️ 事件监听已在运行中")
            return
        }
        
        // 创建事件掩码：监听按键按下、释放和修饰键变化
        let eventMask = (1 << CGEventType.keyDown.rawValue) 
            | (1 << CGEventType.keyUp.rawValue)
            | (1 << CGEventType.flagsChanged.rawValue)
        
        // 创建监听器包装器
        let wrapper = KeyEventMonitorWrapper.shared
        wrapper.monitor = self
        
        print("🔧 正在创建事件监听器...")
        
        // 创建事件监听器
        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(eventMask),
            callback: keyEventCallback,
            userInfo: Unmanaged.passUnretained(wrapper).toOpaque()
        ) else {
            print("❌ 无法创建事件监听器，请检查无障碍权限")
            return
        }
        
        eventTap = tap
        
        // 创建运行循环源并添加到当前运行循环
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        guard let source = runLoopSource else {
            print("❌ 无法创建运行循环源")
            return
        }
        
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        
        isMonitoring = true
        print("✅ 键盘事件监听已启动，正在拦截 Cmd+Q")
    }
    
    /// 停止监听键盘事件
    func stopMonitoring() {
        guard isMonitoring else { return }
        
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
        }
        
        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
        }
        
        eventTap = nil
        runLoopSource = nil
        isMonitoring = false
        isCmdQPressed = false
        
        print("🛑 键盘事件监听已停止")
    }
    
    /// 重新启用事件监听
    func reenableTap() {
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: true)
        }
    }
    
    /// 处理键盘事件
    func handleKeyEvent(_ keyEvent: KeyEvent) {
        switch keyEvent.type {
        case .keyDown:
            // Cmd+Q 按下
            if keyEvent.isCmdQDown {
                isCmdQPressed = true
                delegate?.keyEventMonitor(self, didReceiveKeyDown: keyEvent)
            }
            
        case .keyUp:
            // Q 键释放
            if keyEvent.isQKey && isCmdQPressed {
                isCmdQPressed = false
                delegate?.keyEventMonitor(self, didReceiveKeyUp: keyEvent)
            }
            
        case .flagsChanged:
            // Cmd 键释放（修饰键变化）
            if !keyEvent.hasCommandModifier && isCmdQPressed {
                isCmdQPressed = false
                delegate?.keyEventMonitor(self, didReceiveKeyUp: keyEvent)
            }
        }
    }
}

// MARK: - 监听器包装器（用于 C 回调）

/// 用于在 C 回调中访问 KeyEventMonitor 的包装器
final class KeyEventMonitorWrapper: @unchecked Sendable {
    static let shared = KeyEventMonitorWrapper()
    
    weak var monitor: KeyEventMonitor?
    
    private init() {}
}

// MARK: - C 回调函数

/// CGEvent 回调函数
private func keyEventCallback(
    proxy: CGEventTapProxy,
    type: CGEventType,
    event: CGEvent,
    userInfo: UnsafeMutableRawPointer?
) -> Unmanaged<CGEvent>? {
    guard let info = userInfo else {
        return Unmanaged.passRetained(event)
    }
    
    let wrapper = Unmanaged<KeyEventMonitorWrapper>.fromOpaque(info).takeUnretainedValue()
    
    // 处理事件禁用通知
    guard type == .keyDown || type == .keyUp || type == .flagsChanged else {
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            DispatchQueue.main.async {
                wrapper.monitor?.reenableTap()
            }
        }
        return Unmanaged.passRetained(event)
    }
    
    // 获取按键码
    let keyCode = UInt16(event.getIntegerValueField(.keyboardEventKeycode))
    let modifiers = UInt(event.flags.rawValue)
    
    // 确定事件类型
    let eventType: KeyEventType
    switch type {
    case .keyDown: eventType = .keyDown
    case .keyUp: eventType = .keyUp
    case .flagsChanged: eventType = .flagsChanged
    default: return Unmanaged.passRetained(event)
    }
    
    let keyEvent = KeyEvent(
        keyCode: keyCode,
        modifiers: modifiers,
        type: eventType,
        timestamp: Date()
    )
    
    // 判断是否需要拦截
    // 1. Cmd+Q keyDown 需要拦截
    // 2. 如果正在进行 Cmd+Q，Q 的 keyUp 需要拦截
    // 3. flagsChanged 不拦截（让其他应用正常响应）
    
    let shouldIntercept: Bool
    switch eventType {
    case .keyDown:
        shouldIntercept = keyEvent.isCmdQDown
    case .keyUp:
        // Q 键释放时，如果正处于 Cmd+Q 状态则拦截
        shouldIntercept = keyEvent.isQKey && keyEvent.hasCommandModifier
    case .flagsChanged:
        // 修饰键变化不拦截，但需要处理
        shouldIntercept = false
    }
    
    // 在主线程通知代理
    DispatchQueue.main.async {
        wrapper.monitor?.handleKeyEvent(keyEvent)
    }
    
    // 返回 nil 拦截事件，否则传递
    return shouldIntercept ? nil : Unmanaged.passRetained(event)
}
