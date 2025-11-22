// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'level.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Level _$LevelFromJson(Map<String, dynamic> json) => Level(
      id: (json['id'] as num).toInt(),
      difficulty: (json['difficulty'] as num).toInt(),
      containerCount: (json['containerCount'] as num).toInt(),
      colorCount: (json['colorCount'] as num).toInt(),
      initialContainers: (json['initialContainers'] as List<dynamic>)
          .map((e) => Container.fromJson(e as Map<String, dynamic>))
          .toList(),
      minimumMoves: (json['minimumMoves'] as num?)?.toInt(),
      maxMoves: (json['maxMoves'] as num?)?.toInt(),
      isValidated: json['isValidated'] as bool? ?? false,
      hint: json['hint'] as String?,
      tags:
          (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
              const [],
    );

Map<String, dynamic> _$LevelToJson(Level instance) => <String, dynamic>{
      'id': instance.id,
      'difficulty': instance.difficulty,
      'containerCount': instance.containerCount,
      'colorCount': instance.colorCount,
      'initialContainers':
          instance.initialContainers.map((e) => e.toJson()).toList(),
      'minimumMoves': instance.minimumMoves,
      'maxMoves': instance.maxMoves,
      'isValidated': instance.isValidated,
      'hint': instance.hint,
      'tags': instance.tags,
    };
