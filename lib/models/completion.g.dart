// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'completion.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CompletionAdapter extends TypeAdapter<Completion> {
  @override
  final int typeId = 3;

  @override
  Completion read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Completion(
      habitId: fields[0] as String,
      date: fields[1] as DateTime,
      completed: fields[2] as bool,
      timeValue: fields[3] as double?,
      count: fields[4] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, Completion obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.habitId)
      ..writeByte(1)
      ..write(obj.date)
      ..writeByte(2)
      ..write(obj.completed)
      ..writeByte(3)
      ..write(obj.timeValue)
      ..writeByte(4)
      ..write(obj.count);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CompletionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
