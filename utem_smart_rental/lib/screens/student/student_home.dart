import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/property_model.dart';
import '../../models/booking_model.dart';
import '../../utils/constants.dart';
import '../shared/profile_view.dart';
import '../shared/notification_bell.dart';
import '../shared/chat_list_screen.dart'; 
import '../shared/chat_screen.dart'; 
import 'contract_payment_screen.dart'; 
import 'student_explore.dart';
import 'my_bookings_screen.dart';
import 'add_vacancy_screen.dart';

class StudentHome extends StatefulWidget {
  const StudentHome({super.key});

  @override
  State<StudentHome> createState() => _StudentHomeState();
}

class _StudentHomeState extends State<StudentHome> {
  final String _currentUserId = FirebaseAuth.instance.currentUser!.uid;
  int _selectedIndex = 1; // Default starting tab: Explore

  // Fallback Welcome Screen [16]
  Widget _buildWelcomingPlaceholder() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(defaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Rent Smart.", style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: textDark)),
          const Text("Stay Better.", style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: primaryBlue)),
          const SizedBox(height: 16),
          const Text("The official hub for safe, student-friendly rentals near UTeM Melaka.", style: TextStyle(color: textGrey, fontSize: 16)),
          const SizedBox(height: 30),
          
          Container(
            width: double.infinity, padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: primaryBlue, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: primaryBlue.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))]),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.verified_user, color: Colors.white, size: 40),
                const SizedBox(height: 16),
                const Text("Verified Listings", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                const Text("All properties are checked for student safety.", style: TextStyle(color: Colors.white70)),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => setState(() => _selectedIndex = 1), 
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: primaryBlue),
                  child: const Text("Start Exploring", style: TextStyle(fontWeight: FontWeight.bold)),
                )
              ],
            ),
          ),
          const SizedBox(height: 30),
          const Text("Nearby Areas", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textDark)),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ["Taman Tasik", "Ayer Keroh", "Durian Tunggal", "Bukit Beruang"].map((area) => Container(
                margin: const EdgeInsets.only(right: 12), padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
                child: Text(area, style: const TextStyle(fontWeight: FontWeight.bold, color: textGrey)),
              )).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // Active Rental Portal (My Home, Rent Due, Contract, Maintenance) [16, 21]
  Widget _buildActiveRentalPortal(Booking booking, Property property) {
    double deposit = property.price * 2;
    double total = property.price + deposit + 100;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(defaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children:[
          const Text("My Rental Portal", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textDark)),
          const SizedBox(height: 16),

          // Active House Card [16]
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    property.imageUrls.isNotEmpty ? property.imageUrls[0] : "https://images.unsplash.com/photo-1568605114967-8130f3a36994?ixlib=rb-1.2.1&auto=format&fit=crop&w=300&q=80",
                    width: 80, height: 80, fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children:[
                      Text(property.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textDark), maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Text("Address: ${property.location}", style: const TextStyle(color: textGrey, fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                )
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Rent Tracker Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: primaryBlue.withOpacity(0.05), borderRadius: BorderRadius.circular(16), border: Border.all(color: primaryBlue.withOpacity(0.2))),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children:[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children:[
                    const Text("Monthly Rent Due", style: TextStyle(color: textGrey, fontSize: 12)),
                    const SizedBox(height: 4),
                    Text("RM ${property.price.toStringAsFixed(2)}", style: const TextStyle(color: primaryBlue, fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    const Text("Next Due: 1st July 2026", style: TextStyle(color: textGrey, fontSize: 11)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8), decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(20)),
                  child: const Text("PAID", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          const Text("Quick Actions", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textDark)),
          const SizedBox(height: 12),
          
         // --- UPDATED: 3-BUTTON QUICK ACTIONS ROW --- [16, 21]
          Row(
            children: [
              // 1. VIEW CONTRACT
              Expanded(
                child: _buildPortalButton(Icons.description_outlined, "Lease Contract", Colors.purple, () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => ContractPaymentScreen(booking: booking, property: property, isViewOnly: true)));
                }),
              ),
              const SizedBox(width: 8),
              
              // 2. CONTACT LANDLORD
              Expanded(
                child: _buildPortalButton(Icons.chat_bubble_outline, "Contact Landlord", Colors.green, () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(receiverId: property.homeownerId, receiverName: "My Landlord")));
                }),
              ),
              const SizedBox(width: 8),

             // 3. UPDATED: PROMOTE VACANCY WITH SECURE DOUBLE-PROMOTION CHECK [16, 21]
              Expanded(
                child: _buildPortalButton(Icons.group_add, "Promote Vacancy", Colors.orange, () async {
                  FocusScope.of(context).unfocus();

                  // Show a quick sleek loading spinner while we check Firestore
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) => const Center(child: CircularProgressIndicator(color: primaryBlue)),
                  );

                  try {
                    // Check if this student already has an active vacancy post for this property
                    var query = await FirebaseFirestore.instance
                        .collection('vacancies')
                        .where('studentId', isEqualTo: _currentUserId)
                        .where('propertyId', isEqualTo: property.id)
                        .get();

                    if (context.mounted) Navigator.pop(context); // Close loading spinner

                    if (query.docs.isNotEmpty) {
                      // Already promoted! Block them and show a warning
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            backgroundColor: Colors.orange,
                            content: Text("You already have an active vacancy post! Edit it in the Roommate Finder tab."),
                          ),
                        );
                      }
                    } else {
                      // Not promoted yet! Safely navigate to the form [16]
                      if (context.mounted) {
                        Navigator.push(
                          context, 
                          MaterialPageRoute(
                            builder: (_) => AddVacancyScreen(booking: booking, property: property),
                          ),
                        );
                      }
                    }
                  } catch (e) {
                    if (context.mounted) {
                      Navigator.pop(context); // Safety close
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
                    }
                  }
                }),
              ),
            ],
          ),
          const SizedBox(height: 24),

          const Text("Maintenance / Reports", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textDark)),
          const SizedBox(height: 12),
          _buildMaintenanceSection(property.homeownerId, property.title),
        ],
      ),
    );
  }

  Widget _buildPortalButton(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
        child: Column(
          children:[
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textDark)),
          ],
        ),
      ),
    );
  }

  Widget _buildMaintenanceSection(String landlordId, String propertyTitle) {
    final TextEditingController reportCtrl = TextEditingController();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children:[
          const Text("Report an Issue (Leak, Damage, etc.)", style: TextStyle(fontWeight: FontWeight.bold, color: textDark, fontSize: 13)),
          const SizedBox(height: 8),
          TextField(
            controller: reportCtrl,
            decoration: InputDecoration(
              hintText: "e.g. Master bathroom pipe is leaking.", hintStyle: const TextStyle(color: Colors.grey, fontSize: 13), filled: true, fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                if (reportCtrl.text.trim().isNotEmpty) {
                  String reportText = reportCtrl.text.trim();
                  reportCtrl.clear();
                  FocusScope.of(context).unfocus();

                  await FirebaseFirestore.instance.collection('notifications').add({
                    'userId': landlordId,
                    'title': "Maintenance Request 🛠️",
                    'message': "A tenant at '$propertyTitle' reported: '$reportText'",
                    'timestamp': DateTime.now().toIso8601String(),
                    'isRead': false,
                  });

                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(backgroundColor: Colors.green, content: Text("Report sent directly to landlord!")));
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: primaryBlue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
              child: const Text("Send Report", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildStudentHomeTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('bookings')
          .where('studentId', isEqualTo: _currentUserId)
          .where('status', isEqualTo: 'signed')
          .snapshots(),
      builder: (context, bookingSnapshot) {
        if (bookingSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: primaryBlue));
        }

        final signedBookings = bookingSnapshot.data?.docs ?? [];

        if (signedBookings.isEmpty) {
          return _buildWelcomingPlaceholder();
        }

        var bookingDoc = signedBookings.first;
        Booking booking = Booking.fromMap(bookingDoc.data() as Map<String, dynamic>, bookingDoc.id);

        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance.collection('properties').doc(booking.propertyId).get(),
          builder: (context, propSnapshot) {
            if (propSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: primaryBlue));
            }
            if (!propSnapshot.hasData || !propSnapshot.data!.exists) {
              return _buildWelcomingPlaceholder(); 
            }

            Property property = Property.fromMap(propSnapshot.data!.data() as Map<String, dynamic>, propSnapshot.data!.id);
            return _buildActiveRentalPortal(booking, property);
          },
        );
      },
    );
  }

  // --- DYNAMIC BODY TAB ROUTER --- [15, 18, 23]
  Widget _buildBody() {
    if (_selectedIndex == 0) return _buildStudentHomeTab();
    if (_selectedIndex == 1) return const StudentExplore(); // <--- CALLING NEW DEDICATED FILE!
    if (_selectedIndex == 2) return const ChatListScreen(); 
    return const ProfileView();
  }

  @override
  Widget build(BuildContext context) {
    final String uid = FirebaseAuth.instance.currentUser!.uid;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: backgroundLight,
        appBar: _selectedIndex == 2 
            ? null 
            : AppBar(
                backgroundColor: backgroundLight, 
                elevation: 0, 
                title: _selectedIndex == 3 
                    ? const Text("My Profile", style: TextStyle(color: textDark, fontWeight: FontWeight.bold, fontSize: 18))
                    : const SmartRentalLogo(),
                actions: _selectedIndex == 3
                    ? null 
                    : [
                        const NotificationBell(),
                        if (_selectedIndex == 1) 
                          IconButton(
                            icon: const Icon(Icons.calendar_month, color: textDark), 
                            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyBookingsScreen()))
                          ),
                        const SizedBox(width: 8),
                      ],
              ),
        
        body: _buildBody(), 
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
          type: BottomNavigationBarType.fixed, selectedItemColor: primaryBlue, unselectedItemColor: textGrey,
          items:[
            const BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: "Home"),
            const BottomNavigationBarItem(icon: Icon(Icons.search), label: "Explore"),
            
            BottomNavigationBarItem(
              icon: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('chats')
                    .where('unreadBy', arrayContains: uid) 
                    .snapshots(),
                builder: (context, snapshot) {
                  bool hasUnread = snapshot.hasData && snapshot.data!.docs.isNotEmpty;
                  return Badge(
                    isLabelVisible: hasUnread, 
                    smallSize: 12, 
                    backgroundColor: Colors.redAccent,
                    child: const Icon(Icons.chat_bubble_outline),
                  );
                },
              ),
              label: "Chat",
            ),
            
            const BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: "Account"),
          ],
        ),
      ),
    );
  }
}