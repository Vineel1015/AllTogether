import 'package:flutter/foundation.dart';

@immutable
class Post {
  final String id;
  final String userId;
  final String username;
  final String userAvatarUrl;
  final String content;
  final String? imageUrl;
  final DateTime createdAt;
  
  // Meal-specific data
  final String? mealId;
  final double? calories;
  final double? sustainabilityScore;
  final List<String> tags;

  // Social metrics
  final int likeCount;
  final int commentCount;
  final int shareCount;
  final bool isLiked;
  final bool isSaved;

  const Post({
    required this.id,
    required this.userId,
    required this.username,
    required this.userAvatarUrl,
    required this.content,
    this.imageUrl,
    required this.createdAt,
    this.mealId,
    this.calories,
    this.sustainabilityScore,
    this.tags = const [],
    this.likeCount = 0,
    this.commentCount = 0,
    this.shareCount = 0,
    this.isLiked = false,
    this.isSaved = false,
  });

  Post copyWith({
    String? content,
    String? imageUrl,
    int? likeCount,
    int? commentCount,
    int? shareCount,
    bool? isLiked,
    bool? isSaved,
  }) {
    return Post(
      id: id,
      userId: userId,
      username: username,
      userAvatarUrl: userAvatarUrl,
      content: content ?? this.content,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt,
      mealId: mealId,
      calories: calories,
      sustainabilityScore: sustainabilityScore,
      tags: tags,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
      shareCount: shareCount ?? this.shareCount,
      isLiked: isLiked ?? this.isLiked,
      isSaved: isSaved ?? this.isSaved,
    );
  }
}
