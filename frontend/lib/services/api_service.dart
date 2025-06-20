// ignore_for_file: depend_on_referenced_packages

import 'dart:convert';
import 'dart:developer';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:frontend/models/post_model.dart';
import 'package:frontend/models/user_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:http_parser/http_parser.dart';
import 'package:file_picker/file_picker.dart';

class ApiService {
  static const String baseUrl =
      'https://blynd-backend-production.up.railway.app/api'; // Use 10.0.2.2 for Android emulator
  static String? _token;

  // Set token after login/register
  static void setToken(String? token) {
    _token = token;
  }

  static Map<String, String> get _headers {
    return {
      'Content-Type': 'application/json',
      if (_token != null) 'Authorization': 'Bearer $_token',
    };
  }

  // Authentication
  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String userName,
    required int age,
    required String phone,
    Uint8List? profileImage,
  }) async {
    try {
      String? profileImageUrl;

      if (profileImage != null) {
        final supabase = Supabase.instance.client;
        final fileName = 'user_${DateTime.now().millisecondsSinceEpoch}.jpg';

        final uploadResponse =
            await supabase.storage.from('user-images').uploadBinary(
                  fileName,
                  profileImage,
                  fileOptions: const FileOptions(
                    contentType: 'image/jpeg',
                    upsert: true,
                  ),
                );

        if (uploadResponse.isNotEmpty) {
          profileImageUrl =
              supabase.storage.from('user-images').getPublicUrl(fileName);
        }
      }

      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
          'userName': userName,
          'age': age,
          'phone': phone,
          'profileImage': profileImageUrl,
        }),
      );

      if (response.statusCode != 201) {
        throw Exception('Registration failed: ${response.body}');
      }

      return jsonDecode(response.body);
    } catch (e) {
      throw Exception('Registration error: $e');
    }
  }

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode != 200) {
        throw Exception('Login failed: ${response.body}');
      }

      final data = jsonDecode(response.body);
      if (data['token'] != null) {
        setToken(data['token']);
      }

      return data;
    } catch (e) {
      throw Exception('Login error: $e');
    }
  }

  // Posts
  static Future<PostModel> createPost({
    required String caption,
    required PlatformFile mediaFile,
  }) async {
    final uri = Uri.parse('$baseUrl/posts');
    final request = http.MultipartRequest('POST', uri);

    if (_token != null) {
      request.headers['Authorization'] = 'Bearer $_token';
    }

    request.fields['caption'] = caption;

    // Detect content type
    String? ext = mediaFile.extension?.toLowerCase();
    MediaType contentType;
    if (ext == 'jpg' || ext == 'jpeg') {
      contentType = MediaType('image', 'jpeg');
    } else if (ext == 'png') {
      contentType = MediaType('image', 'png');
    } else if (ext == 'mp4') {
      contentType = MediaType('video', 'mp4');
    } else if (ext == 'mov') {
      contentType = MediaType('video', 'quicktime');
    } else if (ext == 'webm') {
      contentType = MediaType('video', 'webm');
    } else {
      contentType = MediaType('application', 'octet-stream');
    }

    request.files.add(
      http.MultipartFile.fromBytes(
        'media',
        mediaFile.bytes!,
        filename: mediaFile.name,
        contentType: contentType,
      ),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode != 201) {
      throw Exception('Failed to create post: \\n${response.body}');
    }

    final data = jsonDecode(response.body);
    return PostModel.fromJson(data['post']);
  }

  static Future<List<PostModel>> getPosts({int page = 1}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/posts?page=$page'),
        headers: _headers,
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to fetch posts: ${response.body}');
      }

      final data = jsonDecode(response.body);
      return (data['posts'] as List)
          .map((post) => PostModel.fromJson(post))
          .toList();
    } catch (e) {
      throw Exception('Get posts error: $e');
    }
  }

  static Future<List<PostModel>> getUserPosts(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/posts/user/$userId'),
        headers: _headers,
      );
      if (response.statusCode != 200) {
        throw Exception('Failed to get user posts: ${response.body}');
      }
      final data = jsonDecode(response.body);
      return (data['posts'] as List)
          .map((post) => PostModel.fromJson(post))
          .toList();
    } catch (e) {
      throw Exception('Error getting user posts: $e');
    }
  }

  static Future<PostModel> likePost(String postId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/posts/$postId/like'),
        headers: _headers,
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to like/unlike post: ${response.body}');
      }

      final data = jsonDecode(response.body);
      return PostModel.fromJson(data['post']);
    } catch (e) {
      throw Exception('Like post error: $e');
    }
  }

  static Future<PostModel> commentOnPost({
    required String postId,
    required String text,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/posts/$postId/comment'),
        headers: _headers,
        body: jsonEncode({'text': text}),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to add comment: ${response.body}');
      }

      final data = jsonDecode(response.body);
      return PostModel.fromJson(data['post']);
    } catch (e) {
      throw Exception('Comment on post error: $e');
    }
  }

  static Future<void> deletePost(String postId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/posts/$postId'),
        headers: _headers,
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to delete post: ${response.body}');
      }
    } catch (e) {
      throw Exception('Delete post error: $e');
    }
  }

  // User Profile
  static Future<UserModel> getCurrentUser() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/auth/me'),
        headers: _headers,
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to fetch current user: ${response.body}');
      }

      final data = jsonDecode(response.body);
      return UserModel.fromJson(data['user']);
    } catch (e) {
      throw Exception('Get current user error: $e');
    }
  }

  static Future<UserModel> getUserProfile(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users/$userId'),
        headers: _headers,
      );
      if (response.statusCode != 200) {
        throw Exception('Failed to get user profile: ${response.body}');
      }
      final data = jsonDecode(response.body);
      return UserModel.fromJson(data['user']);
    } catch (e) {
      throw Exception('Error getting user profile: $e');
    }
  }

  static Future<UserModel> toggleFollow(String userId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users/$userId/follow'),
        headers: _headers,
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to toggle follow: ${response.body}');
      }

      final data = jsonDecode(response.body);
      return UserModel.fromJson(data['user']);
    } catch (e) {
      throw Exception('Toggle follow error: $e');
    }
  }

  static Future<UserModel> updateProfile({
    String? name,
    String? bio,
    Uint8List? profileImage,
  }) async {
    try {
      String? profileImageUrl;

      if (profileImage != null) {
        log('Uploading profile image to Supabase...');

        final supabase = Supabase.instance.client;
        final fileName = 'user_${DateTime.now().millisecondsSinceEpoch}.jpg';

        // Upload image to Supabase
        final uploadResponse =
            await supabase.storage.from('user-images').uploadBinary(
                  fileName,
                  profileImage,
                  fileOptions: const FileOptions(
                    contentType: 'image/jpeg',
                    upsert: true,
                  ),
                );

        if (uploadResponse.isEmpty) {
          throw Exception('Failed to upload image to Supabase');
        }

        log('Upload response path: $uploadResponse');

        // Get the public URL for the uploaded image
        final publicUrl =
            supabase.storage.from('user-images').getPublicUrl(fileName);

        log('Generated profile image URL: $publicUrl');
        profileImageUrl = publicUrl;
      }

      // Create request body
      final requestBody = jsonEncode({
        if (name != null) 'name': name,
        if (bio != null) 'bio': bio,
        if (profileImageUrl != null) 'profileImage': profileImageUrl,
      });

      log('Sending update profile request with body: $requestBody');

      final response = await http.put(
        Uri.parse('$baseUrl/users/profile'),
        headers: _headers,
        body: requestBody,
      );

      log('Update profile response: ${response.body}');

      if (response.statusCode != 200) {
        throw Exception('Failed to update profile: ${response.body}');
      }

      final data = jsonDecode(response.body);
      return UserModel.fromJson(data['user']);
    } catch (e) {
      log('Update profile error: $e');
      throw Exception('Update profile error: $e');
    }
  }

  static Future<void> logout() async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/logout'),
        headers: _headers,
      );

      if (response.statusCode != 200) {
        throw Exception('Logout failed: ${response.body}');
      }
    } finally {
      // Clear token even if the request fails
      setToken(null);
    }
  }

  static Future<void> deleteAccount() async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/users/me'),
        headers: _headers,
      );
      if (response.statusCode != 200) {
        throw Exception('Failed to delete account');
      }
    } catch (e) {
      throw Exception('Error deleting account: $e');
    }
  }

  static Future<void> followUser(String userId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users/follow/$userId'),
        headers: _headers,
      );
      if (response.statusCode != 200) {
        throw Exception('Failed to follow user: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error following user: $e');
    }
  }

  static Future<void> unfollowUser(String userId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users/unfollow/$userId'),
        headers: _headers,
      );
      if (response.statusCode != 200) {
        throw Exception('Failed to unfollow user: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error unfollowing user: $e');
    }
  }

  static Future<List<UserModel>> searchUsers(String query) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users?search=$query'),
        headers: _headers,
      );
      if (response.statusCode != 200) {
        throw Exception('Failed to search users: ${response.body}');
      }
      final data = jsonDecode(response.body);
      return (data['users'] as List)
          .map((user) => UserModel.fromJson(user))
          .toList();
    } catch (e) {
      throw Exception('Error searching users: $e');
    }
  }

  static Future<Map<String, dynamic>> checkUsernameAvailability(
      String username) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/auth/check-username/$username'),
        headers: _headers,
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to check username: ${response.body}');
      }

      return jsonDecode(response.body);
    } catch (e) {
      throw Exception('Error checking username: $e');
    }
  }

  static String? get token => _token;
}
