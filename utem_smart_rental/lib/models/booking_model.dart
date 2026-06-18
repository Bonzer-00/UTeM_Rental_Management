class Booking {
  final String id;
  final String propertyId;
  final String propertyTitle;
  final String studentId;
  final String studentName;
  final DateTime date;
  final String status; 
  final int groupSize;          
  final String additionalNames; 
  final String signatureName; 
  final String tenancyLength; // <--- NEW: e.g. "12 Months"
  final String signedDate;    // <--- NEW: e.g. "15 Jun 2026"

  Booking({
    required this.id,
    required this.propertyId,
    required this.propertyTitle,
    required this.studentId,
    required this.studentName,
    required this.date,
    this.status = 'pending',
    this.groupSize = 1,         
    this.additionalNames = '',   
    this.signatureName = '', 
    this.tenancyLength = '12 Months', // Default to 12 Months
    this.signedDate = '',             // Default to empty
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
      'signatureName': signatureName,
      'tenancyLength': tenancyLength, // <--- NEW
      'signedDate': signedDate,       // <--- NEW
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
      signatureName: data['signatureName'] ?? '',
      tenancyLength: data['tenancyLength'] ?? '12 Months', // <--- NEW
      signedDate: data['signedDate'] ?? '',               // <--- NEW
    );
  }
}