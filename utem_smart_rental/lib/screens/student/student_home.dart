import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/property_model.dart';
import '../../services/property_service.dart';
import '../../utils/constants.dart';
//import '../auth/login_screen.dart';
import 'property_details_screen.dart';
import 'my_bookings_screen.dart';
import '../shared/profile_view.dart';
import '../shared/notification_bell.dart';
import '../shared/chat_list_screen.dart'; // <--- NEW IMPORT

class StudentHome extends StatefulWidget {
  const StudentHome({super.key});

  @override
  State<StudentHome> createState() => _StudentHomeState();
}

class _StudentHomeState extends State<StudentHome> {
  final PropertyService _propertyService = PropertyService();
  
  int _selectedIndex = 1; 

  String _searchQuery = "";
  double _maxDistance = 15.0; 
  double _maxPrice = 1500.0;
  String _sortBy = 'Price: Low to High';

  late Stream<List<Property>> _propertiesStream;

  @override
  void initState() {
    super.initState();
    _propertiesStream = _propertyService.getAllProperties();
  }

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

  Widget _buildStudentHomeTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children:[
          Icon(Icons.dashboard_customize_outlined, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text("Student Dashboard Overview", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textDark)),
          const SizedBox(height: 8),
          const Text("Coming soon in the next update.", style: TextStyle(color: textGrey)),
        ],
      ),
    );
  }

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
                hintText: 'Search area or facilities...', hintStyle: const TextStyle(color: textGrey),
                prefixIcon: const Icon(Icons.search, color: textGrey),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.tune, color: primaryBlue),
                  onPressed: () { FocusScope.of(context).unfocus(); _showFilterBottomSheet(); },
                ),
                border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(vertical: 15),
              ),
            ),
          ),
        ),

        Expanded(
          child: StreamBuilder<List<Property>>(
            stream: _propertiesStream,
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
                              items:['Price: Low to High', 'Price: High to Low', 'Nearest to UTeM']
                                  .map<DropdownMenuItem<String>>((String value) => DropdownMenuItem<String>(
                                        value: value,
                                        child: Text(value),
                                      ))
                                  .toList(),
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
                          itemBuilder: (context, index) => _buildPropertyCard(properties[index]),
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

  Widget _buildPropertyCard(Property prop) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus(); 
        Navigator.push(context, MaterialPageRoute(builder: (_) => PropertyDetailsScreen(property: prop)));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(color: cardWhite, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200), boxShadow:[BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 4))]),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children:[
              ClipRRect(
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), bottomLeft: Radius.circular(16)),
                child: Image.network(
                  prop.imageUrls.isNotEmpty 
                      ? prop.imageUrls[0] 
                      : "https://images.unsplash.com/photo-1568605114967-8130f3a36994?ixlib=rb-1.2.1&auto=format&fit=crop&w=300&q=80", 
                  width: 130, fit: BoxFit.cover, 
                  errorBuilder: (context, error, stackTrace) => Container(width: 130, color: Colors.grey[300], child: const Icon(Icons.home, color: Colors.white, size: 40)),
                ),
              ),
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
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(prop.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textDark), maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Text(prop.description, style: const TextStyle(color: textGrey, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                      const Spacer(),
                      Wrap(
                        spacing: 6, runSpacing: 4,
                        children: prop.facilities.take(3).map((f) => Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: primaryBlue.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Text(f, style: const TextStyle(color: primaryBlue, fontSize: 10, fontWeight: FontWeight.bold)))).toList(),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- 2. UPDATED BODY TAB ROUTER ---
  Widget _buildBody() {
    if (_selectedIndex == 0) return _buildStudentHomeTab();
    if (_selectedIndex == 1) return _buildExploreTab();
    if (_selectedIndex == 2) return const ChatListScreen(); // <--- NEW CHAT LIST TAB! [18]
    return const ProfileView();
  }

  @override
  Widget build(BuildContext context) {
    final String uid = FirebaseAuth.instance.currentUser!.uid;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: backgroundLight,
        
        // --- 3. DYNAMIC APPBAR LOGIC ---
        appBar: _selectedIndex == 2 
            ? null // Hide main AppBar because ChatListScreen has its own custom AppBar!
            : AppBar(
                backgroundColor: backgroundLight, 
                elevation: 0, 
                title: _selectedIndex == 3 
                    ? const Text("My Profile", style: TextStyle(color: textDark, fontWeight: FontWeight.bold, fontSize: 18))
                    : const SmartRentalLogo(),
                actions: _selectedIndex == 3
                    ? null // No notification/booking bell on the Profile tab
                    : [
                        const NotificationBell(),
                        if (_selectedIndex == 1) // Only show bookings button on the Explore Tab
                          IconButton(
                            icon: const Icon(Icons.calendar_month, color: textDark), 
                            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyBookingsScreen()))
                          ),
                        const SizedBox(width: 8),
                      ],
              ),
        
        body: _buildBody(), 

        // --- 4. THE 4-ITEM BOTTOM NAVIGATION BAR WITH UNREAD BADGE ---
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
          type: BottomNavigationBarType.fixed, selectedItemColor: primaryBlue, unselectedItemColor: textGrey,
          items:[
            const BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: "Home"),
            const BottomNavigationBarItem(icon: Icon(Icons.search), label: "Explore"),
            
           // --- NEW: CHAT ICON WITH LIVE BIGGER RED DOT BADGE --- [15, 23]
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
                    smallSize: 12, // <--- THE FIX: Double the default size! [15]
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