import 'package:freezed_annotation/freezed_annotation.dart';

part 'post.freezed.dart';
part 'post.g.dart';

@freezed
class Post with _$Post {
  const factory Post({
    required String id,
    required String content,
    @JsonKey(name: 'likes_count', includeToJson: true, includeFromJson: true) required int likesCount,
    @JsonKey(name: 'created_at', includeToJson: true, includeFromJson: true) required DateTime createdAt,
    @JsonKey(name: 'updated_at', includeToJson: true, includeFromJson: true) required DateTime updatedAt,
  }) = _Post;

  factory Post.fromJson(Map<String, dynamic> json) => _$PostFromJson(json);
}
