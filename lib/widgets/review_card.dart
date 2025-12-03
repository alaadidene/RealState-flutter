import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ReviewCard extends StatefulWidget {
  final Map<String, dynamic> review;
  final String? currentUserId;
  final void Function(Map<String, dynamic>)? onEdit;
  final void Function(String)? onDelete;
  final VoidCallback? onLikeUpdate;

  const ReviewCard({
    required this.review,
    super.key,
    this.currentUserId,
    this.onEdit,
    this.onDelete,
    this.onLikeUpdate,
  });

  @override
  State<ReviewCard> createState() => _ReviewCardState();
}

class _ReviewCardState extends State<ReviewCard> {
  late int _likesCount;
  late bool _isLiked;
  bool _isLiking = false;

  @override
  void initState() {
    super.initState();
    final likes = widget.review['likes'] as List? ?? [];
    _likesCount = likes.length;
    _isLiked = widget.currentUserId != null && likes.contains(widget.currentUserId);
  }

  bool get _isOwner => widget.currentUserId == (widget.review['userId'] as String?);

  Future<void> _handleLike() async {
    if (widget.currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to like reviews')),
      );
      return;
    }

    setState(() {
      _isLiking = true;
      _isLiked = !_isLiked;
      _likesCount = _isLiked ? _likesCount + 1 : _likesCount - 1;
    });

    try {
      // TODO: Call Appwrite service to toggle like
      // await _appwrite.toggleReviewLike(widget.review['\$id']);
      widget.onLikeUpdate?.call();
    } catch (error) {
      // Revert on error
      setState(() {
        _isLiked = !_isLiked;
        _likesCount = _isLiked ? _likesCount + 1 : _likesCount - 1;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update like')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLiking = false);
      }
    }
  }

  void _handleDelete() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Review'),
        content: const Text('Are you sure you want to delete this review?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onDelete?.call(widget.review['\$id'] as String? ?? '');
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Widget _buildStars() {
    final rating = (widget.review['rating'] as num?)?.toInt() ?? 0;
    return Row(
      children: List.generate(5, (index) {
        return Icon(
          Icons.star,
          size: 16,
          color: index < rating ? const Color(0xFFFFD700) : const Color(0xFFD1D5DB),
        );
      }),
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return '';
    
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inMinutes < 1) return 'Just now';
      if (difference.inMinutes < 60) {
        return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
      }
      if (difference.inHours < 24) {
        return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
      }
      if (difference.inDays == 0) return 'Today';
      if (difference.inDays == 1) return 'Yesterday';
      if (difference.inDays < 7) return '${difference.inDays} days ago';
      if (difference.inDays < 30) return '${(difference.inDays / 7).floor()} weeks ago';
      if (difference.inDays < 365) return '${(difference.inDays / 30).floor()} months ago';
      return '${(difference.inDays / 365).floor()} years ago';
    } catch (e) {
      return dateString;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.review['user'] as Map<String, dynamic>? ?? <String, dynamic>{};
    final userName = (user['name'] as String?) ?? 'Unknown User';
    final userAvatar = user['avatar'] as String?;
    final comment = (widget.review['comment'] as String?) ?? '';
    final isEdited = (widget.review['isEdited'] as bool?) ?? false;
    final createdAt = widget.review['\$createdAt'] as String?;
    final editedAt = widget.review['editedAt'] as String?;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User info & rating
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundImage: userAvatar != null
                    ? CachedNetworkImageProvider(userAvatar) as ImageProvider
                    : null,
                child: userAvatar == null
                    ? Text(
                        userName.substring(0, 1).toUpperCase(),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _buildStars(),
                        const SizedBox(width: 8),
                        Text(
                          _formatDate(createdAt),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (_isOwner) ...[
                IconButton(
                  onPressed: () => widget.onEdit?.call(widget.review),
                  icon: const Icon(Icons.edit, size: 20),
                  color: const Color(0xFF0061FF),
                ),
                IconButton(
                  onPressed: _handleDelete,
                  icon: const Icon(Icons.close, size: 20),
                  color: Colors.red,
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),

          // Comment
          Text(
            comment,
            style: const TextStyle(fontSize: 14, height: 1.5),
          ),

          // Edited indicator
          if (isEdited)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Edited ${_formatDate(editedAt)}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade400,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),

          // Like button
          const Divider(height: 24),
          InkWell(
            onTap: _isLiking ? null : _handleLike,
            child: Row(
              children: [
                Icon(
                  _isLiked ? Icons.favorite : Icons.favorite_border,
                  size: 20,
                  color: _isLiked ? Colors.red : Colors.grey,
                ),
                const SizedBox(width: 4),
                Text(
                  '$_likesCount ${_likesCount == 1 ? 'Like' : 'Likes'}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: _isLiked ? Colors.red : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
