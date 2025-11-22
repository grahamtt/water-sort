// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'move.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Move _$MoveFromJson(Map<String, dynamic> json) => Move(
      fromContainerId: (json['fromContainerId'] as num).toInt(),
      toContainerId: (json['toContainerId'] as num).toInt(),
      liquidMoved:
          LiquidLayer.fromJson(json['liquidMoved'] as Map<String, dynamic>),
      timestamp: DateTime.parse(json['timestamp'] as String),
    );

Map<String, dynamic> _$MoveToJson(Move instance) => <String, dynamic>{
      'fromContainerId': instance.fromContainerId,
      'toContainerId': instance.toContainerId,
      'liquidMoved': instance.liquidMoved.toJson(),
      'timestamp': instance.timestamp.toIso8601String(),
    };
