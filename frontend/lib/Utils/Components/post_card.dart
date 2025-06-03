// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:frontend/models/post_model.dart';
import 'package:frontend/utils/Navigation/app_custom_route.dart';
import 'package:frontend/View/Interface/Feed/post_detail_page.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

class PostCard extends StatefulWidget {
  final String userName;
  final String userImageUrl;
  final List<MediaItem> media;
  final String description;
  final bool isLiked;
  final bool isSaved;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final VoidCallback onSave;
  final DateTime createdAt;
  final int likeCount;
  final List<CommentModel> comments;
  final String postId;
  final String userEmail;
  final String userId;
  final List<String> likedBy;

  const PostCard({
    super.key,
    required this.userName,
    required this.userImageUrl,
    required this.media,
    required this.description,
    this.isLiked = false,
    this.isSaved = false,
    required this.onLike,
    required this.onComment,
    required this.onSave,
    required this.createdAt,
    this.likeCount = 0,
    this.comments = const [],
    required this.postId,
    required this.userEmail,
    required this.userId,
    required this.likedBy,
  });

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _heartAnimationController;
  bool _showOverlayHeart = false;

  @override
  void initState() {
    super.initState();
    _heartAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _heartAnimationController.dispose();
    super.dispose();
  }

  void _showHeartOverlay() {
    setState(() => _showOverlayHeart = true);
    _heartAnimationController.forward().then((_) {
      _heartAnimationController.reset();
      setState(() => _showOverlayHeart = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          elegantRoute(
            PostDetailPage(
              post: PostModel(
                postId: widget.postId,
                userEmail: widget.userEmail,
                userId: widget.userId,
                userName: widget.userName,
                userProfileImage: widget.userImageUrl,
                caption: widget.description,
                media: widget.media,
                likeCount: widget.likeCount,
                likedBy: widget.likedBy,
                comments: widget.comments,
                createdAt: widget.createdAt,
              ),
            ),
          ),
        );
      },
      onDoubleTap: () {
        if (!widget.isLiked) {
          widget.onLike();
          _showHeartOverlay();
        }
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// Header
                Row(
                  children: [
                    ClipOval(
                      child: CachedNetworkImage(
                        imageUrl: widget.userImageUrl,
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                        useOldImageOnUrlChange: true,
                        fadeInDuration: const Duration(milliseconds: 200),
                        placeholder: (context, url) => Container(
                          color: theme.colorScheme.surface,
                          child: Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                theme.colorScheme.primary,
                              ),
                              strokeWidth: 2,
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: theme.colorScheme.surface,
                          child: Icon(
                            Iconsax.user,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        widget.userName,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onBackground,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.more_horiz),
                      onPressed: () {},
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                /// Post Media (image or video)
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (widget.media.isNotEmpty)
                        _MediaPreview(media: widget.media.first)
                      else
                        Container(
                          width: double.infinity,
                          height: MediaQuery.of(context).size.width,
                          color: Theme.of(context).colorScheme.surface,
                          child: Center(
                            child: Icon(
                              Iconsax.image,
                              color: Theme.of(context).colorScheme.primary,
                              size: 40,
                            ),
                          ),
                        ),
                      if (_showOverlayHeart)
                        ScaleTransition(
                          scale: Tween<double>(begin: 0.0, end: 1.0).animate(
                            CurvedAnimation(
                              parent: _heartAnimationController,
                              curve: Curves.elasticOut,
                              reverseCurve: Curves.easeOut,
                            ),
                          ),
                          child: FadeTransition(
                            opacity:
                                Tween<double>(begin: 0.0, end: 1.0).animate(
                              CurvedAnimation(
                                parent: _heartAnimationController,
                                curve: const Interval(0.0, 0.2),
                                reverseCurve: const Interval(0.6, 1.0),
                              ),
                            ),
                            child: Icon(
                              FontAwesomeIcons.solidHeart,
                              color: Colors.red,
                              size: MediaQuery.of(context).size.width * 0.3,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                /// Description
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: RichText(
                    text: TextSpan(
                      style: GoogleFonts.poppins(
                        color: theme.colorScheme.onBackground,
                        fontSize: 14,
                      ),
                      children: [
                        TextSpan(
                          text: "${widget.userName} ",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(text: widget.description),
                      ],
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                // Add timestamp display
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Text(
                    _formatTimestamp(widget.createdAt),
                    style: GoogleFonts.poppins(
                      color: theme.colorScheme.onBackground.withOpacity(0.6),
                      fontSize: 12,
                    ),
                  ),
                ),

                const SizedBox(height: 6),

                /// Like Count
                if (widget.likeCount > 0)
                  Padding(
                    padding: const EdgeInsets.only(left: 8, bottom: 4),
                    child: Text(
                      '${widget.likeCount} ${widget.likeCount == 1 ? 'like' : 'likes'}',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onBackground,
                      ),
                    ),
                  ),

                /// Action Buttons
                Row(
                  children: [
                    TweenAnimationBuilder<double>(
                      tween: Tween<double>(
                        begin: widget.isLiked ? 0.0 : 1.0,
                        end: widget.isLiked ? 1.0 : 0.0,
                      ),
                      duration: const Duration(milliseconds: 200),
                      builder: (context, value, child) {
                        return Transform.scale(
                          scale: 1.0 + (value * 0.2),
                          child: IconButton(
                            icon: Icon(
                              widget.isLiked
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: widget.isLiked
                                  ? Colors.red
                                  : theme.colorScheme.onBackground,
                            ),
                            onPressed: widget.onLike,
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 4),
                    Text(
                      widget.likeCount.toString(),
                      style: GoogleFonts.poppins(
                        color: theme.colorScheme.onBackground,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 16),
                    IconButton(
                      icon: Icon(
                        FontAwesomeIcons.comments,
                        color: theme.colorScheme.onBackground,
                      ),
                      onPressed: widget.onComment,
                    ),
                    const Spacer(),
                    IconButton(
                      icon: Icon(
                        widget.isSaved ? Icons.bookmark : Icons.bookmark_border,
                        color: theme.colorScheme.onBackground,
                      ),
                      onPressed: widget.onSave,
                    ),
                  ],
                ),

                /// Comments Preview
                if (widget.comments.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'View all ${widget.comments.length} comments',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color:
                                theme.colorScheme.onBackground.withOpacity(0.6),
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Show last 2 comments
                        ...widget.comments.take(2).map(
                              (comment) => Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: RichText(
                                  text: TextSpan(
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      color: theme.colorScheme.onBackground,
                                    ),
                                    children: [
                                      TextSpan(
                                        text: '${comment.userName} ',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      TextSpan(text: comment.text),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}

class _MediaPreview extends StatefulWidget {
  final MediaItem media;
  const _MediaPreview({required this.media});
  @override
  State<_MediaPreview> createState() => _MediaPreviewState();
}

class _MediaPreviewState extends State<_MediaPreview> {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  bool _isVideo = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _isVideo = widget.media.type == 'video';
    if (_isVideo) {
      _initVideo();
    }
  }

  Future<void> _initVideo() async {
    _videoController = VideoPlayerController.network(widget.media.url);
    await _videoController!.initialize();
    _chewieController = ChewieController(
      videoPlayerController: _videoController!,
      autoPlay: false,
      looping: false,
      aspectRatio: _videoController!.value.aspectRatio > 0
          ? _videoController!.value.aspectRatio
          : 9 / 16,
    );
    if (mounted) {
      setState(() {
        _isInitialized = true;
      });
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isVideo) {
      return CachedNetworkImage(
        imageUrl: widget.media.url,
        width: double.infinity,
        height: MediaQuery.of(context).size.width,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          width: double.infinity,
          height: MediaQuery.of(context).size.width,
          color: Theme.of(context).colorScheme.surface,
          child: Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).colorScheme.primary,
              ),
              strokeWidth: 2,
            ),
          ),
        ),
        errorWidget: (context, url, error) => Container(
          width: double.infinity,
          height: MediaQuery.of(context).size.width,
          color: Theme.of(context).colorScheme.surface,
          child: Center(
            child: Icon(
              Iconsax.image,
              color: Theme.of(context).colorScheme.primary,
              size: 40,
            ),
          ),
        ),
      );
    } else {
      if (!_isInitialized) {
        return Container(
          width: double.infinity,
          height: MediaQuery.of(context).size.width,
          color: Theme.of(context).colorScheme.surface,
          child: const Center(child: CircularProgressIndicator()),
        );
      }
      return SizedBox(
        width: double.infinity,
        height: MediaQuery.of(context).size.width,
        child: Chewie(controller: _chewieController!),
      );
    }
  }
}
