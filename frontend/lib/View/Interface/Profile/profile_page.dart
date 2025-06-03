// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:frontend/Utils/Navigation/app_custom_route.dart';
import 'package:frontend/models/user_model.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:frontend/models/post_model.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/utils/Components/post_card.dart';
import 'package:frontend/View/Interface/Settings/settings_page.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_player/video_player.dart';

class ProfilePage extends StatefulWidget {
  final String? userId;

  const ProfilePage({super.key, this.userId});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _isLoading = false;
  UserModel? _user;
  List<PostModel> _posts = [];

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    setState(() => _isLoading = true);
    try {
      final user = widget.userId != null
          ? await ApiService.getUserProfile(widget.userId!)
          : await ApiService.getCurrentUser();
      final posts = await ApiService.getUserPosts(widget.userId ?? user.id);
      if (mounted) {
        setState(() {
          _user = user;
          _posts = posts;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _toggleFollow() async {
    if (widget.userId == null) return;

    setState(() => _isLoading = true);
    try {
      final updatedUser = await ApiService.toggleFollow(widget.userId!);
      if (mounted) {
        setState(() => _user = updatedUser);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _navigateToSettings() async {
    final result = await Navigator.push(
      context,
      elegantRoute(const SettingsPage()),
    );

    // If settings were updated, refresh the profile
    if (result == true) {
      _loadUserProfile();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading && _user == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_user == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Iconsax.user,
              size: 48,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'User not found',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: RefreshIndicator(
        onRefresh: _loadUserProfile,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // App Bar
            SliverAppBar(
              floating: true,
              title: Text(
                _user!.userName,
                style: GoogleFonts.poppins(
                  color: theme.colorScheme.onBackground,
                  fontWeight: FontWeight.w600,
                ),
              ),
              actions: [
                if (widget.userId == null)
                  IconButton(
                    icon: const Icon(Iconsax.setting_2),
                    onPressed: _navigateToSettings,
                  ),
              ],
            ),

            // Profile Info
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Profile Image
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: theme.colorScheme.surface,
                      child: ClipOval(
                        child: _user!.profileImage != null &&
                                _user!.profileImage!.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: _user!.profileImage!,
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  color: theme.colorScheme.surface,
                                  child: const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                ),
                                errorWidget: (context, url, error) => Icon(
                                  Icons.person,
                                  size: 50,
                                  color: theme.colorScheme.primary,
                                ),
                              )
                            : Icon(
                                Icons.person,
                                size: 50,
                                color: theme.colorScheme.primary,
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // User Info
                    Text(
                      _user!.name,
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (_user!.bio != null && _user!.bio!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        _user!.bio!,
                        style: GoogleFonts.poppins(fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    const SizedBox(height: 16),

                    // Stats
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStatColumn('Posts', _posts.length.toString()),
                        _buildStatColumn(
                          'Followers',
                          _user!.followers.length.toString(),
                        ),
                        _buildStatColumn(
                          'Following',
                          _user!.following.length.toString(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Follow/Edit Profile Button
                    if (widget.userId != null)
                      ElevatedButton(
                        onPressed: _isLoading ? null : _toggleFollow,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              _user!.followers.contains(_getCurrentUserId())
                                  ? theme.colorScheme.surface
                                  : theme.colorScheme.primary,
                          foregroundColor:
                              _user!.followers.contains(_getCurrentUserId())
                                  ? theme.colorScheme.onSurface
                                  : theme.colorScheme.onPrimary,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                _user!.followers.contains(_getCurrentUserId())
                                    ? 'Unfollow'
                                    : 'Follow',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                  ],
                ),
              ),
            ),

            // Posts Grid
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 2,
                  crossAxisSpacing: 2,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final post = _posts[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PostCard(
                              userName: post.userName,
                              userImageUrl: post.userProfileImage ??
                                  'https://via.placeholder.com/150',
                              media: post.media,
                              description: post.caption,
                              isLiked:
                                  post.likedBy.contains(_getCurrentUserId()),
                              onLike: () async {
                                try {
                                  final updatedPost =
                                      await ApiService.likePost(post.postId);
                                  setState(() {
                                    final index = _posts.indexWhere(
                                      (p) => p.postId == post.postId,
                                    );
                                    if (index != -1) {
                                      _posts[index] = updatedPost;
                                    }
                                  });
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Error liking post: $e'),
                                    ),
                                  );
                                }
                              },
                              onComment: () {
                                // Show comment sheet
                              },
                              onSave: () {},
                              createdAt: post.createdAt,
                              likeCount: post.likeCount,
                              comments: post.comments,
                              postId: post.postId,
                              userEmail: post.userEmail,
                              userId: post.userId,
                              likedBy: post.likedBy,
                            ),
                          ),
                        );
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: post.media.isNotEmpty
                            ? (post.media.first.type == 'video'
                                ? _ProfileVideoPreviewGrid(
                                    url: post.media.first.url)
                                : CachedNetworkImage(
                                    imageUrl: post.media.first.url,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: double.infinity,
                                    placeholder: (context, url) => Container(
                                      color: theme.colorScheme.surface,
                                      child: Center(
                                        child: CircularProgressIndicator(
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                            theme.colorScheme.primary,
                                          ),
                                          strokeWidth: 2,
                                        ),
                                      ),
                                    ),
                                    errorWidget: (context, url, error) =>
                                        Container(
                                      color: theme.colorScheme.surface,
                                      child: Icon(
                                        Iconsax.image,
                                        color: theme.colorScheme.primary,
                                      ),
                                    ),
                                  ))
                            : Container(
                                color: theme.colorScheme.surface,
                                child: Icon(
                                  Iconsax.image,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                      ),
                    );
                  },
                  childCount: _posts.length,
                ),
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

  Widget _buildStatColumn(String label, String count) {
    return Column(
      children: [
        Text(
          count,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
          ),
        ),
      ],
    );
  }
}

class _ProfileVideoPreviewGrid extends StatefulWidget {
  final String url;
  const _ProfileVideoPreviewGrid({required this.url});
  @override
  State<_ProfileVideoPreviewGrid> createState() =>
      _ProfileVideoPreviewGridState();
}

class _ProfileVideoPreviewGridState extends State<_ProfileVideoPreviewGrid> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.network(widget.url)
      ..setLooping(true)
      ..setVolume(0)
      ..initialize().then((_) {
        _controller.play();
        if (mounted) setState(() => _isInitialized = true);
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Container(
        color: Theme.of(context).colorScheme.surface,
        child: const Center(child: CircularProgressIndicator()),
      );
    }
    return AspectRatio(
      aspectRatio:
          _controller.value.aspectRatio > 0 ? _controller.value.aspectRatio : 1,
      child: VideoPlayer(_controller),
    );
  }
}
