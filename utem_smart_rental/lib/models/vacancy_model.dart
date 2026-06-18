class VacancyPost {
  final String id;
  final String studentId;
  final String studentName;
  final String propertyId;
  final String propertyTitle;
  final int vacantSlots;
  final double price;
  final String description;

  VacancyPost({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.propertyId,
    required this.propertyTitle,
    required this.vacantSlots,
    required this.price,
    required this.description,
  });

  Map<String, dynamic> toMap() {
    return {
      'studentId': studentId,
      'studentName': studentName,
      'propertyId': propertyId,
      'propertyTitle': propertyTitle,
      'vacantSlots': vacantSlots,
      'price': price,
      'description': description,
    };
  }

  factory VacancyPost.fromMap(Map<String, dynamic> data, String documentId) {
    return VacancyPost(
      id: documentId,
      studentId: data['studentId'] ?? '',
      studentName: data['studentName'] ?? '',
      propertyId: data['propertyId'] ?? '',
      propertyTitle: data['propertyTitle'] ?? '',
      vacantSlots: data['vacantSlots'] ?? 1,
      price: (data['price'] ?? 0).toDouble(),
      description: data['description'] ?? '',
    );
  }
}