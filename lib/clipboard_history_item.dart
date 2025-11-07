import 'package:hive/hive.dart';

part 'clipboard_history_item.g.dart'; // ビルドランナーで生成

@HiveType(typeId: 0)
class ClipboardHistoryItem extends HiveObject {
  @HiveField(0)
  final String content;

  @HiveField(1)
  final DateTime timestamp;

  ClipboardHistoryItem({required this.content, required this.timestamp});
}
/*
import 'package:hive/hive.dart';

part 'clipboard_history_item.g.dart'; // ビルド時に自動生成されるファイル

@HiveType(typeId: 0)
class ClipboardHistoryItem extends HiveObject {
  @HiveField(0)
  final String content;

  @HiveField(1)
  final DateTime timestamp;

  ClipboardHistoryItem({required this.content, required this.timestamp});
}
*/