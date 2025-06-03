// ignore_for_file: deprecated_member_use, unnecessary_null_comparison

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import 'package:frontend/providers/user_provider.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/models/user_model.dart';
import 'package:frontend/models/post_model.dart';
import 'package:video_player/video_player.dart';
import 'package:frontend/utils/Components/media_carousel.dart';

class UserProfilePage extends StatefulWidget {
  final String userId;
  final String userName;

  const UserProfilePage({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  bool _isLoading = true;
  bool _isFollowing = false;
  UserModel? _user;
  List<PostModel> _posts = [];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final user = await ApiService.getUserProfile(widget.userId);
      final posts = await ApiService.getUserPosts(widget.userId);
      if (mounted) {
        setState(() {
          _user = user;
          _posts = posts;
          _isFollowing = user.isFollowing;
          _isLoading = false;
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
    }
  }

  Future<void> _toggleFollow() async {
    if (_user == null) return;
    setState(() => _isLoading = true);
    try {
      if (_isFollowing) {
        await ApiService.unfollowUser(_user!.id);
      } else {
        await ApiService.followUser(_user!.id);
      }
      // Reload user profile to get updated isFollowing and follower count
      await _loadUserData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Error ${_isFollowing ? 'unfollowing' : 'following'} user: $e'),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userProvider = context.watch<UserProvider>();
    final currentUser = userProvider.user;

    // Ensure current user is loaded
    if (currentUser == null) {
      // Trigger load if not already loading
      if (!userProvider.isLoading) {
        userProvider.loadCurrentUser();
      }
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            widget.userName,
            style: GoogleFonts.poppins(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          elevation: 0,
          backgroundColor: theme.scaffoldBackgroundColor,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new,
              color: theme.colorScheme.primary,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_user == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            widget.userName,
            style: GoogleFonts.poppins(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          elevation: 0,
          backgroundColor: theme.scaffoldBackgroundColor,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new,
              color: theme.colorScheme.primary,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Text(
            'User not found',
            style: GoogleFonts.poppins(
              color: theme.colorScheme.primary,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _user!.name,
          style: GoogleFonts.poppins(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: theme.colorScheme.primary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                    backgroundImage: _user!.profileImage != null
                        ? NetworkImage(_user!.profileImage!)
                        : null,
                    child: _user!.profileImage == null
                        ? Icon(Icons.person,
                            color: theme.colorScheme.primary, size: 40)
                        : null,
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _user!.name,
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        if (_user!.bio != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            _user!.bio!,
                            style: GoogleFonts.poppins(
                              color: theme.colorScheme.primary.withOpacity(0.7),
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _buildStatColumn(
                              context,
                              _posts.length.toString(),
                              'Posts',
                            ),
                            const SizedBox(width: 24),
                            _buildStatColumn(
                              context,
                              _user!.followers.length.toString(),
                              'Followers',
                            ),
                            const SizedBox(width: 24),
                            _buildStatColumn(
                              context,
                              _user!.following.length.toString(),
                              'Following',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Follow Button
            if (currentUser != null && currentUser.id != _user!.id)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _toggleFollow,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isFollowing
                          ? theme.colorScheme.surface
                          : theme.colorScheme.primary,
                      foregroundColor: _isFollowing
                          ? theme.colorScheme.primary
                          : theme.colorScheme.surface,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(
                          color: theme.colorScheme.primary,
                          width: _isFollowing ? 1 : 0,
                        ),
                      ),
                    ),
                    child: Text(
                      _isFollowing ? 'Unfollow' : 'Follow',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 24),

            // Posts Grid
            if (_posts.isNotEmpty)
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: _posts.length,
                itemBuilder: (context, index) {
                  final post = _posts[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        '/post-detail',
                        arguments: post,
                      );
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: MediaCarousel(
                        media: post.media,
                        height: 120,
                        borderRadius: 8,
                        showIndicators: false,
                        autoPlay: true,
                      ),
                    ),
                  );
                },
              )
            else
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(
                        Iconsax.gallery,
                        size: 48,
                        color: theme.colorScheme.primary.withOpacity(0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No posts yet',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: theme.colorScheme.primary.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(BuildContext context, String count, String label) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          count,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.primary,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: theme.colorScheme.primary.withOpacity(0.7),
          ),
        ),
      ],
    );
  }
}

class _UserProfileVideoPreview extends StatefulWidget {
  final String url;
  const _UserProfileVideoPreview({required this.url});
  @override
  State<_UserProfileVideoPreview> createState() =>
      _UserProfileVideoPreviewState();
}

class _UserProfileVideoPreviewState extends State<_UserProfileVideoPreview> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.network(widget.url)
      ..initialize().then((_) {
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
      aspectRatio: _controller.value.aspectRatio > 0
          ? _controller.value.aspectRatio
          : 9 / 16,
      child: VideoPlayer(_controller),
    );
  }
}

class _UserProfileVideoPreviewGrid extends StatefulWidget {
  final String url;
  const _UserProfileVideoPreviewGrid({required this.url});
  @override
  State<_UserProfileVideoPreviewGrid> createState() =>
      _UserProfileVideoPreviewGridState();
}

class _UserProfileVideoPreviewGridState
    extends State<_UserProfileVideoPreviewGrid> {
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
