class CommentModel {
  final String userId;
  final String userName;
  final String? userProfileImage;
  final String text;
  final DateTime createdAt;

  CommentModel({
    required this.userId,
    required this.userName,
    this.userProfileImage,
    required this.text,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'userName': userName,
      'userProfileImage': userProfileImage,
      'text': text,
      'createdAt': createdAt.toUtc().toIso8601String(),
    };
  }

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    return CommentModel(
      userId: json['userId'],
      userName: json['userName'],
      userProfileImage: json['userProfileImage'],
      text: json['text'],
      createdAt: DateTime.parse(json['createdAt']).toUtc(),
    );
  }
}

class MediaItem {
  final String url;
  final String type; // 'image' or 'video'

  MediaItem({required this.url, required this.type});

  factory MediaItem.fromJson(Map<String, dynamic> json) {
    return MediaItem(
      url: json['url'],
      type: json['type'],
    );
  }

  Map<String, dynamic> toJson() => {
        'url': url,
        'type': type,
      };
}

class PostModel {
  final String postId;
  final String userEmail;
  final String userId;
  final String userName;
  final String? userProfileImage;
  final String caption;
  final List<MediaItem> media;
  final int likeCount;
  final List<String> likedBy;
  final List<CommentModel> comments;
  final DateTime createdAt;

  PostModel({
    required this.postId,
    required this.userEmail,
    required this.userId,
    required this.userName,
    this.userProfileImage,
    required this.caption,
    this.media = const [],
    this.likeCount = 0,
    this.likedBy = const [],
    this.comments = const [],
    required this.createdAt,
  });

  bool get hasMedia => media.isNotEmpty;
  bool get hasUserImage =>
      userProfileImage != null && userProfileImage!.isNotEmpty;
  bool isLikedByUser(String userId) => likedBy.contains(userId);

  Map<String, dynamic> toJson() {
    return {
      'postId': postId,
      'userEmail': userEmail,
      'userId': userId,
      'userName': userName,
      'userProfileImage': userProfileImage,
      'caption': caption,
      'media': media.map((m) => m.toJson()).toList(),
      'likeCount': likeCount,
      'likedBy': likedBy,
      'comments': comments.map((comment) => comment.toJson()).toList(),
      'createdAt': createdAt.toUtc().toIso8601String(),
    };
  }

  factory PostModel.fromJson(Map<String, dynamic> json) {
    return PostModel(
      postId: json['postId'] ?? '',
      userEmail: json['userEmail'] ?? '',
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? '',
      userProfileImage: json['userProfileImage'],
      caption: json['caption'] ?? '',
      media: (json['media'] as List?)
              ?.map((m) => MediaItem.fromJson(m))
              .toList() ??
          [],
      likeCount: json['likeCount'] ?? 0,
      likedBy: List<String>.from(json['likedBy'] ?? []),
      comments: (json['comments'] as List?)
              ?.map((comment) => CommentModel.fromJson(comment))
              .toList() ??
          [],
      createdAt: DateTime.parse(
              json['createdAt'] ?? DateTime.now().toUtc().toIso8601String())
          .toUtc(),
    );
  }

  PostModel copyWith({
    String? postId,
    String? userEmail,
    String? userId,
    String? userName,
    String? userProfileImage,
    String? caption,
    List<MediaItem>? media,
    int? likeCount,
    List<String>? likedBy,
    List<CommentModel>? comments,
    DateTime? createdAt,
  }) {
    return PostModel(
      postId: postId ?? this.postId,
      userEmail: userEmail ?? this.userEmail,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userProfileImage: userProfileImage ?? this.userProfileImage,
      caption: caption ?? this.caption,
      media: media ?? this.media,
      likeCount: likeCount ?? this.likeCount,
      likedBy: likedBy ?? this.likedBy,
      comments: comments ?? this.comments,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
