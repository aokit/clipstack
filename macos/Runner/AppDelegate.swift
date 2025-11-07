// macos/Runner/AppDelegate.swift

import Cocoa
import FlutterMacOS

// ★ 1. NSStatusItem を AppDelegate のプロパティとして保持 ★
class AppDelegate: FlutterAppDelegate {
    
    // システムトレイアイコンのインスタンスを保持
    var statusItem: NSStatusItem!
    let channelName = "com.clipstack.tray"

    override func applicationDidFinishLaunching(_ notification: Notification) {
        super.applicationDidFinishLaunching(notification)
        
        // ★ 2. Flutter Method Channel の設定 ★
        // メッセージ送信は 'sendFlutterMessage' 関数で行うため、ここでは初期化のみ
        if let controller = mainFlutterWindow?.contentViewController as? FlutterViewController {
            // "channel" はここでは使わないため、警告を避けるために "_" で受ける
            let _ = FlutterMethodChannel(name: channelName, binaryMessenger: controller.engine.binaryMessenger)
            
            // ★ 3. システムトレイアイコンの初期化 ★
            statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
            
            if let button = statusItem.button {
                // アイコンパスを安全に検索し、ロードする
                let iconPath = Bundle.main.path(forResource: "AppIcon", ofType: "icns") ?? Bundle.main.path(forResource: "app_icon", ofType: "png", inDirectory: "flutter_assets/assets")
                
                // ★ 修正点: NSImageの生成と設定を安全なオプショナルバインディング（if let）で行う ★
                if let path = iconPath, let image = NSImage(contentsOfFile: path) { 
                    button.image = image
                    button.image?.size = NSSize(width: 18, height: 18) 
                    button.image?.isTemplate = true 
                } else {
                    // アイコンロード失敗時はクラッシュを避け、ログに出力
                    print("Error: System tray icon could not be loaded. Check 'assets/app_icon.png' path.")
                }

                // マウスダウンイベントを両方取得
                button.action = #selector(statusBarButtonClicked(_:))
                button.sendAction(on: [.leftMouseDown, .rightMouseDown]) 
            }
            
            // 4. コンテキストメニューの設定
            let menu = NSMenu()
            // 左クリックのアクションはstatusBarButtonClickedで処理するため、メニューは右クリック専用
            menu.addItem(NSMenuItem(title: "履歴を表示", action: #selector(showHistory(_:)), keyEquivalent: "")) // Index 0
            menu.addItem(NSMenuItem(title: "履歴をクリア", action: #selector(clearHistory(_:)), keyEquivalent: "")) // Index 1
            menu.addItem(NSMenuItem.separator())
            menu.addItem(NSMenuItem(title: "終了", action: #selector(exitApp(_:)), keyEquivalent: "")) // Index 2
            
            statusItem.menu = menu // 右クリックでこのメニューが表示される
        }
    }
    
    // ★ 5. メニュー項目のアクション（Flutterに通知） ★
    @objc func showHistory(_ sender: NSMenuItem) {
        // Flutterにウィンドウ表示をトグルするよう通知
        sendFlutterMessage(method: "toggleWindow")
    }

    @objc func clearHistory(_ sender: NSMenuItem) {
        // Flutterに履歴クリアを通知
        sendFlutterMessage(method: "clearHistory")
    }
    
    @objc func exitApp(_ sender: NSMenuItem) {
        // 終了
        NSApp.terminate(nil) 
    }
    
    // ★ 6. 左クリック/右クリックイベントハンドラ ★
    @objc func statusBarButtonClicked(_ sender: NSStatusBarButton) {
        // イベントがnilでないことを保証（クラッシュレポートの "Unexpectedly found nil" を避ける）
        guard let event = NSApp.currentEvent else { return } 
        
        if event.type == .rightMouseDown {
            // 右クリック: OS が statusItem.menu を表示する
            statusItem.menu?.popUp(positioning: nil, at: NSEvent.mouseLocation, in: nil)
        } else if event.type == .leftMouseDown {
            // 左クリック: Flutter にウィンドウ表示をトグルするよう通知
            sendFlutterMessage(method: "toggleWindow")
        }
    }
    
    // 7. メッセージ送信ヘルパー関数
    func sendFlutterMessage(method: String) {
        if let controller = mainFlutterWindow?.contentViewController as? FlutterViewController {
            let channel = FlutterMethodChannel(name: channelName, binaryMessenger: controller.engine.binaryMessenger)
            // ウィンドウ表示/非表示の命令をFlutterのDartコードに送信
            channel.invokeMethod(method, arguments: nil)
        }
    }
}

// macOS 起動時にウィンドウを自動で表示させないための修正
extension AppDelegate {
    override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false // 最後のウィンドウが閉じてもアプリを終了させない
    }
}
