import 'package:flutter/material.dart';
import '../models/post_model.dart';

class SocialPostCard extends StatelessWidget {
  final Post post;

  const SocialPostCard({super.key, required this.post});

  @override
  Widget build(BuildContext methodContext) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundImage: NetworkImage(post.userAvatarUrl),
            radius: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      post.username,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '@${post.username.toLowerCase()} · ${_formatTimeAgo(post.createdAt)}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  post.content,
                  style: const TextStyle(fontSize: 15),
                ),
                const SizedBox(height: 12),
                if (post.calories != null || post.sustainabilityScore != null)
                  _buildMealStats(),
                const SizedBox(height: 12),
                _buildSocialActions(methodContext),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMealStats() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          if (post.calories != null)
            _buildStatItem(Icons.local_fire_department, '${post.calories!.toInt()} kcal', Colors.orange),
          if (post.sustainabilityScore != null)
            _buildStatItem(Icons.eco, '${post.sustainabilityScore}/10', Colors.green),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String label, Color color) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey[800], fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildSocialActions(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildActionItem(
          Icons.chat_bubble_outline, 
          post.commentCount.toString(),
          onTap: () => _showCommentDialog(context),
        ),
        _buildActionItem(Icons.repeat, post.shareCount.toString()),
        _buildActionItem(post.isLiked ? Icons.favorite : Icons.favorite_border, post.likeCount.toString(), color: post.isLiked ? Colors.pink : null),
        _buildActionItem(Icons.bookmark_border, ''),
        _buildActionItem(Icons.share_outlined, ''),
      ],
    );
  }

  void _showCommentDialog(BuildContext context) {
    final commentController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Add a comment', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextField(
              controller: commentController,
              decoration: const InputDecoration(
                hintText: 'Type your comment...',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                FilledButton(
                  onPressed: () {
                    // Logic to save comment would go here
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Comment posted!')),
                    );
                  },
                  child: const Text('Reply'),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildActionItem(IconData icon, String count, {Color? color, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 18, color: color ?? Colors.grey[600]),
          if (count.isNotEmpty) ...[
            const SizedBox(width: 4),
            Text(
              count,
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    if (difference.inHours < 1) return '${difference.inMinutes}m';
    if (difference.inHours < 24) return '${difference.inHours}h';
    return '${difference.inDays}d';
  }
}
