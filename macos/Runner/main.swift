import Cocoa
import FlutterMacOS

// ★ 強い参照を保持するためのグローバル変数を宣言 ★
var appDelegate: AppDelegate! 

func main() {
    if #available(macOS 10.13, *) {
        // インスタンスをグローバル変数に保持してからデリゲートに設定
        appDelegate = AppDelegate() 
        NSApp.delegate = appDelegate 
    } else {
        // Fallback on earlier versions
    }
    NSApplication.shared.run()
}
main()
