// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'game_state.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GameState _$GameStateFromJson(Map<String, dynamic> json) => GameState(
      levelId: (json['levelId'] as num).toInt(),
      containers: (json['containers'] as List<dynamic>)
          .map((e) => Container.fromJson(e as Map<String, dynamic>))
          .toList(),
      initialContainers: (json['initialContainers'] as List<dynamic>)
          .map((e) => Container.fromJson(e as Map<String, dynamic>))
          .toList(),
      moveHistory: (json['moveHistory'] as List<dynamic>)
          .map((e) => Move.fromJson(e as Map<String, dynamic>))
          .toList(),
      isCompleted: json['isCompleted'] as bool,
      moveCount: (json['moveCount'] as num).toInt(),
      currentMoveIndex: (json['currentMoveIndex'] as num).toInt(),
    );

Map<String, dynamic> _$GameStateToJson(GameState instance) => <String, dynamic>{
      'levelId': instance.levelId,
      'containers': instance.containers.map((e) => e.toJson()).toList(),
      'initialContainers':
          instance.initialContainers.map((e) => e.toJson()).toList(),
      'moveHistory': instance.moveHistory.map((e) => e.toJson()).toList(),
      'isCompleted': instance.isCompleted,
      'moveCount': instance.moveCount,
      'currentMoveIndex': instance.currentMoveIndex,
    };
