class Message {
  final String senderId;
  final String text;
  final DateTime timestamp;
  final String type; // 'text', 'contract', or 'contract_signed' <--- NEW
  final String? bookingId; // <--- NEW: Links the chat message directly to the Firestore booking

  Message({
    required this.senderId,
    required this.text,
    required this.timestamp,
    this.type = 'text', // Default to text
    this.bookingId,
  });

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'text': text,
      'timestamp': timestamp.toIso8601String(),
      'type': type,
      'bookingId': bookingId,
    };
  }

  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
      senderId: map['senderId'] ?? '',
      text: map['text'] ?? '',
      timestamp: DateTime.parse(map['timestamp']),
      type: map['type'] ?? 'text',
      bookingId: map['bookingId'],
    );
  }
}