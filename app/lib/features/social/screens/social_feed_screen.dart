import 'package:flutter/material.dart';
import '../models/post_model.dart';
import '../widgets/social_post_card.dart';

class SocialFeedScreen extends StatelessWidget {
  const SocialFeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Placeholder data to simulate an X-like feed.
    final List<Post> mockPosts = [
      Post(
        id: '1',
        userId: 'u1',
        username: 'HealthyChef',
        userAvatarUrl: 'https://i.pravatar.cc/150?u=u1',
        content: 'Just made this amazing sustainable quinoa bowl! Low calorie and high protein. #healthy #sustainable #quinoa',
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        calories: 350,
        sustainabilityScore: 9.5,
        likeCount: 42,
        commentCount: 5,
        shareCount: 12,
      ),
      Post(
        id: '2',
        userId: 'u2',
        username: 'GreenEater',
        userAvatarUrl: 'https://i.pravatar.cc/150?u=u2',
        content: 'Testing out the new meal planning feature. It suggested a great plant-based diet for this week! 🥗♻️ #vegan #mealplanning',
        createdAt: DateTime.now().subtract(const Duration(hours: 5)),
        calories: 420,
        sustainabilityScore: 10.0,
        likeCount: 128,
        commentCount: 14,
        shareCount: 25,
      ),
      Post(
        id: '3',
        userId: 'u3',
        username: 'FitnessFreak',
        userAvatarUrl: 'https://i.pravatar.cc/150?u=u3',
        content: 'Macros are looking good today. Loving the analytics page updates! 💪 #macros #fitness #health',
        createdAt: DateTime.now().subtract(const Duration(hours: 8)),
        calories: 550,
        sustainabilityScore: 7.2,
        likeCount: 89,
        commentCount: 3,
        shareCount: 8,
      ),
    ];

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
            _buildFeed(mockPosts),
            _buildFeed(mockPosts.reversed.toList()),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {},
          backgroundColor: Colors.green,
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildFeed(List<Post> posts) {
    return ListView.separated(
      itemCount: posts.length,
      separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey[200]),
      itemBuilder: (context, index) => SocialPostCard(post: posts[index]),
    );
  }
}
