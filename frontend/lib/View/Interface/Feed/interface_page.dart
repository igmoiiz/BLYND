// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/Model/post_model.dart';
import 'package:frontend/Utils/Components/post_card.dart';
import 'package:frontend/Utils/Components/comment_sheet.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';

class InterfacePage extends StatefulWidget {
  const InterfacePage({super.key});

  @override
  State<InterfacePage> createState() => _InterfacePageState();
}

class _InterfacePageState extends State<InterfacePage> {
  List<PostModel> _posts = [];
  bool _isLoading = false;
  int _currentPage = 1;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadPosts();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadPosts({bool refresh = false}) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      if (refresh) {
        _currentPage = 1;
        _posts = [];
      }
    });

    try {
      final newPosts = await ApiService.getPosts(page: _currentPage);
      setState(() {
        if (refresh) {
          _posts = newPosts;
        } else {
          _posts = [..._posts, ...newPosts];
        }
        _currentPage++;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading posts: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadPosts();
    }
  }

  Future<void> _onRefresh() async {
    await _loadPosts(refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: LiquidPullToRefresh(
        onRefresh: _onRefresh,
        color: colorScheme.primary,
        backgroundColor: colorScheme.surface,
        height: 100,
        child: CustomScrollView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(),
          slivers: [
            // App Bar
            SliverAppBar(
              floating: true,
              backgroundColor: colorScheme.surface,
              title: Text(
                'BLYND',
                style: GoogleFonts.poppins(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
              actions: [
                IconButton(
                  icon: Icon(
                    FontAwesomeIcons.message,
                    color: colorScheme.primary,
                    size: 20,
                  ),
                  onPressed: () {
                    // Navigate to messages
                  },
                ),
              ],
            ),

            // Posts
            if (_posts.isEmpty && !_isLoading)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Iconsax.image,
                        color: colorScheme.primary,
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "No posts yet",
                        style: GoogleFonts.poppins(
                          color: colorScheme.primary,
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
                    if (index == _posts.length) {
                      return _isLoading
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    colorScheme.primary,
                                  ),
                                ),
                              ),
                            )
                          : null;
                    }

                    final post = _posts[index];
                    return PostCard(
                      userName: post.userName,
                      userImageUrl: post.userProfileImage ??
                          'https://via.placeholder.com/150',
                      postImageUrl:
                          post.postImage ?? 'https://via.placeholder.com/150',
                      description: post.caption ?? '',
                      isLiked:
                          post.likedBy?.contains(_getCurrentUserId()) ?? false,
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
                  childCount: _posts.length + (_isLoading ? 1 : 0),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String? _getCurrentUserId() {
    // TODO: Implement getting current user ID from shared preferences or state management
    return null;
  }

  Future<void> _handleLike(String postId) async {
    try {
      final updatedPost = await ApiService.likePost(postId);
      setState(() {
        final index = _posts.indexWhere((p) => p.postId == postId);
        if (index != -1) {
          _posts[index] = updatedPost;
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error liking post: $e')),
      );
    }
  }

  void _showCommentSheet(String postId) {
    final post = _posts.firstWhere((p) => p.postId == postId);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => CommentSheet(
        postId: postId,
        comments: post.comments,
        onCommentAdded: (text) async {
          try {
            final updatedPost = await ApiService.commentOnPost(
              postId: postId,
              text: text,
            );
            setState(() {
              final index = _posts.indexWhere((p) => p.postId == postId);
              if (index != -1) {
                _posts[index] = updatedPost;
              }
            });
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error adding comment: $e')),
            );
          }
        },
      ),
    );
  }
}
