// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'habit.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class HabitAdapter extends TypeAdapter<Habit> {
  @override
  final int typeId = 0;

  @override
  Habit read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Habit(
      id: fields[0] as String?,
      name: fields[1] as String,
      color: fields[2] as String,
      icon: fields[3] as String,
      type: fields[4] as HabitType,
      streak: fields[5] as int,
      createdAt: fields[6] as DateTime?,
      category: fields[7] as String,
      targetDaysPerWeek: fields[8] as int?,
      frequency: fields[9] as Frequency,
      targetTime: fields[10] as double?,
    );
  }

  @override
  void write(BinaryWriter writer, Habit obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.color)
      ..writeByte(3)
      ..write(obj.icon)
      ..writeByte(4)
      ..write(obj.type)
      ..writeByte(5)
      ..write(obj.streak)
      ..writeByte(6)
      ..write(obj.createdAt)
      ..writeByte(7)
      ..write(obj.category)
      ..writeByte(8)
      ..write(obj.targetDaysPerWeek)
      ..writeByte(9)
      ..write(obj.frequency)
      ..writeByte(10)
      ..write(obj.targetTime);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HabitAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class HabitTypeAdapter extends TypeAdapter<HabitType> {
  @override
  final int typeId = 1;

  @override
  HabitType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return HabitType.check;
      case 1:
        return HabitType.time;
      default:
        return HabitType.check;
    }
  }

  @override
  void write(BinaryWriter writer, HabitType obj) {
    switch (obj) {
      case HabitType.check:
        writer.writeByte(0);
        break;
      case HabitType.time:
        writer.writeByte(1);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HabitTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class FrequencyAdapter extends TypeAdapter<Frequency> {
  @override
  final int typeId = 2;

  @override
  Frequency read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return Frequency.daily;
      case 1:
        return Frequency.weekly;
      default:
        return Frequency.daily;
    }
  }

  @override
  void write(BinaryWriter writer, Frequency obj) {
    switch (obj) {
      case Frequency.daily:
        writer.writeByte(0);
        break;
      case Frequency.weekly:
        writer.writeByte(1);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FrequencyAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
