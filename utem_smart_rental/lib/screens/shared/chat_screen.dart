import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart'; // <--- NEW IMPORT [1]
import '../../services/chat_service.dart';
import '../../models/message_model.dart';
import '../../utils/constants.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart'; // To open document URLs

// Models needed for contract viewing inside chat
import '../../models/booking_model.dart';
import '../../models/property_model.dart';
import '../student/contract_payment_screen.dart';

class ChatScreen extends StatefulWidget {
  final String receiverId;
  final String receiverName;

  const ChatScreen({super.key, required this.receiverId, required this.receiverName});

  Widget build(BuildContext context) {
    return _ChatScreenState().build(context);
  }

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatService _chatService = ChatService();
  final String _currentUserId = FirebaseAuth.instance.currentUser!.uid;
  final TextEditingController _msgCtrl = TextEditingController();

  // --- NEW: Media Picking Variables ---
  final ImagePicker _picker = ImagePicker();
  bool _isSendingMedia = false; // Displays loading spinner during upload

  @override
  void initState() {
    super.initState();
    _clearUnreadStatus();
  }

  void _clearUnreadStatus() async {
    String chatRoomId = _chatService.getChatRoomId(_currentUserId, widget.receiverId);
    await FirebaseFirestore.instance.collection('chats').doc(chatRoomId).update({
      'unreadBy': FieldValue.arrayRemove([_currentUserId])
    }).catchError((e) => debugPrint("No unread status to clear."));
  }

  void _sendMessage() async {
    if (_msgCtrl.text.trim().isNotEmpty) {
      String text = _msgCtrl.text.trim();
      _msgCtrl.clear(); 
      await _chatService.sendMessage(widget.receiverId, text);
      _clearUnreadStatus();
    }
  }

  // --- NEW: PICK & SEND ATTACHMENTS (Images or Documents) --- [1, 23]
  Future<void> _sendAttachment(String type) async {
    Navigator.pop(context); // Close bottom sheet option menu
    
    File? file;
    String fileName = "";

    try {
      if (type == 'image') {
        // Pick Photo from Gallery
        final XFile? picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
        if (picked != null) {
          file = File(picked.path);
          fileName = picked.name;
        }
      } else if (type == 'file') {
        // Pick Document (PDF, Word, Excel, TXT, PPT) [1]
        FilePickerResult? result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['pdf', 'doc', 'docx', 'xls', 'xlsx', 'txt', 'ppt', 'pptx'],
        );
        if (result != null && result.files.single.path != null) {
          file = File(result.files.single.path!);
          fileName = result.files.single.name;
        }
      }

      if (file == null) return;

      setState(() => _isSendingMedia = true);

      // 1. Generate unique file name and upload to Firebase Storage
      String uniqueName = '${DateTime.now().millisecondsSinceEpoch}_$fileName';
      Reference ref = FirebaseStorage.instance.ref().child('chat_media').child(uniqueName);
      
      UploadTask uploadTask = ref.putFile(file);
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();

      // 2. Save to Firestore.
      // To keep it simple, we store the data as "FileName|DownloadURL" in the text field [23]
      await _chatService.sendMessage(
        widget.receiverId,
        "$fileName|$downloadUrl",
        type: type,
      );

      _clearUnreadStatus();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: Colors.red, content: Text("Upload failed: $e")));
    }

    setState(() => _isSendingMedia = false);
  }

  // --- NEW: ATTACHMENTS SELECTION SHEET ---
  void _showAttachmentMenu() {
    FocusScope.of(context).unfocus();
    showModalBottomSheet(
      context: context,
      backgroundColor: cardWhite,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Send Attachment", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textDark)),
              const SizedBox(height: 20),
              
              // Photo Gallery Option
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: primaryBlue.withOpacity(0.1), shape: BoxShape.circle), child: const Icon(Icons.photo_library_outlined, color: primaryBlue)),
                title: const Text("Photo", style: TextStyle(fontWeight: FontWeight.bold, color: textDark)),
                subtitle: const Text("Send an image from your gallery", style: TextStyle(color: textGrey, fontSize: 12)),
                onTap: () => _sendAttachment('image'),
              ),
              const Divider(),
              
              // Document/File Option [1]
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), shape: BoxShape.circle), child: const Icon(Icons.insert_drive_file_outlined, color: Colors.orange)),
                title: const Text("Document", style: TextStyle(fontWeight: FontWeight.bold, color: textDark)),
                subtitle: const Text("Send PDFs, Word docs, Excel sheets", style: TextStyle(color: textGrey, fontSize: 12)),
                onTap: () => _sendAttachment('file'),
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
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
                  reverse: true,
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

          // Loading bar during media upload
          if (_isSendingMedia)
            const LinearProgressIndicator(color: primaryBlue, backgroundColor: Colors.white),

          // 2. Bottom Text Input Bar (With '+' Button!)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.white,
            child: SafeArea(
              child: Row(
                children: [
                  // --- NEW: THE ATTACHMENT PLUS BUTTON ---
                  GestureDetector(
                    onTap: _showAttachmentMenu,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: primaryBlue.withOpacity(0.1), shape: BoxShape.circle),
                      child: const Icon(Icons.add, color: primaryBlue, size: 22),
                    ),
                  ),
                  const SizedBox(width: 10),
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

  // --- UPDATED BUBBLE DISPATCHER --- [23]
  Widget _buildMessageBubble(Message msg, bool isMe) {
    if (msg.type == 'contract' || msg.type == 'contract_signed') {
      return _buildContractBubble(msg, isMe);
    }
    if (msg.type == 'image') {
      return _buildImageBubble(msg, isMe); // Render rounded image [23]
    }
    if (msg.type == 'file') {
      return _buildFileBubble(msg, isMe); // Render doc attachment [1, 23]
    }

    // Default text bubble
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
            Text(msg.text, style: TextStyle(color: isMe ? Colors.white : textDark, fontSize: 14)),
            const SizedBox(height: 4),
            Text(DateFormat('hh:mm a').format(msg.timestamp), style: TextStyle(color: isMe ? Colors.white70 : textGrey, fontSize: 9, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  // --- NEW: RENDER CHAT PHOTOS --- [23]
  Widget _buildImageBubble(Message msg, bool isMe) {
    // Split the formatted "FileName|URL" string [23]
    List<String> parts = msg.text.split('|');
    String url = parts.length > 1 ? parts[1] : parts[0];

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onTap: () {
          // Open Photo in Fullscreen with pinch-to-zoom!
          Navigator.push(context, MaterialPageRoute(builder: (_) => FullScreenViewer(imageUrl: url)));
        },
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.network(
              url, width: 220, height: 180, fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(width: 220, height: 180, color: Colors.grey[100], child: const Center(child: CircularProgressIndicator(color: primaryBlue)));
              },
            ),
          ),
        ),
      ),
    );
  }

  // --- NEW: RENDER FILE ATTACHMENTS (PDF, Word, etc) --- [1, 23]
  Widget _buildFileBubble(Message msg, bool isMe) {
    // Split the formatted "FileName|URL" string [23]
    List<String> parts = msg.text.split('|');
    String name = parts[0];
    String url = parts.length > 1 ? parts[1] : '';

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        width: 240,
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isMe ? primaryBlue.withOpacity(0.1) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isMe ? primaryBlue.withOpacity(0.3) : Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Icon(Icons.insert_drive_file, color: isMe ? primaryBlue : textDark, size: 30),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textDark), maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text(DateFormat('hh:mm a').format(msg.timestamp), style: const TextStyle(color: textGrey, fontSize: 9)),
                ],
              ),
            ),
           IconButton(
              icon: Icon(Icons.open_in_new, color: isMe ? primaryBlue : textDark, size: 20),
              onPressed: () async {
                final Uri uri = Uri.parse(url);
                try {
                  // --- THE FIX: Force it to open in external browser --- [25]
                  await launchUrl(
                    uri, 
                    mode: LaunchMode.externalApplication, // Bypasses Android blocks [25]
                  );
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(backgroundColor: Colors.red, content: Text("Could not open file: $e")),
                    );
                  }
                }
              },
            )
          ],
        ),
      ),
    );
  }

  // --- CONTRACT BUBBLE (Unchanged) --- [23]
  Widget _buildContractBubble(Message msg, bool isMe) {
    bool isSigned = msg.type == 'contract_signed';
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        width: 250, margin: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(color: cardWhite, borderRadius: BorderRadius.circular(16), border: Border.all(color: isSigned ? Colors.green.withOpacity(0.5) : primaryBlue.withOpacity(0.5), width: 1.5), boxShadow:[BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2))]),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: isSigned ? Colors.green.withOpacity(0.1) : primaryBlue.withOpacity(0.1), borderRadius: const BorderRadius.only(topLeft: Radius.circular(14), topRight: Radius.circular(14))),
              child: Row(
                children: [
                  Icon(Icons.picture_as_pdf, color: isSigned ? Colors.green : primaryBlue, size: 28),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(isSigned ? "Signed_Lease.pdf" : "Tenancy_Lease.pdf", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textDark), overflow: TextOverflow.ellipsis),
                        Text(isSigned ? "LEASE ACTIVE" : "SIGNATURE REQUIRED", style: TextStyle(color: isSigned ? Colors.green : primaryBlue, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                      ],
                    ),
                  )
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(isSigned ? "Agreement fully signed and deposit paid." : "Please open this document, review the clauses, and digitally sign.", style: const TextStyle(color: textGrey, fontSize: 11)),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity, height: 35,
                    child: ElevatedButton(
                      onPressed: () async {
                        showDialog(context: context, barrierDismissible: false, builder: (context) => const Center(child: CircularProgressIndicator(color: primaryBlue)));
                        var bookingDoc = await FirebaseFirestore.instance.collection('bookings').doc(msg.bookingId).get();
                        var propDoc = await FirebaseFirestore.instance.collection('properties').doc(bookingDoc['propertyId']).get();
                        if (context.mounted) Navigator.pop(context);
                        if (bookingDoc.exists && propDoc.exists) {
                          Booking b = Booking.fromMap(bookingDoc.data()!, bookingDoc.id);
                          Property p = Property.fromMap(propDoc.data()!, propDoc.id);
                          bool viewOnly = b.status == 'signed' || (b.studentId != _currentUserId);
                          if (context.mounted) {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => ContractPaymentScreen(booking: b, property: p, isViewOnly: viewOnly)));
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: isSigned ? Colors.green : primaryBlue, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                      child: Text(isSigned ? "View Signed PDF" : "Review & Sign", style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

// --- NEW COMPONENT: SOLID 3D PINCH-TO-ZOOM IMAGE VIEWER --- [23]
class FullScreenViewer extends StatelessWidget {
  final String imageUrl;
  const FullScreenViewer({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(
            child: InteractiveViewer( // Enables Pinch-to-Zoom!
              child: Image.network(imageUrl, fit: BoxFit.contain),
            ),
          ),
          Positioned(
            top: 50, left: 16,
            child: CircleAvatar(
              backgroundColor: Colors.black45,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          )
        ],
      ),
    );
  }
}