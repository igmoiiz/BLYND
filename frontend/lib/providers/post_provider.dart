import 'package:flutter/material.dart';
import 'package:frontend/models/post_model.dart';
import 'package:frontend/services/api_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:file_picker/file_picker.dart';

class PostProvider extends ChangeNotifier {
  List<PostModel> _posts = [];
  bool _isLoading = false;
  String? _error;
  int _currentPage = 1;
  bool _hasMore = true;
  DateTime? _lastRefreshTime;
  static const _refreshInterval = Duration(minutes: 5);

  List<PostModel> get posts => _posts;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasMore => _hasMore;

  // Add new post to the feed
  void addNewPost(PostModel post) {
    _posts.insert(0, post);
    notifyListeners();
  }

  // Check if we need to refresh based on time
  bool _shouldRefresh() {
    if (_lastRefreshTime == null) return true;
    return DateTime.now().difference(_lastRefreshTime!) > _refreshInterval;
  }

  Future<void> loadPosts({bool refresh = false}) async {
    if (_isLoading || (!refresh && !_hasMore)) return;

    try {
      _isLoading = true;
      _error = null;
      // Don't notify listeners here to avoid build-time updates

      if (refresh) {
        _currentPage = 1;
        _hasMore = true;
        _lastRefreshTime = DateTime.now();
      }

      final newPosts = await ApiService.getPosts(page: _currentPage);

      if (refresh) {
        _posts = newPosts;
      } else {
        // Merge new posts with existing ones, avoiding duplicates
        final existingIds = _posts.map((p) => p.postId).toSet();
        final uniqueNewPosts =
            newPosts.where((p) => !existingIds.contains(p.postId)).toList();
        _posts = [..._posts, ...uniqueNewPosts];
      }

      _currentPage++;
      _hasMore = newPosts.isNotEmpty;
    } catch (e) {
      debugPrint('Error loading posts: $e');
      _error = e.toString();
    } finally {
      _isLoading = false;
      // Notify listeners after all state changes are complete
      notifyListeners();
    }
  }

  Future<void> createPost({
    required String caption,
    required PlatformFile mediaFile,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      // Don't notify listeners here to avoid build-time updates

      final newPost = await ApiService.createPost(
        caption: caption,
        mediaFile: mediaFile,
      );

      // Add the new post to the beginning of the list
      _posts.insert(0, newPost);
    } catch (e) {
      debugPrint('Error creating post: $e');
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      // Notify listeners after all state changes are complete
      notifyListeners();
    }
  }

  Future<void> likePost(String postId) async {
    try {
      final updatedPost = await ApiService.likePost(postId);
      final index = _posts.indexWhere((p) => p.postId == postId);
      if (index != -1) {
        _posts[index] = updatedPost;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error liking post: $e');
      _error = e.toString();
      rethrow;
    }
  }

  Future<void> addComment({
    required String postId,
    required String text,
  }) async {
    try {
      final updatedPost = await ApiService.commentOnPost(
        postId: postId,
        text: text,
      );
      final index = _posts.indexWhere((p) => p.postId == postId);
      if (index != -1) {
        _posts[index] = updatedPost;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error adding comment: $e');
      _error = e.toString();
      rethrow;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
