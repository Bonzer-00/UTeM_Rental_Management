import 'package:flutter/material.dart';
//import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/property_model.dart';
import '../../models/booking_model.dart';
import '../../services/booking_service.dart';
import '../../utils/constants.dart';
import '../../services/notification_service.dart';
import '../shared/chat_screen.dart';

class PropertyDetailsScreen extends StatefulWidget {
  final Property property;
  const PropertyDetailsScreen({super.key, required this.property});

  @override
  State<PropertyDetailsScreen> createState() => _PropertyDetailsScreenState();
}

class _PropertyDetailsScreenState extends State<PropertyDetailsScreen> {
  int _currentImageIndex = 0;
  late List<String> _propertyImages;
  bool _isCheckingBooking = false; // Loading state for the button

  @override
  void initState() {
    super.initState();
    if (widget.property.imageUrls.isNotEmpty) {
      _propertyImages = widget.property.imageUrls;
    } else {
      _propertyImages =[
        "https://images.unsplash.com/photo-1568605114967-8130f3a36994?ixlib=rb-1.2.1&auto=format&fit=crop&w=800&q=80",
        "https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?ixlib=rb-1.2.1&auto=format&fit=crop&w=800&q=80",
      ];
    }
  }

  // Check if student already booked this house ---
  Future<void> _handleBookViewingClick() async {
    setState(() => _isCheckingBooking = true);
    final user = FirebaseAuth.instance.currentUser;
    
    if (user != null) {
      // Check Firestore for existing booking for THIS property by THIS student
      var query = await FirebaseFirestore.instance
          .collection('bookings')
          .where('propertyId', isEqualTo: widget.property.id)
          .where('studentId', isEqualTo: user.uid)
          .where('status', whereIn: ['pending', 'approved'])
          .get();

      if (query.docs.isNotEmpty) {
        setState(() => _isCheckingBooking = false);
        if (!mounted) return;
        
        String status = query.docs.first['status'];
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: status == 'approved' ? Colors.green : Colors.orange,
            content: Text(status == 'approved' 
              ? "You already have an approved viewing for this property!" 
              : "You already have a pending request for this property!"),
          )
        );
        return; // Stop them from booking again
      }
    }
    
    setState(() => _isCheckingBooking = false);
    if (mounted) _showSleekBookingSheet();
  }

 void _showSleekBookingSheet() {
    int groupSize = 1;
    int availableSlots = widget.property.capacity - widget.property.currentTenants;

    showModalBottomSheet(
      context: context,
      backgroundColor: cardWhite,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children:[
                  const Text("Request a Viewing", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textDark)),
                  const SizedBox(height: 8),
                  Text("How many people will be staying?", style: TextStyle(color: textGrey.withOpacity(0.8), fontSize: 14)),
                  const SizedBox(height: 24),

                  // Group Size Counter
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children:[
                      const Text("Group Size", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textDark)),
                      Container(
                        decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300)),
                        child: Row(
                          children:[
                            IconButton(
                              icon: const Icon(Icons.remove, color: primaryBlue),
                              onPressed: groupSize > 1 ? () => setSheetState(() => groupSize--) : null,
                            ),
                            Text("$groupSize", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textDark)),
                            IconButton(
                              icon: const Icon(Icons.add, color: primaryBlue),
                              onPressed: groupSize < availableSlots ? () => setSheetState(() => groupSize++) : null,
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text("Only $availableSlots slots available", style: const TextStyle(color: Colors.orange, fontSize: 12)),
                  ),
                  const SizedBox(height: 30),

                  // Pick Date Button
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        DateTime? selectedDate = await showDatePicker(
                          context: context, initialDate: DateTime.now(), firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 30)),
                          builder: (context, child) => Theme(data: Theme.of(context).copyWith(colorScheme: const ColorScheme.light(primary: primaryBlue, onPrimary: Colors.white, onSurface: textDark)), child: child!),
                        );

                        if (selectedDate != null) {
                          final user = FirebaseAuth.instance.currentUser;
                          
                          // 1. Create Booking Object (Friends removed, using groupSize counter directly)
                          Booking newBooking = Booking(
                            id: '', propertyId: widget.property.id, propertyTitle: widget.property.title,
                            studentId: user!.uid, studentName: user.email!.split('@')[0], date: selectedDate,
                            groupSize: groupSize, additionalNames: '', 
                          );

                          // 2. Save Booking to Database
                          await BookingService().createBooking(newBooking);
                          
                          // 3. Send Notification to Homeowner
                          await NotificationService().sendNotification(
                            widget.property.homeownerId, 
                            "New Viewing Request 📅", 
                            "${newBooking.studentName} requested to view ${widget.property.title} for a group of $groupSize."
                          );

                          if (context.mounted) {
                            Navigator.pop(context); // Close sheet
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(backgroundColor: Colors.green, content: Text("Viewing Request Sent!")));
                          }
                        }
                      },
                      icon: const Icon(Icons.calendar_month, color: Colors.white),
                      label: const Text("Select Date & Submit", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(backgroundColor: primaryBlue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    ),
                  )
                ],
              ),
            );
          }
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    double deposit = widget.property.price * 2;
    double totalMoveIn = widget.property.price + deposit + 100.0;

    return Scaffold(
      backgroundColor: backgroundLight,
      body: Stack(
        children:[
          Positioned(
            top: 0, left: 0, right: 0,
            child: Container(
              height: 320, color: Colors.black87, 
              child: Stack(
                children:[
                  PageView.builder(
                    itemCount: _propertyImages.length,
                    onPageChanged: (index) => setState(() => _currentImageIndex = index),
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => FullScreenImageViewer(images: _propertyImages, initialIndex: index))),
                        child: Image.network(_propertyImages[index], fit: BoxFit.contain, errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey[800], child: const Icon(Icons.home, size: 80, color: Colors.white))),
                      );
                    },
                  ),
                  Positioned(
                    bottom: 40, left: 0, right: 0, 
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: _propertyImages.asMap().entries.map((entry) {
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: _currentImageIndex == entry.key ? 18.0 : 8.0, height: 8.0, margin: const EdgeInsets.symmetric(horizontal: 4.0),
                          decoration: BoxDecoration(borderRadius: BorderRadius.circular(4), color: Colors.white.withOpacity(_currentImageIndex == entry.key ? 0.9 : 0.4)),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          Positioned(
            top: 40, left: 16,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow:[BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8)]), child: const Icon(Icons.arrow_back, color: textDark)),
            ),
          ),

          Positioned.fill(
            top: 280, 
            child: Container(
              decoration: const BoxDecoration(color: backgroundLight, borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30))),
              child: Column(
                children:[
                  const SizedBox(height: 12),
                  Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10))),
                  const SizedBox(height: 16), 

                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.only(left: defaultPadding, right: defaultPadding, bottom: 20), 
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children:[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween, crossAxisAlignment: CrossAxisAlignment.start,
                            children:[
                              Expanded(child: Text(widget.property.title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textDark, height: 1.2))),
                              const SizedBox(width: 10),
                              Text("RM ${widget.property.price.toStringAsFixed(0)}", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: primaryBlue)),
                            ],
                          ),
                          const SizedBox(height: 8),
                         // --- DUAL CAMPUS DISTANCES BADGES ---
                          Row(
                            children: [
                              const Icon(Icons.location_on, color: Colors.redAccent, size: 18),
                              const SizedBox(width: 4),
                              Expanded(child: Text(widget.property.location, style: const TextStyle(fontSize: 14, color: textGrey))),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(color: primaryBlue.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                                child: Row(
                                  children: [
                                    const Icon(Icons.school, color: primaryBlue, size: 16),
                                    const SizedBox(width: 6),
                                    Text("${widget.property.distanceInduk} km to Induk", style: const TextStyle(color: primaryBlue, fontWeight: FontWeight.bold, fontSize: 12)),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                                child: Row(
                                  children: [
                                    const Icon(Icons.domain, color: Colors.orange, size: 16),
                                    const SizedBox(width: 6),
                                    Text("${widget.property.distanceTekno} km to Tekno", style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 12)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          const SizedBox(height: 24),
                          const Text("Description", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textDark)),
                          const SizedBox(height: 8),
                          Text(widget.property.description, style: const TextStyle(fontSize: 14, color: textGrey, height: 1.5)),
                          const SizedBox(height: 24),
                          const Text("Facilities", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textDark)),
                          const SizedBox(height: 12),
                          Wrap(spacing: 8, runSpacing: 8, children: widget.property.facilities.map((f) => Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), decoration: BoxDecoration(color: primaryBlue.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Text(f, style: const TextStyle(color: primaryBlue, fontWeight: FontWeight.bold, fontSize: 12)))).toList()),
                          const Divider(height: 40, color: Colors.black12),
                          const Text("Estimated Move-in Cost", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textDark)),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: cardWhite, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
                            child: Column(children:[_buildCostRow("Monthly Rent", "RM ${widget.property.price.toStringAsFixed(0)}"), _buildCostRow("Security Deposit (2x)", "RM ${deposit.toStringAsFixed(0)}"), _buildCostRow("Utility Deposit", "RM 100"), const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider()), Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children:[const Text("Total Move-in Cost", style: TextStyle(fontWeight: FontWeight.bold, color: textDark, fontSize: 16)), Text("RM ${totalMoveIn.toStringAsFixed(0)}", style: const TextStyle(fontWeight: FontWeight.bold, color: primaryBlue, fontSize: 18))])]),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),

      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: defaultPadding, vertical: 16),
        decoration: BoxDecoration(color: cardWhite, boxShadow:[BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))]),
        child: SafeArea(
          child: Row(
            children:[
              // --- IN-APP CHAT BUTTON (REPLACED WHATSAPP!) ---
              Container(
                decoration: BoxDecoration(color: primaryBlue.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: IconButton(
                  icon: const Icon(Icons.chat_bubble_outline, color: primaryBlue, size: 28),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatScreen(
                          receiverId: widget.property.homeownerId,
                          receiverName: "Homeowner", 
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 16),
              
              // --- CORRECTED: BOOK VIEWING BUTTON ---
              Expanded(
                child: SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isCheckingBooking ? null : () => _handleBookViewingClick(), // <--- THE FIX
                    style: ElevatedButton.styleFrom(backgroundColor: primaryBlue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    child: _isCheckingBooking 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text("Book Viewing", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCostRow(String label, String value) {
    return Padding(padding: const EdgeInsets.only(bottom: 8.0), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children:[Text(label, style: const TextStyle(color: textGrey, fontSize: 14)), Text(value, style: const TextStyle(color: textDark, fontWeight: FontWeight.bold, fontSize: 14))]));
  }
}

// --- FULLSCREEN VIEWER ---
class FullScreenImageViewer extends StatefulWidget {
  final List<String> images;
  final int initialIndex;

  const FullScreenImageViewer({super.key, required this.images, required this.initialIndex});

  @override
  State<FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<FullScreenImageViewer> {
  late PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, 
      body: Stack(
        children:[
          PageView.builder(controller: _pageController, onPageChanged: (idx) => setState(() => _currentIndex = idx), itemCount: widget.images.length, itemBuilder: (context, index) { return InteractiveViewer(child: Image.network(widget.images[index], fit: BoxFit.contain)); }),
          Positioned(top: 50, left: 16, child: IconButton(icon: const Icon(Icons.close, color: Colors.white, size: 30), onPressed: () => Navigator.pop(context))),
          Positioned(bottom: 40, left: 0, right: 0, child: Text("${_currentIndex + 1} / ${widget.images.length}", textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 2))),
        ],
      ),
    );
  }
}