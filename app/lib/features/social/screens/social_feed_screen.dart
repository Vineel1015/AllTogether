import 'package:flutter/material.dart';
import '../models/post_model.dart';
import '../widgets/social_post_card.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/social_provider.dart';
import '../models/post_model.dart';
import '../widgets/social_post_card.dart';
import '../../auth/providers/auth_provider.dart';

class SocialFeedScreen extends ConsumerStatefulWidget {
  const SocialFeedScreen({super.key});

  @override
  ConsumerState<SocialFeedScreen> createState() => _SocialFeedScreenState();
}

class _SocialFeedScreenState extends ConsumerState<SocialFeedScreen> {
  void _showCreatePostDialog() {
    final textController = TextEditingController();
    bool isValid = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Create New Post', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(
                controller: textController,
                maxLines: 5,
                decoration: const InputDecoration(
                  hintText: 'Share your healthy meal thoughts... (min 10 chars)',
                  border: OutlineInputBorder(),
                ),
                onChanged: (val) {
                  setModalState(() => isValid = val.trim().length >= 10);
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.image_outlined, color: Colors.green),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Image upload coming soon!')),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.videocam_outlined, color: Colors.blue),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Video upload coming soon!')),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: isValid ? () async {
                  final user = ref.read(authServiceProvider).currentUser;
                  if (user != null) {
                    final post = Post(
                      id: '',
                      userId: user.id,
                      username: user.userMetadata?['name'] ?? 'User',
                      userAvatarUrl: '',
                      content: textController.text.trim(),
                      createdAt: DateTime.now(),
                    );
                    await ref.read(socialFeedProvider.notifier).sharePost(post);
                    if (mounted) Navigator.pop(ctx);
                  }
                } : null,
                child: const Text('Post to Potluck'),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
            _buildFeedView(ref, feedAsync),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _showCreatePostDialog,
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
