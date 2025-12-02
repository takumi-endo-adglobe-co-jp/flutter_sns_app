// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'post.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PostImpl _$$PostImplFromJson(Map<String, dynamic> json) => _$PostImpl(
  id: json['id'] as String,
  content: json['content'] as String,
  likesCount: (json['likes_count'] as num).toInt(),
  createdAt: DateTime.parse(json['created_at'] as String),
  updatedAt: DateTime.parse(json['updated_at'] as String),
);

Map<String, dynamic> _$$PostImplToJson(_$PostImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'content': instance.content,
      'likes_count': instance.likesCount,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
    };
