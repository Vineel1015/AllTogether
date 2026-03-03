import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/post_model.dart';
import '../services/social_service.dart';
import '../../../core/models/app_result.dart';

final socialServiceProvider = Provider<SocialService>((ref) => SocialService());

final socialFeedProvider = AsyncNotifierProvider<SocialFeedNotifier, List<Post>>(
  SocialFeedNotifier.new,
);

class SocialFeedNotifier extends AsyncNotifier<List<Post>> {
  @override
  Future<List<Post>> build() async {
    return _fetchFeed();
  }

  Future<List<Post>> _fetchFeed() async {
    final result = await ref.read(socialServiceProvider).getFeed();
    switch (result) {
      case AppSuccess(:final data):
        return data;
      case AppFailure(:final message):
        throw Exception(message);
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchFeed());
  }

  Future<void> sharePost(Post post) async {
    final result = await ref.read(socialServiceProvider).createPost(post);
    if (result is AppSuccess) {
      await refresh();
    }
  }
}
