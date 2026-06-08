import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/notification_model.dart';

class NotificationService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  
  // --- NEW: System Notification Plugin ---
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

// Initialize the system notifications
  static Future<void> initializeSystemNotifications() async {
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings settings = InitializationSettings(android: androidSettings);
    
    // Some versions use positional, some use named. If your change worked, keep it, but this is the standard new syntax:
    await _localNotifications.initialize(settings: settings);

    _localNotifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission();
  }

  // Trigger the actual phone vibration and banner
  static Future<void> showSystemBanner(String title, String body) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'utem_rental_channel', 
      'UTeM Rental Notifications', 
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );
    
    const NotificationDetails details = NotificationDetails(android: androidDetails);
    
    // --- THE FIX: Using Named Parameters ---
    await _localNotifications.show(
      id: DateTime.now().millisecond, // Required named parameter
      title: title,                   // Required named parameter
      body: body,                     // Required named parameter
      notificationDetails: details,   // Required named parameter
    );
  }

  // --- EXISTING FIREBASE LOGIC ---
  Future<void> sendNotification(String userId, String title, String message) async {
    await _db.collection('notifications').add({
      'userId': userId,
      'title': title,
      'message': message,
      'timestamp': DateTime.now().toIso8601String(),
      'isRead': false,
    });
  }

  Stream<List<AppNotification>> getUserNotifications(String userId) {
    return _db.collection('notifications')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          var notifications = snapshot.docs.map((doc) => AppNotification.fromMap(doc.data(), doc.id)).toList();
          notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));
          return notifications;
        });
  }

  Future<void> markAsRead(String notificationId) async {
    await _db.collection('notifications').doc(notificationId).update({'isRead': true});
  }

  // --- NEW: Automatically find all Admins and notify them ---
  Future<void> sendNotificationToAdmins(String title, String message) async {
    try {
      // Find all users where role is Admin
      var adminQuery = await _db.collection('users').where('role', isEqualTo: 'Admin').get();
      
      for (var doc in adminQuery.docs) {
        // Send a notification to each Admin UID found
        await sendNotification(doc.id, title, message);
      }
    } catch (e) {
      print("Error sending admin notification: $e");
    }
  }
}