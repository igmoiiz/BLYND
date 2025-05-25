class UserModel {
  final String id;
  final String name;
  final String userName;
  final String email;
  final String? profileImage;
  final String? bio;
  final List<String> followers;
  final List<String> following;
  final int age;
  final String phone;

  UserModel({
    required this.id,
    required this.name,
    required this.userName,
    required this.email,
    this.profileImage,
    this.bio,
    this.followers = const [],
    this.following = const [],
    required this.age,
    required this.phone,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'userName': userName,
      'email': email,
      'profileImage': profileImage,
      'bio': bio,
      'followers': followers,
      'following': following,
      'age': age,
      'phone': phone,
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    // Handle MongoDB _id field
    String userId = '';
    if (json['_id'] != null) {
      userId = json['_id'].toString();
    } else if (json['id'] != null) {
      userId = json['id'].toString();
    }

    // Convert followers and following IDs to strings
    List<String> followersList = [];
    if (json['followers'] != null) {
      followersList =
          (json['followers'] as List).map((id) => id.toString()).toList();
    }

    List<String> followingList = [];
    if (json['following'] != null) {
      followingList =
          (json['following'] as List).map((id) => id.toString()).toList();
    }

    return UserModel(
      id: userId,
      name: json['name']?.toString() ?? '',
      userName: json['userName']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      profileImage: json['profileImage']?.toString(),
      bio: json['bio']?.toString(),
      followers: followersList,
      following: followingList,
      age: json['age'] is String ? int.parse(json['age']) : (json['age'] ?? 0),
      phone: json['phone']?.toString() ?? '',
    );
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? userName,
    String? email,
    String? profileImage,
    String? bio,
    List<String>? followers,
    List<String>? following,
    int? age,
    String? phone,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      userName: userName ?? this.userName,
      email: email ?? this.email,
      profileImage: profileImage ?? this.profileImage,
      bio: bio ?? this.bio,
      followers: followers ?? this.followers,
      following: following ?? this.following,
      age: age ?? this.age,
      phone: phone ?? this.phone,
    );
  }
}
