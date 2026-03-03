import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/post_model.dart';
import '../../../core/models/app_result.dart';

class SocialService {
  final SupabaseClient _supabase;

  SocialService({SupabaseClient? supabase})
      : _supabase = supabase ?? Supabase.instance.client;

  Future<AppResult<List<Post>>> getFeed() async {
    try {
      final response = await _supabase
          .from('posts')
          .select()
          .order('created_at', ascending: false);

      final posts = (response as List)
          .map((json) => Post(
                id: json['id'],
                userId: json['user_id'],
                username: json['username'],
                userAvatarUrl: 'https://i.pravatar.cc/150?u=${json['user_id']}',
                content: json['content'],
                imageUrl: json['image_url'],
                createdAt: DateTime.parse(json['created_at']),
                mealId: json['meal_id'],
                calories: json['calories']?.toDouble(),
                sustainabilityScore: json['sustainability_score']?.toDouble(),
                tags: List<String>.from(json['tags'] ?? []),
                likeCount: json['like_count'] ?? 0,
                commentCount: json['comment_count'] ?? 0,
                shareCount: json['share_count'] ?? 0,
              ))
          .toList();

      return AppSuccess(posts);
    } catch (e) {
      return AppFailure('Failed to load feed: $e');
    }
  }

  Future<AppResult<void>> createPost(Post post) async {
    try {
      await _supabase.from('posts').insert({
        'user_id': post.userId,
        'username': post.username,
        'content': post.content,
        'image_url': post.imageUrl,
        'meal_id': post.mealId,
        'calories': post.calories,
        'sustainability_score': post.sustainabilityScore,
        'tags': post.tags,
      });
      return const AppSuccess(null);
    } catch (e) {
      return AppFailure('Failed to share post: $e');
    }
  }
}
