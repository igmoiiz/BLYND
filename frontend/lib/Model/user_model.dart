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
    return UserModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      userName: json['userName'] ?? '',
      email: json['email'] ?? '',
      profileImage: json['profileImage'],
      bio: json['bio'],
      followers: List<String>.from(json['followers'] ?? []),
      following: List<String>.from(json['following'] ?? []),
      age: json['age'] ?? 0,
      phone: json['phone'] ?? '',
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
