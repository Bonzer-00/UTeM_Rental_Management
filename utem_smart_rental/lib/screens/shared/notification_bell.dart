import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'notifications_screen.dart';
import '../../services/notification_service.dart';
import '../../utils/constants.dart';

class NotificationBell extends StatefulWidget {
  const NotificationBell({super.key});

  @override
  State<NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends State<NotificationBell> {
  final user = FirebaseAuth.instance.currentUser;
  StreamSubscription? _notificationSubscription;
  bool _isFirstLoad = true; // Prevents buzzing for old messages when you open the app

  @override
  void initState() {
    super.initState();
    _startSystemNotificationListener();
  }

  void _startSystemNotificationListener() {
    if (user == null) return;

    // Listen to Firebase quietly in the background
    _notificationSubscription = FirebaseFirestore.instance
        .collection('notifications')
        .where('userId', isEqualTo: user?.uid)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .listen((snapshot) {
          
      // Skip the first load so it doesn't buzz 5 times when you log in
      if (_isFirstLoad) {
        _isFirstLoad = false;
        return;
      }

      // Check if a NEW document was added to the database
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final data = change.doc.data() as Map<String, dynamic>;
          // Trigger the Android System Banner!
          NotificationService.showSystemBanner(data['title'], data['message']);
        }
      }
    });
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) return const SizedBox.shrink();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('notifications').where('userId', isEqualTo: user?.uid).where('isRead', isEqualTo: false).snapshots(),
      builder: (context, snapshot) {
        int unreadCount = snapshot.hasData ? snapshot.data!.docs.length : 0;

        return Stack(
          alignment: Alignment.center,
          children:[
            IconButton(
              icon: const Icon(Icons.notifications_outlined, color: textDark),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen())),
            ),
            if (unreadCount > 0)
              Positioned(
                top: 10, right: 10,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle, border: Border.all(color: backgroundLight, width: 1.5)),
                  constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                  child: Text(unreadCount > 9 ? '9+' : unreadCount.toString(), style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                ),
              ),
          ],
        );
      },
    );
  }
}