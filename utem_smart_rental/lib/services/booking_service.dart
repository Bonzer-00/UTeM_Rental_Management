import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/booking_model.dart';

class BookingService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Create a new booking
  Future<void> createBooking(Booking booking) async {
    await _db.collection('bookings').add(booking.toMap());
  }

  // Get bookings for a Homeowner (filtered by property owner)
  // For simplicity in this prototype, we'll fetch all and filter locally 
  // or you can add 'homeownerId' to the Booking model later.
  Stream<List<Booking>> getBookingsForProperty(String propertyId) {
    return _db
        .collection('bookings')
        .where('propertyId', isEqualTo: propertyId)
        .snapshots()
        .map((snaps) => snaps.docs.map((doc) => Booking.fromMap(doc.data(), doc.id)).toList());
  }

  // Update status (Approve/Reject)
  Future<void> updateBookingStatus(String id, String status) async {
    await _db.collection('bookings').doc(id).update({'status': status});
  }
}