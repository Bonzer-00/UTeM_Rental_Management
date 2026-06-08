class Message {
  final String senderId;
  final String text;
  final DateTime timestamp;

  Message({
    required this.senderId,
    required this.text,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'text': text,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
      senderId: map['senderId'] ?? '',
      text: map['text'] ?? '',
      timestamp: DateTime.parse(map['timestamp']),
    );
  }
}