// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'container.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Container _$ContainerFromJson(Map<String, dynamic> json) => Container(
      id: (json['id'] as num).toInt(),
      capacity: (json['capacity'] as num).toInt(),
      liquidLayers: (json['liquidLayers'] as List<dynamic>?)
          ?.map((e) => LiquidLayer.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$ContainerToJson(Container instance) => <String, dynamic>{
      'id': instance.id,
      'capacity': instance.capacity,
      'liquidLayers': instance.liquidLayers.map((e) => e.toJson()).toList(),
    };
