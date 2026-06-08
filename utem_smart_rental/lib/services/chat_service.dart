import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/message_model.dart';

class ChatService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Generate a unique Chat Room ID sorted alphabetically.
  // This ensures UserA_UserB and UserB_UserA always open the exact same chat room!
  String getChatRoomId(String user1, String user2) {
    List<String> ids = [user1, user2];
    ids.sort();
    return ids.join("_");
  }

  // Send Message
  Future<void> sendMessage(String receiverId, String text) async {
    final String currentUserId = _auth.currentUser!.uid;
    final String chatRoomId = getChatRoomId(currentUserId, receiverId);

    Message newMessage = Message(
      senderId: currentUserId,
      text: text,
      timestamp: DateTime.now(),
    );

    // 1. Add message to the sub-collection inside the chat room
    await _db
        .collection('chats')
        .doc(chatRoomId)
        .collection('messages')
        .add(newMessage.toMap());

    // 2. Update/Create the Chat Room meta-data
    await _db.collection('chats').doc(chatRoomId).set({
      'users': [currentUserId, receiverId],
      'lastMessage': text,
      'lastMessageTime': DateTime.now().toIso8601String(),
      'unreadBy': [receiverId], 
    }, SetOptions(merge: true));
  }

  // Get Messages Stream (Real-time)
  Stream<QuerySnapshot> getMessages(String chatRoomId) {
    return _db
        .collection('chats')
        .doc(chatRoomId)
        .collection('messages')
        .orderBy('timestamp', descending: true) // Newest messages at the bottom
        .snapshots();
  }

  // Get Chat Rooms for the Inbox (Real-time)
  Stream<QuerySnapshot> getChatRooms(String currentUserId) {
    return _db
        .collection('chats')
        .where('users', arrayContains: currentUserId)
        .snapshots();
  }
}