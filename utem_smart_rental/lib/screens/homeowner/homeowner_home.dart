import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/property_model.dart';
import '../../services/property_service.dart';
import '../../utils/constants.dart';
import 'add_property_screen.dart';
import 'manage_bookings_screen.dart'; 
import '../shared/profile_view.dart';
import '../shared/notification_bell.dart';
import '../student/student_explore.dart'; 
import '../shared/chat_list_screen.dart'; 

class HomeownerHome extends StatefulWidget {
  const HomeownerHome({super.key});

  @override
  State<HomeownerHome> createState() => _HomeownerHomeState();
}

class _HomeownerHomeState extends State<HomeownerHome> {
  final PropertyService _propertyService = PropertyService();
  final String _currentUserId = FirebaseAuth.instance.currentUser!.uid;
  final String _userName = FirebaseAuth.instance.currentUser!.email!.split('@')[0];
  
  int _selectedIndex = 1; // Default to Manage tab
  late Stream<List<Property>> _myPropertiesStream;

  @override
  void initState() {
    super.initState();
    _myPropertiesStream = _propertyService.getHomeownerProperties(_currentUserId);
  }

  // --- MANAGE TAB (Index 1) ---
  Widget _buildManageTab() {
    return StreamBuilder<List<Property>>(
      stream: _myPropertiesStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: primaryBlue));

        final properties = snapshot.data ??[];
        int totalListings = properties.length;
        int activeTenants = properties.fold(0, (sum, prop) => sum + prop.currentTenants);

        List<String> myPropertyIds = properties.map((p) => p.id).toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(defaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children:[
              Text("Welcome back, ${_userName.toUpperCase()}.", style: const TextStyle(fontSize: 16, color: textGrey)),
              const SizedBox(height: 4),
              const Text("Here is your property summary.", style: TextStyle(fontSize: 14, color: textGrey)),
              const SizedBox(height: 20),

              Row(
                children:[
                  Expanded(child: _buildStatCard("Total Listings", totalListings.toString(), Icons.home, primaryBlue.withOpacity(0.1), primaryBlue)),
                  const SizedBox(width: 10),
                  Expanded(child: _buildStatCard("Active Tenants", activeTenants.toString(), Icons.people, Colors.green.withOpacity(0.1), Colors.green)),
                  const SizedBox(width: 10),
                  
                  // LIVE Pending Bookings Counter
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance.collection('bookings').where('status', isEqualTo: 'pending').snapshots(),
                      builder: (context, bookingSnap) {
                        int pendingCount = 0;
                        if (bookingSnap.hasData) {
                          pendingCount = bookingSnap.data!.docs.where((doc) => myPropertyIds.contains(doc['propertyId'])).length;
                        }
                        return _buildStatCard("Pending Bookings", pendingCount.toString(), Icons.calendar_today, Colors.orange.withOpacity(0.1), Colors.orange);
                      }
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children:[
                  const Text("My Active Listings", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textDark)),
                  OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12), minimumSize: const Size(0, 30), side: BorderSide(color: Colors.grey.shade300), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                    child: const Text("View All", style: TextStyle(fontSize: 12, color: textGrey)),
                  )
                ],
              ),
              const SizedBox(height: 16),

              properties.isEmpty
                  ? const Center(child: Padding(padding: EdgeInsets.all(40), child: Text("No properties listed yet.\nTap '+' to add one.", textAlign: TextAlign.center, style: TextStyle(color: textGrey))))
                  : ListView.builder(
                      shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                      itemCount: properties.length,
                      itemBuilder: (context, index) => _buildHomeownerPropertyCard(properties[index]),
                    ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBody() {
    if (_selectedIndex == 0) {
      return const StudentExplore(); // <--- REUSES THE STUDENT EXPLORE SCREENS!
    } else if (_selectedIndex == 1) {
      return _buildManageTab();  
    } else {
      return const ProfileView(); 
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: backgroundLight,
        appBar: AppBar(
          backgroundColor: backgroundLight, 
          elevation: 0, 
          title: const SmartRentalLogo(),
          
          // --- RESTORED: HOMEOWNER CHAT ICON WITH LIVE RED BADGE ---
          actions: [
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .where('unreadBy', arrayContains: _currentUserId) // Tracks unread messages for this homeowner
                  .snapshots(),
              builder: (context, snapshot) {
                bool hasUnread = snapshot.hasData && snapshot.data!.docs.isNotEmpty;

                return Stack(
                  alignment: Alignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chat_bubble_outline, color: textDark),
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatListScreen())),
                    ),
                    // Large red badge with white border
                    if (hasUnread)
                      Positioned(
                        top: 10,
                        right: 10,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: Colors.redAccent,
                            shape: BoxShape.circle,
                            border: Border.all(color: backgroundLight, width: 1.5),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
            const NotificationBell(),
            const SizedBox(width: 8),
          ],
        ),
        body: _buildBody(), 
        
        // FAB only shows on Manage tab (Index 1)
        floatingActionButton: _selectedIndex == 1
            ? FloatingActionButton(
                backgroundColor: primaryBlue, 
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddPropertyScreen())), 
                child: const Icon(Icons.add, color: Colors.white)
              )
            : null,
            
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex, onTap: (index) => setState(() => _selectedIndex = index),
          type: BottomNavigationBarType.fixed, selectedItemColor: primaryBlue, unselectedItemColor: textGrey,
          items: const[
            BottomNavigationBarItem(icon: Icon(Icons.search), label: "Explore"), // Index 0
            BottomNavigationBarItem(icon: Icon(Icons.grid_view), label: "Manage"),  // Index 1
            BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: "Account"), // Index 2
          ],
        ),
      ),
    );
  }

  // --- HELPER WIDGETS ---
  void _confirmDeleteProperty(BuildContext context, String propId, String title) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardWhite, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(children: [Icon(Icons.warning_amber_rounded, color: Colors.red), SizedBox(width: 10), Text("Delete Property?", style: TextStyle(fontWeight: FontWeight.bold, color: textDark))]),
        content: Text("Are you sure you want to permanently remove '$title'? This action cannot be undone.", style: const TextStyle(color: textGrey, height: 1.5)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel", style: TextStyle(color: textGrey))),
          ElevatedButton(
            onPressed: () async {
              await _propertyService.deleteProperty(propId); 
              if (context.mounted) { Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: Colors.red, content: Text("Property '$title' deleted."))); }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            child: const Text("Delete", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color bgColor, Color iconColor) {
    return Container(
      padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: cardWhite, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200), boxShadow:[BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children:[
          Text(title, style: const TextStyle(fontSize: 11, color: textGrey)), const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children:[Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textDark)), Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: iconColor, size: 16))])
        ],
      ),
    );
  }

  Widget _buildHomeownerPropertyCard(Property prop) {
    int vacancies = prop.capacity - prop.currentTenants;
    bool isFull = vacancies <= 0;
    double revenue = prop.price; 

    return Container(
      margin: const EdgeInsets.only(bottom: 16), decoration: BoxDecoration(color: cardWhite, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200), boxShadow:[BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 4))]),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children:[
            ClipRRect(borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), bottomLeft: Radius.circular(16)), child: Image.network(prop.imageUrls.isNotEmpty ? prop.imageUrls[0] : "https://images.unsplash.com/photo-1512917774080-9991f1c4c750?ixlib=rb-1.2.1&auto=format&fit=crop&w=300&q=80", width: 120, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => Container(width: 120, color: Colors.grey[300], child: const Icon(Icons.home, color: Colors.white)))),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children:[
                   Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: Text(prop.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textDark), maxLines: 1, overflow: TextOverflow.ellipsis)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isFull ? Colors.red.withOpacity(0.1) : primaryBlue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            isFull ? "Fully Occupied" : "$vacancies Vacancies",
                            style: TextStyle(color: isFull ? Colors.red : primaryBlue, fontSize: 9, fontWeight: FontWeight.bold),
                          ),
                        ),
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                          onPressed: () => _confirmDeleteProperty(context, prop.id, prop.title),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text("Melaka | ${prop.location}", style: const TextStyle(color: textGrey, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 6),
                    
                    Row(
                      children: [
                        const Icon(Icons.school, size: 14, color: primaryBlue),
                        const SizedBox(width: 4),
                        Text("${prop.distanceInduk} km", style: const TextStyle(color: textGrey, fontSize: 11)),
                        const SizedBox(width: 12),
                        const Icon(Icons.domain, size: 14, color: Colors.orange),
                        const SizedBox(width: 4),
                        Text("${prop.distanceTekno} km", style: const TextStyle(color: textGrey, fontSize: 11)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.people_outline, size: 14, color: textGrey), 
                        const SizedBox(width: 4),
                        Text("${prop.currentTenants}/${prop.capacity} Tenants", style: const TextStyle(color: textGrey, fontSize: 11)), 
                        const SizedBox(width: 12), 
                        const Icon(Icons.trending_up, size: 14, color: Colors.green), 
                        const SizedBox(width: 4), 
                        Text("RM ${revenue.toStringAsFixed(0)} Rev", style: const TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold)), 
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text("RM ${prop.price.toStringAsFixed(0)}/month", style: const TextStyle(color: primaryBlue, fontSize: 12, fontWeight: FontWeight.bold)),
                    const Spacer(),
                    
                    Row(
                      children:[
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: () => Navigator.push(
                              context, 
                              MaterialPageRoute(
                                builder: (_) => ManageBookingsScreen(
                                  propertyId: prop.id, 
                                  propertyTitle: prop.title
                                )
                              )
                            ),
                            style: ElevatedButton.styleFrom(backgroundColor: primaryBlue, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 8), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                            child: const Text("Manage Bookings", style: TextStyle(fontSize: 11)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 1,
                          child: OutlinedButton(
                            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AddPropertyScreen(property: prop))),
                            style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 8), side: BorderSide(color: Colors.grey.shade300), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                            child: const Text("Edit", style: TextStyle(color: textDark, fontSize: 11)),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}