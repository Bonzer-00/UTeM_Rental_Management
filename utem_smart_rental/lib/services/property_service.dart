import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/property_model.dart';
import 'notification_service.dart';

class PropertyService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Add a new property
  Future<void> addProperty(Property property) async {
    await _db.collection('properties').add(property.toMap());
    // Send notification to admins
    await NotificationService().sendNotificationToAdmins('New Property Added', '${property.title} has been listed in ${property.location}.'
    );
  }

  Future<void> updateProperty(String propertyId, Property property) async {
  await _db.collection('properties').doc(propertyId).update(property.toMap());
}

  // Delete a property
  Future<void> deleteProperty(String propertyId) async {
    await _db.collection('properties').doc(propertyId).delete();
  }

  // Get a LIVE stream of properties for a specific homeowner
  Stream<List<Property>> getHomeownerProperties(String homeownerId) {
    return _db
        .collection('properties')
        .where('homeownerId', isEqualTo: homeownerId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Property.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Get a LIVE stream of ALL available properties
  Stream<List<Property>> getAllProperties() {
    return _db
        .collection('properties')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Property.fromMap(doc.data(), doc.id))
            .toList());
  }
}
