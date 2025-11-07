import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:window_manager/window_manager.dart';

import 'clipboard_manager.dart';
import 'clipboard_history_item.dart';

// グローバルオブジェクト
final ClipboardManager clipboardManager = ClipboardManager();

// ★ 1. ウィンドウ操作を分離する関数 (Future.delayed はブロック回避のために維持) ★
// ネイティブ側からこの関数を呼び出す
Future<void> toggleWindowVisibility() async {
  Future.delayed(Duration.zero, () async {
    bool isVisible = await WindowManager.instance.isVisible();
    if (isVisible) {
      await WindowManager.instance.hide();
    } else {
      // 表示する際は、画面右上隅に移動
      await WindowManager.instance.setAlignment(Alignment.topRight);
      await WindowManager.instance.show();
      await WindowManager.instance.focus();
    }
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await WindowManager.instance.ensureInitialized();

  // ウィンドウの初期設定
  windowManager.setMinimumSize(const Size(320, 480));
  windowManager.setSize(const Size(320, 480));
  windowManager.setAlignment(Alignment.topRight);
  windowManager.setAlwaysOnTop(true);
  windowManager.setSkipTaskbar(true);

  await Hive.initFlutter();
  await clipboardManager.init();

  // ★ 2. Nativeからのメッセージを受け取るための MethodChannel を設定 ★
  const platform = MethodChannel('com.clipstack.tray');
  platform.setMethodCallHandler((call) async {
    switch (call.method) {
      case 'toggleWindow':
        // Swiftからの左クリック/メニュー表示命令
        toggleWindowVisibility();
        break;
      case 'clearHistory':
        // Swiftからの履歴クリア命令
        clipboardManager.clearHistory();
        break;
      // Swift側でアプリ終了をNSApp.terminateで行うため、Flutter側でのexit(0)は不要
    }
  });

  runApp(const MyApp());

  // 起動時にウィンドウを非表示
  await WindowManager.instance.hide();
}

// ★ initSystemTray() 関数は、Swiftに処理を移すため、削除またはコメントアウトします。

class MyApp extends StatelessWidget with WindowListener {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    WindowManager.instance.addListener(this);
    WindowManager.instance.setTitle('クリップボード履歴');

    return const MaterialApp(title: 'クリップボード履歴', home: HistoryScreen());
  }

  @override
  void onWindowMinimize() {
    WindowManager.instance.hide();
  }
}

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Box<ClipboardHistoryItem>>(
      valueListenable: Hive.box<ClipboardHistoryItem>(
        'clipboardHistoryBox',
      ).listenable(),
      builder: (context, box, widget) {
        final items = box.values.toList().reversed.toList();

        return Scaffold(
          appBar: AppBar(
            title: const Text('クリップボード履歴'),
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                WindowManager.instance.hide();
              },
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.delete_forever),
                onPressed: () => clipboardManager.clearHistory(),
              ),
            ],
          ),
          body: ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return ListTile(
                title: Text(
                  item.content,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(item.timestamp.toString()),
                onTap: () {
                  Clipboard.setData(ClipboardData(text: item.content));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('履歴をクリップボードにコピーしました')),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}

/*
// main.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:system_tray/system_tray.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';

import 'clipboard_manager.dart';
import 'clipboard_history_item.dart';

final ClipboardManager clipboardManager = ClipboardManager();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  await clipboardManager.init();

  await initSystemTray();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      // macOS/Windowsのデスクトップアプリとして動作させるため、タイトルを設定
      title: 'クリップボード履歴',
      home: HistoryScreen(),
    );
  }
}

// System Trayの初期化と設定
Future<void> initSystemTray() async {
  final SystemTray systemTray = SystemTray();

  String iconPath = 'assets/app_icon.png';

  if (Platform.isWindows) {
    iconPath = 'assets/app_icon.ico';
  } else if (Platform.isMacOS) {
    iconPath = 'assets/app_icon.png';
  }

  await systemTray.initSystemTray(
    iconPath: iconPath,
    title: "クリップボード履歴",
    toolTip: "クリップボード履歴管理アプリ",
  );

  final Menu menu = Menu();
  await menu.buildFrom([
    // IDが必要な場合は、MenuItemを使用するよう修正
    MenuItem(id: 'show_window', label: '履歴を表示'),
    MenuItem(id: 'clear_history', label: '履歴をクリア'),
    MenuItem(id: 'exit_app', label: '終了'),
  ]);

  await systemTray.setContextMenu(menu);

  // イベントハンドラの型とロジックを修正
  systemTray.registerSystemTrayEventHandler((event) {
    // イベントオブジェクトはSystemTrayEvent型であることが期待される
    if (event is SystemTrayEvent) {
      if (event.type == SystemTrayEventType.leftMouseUp) {
        // 左クリック時のウィンドウ操作ロジック
      } else if (event.type == SystemTrayEventType.menuItemClick) {
        if (event.id == 'show_window') {
          // ウィンドウ表示ロジック
        } else if (event.id == 'clear_history') {
          clipboardManager.clearHistory();
        } else if (event.id == 'exit_app') {
          systemTray.destroy();
        }
      }
    }
  });
}

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Box<ClipboardHistoryItem>>(
      valueListenable: Hive.box<ClipboardHistoryItem>(
        'clipboardHistoryBox',
      ).listenable(),
      builder: (context, box, widget) {
        final items = box.values.toList().reversed.toList();

        return Scaffold(
          appBar: AppBar(
            title: const Text('クリップボード履歴'),
            actions: [
              IconButton(
                icon: const Icon(Icons.delete_forever),
                onPressed: () => clipboardManager.clearHistory(),
              ),
            ],
          ),
          body: ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return ListTile(
                title: Text(
                  item.content,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(item.timestamp.toString()),
                onTap: () {
                  Clipboard.setData(ClipboardData(text: item.content));
                },
              );
            },
          ),
        );
      },
    );
  }
}
*/

/*
// main.dart

import 'dart:io'; // Platform.is...のために追加
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Clipboard, ClipboardDataのために追加
import 'package:system_tray/system_tray.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';

// 欠けていたインポートを追加
import 'clipboard_manager.dart';
import 'clipboard_history_item.dart';

final ClipboardManager clipboardManager = ClipboardManager();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  await clipboardManager.init();

  // SystemTrayの初期化をmain関数内で直接行うか、MyAppの前に呼び出す
  await initSystemTray();

  // 欠けていたクラス名を呼び出す
  runApp(const MyApp());
}

// 欠けていたMyAppクラスを定義
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: HistoryScreen());
  }
}

// System Trayの初期化と設定
Future<void> initSystemTray() async {
  final SystemTray systemTray = SystemTray();

  String iconPath = 'assets/app_icon.png';

  // Theme.of()を使わず、Platform.is...で判別するよう修正
  if (Platform.isWindows) {
    iconPath = 'assets/app_icon.ico';
  } else if (Platform.isMacOS) {
    iconPath = 'assets/app_icon.png';
  }

  await systemTray.initSystemTray(
    iconPath: iconPath,
    title: "クリップボード履歴",
    toolTip: "クリップボード履歴管理アプリ",
  );

  final Menu menu = Menu();
  await menu.buildFrom([
    // MenuItemLable -> MenuItemLabel に修正
    MenuItemLabel(label: '履歴を表示', id: 'show_window'),
    MenuItemLabel(label: '履歴をクリア', id: 'clear_history'),
    MenuItemLabel(label: '終了', id: 'exit_app'),
  ]);

  await systemTray.setContextMenu(menu);

  // SystemTrayEventを正しく参照
  systemTray.registerSystemTrayEventHandler((event) {
    // SystemTrayEvent.leftMouseUp は event.event ではなく event.type で比較する
    // system_tray のAPI仕様に合わせて修正
    if (event.type == SystemTrayEventType.leftMouseUp) {
      // ウィンドウ表示ロジック
    } else if (event.type == SystemTrayEventType.menuItemClick) {
      if (event.id == 'show_window') {
        // ウィンドウ表示ロジック
      } else if (event.id == 'clear_history') {
        clipboardManager.clearHistory();
      } else if (event.id == 'exit_app') {
        systemTray.destroy();
      }
    }
  });
}

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Box<ClipboardHistoryItem>>(
      // 型引数を明示
      valueListenable: Hive.box<ClipboardHistoryItem>(
        'clipboardHistoryBox',
      ).listenable(),
      builder: (context, box, widget) {
        final items = box.values.toList().reversed.toList();

        return Scaffold(
          appBar: AppBar(
            title: const Text('クリップボード履歴'),
            actions: [
              IconButton(
                icon: const Icon(Icons.delete_forever),
                onPressed: () => clipboardManager.clearHistory(),
              ),
            ],
          ),
          body: ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return ListTile(
                title: Text(
                  item.content,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(item.timestamp.toString()),
                onTap: () {
                  // Clipboard, ClipboardData を services.dart から正しく使用
                  Clipboard.setData(ClipboardData(text: item.content));
                },
              );
            },
          ),
        );
      },
    );
  }
}
*/

/*
// main.dart

import 'package:flutter/material.dart';
import 'package:system_tray/system_tray.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'clipboard_manager.dart';

// グローバルまたはProviderなどで管理する
final ClipboardManager clipboardManager = ClipboardManager();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // void main() async {
  //   WidgetsFlutterBinding.ensureInitialized();

  // Hiveの初期化
  await Hive.initFlutter();

  // クリップボード監視の初期化と開始
  await clipboardManager.init();

  //   runApp(const MyApp());
  // }
  // SystemTrayの初期化
  await initSystemTray();

  runApp(const MyApp());
}

// System Trayの初期化と設定
Future<void> initSystemTray() async {
  final SystemTray systemTray = SystemTray();

  // プラットフォームに応じたアイコンパスの決定
  String iconPath = 'assets/app_icon.png';
  if (Theme.of(await getApplicationSupportDirectory()).platform ==
      TargetPlatform.windows) {
    // Windowsではicoファイルが推奨される
    iconPath = 'assets/app_icon.ico';
  } else if (Theme.of(await getApplicationSupportDirectory()).platform ==
      TargetPlatform.macOS) {
    // macOSではicnsファイルが推奨されるか、pngでもOK
    iconPath = 'assets/app_icon.png';
  }

  // System Trayの初期化
  await systemTray.initSystemTray(
    iconPath: iconPath,
    title: "クリップボード履歴",
    toolTip: "クリップボード履歴管理アプリ",
  );

  // メニューの作成
  final Menu menu = Menu();
  await menu.buildFrom([
    MenuItemLable(label: '履歴を表示', id: 'show_window'),
    MenuItemLable(label: '履歴をクリア', id: 'clear_history'),
    MenuItemLable(label: '終了', id: 'exit_app'),
  ]);

  // メニューをトレイに設定
  await systemTray.setContextMenu(menu);

  // イベントリスナーの登録
  systemTray.registerSystemTrayEventHandler((event) {
    // ユーザーがトレイアイコンを操作したときの処理
    if (event.event == SystemTrayEvent.leftMouseUp) {
      // 左クリックでウィンドウを表示/非表示 (具体的なウィンドウ操作はネイティブ側で実装が必要な場合あり)
      // ここではアプリがフォーカスされるように簡易的な処理を行う
      // showAppWindow(); // 実際にウィンドウを操作する関数を定義
    } else if (event.event == SystemTrayEvent.menuItemClick) {
      // メニューアイテムがクリックされたときの処理
      if (event.id == 'show_window') {
        // showAppWindow();
      } else if (event.id == 'clear_history') {
        // 前回のコード例で作成した履歴クリア関数を呼び出す
        // clipboardManager.clearHistory();
      } else if (event.id == 'exit_app') {
        // アプリケーションを終了する
        systemTray.destroy();
      }
    }
  });
}

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // ValueListenableBuilderでHive Boxの変更をリスニングし、自動的にUIを更新
    return ValueListenableBuilder(
      valueListenable: Hive.box<ClipboardHistoryItem>(
        'clipboardHistoryBox',
      ).listenable(),
      builder: (context, box, widget) {
        final items = box.values.toList().reversed.toList(); // 新しいものを上にするため反転

        return Scaffold(
          appBar: AppBar(
            title: const Text('クリップボード履歴'),
            actions: [
              IconButton(
                icon: const Icon(Icons.delete_forever),
                onPressed: () => clipboardManager.clearHistory(),
              ),
            ],
          ),
          body: ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return ListTile(
                title: Text(
                  item.content,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(item.timestamp.toString()),
                onTap: () {
                  // タップでその内容を再びクリップボードにコピー
                  Clipboard.setData(ClipboardData(text: item.content));
                  // 通知やメッセージを表示
                },
              );
            },
          ),
        );
      },
    );
  }
}
*/
