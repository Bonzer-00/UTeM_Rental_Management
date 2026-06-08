class AppNotification {
  final String id;
  final String userId; // The person receiving the notification
  final String title;
  final String message;
  final DateTime timestamp;
  final bool isRead;

  AppNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.timestamp,
    this.isRead = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
    };
  }

  factory AppNotification.fromMap(Map<String, dynamic> data, String documentId) {
    return AppNotification(
      id: documentId,
      userId: data['userId'] ?? '',
      title: data['title'] ?? '',
      message: data['message'] ?? '',
      timestamp: DateTime.parse(data['timestamp']),
      isRead: data['isRead'] ?? false,
    );
  }
}