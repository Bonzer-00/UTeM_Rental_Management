class Booking {
  final String id;
  final String propertyId;
  final String propertyTitle;
  final String studentId;
  final String studentName;
  final DateTime date;
  final String status; // pending, approved, rejected
  final int groupSize;          // Added this
  final String additionalNames; // Added this

  Booking({
    required this.id,
    required this.propertyId,
    required this.propertyTitle,
    required this.studentId,
    required this.studentName,
    required this.date,
    this.status = 'pending',
    this.groupSize = 1,         // Default to 1
    this.additionalNames = '',   // Default to empty string
  });

  Map<String, dynamic> toMap() {
    return {
      'propertyId': propertyId,
      'propertyTitle': propertyTitle,
      'studentId': studentId,
      'studentName': studentName,
      'date': date.toIso8601String(),
      'status': status,
      'groupSize': groupSize,
      'additionalNames': additionalNames,
    };
  }

  factory Booking.fromMap(Map<String, dynamic> data, String documentId) {
    return Booking(
      id: documentId,
      propertyId: data['propertyId'] ?? '',
      propertyTitle: data['propertyTitle'] ?? '',
      studentId: data['studentId'] ?? '',
      studentName: data['studentName'] ?? '',
      date: DateTime.parse(data['date']),
      status: data['status'] ?? 'pending',
      groupSize: data['groupSize'] ?? 1,
      additionalNames: data['additionalNames'] ?? '',
    );
  }
}