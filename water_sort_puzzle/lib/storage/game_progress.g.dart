// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'game_progress.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class GameProgressAdapter extends TypeAdapter<GameProgress> {
  @override
  final int typeId = 0;

  @override
  GameProgress read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return GameProgress(
      unlockedLevelsList: (fields[0] as List?)?.cast<int>(),
      completedLevelsList: (fields[1] as List?)?.cast<int>(),
      currentLevel: fields[2] as int?,
      savedGameState: fields[3] as GameState?,
      bestScores: (fields[4] as Map).cast<int, int>(),
      completionTimes: (fields[5] as Map).cast<int, int>(),
      perfectCompletions: fields[6] as int,
      lastPlayed: fields[7] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, GameProgress obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.unlockedLevelsList)
      ..writeByte(1)
      ..write(obj.completedLevelsList)
      ..writeByte(2)
      ..write(obj.currentLevel)
      ..writeByte(3)
      ..write(obj.savedGameState)
      ..writeByte(4)
      ..write(obj.bestScores)
      ..writeByte(5)
      ..write(obj.completionTimes)
      ..writeByte(6)
      ..write(obj.perfectCompletions)
      ..writeByte(7)
      ..write(obj.lastPlayed);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GameProgressAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GameProgress _$GameProgressFromJson(Map<String, dynamic> json) => GameProgress(
      unlockedLevelsList: (json['unlockedLevelsList'] as List<dynamic>?)
          ?.map((e) => (e as num).toInt())
          .toList(),
      completedLevelsList: (json['completedLevelsList'] as List<dynamic>?)
          ?.map((e) => (e as num).toInt())
          .toList(),
      currentLevel: (json['currentLevel'] as num?)?.toInt(),
      savedGameState: json['savedGameState'] == null
          ? null
          : GameState.fromJson(json['savedGameState'] as Map<String, dynamic>),
      bestScores: (json['bestScores'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(int.parse(k), (e as num).toInt()),
          ) ??
          const {},
      completionTimes: (json['completionTimes'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(int.parse(k), (e as num).toInt()),
          ) ??
          const {},
      perfectCompletions: (json['perfectCompletions'] as num?)?.toInt() ?? 0,
      lastPlayed: json['lastPlayed'] == null
          ? null
          : DateTime.parse(json['lastPlayed'] as String),
    );

Map<String, dynamic> _$GameProgressToJson(GameProgress instance) =>
    <String, dynamic>{
      'unlockedLevelsList': instance.unlockedLevelsList,
      'completedLevelsList': instance.completedLevelsList,
      'currentLevel': instance.currentLevel,
      'savedGameState': instance.savedGameState?.toJson(),
      'bestScores':
          instance.bestScores.map((k, e) => MapEntry(k.toString(), e)),
      'completionTimes':
          instance.completionTimes.map((k, e) => MapEntry(k.toString(), e)),
      'perfectCompletions': instance.perfectCompletions,
      'lastPlayed': instance.lastPlayed?.toIso8601String(),
    };
