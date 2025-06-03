// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import 'package:frontend/providers/post_provider.dart';
import 'package:frontend/providers/user_provider.dart';
import 'package:frontend/utils/Components/post_card.dart';
import 'package:frontend/utils/Components/comment_sheet.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';
import 'dart:async';

class InterfacePage extends StatefulWidget {
  const InterfacePage({super.key});

  @override
  State<InterfacePage> createState() => _InterfacePageState();
}

class _InterfacePageState extends State<InterfacePage> {
  final ScrollController _scrollController = ScrollController();
  Timer? _refreshTimer;
  static const _refreshInterval = Duration(minutes: 5);
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _startRefreshTimer();
    // Schedule the initialization for the next frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeFeed();
    });
  }

  Future<void> _initializeFeed() async {
    if (!mounted) return;
    setState(() => _isInitialized = true);
    await context.read<PostProvider>().loadPosts(refresh: true);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _startRefreshTimer() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(_refreshInterval, (timer) {
      if (mounted) {
        _loadPosts(refresh: true);
      }
    });
  }

  Future<void> _loadPosts({bool refresh = false}) async {
    if (!mounted) return;
    await context.read<PostProvider>().loadPosts(refresh: refresh);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadPosts();
    }
  }

  Future<void> _onRefresh() async {
    await _loadPosts(refresh: true);
    _startRefreshTimer(); // Reset the timer after manual refresh
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final postProvider = context.watch<PostProvider>();
    final currentUser = context.watch<UserProvider>().user;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: !_isInitialized
          ? const Center(child: CircularProgressIndicator())
          : LiquidPullToRefresh(
              onRefresh: _onRefresh,
              color: theme.colorScheme.primary,
              backgroundColor: theme.colorScheme.surface,
              height: 100,
              animSpeedFactor: 2,
              showChildOpacityTransition: false,
              child: CustomScrollView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // App Bar
                  SliverAppBar(
                    floating: true,
                    backgroundColor: theme.colorScheme.surface,
                    title: Text(
                      'BLYND',
                      style: GoogleFonts.poppins(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                      ),
                    ),
                    actions: [
                      Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: IconButton(
                          icon: Icon(
                            Iconsax.message,
                            color: theme.colorScheme.primary,
                            size: 30,
                          ),
                          onPressed: () {
                            // Navigate to messages
                          },
                        ),
                      ),
                    ],
                  ),

                  // Posts
                  if (postProvider.isLoading && postProvider.posts.isEmpty)
                    const SliverFillRemaining(
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (postProvider.posts.isEmpty)
                    SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Iconsax.image,
                              color: theme.colorScheme.primary,
                              size: 48,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              "No posts yet",
                              style: GoogleFonts.poppins(
                                color: theme.colorScheme.primary,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          if (index == postProvider.posts.length) {
                            return postProvider.isLoading
                                ? Center(
                                    child: Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: CircularProgressIndicator(
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                          theme.colorScheme.primary,
                                        ),
                                      ),
                                    ),
                                  )
                                : null;
                          }

                          final post = postProvider.posts[index];
                          return PostCard(
                            userName: post.userName,
                            userImageUrl: post.userProfileImage?.isEmpty ?? true
                                ? 'https://via.placeholder.com/150'
                                : post.userProfileImage!,
                            media: post.media,
                            description: post.caption,
                            isLiked: post.likedBy.contains(currentUser?.id),
                            onLike: () => _handleLike(post.postId),
                            onComment: () => _showCommentSheet(post.postId),
                            onSave: () {},
                            createdAt: post.createdAt,
                            likeCount: post.likeCount,
                            comments: post.comments,
                            postId: post.postId,
                            userEmail: post.userEmail,
                            userId: post.userId,
                            likedBy: post.likedBy,
                          );
                        },
                        childCount: postProvider.posts.length +
                            (postProvider.isLoading ? 1 : 0),
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Future<bool> _handleLike(String postId) async {
    try {
      await context.read<PostProvider>().likePost(postId);
      return true;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error liking post: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return false;
    }
  }

  void _showCommentSheet(String postId) {
    final post = context
        .read<PostProvider>()
        .posts
        .firstWhere((p) => p.postId == postId);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => CommentSheet(
        postId: postId,
        comments: post.comments,
        onCommentAdded: (text) async {
          try {
            await context.read<PostProvider>().addComment(
                  postId: postId,
                  text: text,
                );
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error adding comment: $e'),
                  backgroundColor: Colors.red,
                ),
              );
              rethrow; // Re-throw to handle in CommentSheet
            }
          }
        },
      ),
    );
  }
}
