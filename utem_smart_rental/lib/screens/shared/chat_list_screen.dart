import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/chat_service.dart';
import '../../utils/constants.dart';
import 'chat_screen.dart';
import 'package:intl/intl.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  Future<Map<String, String>> _getOtherUserDetails(String otherUserId) async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance.collection('users').doc(otherUserId).get();
      if (doc.exists) {
        var data = doc.data() as Map<String, dynamic>;
        return {
          'name': data['name'] ?? 'User',
          'image': data['profileImage'] ?? '',
        };
      }
    } catch (e) {
      debugPrint("Error fetching user details: $e");
    }
    return {'name': 'User', 'image': ''};
  }

  // --- NEW: Format raw file names into clean icons for the Inbox list --- [23]
  String _formatLastMessagePreview(String rawMessage) {
    if (rawMessage.contains('|')) {
      String fileName = rawMessage.split('|')[0].toLowerCase();
      // Check if it's an image extension
      if (fileName.endsWith('.jpg') || 
          fileName.endsWith('.jpeg') || 
          fileName.endsWith('.png') || 
          fileName.endsWith('.gif') || 
          fileName.contains('scaled_') ||
          fileName.contains('prop_')) {
        return "📷 Photo";
      } else {
        return "📁 Document";
      }
    }
    return rawMessage;
  }

  @override
  Widget build(BuildContext context) {
    final String currentUserId = FirebaseAuth.instance.currentUser!.uid;
    final ChatService chatService = ChatService();

    return Scaffold(
      backgroundColor: backgroundLight,
      appBar: AppBar(
        backgroundColor: backgroundLight,
        elevation: 0,
        iconTheme: const IconThemeData(color: textDark),
        title: const Text("Messages", style: TextStyle(color: textDark, fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: chatService.getChatRooms(currentUserId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: primaryBlue));
          }

          final docs = snapshot.data?.docs ??[];

          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children:[
                  Icon(Icons.forum_outlined, size: 80, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  const Text("No conversations yet.", style: TextStyle(color: textGrey)),
                ],
              ),
            );
          }

          var sortedDocs = List<QueryDocumentSnapshot>.from(docs);
          sortedDocs.sort((a, b) {
            String timeA = a['lastMessageTime'] ?? '';
            String timeB = b['lastMessageTime'] ?? '';
            return timeB.compareTo(timeA);
          });

          return ListView.builder(
            padding: const EdgeInsets.all(defaultPadding),
            itemCount: sortedDocs.length,
            itemBuilder: (context, index) {
              var doc = sortedDocs[index];
              
              List<dynamic> users = doc['users'] ?? [];
              String otherUserId = users.firstWhere((uid) => uid != currentUserId, orElse: () => '') as String;

              if (otherUserId.isEmpty) return const SizedBox.shrink();

              String lastMessage = doc['lastMessage'] ?? '';
              String rawTime = doc['lastMessageTime'] ?? '';
              DateTime? lastMsgTime = rawTime.isNotEmpty ? DateTime.parse(rawTime) : null;

              // --- CHECK IF THIS CONVERSATION IS UNREAD FOR ME --- [23]
              List<dynamic> unreadBy = doc['unreadBy'] ?? [];
              bool isUnread = unreadBy.contains(currentUserId); 

              return FutureBuilder<Map<String, String>>(
                future: _getOtherUserDetails(otherUserId),
                builder: (context, userSnapshot) {
                  String name = userSnapshot.data?['name'] ?? 'Loading...';
                  String img = userSnapshot.data?['image'] ?? '';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      // --- FIX 2: BRIGHT EDGE & TINTED BG IF UNREAD --- [23]
                      color: isUnread ? primaryBlue.withOpacity(0.04) : cardWhite, 
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isUnread ? primaryBlue.withOpacity(0.4) : Colors.grey.shade200, 
                        width: isUnread ? 1.5 : 1.0,
                      ),
                      boxShadow:[
                        BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2))
                      ],
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: CircleAvatar(
                        radius: 24,
                        backgroundColor: primaryBlue.withOpacity(0.1),
                        backgroundImage: img.isNotEmpty ? NetworkImage(img) : null,
                        child: img.isEmpty ? const Icon(Icons.person, color: primaryBlue) : null,
                      ),
                      title: Text(
                        name, 
                        style: TextStyle(
                          fontWeight: FontWeight.bold, 
                          color: textDark,
                          fontSize: 15,
                        )
                      ),
                     subtitle: Text(
                        // --- UPDATED: Uses the new formatter! --- [23]
                        _formatLastMessagePreview(lastMessage), 
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isUnread ? textDark : textGrey, 
                          fontSize: 13,
                          fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      // --- FIX 2: BLUE DOT INDICATOR & BOLD TIME --- [23]
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children:[
                          if (lastMsgTime != null)
                            Text(
                              DateFormat('hh:mm a').format(lastMsgTime),
                              style: TextStyle(
                                color: isUnread ? primaryBlue : Colors.grey, 
                                fontSize: 11,
                                fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          if (isUnread) ...[
                            const SizedBox(height: 6),
                            Container(
                              width: 10,
                              height: 10,
                              decoration: const BoxDecoration(
                                color: primaryBlue, // Bright blue unread dot [23]
                                shape: BoxShape.circle,
                              ),
                            ),
                          ]
                        ],
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatScreen(
                              receiverId: otherUserId,
                              receiverName: name,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}