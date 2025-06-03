// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/models/post_model.dart';
import 'package:frontend/models/user_model.dart';
import 'package:iconsax/iconsax.dart';
import 'package:frontend/View/Interface/Profile/user_profile_page.dart';
import 'package:frontend/View/Interface/Feed/post_detail_page.dart';
import 'package:video_player/video_player.dart';
import 'package:frontend/utils/Components/media_carousel.dart';

enum ExploreTab { posts, users }

class ExplorePage extends StatefulWidget {
  const ExplorePage({super.key});

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  final TextEditingController _searchController = TextEditingController();
  List<PostModel> _posts = [];
  List<UserModel> _users = [];
  bool _isLoading = true;
  bool _isSearching = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadExplorePosts();
  }

  Future<void> _loadExplorePosts() async {
    setState(() => _isLoading = true);
    try {
      final posts =
          await ApiService.getPosts(page: 1); // Get random/recent posts
      setState(() {
        _posts = posts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading posts: $e')),
      );
    }
  }

  Future<void> _searchUsers(String query) async {
    setState(() {
      _isSearching = true;
      _searchQuery = query;
    });
    try {
      final users = await ApiService.searchUsers(query);
      setState(() {
        _users = users;
        _isSearching = false;
      });
    } catch (e) {
      setState(() => _isSearching = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error searching users: $e')),
      );
    }
  }

  Widget _buildPostGridItem(
      PostModel post, BuildContext context, ThemeData theme) {
    return MediaCarousel(
      media: post.media,
      height: 120,
      borderRadius: 8,
      showIndicators: false,
      autoPlay: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('Explore',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                if (value.trim().isEmpty) {
                  setState(() {
                    _users = [];
                    _searchQuery = '';
                  });
                } else {
                  _searchUsers(value.trim());
                }
              },
              decoration: InputDecoration(
                hintText: 'Search users...',
                prefixIcon: const Icon(Iconsax.search_normal),
                filled: true,
                fillColor: theme.colorScheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
              ),
            ),
          ),
          if (_searchQuery.isNotEmpty)
            Expanded(
              child: _isSearching
                  ? const Center(child: CircularProgressIndicator())
                  : _users.isEmpty
                      ? Center(
                          child: Text('No users found',
                              style: GoogleFonts.poppins()))
                      : ListView.separated(
                          itemCount: _users.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final user = _users[index];
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundImage: user.profileImage != null &&
                                        user.profileImage!.isNotEmpty
                                    ? NetworkImage(user.profileImage!)
                                    : null,
                                child: (user.profileImage == null ||
                                        user.profileImage!.isEmpty)
                                    ? const Icon(Icons.person)
                                    : null,
                              ),
                              title: Text(user.userName,
                                  style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600)),
                              subtitle:
                                  Text(user.name, style: GoogleFonts.poppins()),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => UserProfilePage(
                                      userId: user.id,
                                      userName: user.userName,
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
            ),
          if (_searchQuery.isEmpty)
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _posts.isEmpty
                      ? Center(
                          child: Text('No posts to show',
                              style: GoogleFonts.poppins()))
                      : GridView.builder(
                          padding: const EdgeInsets.all(8),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 4,
                            mainAxisSpacing: 4,
                          ),
                          itemCount: _posts.length,
                          itemBuilder: (context, index) {
                            final post = _posts[index];
                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        PostDetailPage(post: post),
                                  ),
                                );
                              },
                              child: _buildPostGridItem(post, context, theme),
                            );
                          },
                        ),
            ),
        ],
      ),
    );
  }
}

class _ExploreVideoPreview extends StatefulWidget {
  final String url;
  const _ExploreVideoPreview({required this.url});
  @override
  State<_ExploreVideoPreview> createState() => _ExploreVideoPreviewState();
}

class _ExploreVideoPreviewState extends State<_ExploreVideoPreview> {
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
