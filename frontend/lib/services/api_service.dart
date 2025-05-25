import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:frontend/Model/post_model.dart';
import 'package:frontend/Model/user_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ApiService {
  static const String baseUrl =
      'http://192.168.100.62:3000/api'; // Use 10.0.2.2 for Android emulator
  static String? _token;

  // Set token after login/register
  static void setToken(String token) {
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
    required Uint8List imageBytes,
  }) async {
    try {
      final supabase = Supabase.instance.client;
      final fileName = 'post_${DateTime.now().millisecondsSinceEpoch}.jpg';

      final uploadResponse =
          await supabase.storage.from('post-images').uploadBinary(
                fileName,
                imageBytes,
                fileOptions: const FileOptions(
                  contentType: 'image/jpeg',
                  upsert: true,
                ),
              );

      if (uploadResponse.isEmpty) {
        throw Exception('Failed to upload image');
      }

      final imageUrl =
          supabase.storage.from('post-images').getPublicUrl(fileName);

      final response = await http.post(
        Uri.parse('$baseUrl/posts'),
        headers: _headers,
        body: jsonEncode({
          'caption': caption,
          'postImage': imageUrl,
        }),
      );

      if (response.statusCode != 201) {
        throw Exception('Failed to create post: ${response.body}');
      }

      final data = jsonDecode(response.body);
      return PostModel.fromJson(data['post']);
    } catch (e) {
      throw Exception('Create post error: $e');
    }
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
        throw Exception('Failed to fetch user posts: ${response.body}');
      }

      final data = jsonDecode(response.body);
      return (data['posts'] as List)
          .map((post) => PostModel.fromJson(post))
          .toList();
    } catch (e) {
      throw Exception('Get user posts error: $e');
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
        throw Exception('Failed to fetch user profile: ${response.body}');
      }

      final data = jsonDecode(response.body);
      return UserModel.fromJson(data['user']);
    } catch (e) {
      throw Exception('Get user profile error: $e');
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

  static Future<void> updateProfile({
    String? name,
    String? bio,
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

      final response = await http.patch(
        Uri.parse('$baseUrl/users/me'),
        headers: _headers,
        body: jsonEncode({
          if (name != null) 'name': name,
          if (bio != null) 'bio': bio,
          if (profileImageUrl != null) 'profileImage': profileImageUrl,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to update profile: ${response.body}');
      }
    } catch (e) {
      throw Exception('Update profile error: $e');
    }
  }
}
