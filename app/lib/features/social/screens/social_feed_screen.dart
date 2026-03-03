import 'package:flutter/material.dart';
import '../models/post_model.dart';
import '../widgets/social_post_card.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/social_provider.dart';
import '../models/post_model.dart';
import '../widgets/social_post_card.dart';

class SocialFeedScreen extends ConsumerWidget {
  const SocialFeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedAsync = ref.watch(socialFeedProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: const TabBar(
          indicatorColor: Colors.green,
          labelColor: Colors.black,
          unselectedLabelColor: Colors.grey,
          labelStyle: TextStyle(fontWeight: FontWeight.bold),
          tabs: [
            Tab(text: 'For you'),
            Tab(text: 'Following'),
          ],
        ),
        body: TabBarView(
          children: [
            _buildFeedView(ref, feedAsync),
            _buildFeedView(ref, feedAsync), // Currently showing same feed for both
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            // Implementation for creating a new post
          },
          backgroundColor: Colors.green,
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildFeedView(WidgetRef ref, AsyncValue<List<Post>> feedAsync) {
    return feedAsync.when(
      data: (posts) => posts.isEmpty
          ? const _EmptySocialState()
          : RefreshIndicator(
              onRefresh: () => ref.read(socialFeedProvider.notifier).refresh(),
              child: ListView.separated(
                itemCount: posts.length,
                separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey[200]),
                itemBuilder: (context, index) => SocialPostCard(post: posts[index]),
              ),
            ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Error loading feed: $e'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.invalidate(socialFeedProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptySocialState extends StatelessWidget {
  const _EmptySocialState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text(
            'The feed is empty. Be the first to post!',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
