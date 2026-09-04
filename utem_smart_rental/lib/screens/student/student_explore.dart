import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/property_model.dart';
import '../../models/vacancy_model.dart'; 
import '../../services/property_service.dart';
import '../../services/vacancy_service.dart'; 
import '../../utils/constants.dart';
import '../shared/chat_screen.dart'; 
import 'property_details_screen.dart';


class StudentExplore extends StatefulWidget {
  const StudentExplore({super.key});

  @override
  State<StudentExplore> createState() => _StudentExploreState();
}

class _StudentExploreState extends State<StudentExplore> {
  final PropertyService _propertyService = PropertyService();
  final VacancyService _vacancyService = VacancyService(); 

  // Search & Filter States
  String _searchQuery = "";
  double _maxPrice = 2000.0;
  String _sortBy = 'Price: Low to High';
  bool _isSearchingVacancies = false;

  // --- 1. NEW: DUAL CAMPUS DISTANCE FILTER VARIABLES ---
  double _maxDistanceInduk = 15.0; // Max distance to Main Campus (Durian Tunggal)
  double _maxDistanceTekno = 15.0; // Max distance to Technology Campus (Ayer Keroh)

  late Stream<List<Property>> _propertiesStream;

  @override
  void initState() {
    super.initState();
    _propertiesStream = _propertyService.getAllProperties();
  }

  // Fetch Property Image & Student Full Name for Roommate Finder [14, 21]
  Future<Map<String, dynamic>> _getVacancyCardDetails(String propertyId, String studentId) async {
    String imageUrl = "";
    String fullName = "Student";
    try {
      DocumentSnapshot propDoc = await FirebaseFirestore.instance.collection('properties').doc(propertyId).get();
      if (propDoc.exists) {
        var data = propDoc.data() as Map<String, dynamic>;
        List<dynamic> imgs = data['imageUrls'] ??[];
        if (imgs.isNotEmpty) imageUrl = imgs[0];
      }
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(studentId).get();
      if (userDoc.exists) {
        fullName = userDoc['name'] ?? "Student";
      }
    } catch (e) {
      debugPrint("Error loading details: $e");
    }
    return {'imageUrl': imageUrl, 'fullName': fullName};
  }

  // --- NEW: EDIT SLOTS DIALOG (WITH AUTO-HIDE LOGIC) --- [23]
  void _showEditSlotsDialog(BuildContext context, VacancyPost post) {
    final TextEditingController slotsCtrl = TextEditingController(text: post.vacantSlots.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Edit Vacant Slots", style: TextStyle(fontWeight: FontWeight.bold, color: textDark)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Update the number of empty slots left in your house:", style: TextStyle(color: textGrey, fontSize: 13)),
            const SizedBox(height: 16),
            TextField(
              controller: slotsCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Slots Left", border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: primaryBlue),
            onPressed: () async {
              int newSlots = int.tryParse(slotsCtrl.text) ?? 0;
              Navigator.pop(context); // Close dialog

              if (newSlots <= 0) {
                // --- AUTO-HIDE / DELETE IF FULL (0 SLOTS LEFT) --- [23]
                await _vacancyService.deleteVacancy(post.id);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(backgroundColor: Colors.red, content: Text("Vacancy post auto-removed because slots are full!")),
                  );
                }
              } else {
                // Update Firestore normally [23]
                await FirebaseFirestore.instance.collection('vacancies').doc(post.id).update({
                  'vacantSlots': newSlots,
                });
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(backgroundColor: Colors.green, content: Text("Slots updated successfully!")),
                  );
                }
              }
            },
            child: const Text("Save", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // Delete confirmation for Vacancies
  void _confirmDeleteVacancy(BuildContext context, String postId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Delete Post?", style: TextStyle(fontWeight: FontWeight.bold, color: textDark)),
        content: const Text("Are you sure you want to remove your roommate vacancy post?"),
        actions:[
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              _vacancyService.deleteVacancy(postId);
              Navigator.pop(context);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // Toggle Segment Bar UI (Entire Houses vs Roommate Finder) [15]
  Widget _buildToggleBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: defaultPadding, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isSearchingVacancies = false),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: !_isSearchingVacancies ? primaryBlue : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: !_isSearchingVacancies ? primaryBlue : Colors.grey.shade300),
                ),
                child: Text(
                  "Entire Houses",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: !_isSearchingVacancies ? Colors.white : textDark, fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isSearchingVacancies = true),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _isSearchingVacancies ? primaryBlue : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _isSearchingVacancies ? primaryBlue : Colors.grey.shade300),
                ),
                child: Text(
                  "Roommate Finder",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: _isSearchingVacancies ? Colors.white : textDark, fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- UPDATED: FILTER BOTTOM SHEET WITH TWO DISTANCE SLIDERS --- [23]
  void _showFilterBottomSheet() {
    FocusScope.of(context).unfocus();
    showModalBottomSheet(
      context: context, backgroundColor: cardWhite,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
            children:[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children:[
                  const Text("Filter Properties", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textDark)),
                  // Reset Button (Resets both sliders!)
                  TextButton(
                    onPressed: () {
                      setModalState(() { 
                        _maxPrice = 2000.0; 
                        _maxDistanceInduk = 15.0; // Reset [10]
                        _maxDistanceTekno = 15.0; // Reset [10]
                      });
                      setState(() { 
                        _maxPrice = 2000.0; 
                        _maxDistanceInduk = 15.0; 
                        _maxDistanceTekno = 15.0; 
                      });
                    },
                    child: const Text("Reset", style: TextStyle(color: primaryBlue, fontWeight: FontWeight.bold)),
                  )
                ],
              ),
              const SizedBox(height: 16),
              
              // 1. Rent Price Slider
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children:[const Text("Max Rent:", style: TextStyle(fontWeight: FontWeight.bold, color: textDark)), Text("RM ${_maxPrice.toStringAsFixed(0)}", style: const TextStyle(color: primaryBlue, fontWeight: FontWeight.bold))]),
              Slider(value: _maxPrice, min: 200, max: 2000, divisions: 18, activeColor: primaryBlue, onChanged: (val) { setModalState(() => _maxPrice = val); setState(() => _maxPrice = val); }),
              const SizedBox(height: 16),

              // 2. Kampus Induk Distance Slider (New)
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children:[const Text("Max Dist to Induk:", style: TextStyle(fontWeight: FontWeight.bold, color: textDark)), Text("${_maxDistanceInduk.toStringAsFixed(1)} km", style: const TextStyle(color: primaryBlue, fontWeight: FontWeight.bold))]),
              Slider(value: _maxDistanceInduk, min: 1, max: 30, divisions: 29, activeColor: primaryBlue, onChanged: (val) { setModalState(() => _maxDistanceInduk = val); setState(() => _maxDistanceInduk = val); }),
              const SizedBox(height: 16),

              // 3. Kampus Teknologi (Tekno) Distance Slider (New)
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children:[const Text("Max Dist to Tekno:", style: TextStyle(fontWeight: FontWeight.bold, color: textDark)), Text("${_maxDistanceTekno.toStringAsFixed(1)} km", style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold))]),
              Slider(value: _maxDistanceTekno, min: 1, max: 30, divisions: 29, activeColor: Colors.orange, onChanged: (val) { setModalState(() => _maxDistanceTekno = val); setState(() => _maxDistanceTekno = val); }),
              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity, height: 50, 
                child: ElevatedButton(
                  onPressed: () { FocusScope.of(context).unfocus(); Navigator.pop(context); }, 
                  style: ElevatedButton.styleFrom(backgroundColor: primaryBlue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))), 
                  child: const Text("Apply Filters", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold))
                )
              )
            ],
          ),
        ),
      ),
    );
  }

  // RENDER THE ROOMMATE FINDER FEED [17]
  Widget _buildVacancyFeed() {
    final String currentUserId = FirebaseAuth.instance.currentUser!.uid;
    return StreamBuilder<List<VacancyPost>>(
      stream: _vacancyService.getAllVacancies(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: primaryBlue));
        }
        final posts = snapshot.data ??[];
        
        final filteredPosts = posts.where((p) {
          return p.propertyTitle.toLowerCase().contains(_searchQuery) ||
                 p.description.toLowerCase().contains(_searchQuery) ||
                 p.studentName.toLowerCase().contains(_searchQuery);
        }).toList();

        if (filteredPosts.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children:[
                Icon(Icons.group_add_outlined, size: 70, color: Colors.grey.shade300),
                const SizedBox(height: 12),
                const Text("No roommate vacancies posted yet.", style: TextStyle(color: textGrey)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: defaultPadding),
          itemCount: filteredPosts.length,
          itemBuilder: (context, index) {
            return _buildVacancyCard(filteredPosts[index], currentUserId);
          },
        );
      },
    );
  }

// --- DYNAMIC HORIZONTAL VACANCY CARD (Pulls Real Image & Full Name) --- [1, 14, 17, 21, 23]
  Widget _buildVacancyCard(VacancyPost post, String currentUserId) {
    bool isMyPost = post.studentId == currentUserId;
    return FutureBuilder<Map<String, dynamic>>(
      future: _getVacancyCardDetails(post.propertyId, post.studentId), // Unified lookup [14, 21]
      builder: (context, snapshot) {
        String imageUrl = snapshot.data?['imageUrl'] ?? "";
        String fullName = snapshot.data?['fullName'] ?? "Loading..."; // Real Full Name [21]

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: cardWhite, borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow:[BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 4))],
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children:[
                // Left side: Real Property Thumbnail [1, 14]
                ClipRRect(
                  borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), bottomLeft: Radius.circular(16)),
                  child: imageUrl.isNotEmpty
                      ? Image.network(imageUrl, width: 130, fit: BoxFit.cover)
                      : Container(width: 130, color: Colors.grey[200], child: const Icon(Icons.home, color: Colors.white, size: 40)),
                ),
                
                // Right side: Details Column
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children:[
                        // --- ROW 1: TITLE & ACTION BUTTONS --- [23]
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children:[
                            Expanded(
                              child: Text(
                                post.propertyTitle, 
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: textDark),
                                maxLines: 1, 
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isMyPost) ...[
                              const SizedBox(width: 8),
                              IconButton(
                                padding: EdgeInsets.zero, constraints: const BoxConstraints(),
                                icon: const Icon(Icons.edit_outlined, color: primaryBlue, size: 18),
                                onPressed: () => _showEditSlotsDialog(context, post), 
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                padding: EdgeInsets.zero, constraints: const BoxConstraints(),
                                icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
                                onPressed: () => _confirmDeleteVacancy(context, post.id),
                              )
                            ],
                          ],
                        ),
                        const SizedBox(height: 6),
                        
                        // --- ROW 2: POSTER NAME & ORANGE SLOTS BADGE --- [21, 23]
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                "Posted by: $fullName ${isMyPost ? '(You)' : ''}", // Uses 'fullName' directly! [21]
                                style: const TextStyle(color: textGrey, fontSize: 11, fontWeight: FontWeight.bold),
                                maxLines: 1, 
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                              child: Text("${post.vacantSlots} Slots Left", style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 9)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        
                        // Description text
                        Text(
                          post.description, 
                          style: const TextStyle(color: textGrey, fontSize: 12),
                          maxLines: 2, overflow: TextOverflow.ellipsis,
                        ),
                        
                        const Spacer(), // Pushes rent and button to the bottom
                        
                        // Row 3: Price & Chat Button
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children:[
                            Text(
                              "RM ${post.price.toStringAsFixed(0)}/mo", 
                              style: const TextStyle(color: primaryBlue, fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                            if (!isMyPost)
                              SizedBox(
                                height: 30,
                                child: ElevatedButton(
                                  onPressed: () {
                                    Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(receiverId: post.studentId, receiverName: fullName)));
                                  },
                                  style: ElevatedButton.styleFrom(backgroundColor: primaryBlue, elevation: 0, padding: const EdgeInsets.symmetric(horizontal: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                                  child: const Text("Chat with Tenant", style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
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
      },
    );
  }

  // --- HORIZONTAL PROPERTY CARD --- [1]
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
              // Left Photo [1]
              ClipRRect(
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), bottomLeft: Radius.circular(16)),
                child: Image.network(
                  prop.imageUrls.isNotEmpty ? prop.imageUrls[0] : "https://images.unsplash.com/photo-1568605114967-8130f3a36994?ixlib=rb-1.2.1&auto=format&fit=crop&w=300&q=80", 
                  width: 130, fit: BoxFit.cover, 
                  errorBuilder: (context, error, stackTrace) => Container(width: 130, color: Colors.grey[300], child: const Icon(Icons.home, color: Colors.white, size: 40)),
                ),
              ),
              
              // Right Details
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

  @override
  Widget build(BuildContext context) {
    return Column(
      children:[
        _buildToggleBar(), // [15]

        Padding(
          padding: const EdgeInsets.all(defaultPadding),
          child: Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow:[BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]),
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
              decoration: InputDecoration(
                hintText: _isSearchingVacancies ? 'Search roommate vacancies...' : 'Search area or facilities...',
                hintStyle: const TextStyle(color: textGrey),
                prefixIcon: const Icon(Icons.search, color: textGrey),
                suffixIcon: _isSearchingVacancies 
                  ? null 
                  : IconButton(icon: const Icon(Icons.tune, color: primaryBlue), onPressed: _showFilterBottomSheet),
                border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(vertical: 15),
              ),
            ),
          ),
        ),

        Expanded(
          child: _isSearchingVacancies 
              ? _buildVacancyFeed() // Shows Student Listings with Gallery Image & Full Name! [17]
              : StreamBuilder<List<Property>>( 
                  stream: _propertiesStream,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: primaryBlue));
                    if (!snapshot.hasData || snapshot.data!.isEmpty) return const Center(child: Text('No properties available.', style: TextStyle(color: textGrey)));

                    // Apply Filters
                    var properties = snapshot.data!.where((p) {
                      bool matchesSearch = p.location.toLowerCase().contains(_searchQuery) || p.title.toLowerCase().contains(_searchQuery) || p.description.toLowerCase().contains(_searchQuery) || p.facilities.any((f) => f.toLowerCase().contains(_searchQuery));
                      
                      // --- UPDATED DUAL DISTANCE CHECK --- [10]
                      bool matchesDistance = p.distanceInduk <= _maxDistanceInduk && p.distanceTekno <= _maxDistanceTekno;
                      bool matchesPrice = p.price <= _maxPrice;
                      
                      bool hasVacancy = p.currentTenants < p.capacity; 
                      return matchesSearch && matchesDistance && matchesPrice && hasVacancy;
                    }).toList();

                    // Apply Sorting
                   // --- UPDATED: DUAL CAMPUS SORTING ALGORITHMS ---
                      if (_sortBy == 'Price: Low to High') {
                        properties.sort((a, b) => a.price.compareTo(b.price));
                      } else if (_sortBy == 'Price: High to Low') {
                        properties.sort((a, b) => b.price.compareTo(a.price));
                      } else if (_sortBy == 'Nearest to UTeM Induk') { // <--- UPDATED
                        properties.sort((a, b) => a.distanceInduk.compareTo(b.distanceInduk));
                      } else if (_sortBy == 'Nearest to UTeM Tekno') { // <--- NEW
                        properties.sort((a, b) => a.distanceTekno.compareTo(b.distanceTekno));
                      }

                    return Column(
                      children:[
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: defaultPadding),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children:[
                              Text("${properties.length} Properties", style: const TextStyle(fontWeight: FontWeight.bold, color: textDark, fontSize: 14)),
                              PopupMenuButton<String>(
                                onOpened: () => FocusScope.of(context).unfocus(),
                                onSelected: (value) { FocusScope.of(context).unfocus(); setState(() => _sortBy = value); },
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                color: cardWhite,
                                child: Row(
                                  children:[
                                    Text(_sortBy, style: const TextStyle(color: primaryBlue, fontSize: 12, fontWeight: FontWeight.bold)),
                                    const Icon(Icons.keyboard_arrow_down, color: primaryBlue, size: 20),
                                  ],
                                ),
                                itemBuilder: (context) =>[
                                  const PopupMenuItem(value: 'Price: Low to High', child: Text('Price: Low to High', style: TextStyle(fontSize: 13))),
                                  const PopupMenuItem(value: 'Price: High to Low', child: Text('Price: High to Low', style: TextStyle(fontSize: 13))),
                                  const PopupMenuItem(value: 'Nearest to UTeM Induk', child: Text('Nearest to UTeM Induk', style: TextStyle(fontSize: 13))),
                                  const PopupMenuItem(value: 'Nearest to UTeM Tekno', child: Text('Nearest to UTeM Tekno', style: TextStyle(fontSize: 13))),
                                ],
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
}

// --- PINCH-TO-ZOOM IMAGE VIEWER --- [23]
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
            child: InteractiveViewer(
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