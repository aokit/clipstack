import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:clipboard_watcher/clipboard_watcher.dart';
import 'clipboard_history_item.dart';

class ClipboardManager extends ClipboardListener {
  static const String _boxName = 'clipboardHistoryBox';
  late Box<ClipboardHistoryItem> _historyBox;

  // 履歴を逆順（最新が最後）で取得するためのゲッター
  List<ClipboardHistoryItem> get history => _historyBox.values.toList();

  Future<void> init() async {
    // Hiveアダプタの登録（アダプタはg.dartに生成される）
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(ClipboardHistoryItemAdapter());
    }
    _historyBox = await Hive.openBox<ClipboardHistoryItem>(_boxName);

    // クリップボード監視の開始
    clipboardWatcher.addListener(this);
    clipboardWatcher.start();
  }

  void dispose() {
    clipboardWatcher.removeListener(this);
    clipboardWatcher.stop();
  }

  @override
  void onClipboardChanged() async {
    final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
    final newContent = clipboardData?.text;

    if (newContent == null || newContent.trim().isEmpty) {
      return;
    }

    // 履歴を時系列順（古いものが先頭）で取得
    final latestEntry = history.isNotEmpty ? history.last.content : null;

    // 重複チェック: 最新の項目と同じ内容であれば追加しない
    if (newContent != latestEntry) {
      final newItem = ClipboardHistoryItem(
        content: newContent,
        timestamp: DateTime.now(),
      );

      // Boxに新しいアイテムを追加
      await _historyBox.add(newItem);
    }
  }

  Future<void> clearHistory() async {
    await _historyBox.clear();
  }
}

/*
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:clipboard_watcher/clipboard_watcher.dart';
import 'clipboard_history_item.dart';

class ClipboardManager extends ClipboardListener {
  static const String _boxName = 'clipboardHistoryBox';
  late Box<ClipboardHistoryItem> _historyBox;

  List<ClipboardHistoryItem> get history => _historyBox.values.toList();

  Future<void> init() async {
    // 1. Hiveの初期化とBoxオープン
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(ClipboardHistoryItemAdapter());
    }
    _historyBox = await Hive.openBox<ClipboardHistoryItem>(_boxName);

    // 2. クリップボード監視の開始
    clipboardWatcher.addListener(this);
    clipboardWatcher.start();
  }

  void dispose() {
    clipboardWatcher.removeListener(this);
    clipboardWatcher.stop();
    // アプリ終了時にHive Boxを閉じる必要があれば追加
  }

  // クリップボードが変更されたときに呼ばれるコールバック
  @override
  void onClipboardChanged() async {
    final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
    final newContent = clipboardData?.text;

    if (newContent == null || newContent.trim().isEmpty) {
      return;
    }

    // 履歴の最新エントリを取得 (重複チェック用)
    final latestEntry = history.isNotEmpty ? history.last.content : null;

    // 3. 重複チェックと履歴への追加
    if (newContent != latestEntry) {
      final newItem = ClipboardHistoryItem(
        content: newContent,
        timestamp: DateTime.now(),
      );

      // Boxに新しいアイテムを追加し、自動的に永続化されます
      await _historyBox.add(newItem);
      print('クリップボードに新しい項目が追加されました: $newContent');
      // ★ ここでUIの更新や通知の発火を行うロジックを追加
    }
  }

  // 履歴をクリアするメソッド (UIから呼び出す用)
  Future<void> clearHistory() async {
    await _historyBox.clear();
  }
}
*/
