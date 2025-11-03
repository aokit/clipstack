import Cocoa
import FlutterMacOS
// import Flutter

@main
class AppDelegate: FlutterAppDelegate {
  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    // return true
    return false
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }
}

// AppDelegate.swift (抜粋)

// import Cocoa
// import FlutterMacOS

// @main
// class AppDelegate: FlutterAppDelegate {
//  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    // ウィンドウを閉じてもアプリケーションを終了させないように「false」を返す
//     return false
//   }
// }