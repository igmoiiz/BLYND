import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:frontend/models/post_model.dart';
import 'package:frontend/services/api_service.dart';

class PostProvider extends ChangeNotifier {
  List<PostModel> _posts = [];
  bool _isLoading = false;
  String? _error;
  int _currentPage = 1;
  bool _hasMore = true;

  List<PostModel> get posts => _posts;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasMore => _hasMore;

  Future<void> loadPosts({bool refresh = false}) async {
    if (_isLoading || (!refresh && !_hasMore)) return;

    try {
      _isLoading = true;
      notifyListeners();

      if (refresh) {
        _currentPage = 1;
        _hasMore = true;
      }

      final newPosts = await ApiService.getPosts(page: _currentPage);

      // Log post image URLs for debugging
      for (var post in newPosts) {
        debugPrint('Post ${post.postId} image URL: ${post.postImage}');
      }

      if (refresh) {
        _posts = newPosts;
      } else {
        _posts = [..._posts, ...newPosts];
      }

      _currentPage++;
      _hasMore = newPosts.isNotEmpty;
    } catch (e) {
      debugPrint('Error loading posts: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createPost({
    required String caption,
    required List<int> imageBytes,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      final newPost = await ApiService.createPost(
        caption: caption,
        imageBytes: Uint8List.fromList(imageBytes),
      );

      // Log new post image URL for debugging
      debugPrint('New post ${newPost.postId} image URL: ${newPost.postImage}');

      _posts.insert(0, newPost);
    } catch (e) {
      debugPrint('Error creating post: $e');
      rethrow;
    } finally {
      _isLoading = false;
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
        _posts[index] = _posts[index].copyWith(
          comments: updatedPost.comments,
        );
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error adding comment: $e');
      rethrow;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
