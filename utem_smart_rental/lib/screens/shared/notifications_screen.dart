import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/notification_model.dart';
import '../../services/notification_service.dart';
import '../../utils/constants.dart';
import 'package:intl/intl.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final String currentUserId = FirebaseAuth.instance.currentUser!.uid;
    final NotificationService notifService = NotificationService();

    return Scaffold(
      backgroundColor: backgroundLight,
      appBar: AppBar(
        backgroundColor: backgroundLight,
        elevation: 0,
        iconTheme: const IconThemeData(color: textDark),
        title: const Text("Notifications", style: TextStyle(color: textDark, fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      body: StreamBuilder<List<AppNotification>>(
        stream: notifService.getUserNotifications(currentUserId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: primaryBlue));
          }

          final notifications = snapshot.data ??[];

          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children:[
                  Icon(Icons.notifications_off_outlined, size: 80, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  const Text("No new notifications.", style: TextStyle(fontSize: 16, color: textGrey)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(defaultPadding),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notif = notifications[index];
              final bool isUnread = !notif.isRead;

              return GestureDetector(
                onTap: () {
                  if (isUnread) notifService.markAsRead(notif.id);
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isUnread ? primaryBlue.withOpacity(0.05) : cardWhite,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isUnread ? primaryBlue.withOpacity(0.3) : Colors.grey.shade200),
                    boxShadow:[BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2))],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children:[
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isUnread ? primaryBlue : Colors.grey.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.notifications_active, 
                          color: isUnread ? Colors.white : Colors.grey.shade400, 
                          size: 20
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children:[
                            Text(notif.title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textDark)),
                            const SizedBox(height: 4),
                            Text(notif.message, style: TextStyle(fontSize: 13, color: textGrey, height: 1.4)),
                            const SizedBox(height: 8),
                            Text(
                              DateFormat('dd MMM, hh:mm a').format(notif.timestamp),
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade400, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      if (isUnread)
                        Container(width: 8, height: 8, decoration: const BoxDecoration(color: primaryBlue, shape: BoxShape.circle)),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}