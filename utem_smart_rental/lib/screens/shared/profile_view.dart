import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../../utils/constants.dart';
import '../auth/login_screen.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  final User? user = FirebaseAuth.instance.currentUser;
  final TextEditingController _nameCtrl = TextEditingController();
  final ImagePicker _picker = ImagePicker(); // Added ImagePicker
  
  String _email = '';
  String _role = '';
  String _profileImageUrl = '';
  bool _isLoading = true;
  bool _isSaving = false;

  final List<String> _avatarOptions =[
    "https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?ixlib=rb-1.2.1&auto=format&fit=crop&w=200&q=80", 
    "https://images.unsplash.com/photo-1494790108377-be9c29b29330?ixlib=rb-1.2.1&auto=format&fit=crop&w=200&q=80", 
    "https://images.unsplash.com/photo-1599566150163-29194dcaad36?ixlib=rb-1.2.1&auto=format&fit=crop&w=200&q=80", 
    "https://images.unsplash.com/photo-1438761681033-6461ffad8d80?ixlib=rb-1.2.1&auto=format&fit=crop&w=200&q=80", 
    "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?ixlib=rb-1.2.1&auto=format&fit=crop&w=200&q=80", 
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() async {
    if (user == null) return;
    DocumentSnapshot doc = await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();
    
    if (!mounted) return; // <--- ADDED SAFETY CHECK

    if (doc.exists) {
      var data = doc.data() as Map<String, dynamic>;
      setState(() {
        _nameCtrl.text = data['name'] ?? '';
        _email = data['email'] ?? user!.email ?? '';
        _role = data['role'] ?? '';
        _profileImageUrl = data['profileImage'] ?? _avatarOptions[0];
        _isLoading = false;
      });
    }
  }

  void _saveProfile() async {
    setState(() => _isSaving = true);
    await FirebaseFirestore.instance.collection('users').doc(user!.uid).update({
      'name': _nameCtrl.text.trim(),
      'profileImage': _profileImageUrl,
    });
    
    if (!mounted) return; // <--- ADDED SAFETY CHECK
    
    setState(() => _isSaving = false);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(backgroundColor: Colors.green, content: Text("Profile Updated Successfully!")));
  }

  void _logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    // pushAndRemoveUntil prevents the user from clicking the Android "Back" button to return to the app
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  // --- OPTION 1: CONFIRM DEFAULT AVATAR ---
  void _confirmDefaultAvatar(BuildContext context, String newUrl) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: cardWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Use Default Avatar?", style: TextStyle(fontWeight: FontWeight.bold, color: textDark)),
        content: const Text("Do you want to use this image as your profile picture?", style: TextStyle(color: textGrey)),
        actions:[
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text("Cancel", style: TextStyle(color: textGrey))),
          ElevatedButton(
            onPressed: () {
              setState(() => _profileImageUrl = newUrl); 
              Navigator.pop(dialogContext); // Close dialog
              Navigator.pop(context); // Close bottom sheet
            },
            style: ElevatedButton.styleFrom(backgroundColor: primaryBlue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            child: const Text("Confirm", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // --- OPTION 2: PICK FROM GALLERY & UPLOAD ---
  Future<void> _pickAndUploadGalleryImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    File imageFile = File(pickedFile.path);

    if (!mounted) return;
    
    // Show Confirmation Dialog for Gallery Image
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: cardWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Use this photo?", style: TextStyle(fontWeight: FontWeight.bold, color: textDark)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children:[
            CircleAvatar(radius: 60, backgroundImage: FileImage(imageFile)),
            const SizedBox(height: 16),
            const Text("This photo will be uploaded to your profile.", style: TextStyle(color: textGrey, fontSize: 13), textAlign: TextAlign.center),
          ],
        ),
        actions:[
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text("Cancel", style: TextStyle(color: textGrey))),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext); // Close dialog
              Navigator.pop(context); // Close bottom sheet
              _uploadImageToFirebase(imageFile);
            },
            style: ElevatedButton.styleFrom(backgroundColor: primaryBlue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            child: const Text("Upload", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // Firebase Storage Upload Logic
  Future<void> _uploadImageToFirebase(File file) async {
    setState(() => _isSaving = true);
    try {
      String fileName = '${user!.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      Reference ref = FirebaseStorage.instance.ref().child('profiles/$fileName');
      
      await ref.putFile(file, SettableMetadata(contentType: 'image/jpeg'));
      String url = await ref.getDownloadURL();

      await FirebaseFirestore.instance.collection('users').doc(user!.uid).update({'profileImage': url});
      
      if (!mounted) return; // <--- ADDED SAFETY CHECK
      
      setState(() => _profileImageUrl = url);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(backgroundColor: Colors.green, content: Text("Profile picture updated!")));
    } catch (e) {
      if (!mounted) return; // <--- ADDED SAFETY CHECK
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: Colors.red, content: Text("Error uploading: $e")));
    }
    
    if (!mounted) return; // <--- ADDED SAFETY CHECK
    setState(() => _isSaving = false);
  }

  // --- THE NEW BOTTOM SHEET ---
  void _showAvatarPicker() {
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
            children:[
              const Text("Update Profile Picture", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textDark)),
              const SizedBox(height: 20),
              
              // Custom Gallery Button
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: primaryBlue.withOpacity(0.1), shape: BoxShape.circle),
                  child: const Icon(Icons.photo_library_outlined, color: primaryBlue),
                ),
                title: const Text("Upload from Gallery", style: TextStyle(fontWeight: FontWeight.bold, color: textDark)),
                subtitle: const Text("Choose a photo from your device", style: TextStyle(color: textGrey, fontSize: 12)),
                onTap: _pickAndUploadGalleryImage,
                trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: textGrey),
              ),
              
              const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider()),
              const Text("Or select a default avatar:", style: TextStyle(fontWeight: FontWeight.bold, color: textDark, fontSize: 14)),
              const SizedBox(height: 16),
              
              // Default Avatars
              Wrap(
                spacing: 16, runSpacing: 16,
                children: _avatarOptions.map((url) {
                  return GestureDetector(
                    onTap: () => _confirmDefaultAvatar(context, url), 
                    child: Stack(
                      alignment: Alignment.center,
                      children:[
                        CircleAvatar(radius: 35, backgroundImage: NetworkImage(url)),
                        if (_profileImageUrl == url)
                          Container(
                            width: 70, height: 70,
                            decoration: BoxDecoration(color: Colors.black.withOpacity(0.4), shape: BoxShape.circle),
                            child: const Icon(Icons.check_circle, color: Colors.greenAccent, size: 30),
                          )
                      ],
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator(color: primaryBlue));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(defaultPadding),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Stack(
            children:[
              Container(
                decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: primaryBlue.withOpacity(0.3), width: 4)),
                child: CircleAvatar(radius: 60, backgroundImage: NetworkImage(_profileImageUrl)),
              ),
              Positioned(
                bottom: 0, right: 0,
                child: GestureDetector(
                  onTap: _showAvatarPicker,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: primaryBlue, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                    child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                  ),
                ),
              )
            ],
          ),
          const SizedBox(height: 30),

          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: cardWhite, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200), boxShadow:[BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))]),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children:[
                const Text("Personal Information", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textDark)),
                const SizedBox(height: 20),

                const Text("Full Name", style: TextStyle(fontWeight: FontWeight.bold, color: textDark, fontSize: 13)),
                const SizedBox(height: 6),
                TextField(
                  controller: _nameCtrl,
                  decoration: InputDecoration(
                    filled: true, fillColor: const Color(0xFFF8FAFC),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: primaryBlue)),
                  ),
                ),
                const SizedBox(height: 16),

                const Text("Email Address", style: TextStyle(fontWeight: FontWeight.bold, color: textDark, fontSize: 13)),
                const SizedBox(height: 6),
                TextField(
                  controller: TextEditingController(text: _email),
                  enabled: false, 
                  decoration: InputDecoration(
                    filled: true, fillColor: Colors.grey.shade100,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 16),

                const Text("Account Role", style: TextStyle(fontWeight: FontWeight.bold, color: textDark, fontSize: 13)),
                const SizedBox(height: 6),
                TextField(
                  controller: TextEditingController(text: _role),
                  enabled: false, 
                  decoration: InputDecoration(
                    filled: true, fillColor: Colors.grey.shade100,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 30),

                _isSaving 
                  ? const Center(child: CircularProgressIndicator(color: primaryBlue))
                  : SizedBox(
                      width: double.infinity, height: 50,
                      child: ElevatedButton(
                        onPressed: _saveProfile,
                        style: ElevatedButton.styleFrom(backgroundColor: primaryBlue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                        child: const Text("Save Changes", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    ),
                      const SizedBox(height: 16), // <--- ADD THIS
                
                // --- NEW LOGOUT BUTTON ---
                SizedBox(
                  width: double.infinity, height: 50,
                  child: OutlinedButton.icon(
                    onPressed: _logout,
                    icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
                    label: const Text("Log Out", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.redAccent)),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.redAccent.withOpacity(0.5)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}