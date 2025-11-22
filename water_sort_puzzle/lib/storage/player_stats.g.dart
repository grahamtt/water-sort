// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'player_stats.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PlayerStatsAdapter extends TypeAdapter<PlayerStats> {
  @override
  final int typeId = 1;

  @override
  PlayerStats read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PlayerStats(
      totalMoves: fields[0] as int,
      perfectSolutions: fields[1] as int,
      totalPlayTimeSeconds: fields[2] as int,
      gamesStarted: fields[3] as int,
      gamesCompleted: fields[4] as int,
      totalUndos: fields[5] as int,
      longestWinStreak: fields[6] as int,
      currentWinStreak: fields[7] as int,
      bestCompletionTime: fields[8] as int?,
      bestCompletionTimeLevel: fields[9] as int?,
      bestAverageMovesPerLevel: fields[10] as double?,
      hintsUsed: fields[11] as int,
      firstPlayDate: fields[12] as DateTime?,
      lastPlayDate: fields[13] as DateTime?,
      consecutiveDaysPlayed: fields[14] as int,
      levelAttempts: (fields[15] as Map).cast<int, int>(),
      difficultyCompletions: (fields[16] as Map).cast<int, int>(),
    );
  }

  @override
  void write(BinaryWriter writer, PlayerStats obj) {
    writer
      ..writeByte(17)
      ..writeByte(0)
      ..write(obj.totalMoves)
      ..writeByte(1)
      ..write(obj.perfectSolutions)
      ..writeByte(2)
      ..write(obj.totalPlayTimeSeconds)
      ..writeByte(3)
      ..write(obj.gamesStarted)
      ..writeByte(4)
      ..write(obj.gamesCompleted)
      ..writeByte(5)
      ..write(obj.totalUndos)
      ..writeByte(6)
      ..write(obj.longestWinStreak)
      ..writeByte(7)
      ..write(obj.currentWinStreak)
      ..writeByte(8)
      ..write(obj.bestCompletionTime)
      ..writeByte(9)
      ..write(obj.bestCompletionTimeLevel)
      ..writeByte(10)
      ..write(obj.bestAverageMovesPerLevel)
      ..writeByte(11)
      ..write(obj.hintsUsed)
      ..writeByte(12)
      ..write(obj.firstPlayDate)
      ..writeByte(13)
      ..write(obj.lastPlayDate)
      ..writeByte(14)
      ..write(obj.consecutiveDaysPlayed)
      ..writeByte(15)
      ..write(obj.levelAttempts)
      ..writeByte(16)
      ..write(obj.difficultyCompletions);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlayerStatsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PlayerStats _$PlayerStatsFromJson(Map<String, dynamic> json) => PlayerStats(
      totalMoves: (json['totalMoves'] as num?)?.toInt() ?? 0,
      perfectSolutions: (json['perfectSolutions'] as num?)?.toInt() ?? 0,
      totalPlayTimeSeconds:
          (json['totalPlayTimeSeconds'] as num?)?.toInt() ?? 0,
      gamesStarted: (json['gamesStarted'] as num?)?.toInt() ?? 0,
      gamesCompleted: (json['gamesCompleted'] as num?)?.toInt() ?? 0,
      totalUndos: (json['totalUndos'] as num?)?.toInt() ?? 0,
      longestWinStreak: (json['longestWinStreak'] as num?)?.toInt() ?? 0,
      currentWinStreak: (json['currentWinStreak'] as num?)?.toInt() ?? 0,
      bestCompletionTime: (json['bestCompletionTime'] as num?)?.toInt(),
      bestCompletionTimeLevel:
          (json['bestCompletionTimeLevel'] as num?)?.toInt(),
      bestAverageMovesPerLevel:
          (json['bestAverageMovesPerLevel'] as num?)?.toDouble(),
      hintsUsed: (json['hintsUsed'] as num?)?.toInt() ?? 0,
      firstPlayDate: json['firstPlayDate'] == null
          ? null
          : DateTime.parse(json['firstPlayDate'] as String),
      lastPlayDate: json['lastPlayDate'] == null
          ? null
          : DateTime.parse(json['lastPlayDate'] as String),
      consecutiveDaysPlayed:
          (json['consecutiveDaysPlayed'] as num?)?.toInt() ?? 0,
      levelAttempts: (json['levelAttempts'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(int.parse(k), (e as num).toInt()),
          ) ??
          const {},
      difficultyCompletions:
          (json['difficultyCompletions'] as Map<String, dynamic>?)?.map(
                (k, e) => MapEntry(int.parse(k), (e as num).toInt()),
              ) ??
              const {},
    );

Map<String, dynamic> _$PlayerStatsToJson(PlayerStats instance) =>
    <String, dynamic>{
      'totalMoves': instance.totalMoves,
      'perfectSolutions': instance.perfectSolutions,
      'totalPlayTimeSeconds': instance.totalPlayTimeSeconds,
      'gamesStarted': instance.gamesStarted,
      'gamesCompleted': instance.gamesCompleted,
      'totalUndos': instance.totalUndos,
      'longestWinStreak': instance.longestWinStreak,
      'currentWinStreak': instance.currentWinStreak,
      'bestCompletionTime': instance.bestCompletionTime,
      'bestCompletionTimeLevel': instance.bestCompletionTimeLevel,
      'bestAverageMovesPerLevel': instance.bestAverageMovesPerLevel,
      'hintsUsed': instance.hintsUsed,
      'firstPlayDate': instance.firstPlayDate?.toIso8601String(),
      'lastPlayDate': instance.lastPlayDate?.toIso8601String(),
      'consecutiveDaysPlayed': instance.consecutiveDaysPlayed,
      'levelAttempts':
          instance.levelAttempts.map((k, e) => MapEntry(k.toString(), e)),
      'difficultyCompletions': instance.difficultyCompletions
          .map((k, e) => MapEntry(k.toString(), e)),
    };
