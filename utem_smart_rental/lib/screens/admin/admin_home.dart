import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../utils/constants.dart';
import '../auth/login_screen.dart';
import '../../models/property_model.dart';
import '../student/property_details_screen.dart';
import '../shared/notification_bell.dart';

class AdminHome extends StatelessWidget {
  const AdminHome({super.key});

  void _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  // Helper function to dynamically fetch the Owner's Name for each property
  Future<String> _getOwnerName(String homeownerId) async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance.collection('users').doc(homeownerId).get();
      if (doc.exists) {
        return doc['name'] ?? 'Unknown Owner';
      }
    } catch (e) {
      debugPrint("Error fetching owner name: $e");
    }
    return 'Unknown Owner';
  }

  // Safe Deletion Confirmation Dialog
  void _confirmDelete(BuildContext context, String collection, String docId, String itemName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text("Confirm Delete", style: TextStyle(fontWeight: FontWeight.bold, color: textDark)),
          ],
        ),
        content: Text(
          "Are you sure you want to permanently delete '$itemName'? This action cannot be undone.",
          style: const TextStyle(color: textGrey, height: 1.5),
        ),
        actions:[
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel", style: TextStyle(color: textGrey))),
          ElevatedButton(
            onPressed: () {
              FirebaseFirestore.instance.collection(collection).doc(docId).delete();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(backgroundColor: Colors.red, content: Text("Deleted '$itemName'")),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text("Delete", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3, // <--- CHANGED: Increased to 3 Tabs (Students, Homeowners, Properties)
      child: Scaffold(
        backgroundColor: backgroundLight,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 1,
          title: const Text("Admin Panel", style: TextStyle(color: textDark, fontWeight: FontWeight.bold)),
          actions:[
            const NotificationBell(), // <--- NEW: Added the Bell! Admins can now see alerts.
            IconButton(
              icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
              tooltip: "Logout",
              onPressed: () => _logout(context),
            ),
            const SizedBox(width: 8),
          ],
          bottom: const TabBar(
            labelColor: primaryBlue,
            unselectedLabelColor: textGrey,
            indicatorColor: primaryBlue,
            indicatorWeight: 3,
            tabs:[
              Tab(icon: Icon(Icons.school_outlined), text: "Students"), // Tab 1
              Tab(icon: Icon(Icons.real_estate_agent_outlined), text: "Homeowners"), // Tab 2
              Tab(icon: Icon(Icons.home_work_outlined), text: "Properties"), // Tab 3
            ],
          ),
        ),
        body: TabBarView(
          children:[
            _buildUserList("Student"),    // Tab 1: Shows Students only
            _buildUserList("Homeowner"),  // Tab 2: Shows Homeowners only
            _buildPropertyList(),         // Tab 3: Shows Properties & Owners
          ],
        ),
      ),
    );
  }

  // --- DEDICATED USER LIST (Filters dynamically by Role!) ---
  Widget _buildUserList(String filterRole) {
    return StreamBuilder<QuerySnapshot>(
      // Filter database query by Student or Homeowner
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: filterRole)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: primaryBlue));
        }
        
        final docs = snapshot.data?.docs ??[];

        if (docs.isEmpty) {
          return Center(child: Text("No ${filterRole}s registered yet.", style: const TextStyle(color: textGrey)));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(defaultPadding),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            var doc = docs[index];
            Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
            String name = data['name'] ?? 'Unknown User';
            String profileImg = data['profileImage'] ?? '';

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: cardWhite,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow:[BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2))],
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: CircleAvatar(
                  backgroundColor: primaryBlue.withOpacity(0.1),
                  backgroundImage: profileImg.isNotEmpty ? NetworkImage(profileImg) : null,
                  child: profileImg.isEmpty ? const Icon(Icons.person, color: primaryBlue) : null,
                ),
                title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, color: textDark)),
                subtitle: Text(data['email'] ?? '', style: const TextStyle(color: textGrey, fontSize: 12)),
                trailing: IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), shape: BoxShape.circle),
                    child: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                  ),
                  onPressed: () => _confirmDelete(context, "users", doc.id, name),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // --- DEDICATED CLICKABLE PROPERTY LIST (With Owner Lookup!) ---
  Widget _buildPropertyList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('properties').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: primaryBlue));
        }
        
        final docs = snapshot.data?.docs ??[];

        if (docs.isEmpty) {
          return const Center(child: Text("No properties listed.", style: TextStyle(color: textGrey)));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(defaultPadding),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            var doc = docs[index];
            Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
            String title = data['title'] ?? 'Unknown Property';
            List<dynamic> imgs = data['imageUrls'] ??[];

            Property prop = Property.fromMap(data, doc.id);

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: cardWhite,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow:[BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2))],
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => PropertyDetailsScreen(property: prop)),
                  );
                },
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: imgs.isNotEmpty 
                    ? Image.network(imgs[0], width: 50, height: 50, fit: BoxFit.cover)
                    : Container(width: 50, height: 50, color: Colors.grey[200], child: const Icon(Icons.home, size: 20, color: textGrey)),
                ),
                title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: textDark)),
                
                // --- NEW: Dynamic Owner Name & Photo Count ---
                subtitle: FutureBuilder<String>(
                  future: _getOwnerName(prop.homeownerId),
                  builder: (context, ownerSnapshot) {
                    String ownerName = ownerSnapshot.data ?? "Loading...";
                    return Text(
                      "Owner: $ownerName • ${imgs.length} Photo(s)",
                      style: const TextStyle(color: textGrey, fontSize: 12),
                    );
                  },
                ),
                
                trailing: IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), shape: BoxShape.circle),
                    child: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                  ),
                  onPressed: () => _confirmDelete(context, "properties", doc.id, title),
                ),
              ),
            );
          },
        );
      },
    );
  }
}