import 'package:equatable/equatable.dart';

enum NotificationType {
  bill,
  budget,
  goal,
  reminder,
  system;

  static NotificationType fromString(String val) {
    return NotificationType.values.firstWhere(
      (e) => e.name.toLowerCase() == val.toLowerCase(),
      orElse: () => NotificationType.system,
    );
  }
}

class AppNotificationModel extends Equatable {
  final String id;
  final String title;
  final String description;
  final DateTime timestamp;
  final NotificationType type;
  final bool isRead;
  final String? actionRoute;
  final String userEmail;

  const AppNotificationModel({
    required this.id,
    required this.title,
    required this.description,
    required this.timestamp,
    this.type = NotificationType.system,
    this.isRead = false,
    this.actionRoute,
    required this.userEmail,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'timestamp': timestamp.toIso8601String(),
      'type': type.name,
      'isRead': isRead ? 1 : 0,
      'actionRoute': actionRoute,
      'userEmail': userEmail,
    };
  }

  factory AppNotificationModel.fromMap(Map<String, dynamic> map) {
    return AppNotificationModel(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      timestamp: DateTime.parse(map['timestamp'] as String),
      type: NotificationType.fromString(map['type'] as String? ?? 'system'),
      isRead: (map['isRead'] as int? ?? 0) == 1,
      actionRoute: map['actionRoute'] as String?,
      userEmail: map['userEmail'] as String? ?? '',
    );
  }

  AppNotificationModel copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? timestamp,
    NotificationType? type,
    bool? isRead,
    String? actionRoute,
    String? userEmail,
  }) {
    return AppNotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      timestamp: timestamp ?? this.timestamp,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
      actionRoute: actionRoute ?? this.actionRoute,
      userEmail: userEmail ?? this.userEmail,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        timestamp,
        type,
        isRead,
        actionRoute,
        userEmail,
      ];
}
