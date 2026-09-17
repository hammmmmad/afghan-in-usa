class UserModel {
  const UserModel({
    required this.id,
    required this.email,
    this.displayName = '',
    this.photoUrl = '',
    this.firstName = '',
    this.lastName = '',
    this.phone = '',
    this.avatarAsset = '',
  });

  final String id;
  final String email;
  final String displayName;
  final String photoUrl;
  final String firstName;
  final String lastName;
  final String phone;
  final String avatarAsset;

  bool get hasPhoto => photoUrl.trim().isNotEmpty;

  String get fullName {
    final String composed = '$firstName $lastName'.trim();
    if (composed.isNotEmpty) return composed;
    if (displayName.trim().isNotEmpty) return displayName;
    return email;
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoUrl,
    String? firstName,
    String? lastName,
    String? phone,
    String? avatarAsset,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phone: phone ?? this.phone,
      avatarAsset: avatarAsset ?? this.avatarAsset,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'email': email,
        'displayName': displayName,
        'photoUrl': photoUrl,
        'firstName': firstName,
        'lastName': lastName,
        'phone': phone,
        'avatarAsset': avatarAsset,
      };

  factory UserModel.fromJson(Map<dynamic, dynamic> json) => UserModel(
        id: (json['id'] ?? '').toString(),
        email: (json['email'] ?? '').toString(),
        displayName: (json['displayName'] ?? '').toString(),
        photoUrl: (json['photoUrl'] ?? '').toString(),
        firstName: (json['firstName'] ?? '').toString(),
        lastName: (json['lastName'] ?? '').toString(),
        phone: (json['phone'] ?? '').toString(),
        avatarAsset: (json['avatarAsset'] ?? '').toString(),
      );
}

class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.caseId,
    required this.createdAt,
    this.read = false,
  });

  final String id;
  final Map<String, String> title;
  final Map<String, String> body;
  final String caseId;
  final DateTime createdAt;
  final bool read;

  String localizedTitle(String languageCode) =>
      title[languageCode] ?? title['fa'] ?? title['en'] ?? '';

  String localizedBody(String languageCode) =>
      body[languageCode] ?? body['fa'] ?? body['en'] ?? '';

  AppNotification copyWith({bool? read}) => AppNotification(
        id: id,
        title: title,
        body: body,
        caseId: caseId,
        createdAt: createdAt,
        read: read ?? this.read,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'title': title,
        'body': body,
        'caseId': caseId,
        'createdAt': createdAt.toIso8601String(),
        'read': read,
      };

  factory AppNotification.fromJson(Map<dynamic, dynamic> json) =>
      AppNotification(
        id: (json['id'] ?? '').toString(),
        title: _localizedMap(json['title']),
        body: _localizedMap(json['body']),
        caseId: (json['caseId'] ?? '').toString(),
        createdAt: DateTime.tryParse((json['createdAt'] ?? '').toString()) ??
            DateTime.now(),
        read: (json['read'] ?? false) == true,
      );

  static Map<String, String> _localizedMap(Object? value) {
    if (value is Map) {
      return <String, String>{
        'fa': (value['fa'] ?? '').toString(),
        'en': (value['en'] ?? '').toString(),
      };
    }
    final String legacy = value?.toString() ?? '';
    return <String, String>{'fa': legacy, 'en': legacy};
  }
}
