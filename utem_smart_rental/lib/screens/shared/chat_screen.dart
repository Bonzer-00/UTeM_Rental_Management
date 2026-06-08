import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/chat_service.dart';
import '../../models/message_model.dart';
import '../../utils/constants.dart';
import 'package:intl/intl.dart';

class ChatScreen extends StatefulWidget {
  final String receiverId;
  final String receiverName;

  const ChatScreen({super.key, required this.receiverId, required this.receiverName});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatService _chatService = ChatService();
  final String _currentUserId = FirebaseAuth.instance.currentUser!.uid;
  final TextEditingController _msgCtrl = TextEditingController();

  // --- NEW CODE: CLEAR UNREAD STATUS ON OPEN --- [23]
  @override
  void initState() {
    super.initState();
    _clearUnreadStatus(); // Clears unread indicator when you open the chat [23]
  }

  void _clearUnreadStatus() async {
    String chatRoomId = _chatService.getChatRoomId(_currentUserId, widget.receiverId);
    await FirebaseFirestore.instance.collection('chats').doc(chatRoomId).update({
      'unreadBy': FieldValue.arrayRemove([_currentUserId]) // Remove my UID [23]
    }).catchError((e) => debugPrint("No unread status to clear."));
  }
  // ---------------------------------------------

  void _sendMessage() async {
    if (_msgCtrl.text.trim().isNotEmpty) {
      String text = _msgCtrl.text.trim();
      _msgCtrl.clear(); // Clear input instantly for smooth UX
      await _chatService.sendMessage(widget.receiverId, text);
      _clearUnreadStatus(); // Keep it clear while actively texting [23]
    }
  }

  @override
  Widget build(BuildContext context) {
    String chatRoomId = _chatService.getChatRoomId(_currentUserId, widget.receiverId);

    return Scaffold(
      backgroundColor: backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: textDark),
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: primaryBlue.withOpacity(0.1),
              child: Text(widget.receiverName[0].toUpperCase(), style: const TextStyle(color: primaryBlue, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 12),
            Text(widget.receiverName, style: const TextStyle(color: textDark, fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
      ),
      body: Column(
        children: [
          // 1. Live Message List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _chatService.getMessages(chatRoomId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: primaryBlue));
                }

                final docs = snapshot.data?.docs ??[];

                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline, size: 60, color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        const Text("No messages yet. Say hi!", style: TextStyle(color: textGrey)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  reverse: true, // List starts at the bottom
                  padding: const EdgeInsets.all(defaultPadding),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    Map<String, dynamic> data = docs[index].data() as Map<String, dynamic>;
                    Message msg = Message.fromMap(data);
                    bool isMe = msg.senderId == _currentUserId;

                    return _buildMessageBubble(msg, isMe);
                  },
                );
              },
            ),
          ),

          // 2. Bottom Text Input Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.white,
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: TextField(
                        controller: _msgCtrl,
                        decoration: const InputDecoration(
                          hintText: "Type a message...",
                          hintStyle: TextStyle(color: textGrey, fontSize: 14),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: const BoxDecoration(color: primaryBlue, shape: BoxShape.circle),
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white, size: 20),
                      onPressed: _sendMessage,
                    ),
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  // Custom Message Bubble UI (Blue for Sender, Grey for Receiver)
  Widget _buildMessageBubble(Message msg, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isMe ? primaryBlue : Colors.grey.shade200,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: isMe ? const Radius.circular(16) : Radius.zero,
            bottomRight: isMe ? Radius.zero : const Radius.circular(16),
          ),
        ),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              msg.text,
              style: TextStyle(color: isMe ? Colors.white : textDark, fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat('hh:mm a').format(msg.timestamp),
              style: TextStyle(color: isMe ? Colors.white70 : textGrey, fontSize: 9, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}