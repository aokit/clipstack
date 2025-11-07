// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'clipboard_history_item.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ClipboardHistoryItemAdapter extends TypeAdapter<ClipboardHistoryItem> {
  @override
  final int typeId = 0;

  @override
  ClipboardHistoryItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ClipboardHistoryItem(
      content: fields[0] as String,
      timestamp: fields[1] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, ClipboardHistoryItem obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.content)
      ..writeByte(1)
      ..write(obj.timestamp);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ClipboardHistoryItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
