import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/property_model.dart';
import '../../services/property_service.dart';
import '../../utils/constants.dart';
//import '../auth/login_screen.dart';
import 'add_property_screen.dart';
import 'manage_bookings_screen.dart';
import '../shared/profile_view.dart';
import '../shared/notification_bell.dart';
import '../student/property_details_screen.dart';
import '../shared/chat_list_screen.dart'; // To view explore details

class HomeownerHome extends StatefulWidget {
  const HomeownerHome({super.key});

  @override
  State<HomeownerHome> createState() => _HomeownerHomeState();
}

class _HomeownerHomeState extends State<HomeownerHome> {
  final PropertyService _propertyService = PropertyService();
  final String _currentUserId = FirebaseAuth.instance.currentUser!.uid;
  final String _userName = FirebaseAuth.instance.currentUser!.email!.split('@')[0];
  
  int _selectedIndex = 2; 

  late Stream<List<Property>> _myPropertiesStream;
  late Stream<List<Property>> _allPropertiesStream;

  // Search & Filter States for Explore Tab
  String _searchQuery = "";
  double _maxDistance = 15.0; 
  double _maxPrice = 1500.0;
  String _sortBy = 'Price: Low to High';

  @override
  void initState() {
    super.initState();
    _myPropertiesStream = _propertyService.getHomeownerProperties(_currentUserId);
    _allPropertiesStream = _propertyService.getAllProperties(); // For Explore Tab
  }

  // --- FILTER BOTTOM SHEET (For Explore Tab) ---
  void _showFilterBottomSheet() {
    FocusScope.of(context).unfocus();
    showModalBottomSheet(
      context: context, backgroundColor: cardWhite,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
                children:[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children:[
                      const Text("Filter Properties", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textDark)),
                      TextButton(
                        onPressed: () {
                          setModalState(() { _maxPrice = 1500.0; _maxDistance = 15.0; });
                          setState(() { _maxPrice = 1500.0; _maxDistance = 15.0; });
                        },
                        child: const Text("Reset", style: TextStyle(color: primaryBlue, fontWeight: FontWeight.bold)),
                      )
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children:[const Text("Max Monthly Rent:", style: TextStyle(fontWeight: FontWeight.bold, color: textDark)), Text("RM ${_maxPrice.toStringAsFixed(0)}", style: const TextStyle(color: primaryBlue, fontWeight: FontWeight.bold))]),
                  Slider(value: _maxPrice, min: 200, max: 2000, divisions: 18, activeColor: primaryBlue, onChanged: (val) { setModalState(() => _maxPrice = val); setState(() => _maxPrice = val); }),
                  const SizedBox(height: 16),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children:[const Text("Max Distance to UTeM:", style: TextStyle(fontWeight: FontWeight.bold, color: textDark)), Text("${_maxDistance.toStringAsFixed(1)} km", style: const TextStyle(color: primaryBlue, fontWeight: FontWeight.bold))]),
                  Slider(value: _maxDistance, min: 1, max: 30, divisions: 29, activeColor: primaryBlue, onChanged: (val) { setModalState(() => _maxDistance = val); setState(() => _maxDistance = val); }),
                  const SizedBox(height: 30),
                  SizedBox(width: double.infinity, height: 50, child: ElevatedButton(onPressed: () { FocusScope.of(context).unfocus(); Navigator.pop(context); }, style: ElevatedButton.styleFrom(backgroundColor: primaryBlue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))), child: const Text("Apply Filters", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold))))
                ],
              ),
            );
          }
        );
      }
    );
  }

  // --- EXPLORE TAB ---
  Widget _buildExploreTab() {
    return Column(
      children:[
        Padding(
          padding: const EdgeInsets.all(defaultPadding),
          child: Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow:[BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]),
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Search area or facilities...', hintStyle: const TextStyle(color: textGrey), prefixIcon: const Icon(Icons.search, color: textGrey),
                suffixIcon: IconButton(icon: const Icon(Icons.tune, color: primaryBlue), onPressed: () { FocusScope.of(context).unfocus(); _showFilterBottomSheet(); }),
                border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(vertical: 15),
              ),
            ),
          ),
        ),
        Expanded(
          child: StreamBuilder<List<Property>>(
            stream: _allPropertiesStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: primaryBlue));
              if (!snapshot.hasData || snapshot.data!.isEmpty) return const Center(child: Text('No properties available.', style: TextStyle(color: textGrey)));

              var properties = snapshot.data!.where((p) {
                bool matchesSearch = p.location.toLowerCase().contains(_searchQuery) || p.title.toLowerCase().contains(_searchQuery) || p.description.toLowerCase().contains(_searchQuery) || p.facilities.any((f) => f.toLowerCase().contains(_searchQuery));
                return matchesSearch && p.distanceTekno <= _maxDistance && p.distanceInduk <= _maxDistance && p.price <= _maxPrice;
              }).toList();

              if (_sortBy == 'Price: Low to High') properties.sort((a, b) => a.price.compareTo(b.price));
              else if (_sortBy == 'Price: High to Low') properties.sort((a, b) => b.price.compareTo(a.price));
              else if (_sortBy == 'Nearest to UTeM') properties.sort((a, b) => a.distanceTekno.compareTo(b.distanceTekno));

              return Column(
                children:[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: defaultPadding),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children:[
                        Text("${properties.length} Properties", style: const TextStyle(fontWeight: FontWeight.bold, color: textDark, fontSize: 14)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                          decoration: BoxDecoration(color: primaryBlue.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _sortBy, icon: const Icon(Icons.keyboard_arrow_down, color: primaryBlue, size: 18), dropdownColor: cardWhite, borderRadius: BorderRadius.circular(12), style: const TextStyle(color: primaryBlue, fontSize: 12, fontWeight: FontWeight.bold),
                              onChanged: (String? newValue) { FocusScope.of(context).unfocus(); if (newValue != null) setState(() => _sortBy = newValue); },
                              items:['Price: Low to High', 'Price: High to Low', 'Nearest to UTeM'].map<DropdownMenuItem<String>>((String value) => DropdownMenuItem<String>(value: value, child: Text(value))).toList(),
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  properties.isEmpty 
                    ? const Expanded(child: Center(child: Text("No properties match your filters.", style: TextStyle(color: textGrey))))
                    : Expanded(
                        child: ListView.builder(
                          itemCount: properties.length, padding: const EdgeInsets.symmetric(horizontal: defaultPadding),
                          itemBuilder: (context, index) => _buildExplorePropertyCard(properties[index]),
                        ),
                      ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  // --- MANAGE TAB ---
  Widget _buildManageTab() {
    return StreamBuilder<List<Property>>(
      stream: _myPropertiesStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: primaryBlue));

        final properties = snapshot.data ??[];
        int totalListings = properties.length;
        int activeTenants = properties.fold(0, (sum, prop) => sum + prop.currentTenants);

        // Get list of property IDs to count pending bookings
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
                          // Filter bookings that belong to this homeowner's properties
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
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children:[
            Icon(Icons.dashboard_customize_outlined, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            const Text("Homeowner Dashboard", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textDark)),
            const SizedBox(height: 8),
            const Text("Coming soon in the next update.", style: TextStyle(color: textGrey)),
          ],
        ),
      );
    } else if (_selectedIndex == 1) {
      return _buildExploreTab();
    } else if (_selectedIndex == 2) {
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
          backgroundColor: backgroundLight, elevation: 0, title: const SmartRentalLogo(),
         actions:[
         StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('chats')
                .where('unreadBy', arrayContains: _currentUserId) // Check if unread by me [23]
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
                  // BIGGER RED BADGE (12x12 pixels with white border!) [15]
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
        floatingActionButton: _selectedIndex == 2
            ? FloatingActionButton(backgroundColor: primaryBlue, onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddPropertyScreen())), child: const Icon(Icons.add, color: Colors.white))
            : null,
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex, onTap: (index) => setState(() => _selectedIndex = index),
          type: BottomNavigationBarType.fixed, selectedItemColor: primaryBlue, unselectedItemColor: textGrey,
          items: const[
            BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: "Home"),
            BottomNavigationBarItem(icon: Icon(Icons.search), label: "Explore"),
            BottomNavigationBarItem(icon: Icon(Icons.grid_view), label: "Manage"),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: "Account"),
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
    double revenue = prop.price;  //* prop.currentTenants;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cardWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left Image
            ClipRRect(
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), bottomLeft: Radius.circular(16)),
              child: Image.network(
                prop.imageUrls.isNotEmpty ? prop.imageUrls[0] : "https://images.unsplash.com/photo-1512917774080-9991f1c4c750?ixlib=rb-1.2.1&auto=format&fit=crop&w=300&q=80",
                width: 120, fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(width: 120, color: Colors.grey[300], child: const Icon(Icons.home, color: Colors.white)),
              ),
            ),
            
            // Right Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                    
                    // --- DUAL DISTANCES ROW ---
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

                    // --- TENANTS & REVENUE ROW ---
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

                    // --- RESTORED: ACTION BUTTONS ROW (ADDED HERE) ---
                    Row(
                      children: [
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
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryBlue, 
                              foregroundColor: Colors.white, 
                              padding: const EdgeInsets.symmetric(vertical: 8), 
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
                            ),
                            child: const Text("Manage", style: TextStyle(fontSize: 11)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 1,
                          child: OutlinedButton(
                            onPressed: () => Navigator.push(
                              context, 
                              MaterialPageRoute(
                                builder: (_) => AddPropertyScreen(property: prop)
                              )
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 8), 
                              side: BorderSide(color: Colors.grey.shade300), 
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
                            ),
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

  // Used for Explore tab
  Widget _buildExplorePropertyCard(Property prop) {
    return GestureDetector(
      onTap: () { FocusScope.of(context).unfocus(); Navigator.push(context, MaterialPageRoute(builder: (_) => PropertyDetailsScreen(property: prop))); },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16), decoration: BoxDecoration(color: cardWhite, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200), boxShadow:[BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 4))]),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children:[
              ClipRRect(borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), bottomLeft: Radius.circular(16)), child: Image.network(prop.imageUrls.isNotEmpty ? prop.imageUrls[0] : "https://images.unsplash.com/photo-1568605114967-8130f3a36994?ixlib=rb-1.2.1&auto=format&fit=crop&w=300&q=80", width: 130, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => Container(width: 130, color: Colors.grey[300], child: const Icon(Icons.home, color: Colors.white, size: 40)))),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children:[
                     Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween, 
                        children:[
                          Text("RM ${prop.price.toStringAsFixed(0)}/mo", style: const TextStyle(color: primaryBlue, fontWeight: FontWeight.bold, fontSize: 14)), 
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Row(children: [const Icon(Icons.school, size: 12, color: primaryBlue), const SizedBox(width: 2), Text("${prop.distanceInduk}km", style: const TextStyle(color: primaryBlue, fontSize: 11, fontWeight: FontWeight.bold))]),
                              Row(children: [const Icon(Icons.domain, size: 12, color: Colors.orange), const SizedBox(width: 2), Text("${prop.distanceTekno}km", style: const TextStyle(color: Colors.orange, fontSize: 11, fontWeight: FontWeight.bold))]),
                            ],
                          )
                        ]
                      ),
                    ]
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}