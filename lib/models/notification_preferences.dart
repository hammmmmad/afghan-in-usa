/// Notification topics reserved for the future Firebase Cloud Messaging
/// integration. No Firebase service is initialized until credentials are
/// supplied by the app owner.
enum NotificationTopic {
  breakingNews,
  usImmigration,
  siv,
  p1p2,
  refugeesResettlement,
}

extension NotificationTopicValue on NotificationTopic {
  String get id {
    switch (this) {
      case NotificationTopic.breakingNews:
        return 'breaking_news';
      case NotificationTopic.usImmigration:
        return 'us_immigration';
      case NotificationTopic.siv:
        return 'siv';
      case NotificationTopic.p1p2:
        return 'p1_p2';
      case NotificationTopic.refugeesResettlement:
        return 'refugees_resettlement';
    }
  }
}

class NotificationPreferences {
  const NotificationPreferences({this.topics = const <String>{}});

  final Set<String> topics;

  bool isEnabled(String topic) => topics.contains(topic);

  NotificationPreferences copyWith({Set<String>? topics}) =>
      NotificationPreferences(topics: topics ?? this.topics);

  Map<String, dynamic> toJson() => <String, dynamic>{
        'topics': topics.toList(growable: false),
      };
}
