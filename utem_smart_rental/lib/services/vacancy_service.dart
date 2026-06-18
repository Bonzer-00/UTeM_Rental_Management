import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/vacancy_model.dart';

class VacancyService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Post a new vacancy
  Future<void> createVacancy(VacancyPost post) async {
    await _db.collection('vacancies').add(post.toMap());
  }

  // Get a live stream of all active vacancies
  Stream<List<VacancyPost>> getAllVacancies() {
    return _db.collection('vacancies').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => VacancyPost.fromMap(doc.data(), doc.id)).toList();
    });
  }

  // Delete a vacancy post
  Future<void> deleteVacancy(String id) async {
    await _db.collection('vacancies').doc(id).delete();
  }
}