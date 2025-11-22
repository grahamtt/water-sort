// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'liquid_layer.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LiquidLayer _$LiquidLayerFromJson(Map<String, dynamic> json) => LiquidLayer(
      color: $enumDecode(_$LiquidColorEnumMap, json['color']),
      volume: (json['volume'] as num).toInt(),
    );

Map<String, dynamic> _$LiquidLayerToJson(LiquidLayer instance) =>
    <String, dynamic>{
      'color': _$LiquidColorEnumMap[instance.color]!,
      'volume': instance.volume,
    };

const _$LiquidColorEnumMap = {
  LiquidColor.red: 'red',
  LiquidColor.blue: 'blue',
  LiquidColor.green: 'green',
  LiquidColor.yellow: 'yellow',
  LiquidColor.purple: 'purple',
  LiquidColor.orange: 'orange',
  LiquidColor.pink: 'pink',
  LiquidColor.cyan: 'cyan',
  LiquidColor.brown: 'brown',
  LiquidColor.lime: 'lime',
};
