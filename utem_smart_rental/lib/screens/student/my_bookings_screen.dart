import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/booking_model.dart';
import '../../models/property_model.dart';
import '../../utils/constants.dart';
import 'package:intl/intl.dart';
import 'contract_payment_screen.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
  final String userId = FirebaseAuth.instance.currentUser!.uid;
  late Stream<QuerySnapshot> _bookingsStream;

  @override
  void initState() {
    super.initState();
    // Initialize stream ONCE to prevent flickering
    _bookingsStream = FirebaseFirestore.instance
        .collection('bookings')
        .where('studentId', isEqualTo: userId)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundLight,
      appBar: AppBar(
        backgroundColor: backgroundLight,
        elevation: 0,
        iconTheme: const IconThemeData(color: textDark),
        title: const Text("My Viewing Requests", style: TextStyle(color: textDark, fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _bookingsStream, // <--- Uses the saved stream
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: primaryBlue));
          }
          
          final bookings = snapshot.data?.docs
              .map((doc) => Booking.fromMap(doc.data() as Map<String, dynamic>, doc.id))
              .toList() ??[];

          if (bookings.isEmpty) {
            return const Center(
              child: Text("No bookings found.", style: TextStyle(color: textGrey, fontSize: 16)),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(defaultPadding),
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              return _buildModernBookingCard(context, bookings[index]);
            },
          );
        },
      ),
    );
  }

Widget _buildModernBookingCard(BuildContext context, Booking b) {
    bool isApproved = b.status == 'approved';
    bool isContractIssued = b.status == 'contract_issued';
    bool isSigned = b.status == 'signed';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cardWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Title & Status Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    b.propertyTitle,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textDark),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _getStatusBgColor(b.status),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    b.status == 'contract_issued' ? "CONTRACT READY" : b.status.toUpperCase(),
                    style: TextStyle(
                      color: _getStatusTextColor(b.status),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Details Row
            Row(
              children: [
                const Icon(Icons.calendar_today_outlined, size: 14, color: textGrey),
                const SizedBox(width: 6),
                Text("Viewing: ${DateFormat('dd MMM yyyy').format(b.date)}", style: const TextStyle(color: textGrey, fontSize: 13)),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.people_outline, size: 16, color: textGrey),
                const SizedBox(width: 6),
                Text("Group Size: ${b.groupSize} Pax", style: const TextStyle(color: textGrey, fontSize: 13)),
              ],
            ),

            // --- Case A: Viewing is approved, waiting for homeowner to write contract ---
            if (isApproved) ...[
              const Padding(padding: EdgeInsets.symmetric(vertical: 12.0), child: Divider(height: 1)),
              const Row(
                children: [
                  Icon(Icons.hourglass_empty, color: Colors.orange, size: 18),
                  SizedBox(width: 8),
                  Text("Waiting for homeowner to issue contract...", style: TextStyle(color: Colors.orange, fontSize: 13, fontWeight: FontWeight.bold)),
                ],
              )
            ],

            // --- Case B: Contract is ready to be signed (USES REAL DATABASE DATA!) ---
            if (isContractIssued) ...[
              const Padding(padding: EdgeInsets.symmetric(vertical: 12.0), child: Divider(height: 1)),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    // 1. Show a sleek loading dialog while we fetch the real property
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) => const Center(child: CircularProgressIndicator(color: primaryBlue)),
                    );

                    try {
                      // 2. Fetch the REAL property document from your Firestore database
                      DocumentSnapshot propDoc = await FirebaseFirestore.instance
                          .collection('properties')
                          .doc(b.propertyId)
                          .get();

                      // Close the loading dialog
                      if (context.mounted) Navigator.pop(context);

                      if (propDoc.exists) {
                        // 3. Convert the Firestore document into our real Property Model!
                        Property realProperty = Property.fromMap(
                          propDoc.data() as Map<String, dynamic>, 
                          propDoc.id,
                        );

                        // 4. Open the Contract Screen with 100% REAL data!
                        if (context.mounted) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ContractPaymentScreen(
                                booking: b,
                                property: realProperty, // Real data passed here!
                              ),
                            ),
                          );
                        }
                      } else {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(backgroundColor: Colors.red, content: Text("Error: This property no longer exists in the database.")),
                          );
                        }
                      }
                    } catch (e) {
                      // Safety check: close loading dialog if there's an error
                      if (context.mounted) {
                        Navigator.pop(context); 
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(backgroundColor: Colors.red, content: Text("Error fetching property: $e")),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.gavel, size: 18),
                  label: const Text("Review & Sign Contract"),
                  style: ElevatedButton.styleFrom(backgroundColor: primaryBlue, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), padding: const EdgeInsets.symmetric(vertical: 12)),
                ),
              )
            ],

            // --- Case C: Contract is successfully signed and active ---
            if (isSigned) ...[
              const Padding(padding: EdgeInsets.symmetric(vertical: 12.0), child: Divider(height: 1)),
              const Row(
                children: [
                  Icon(Icons.verified, color: Colors.green, size: 18),
                  SizedBox(width: 8),
                  Text("Contract Signed & Active!", style: TextStyle(color: Colors.green, fontSize: 13, fontWeight: FontWeight.bold)),
                ],
              )
            ]
          ],
        ),
      ),
    );
  }

  Color _getStatusBgColor(String status) {
    if (status == 'approved') return Colors.green.withOpacity(0.1);
    if (status == 'rejected') return Colors.red.withOpacity(0.1);
    return Colors.orange.withOpacity(0.1); 
  }

  Color _getStatusTextColor(String status) {
    if (status == 'approved') return Colors.green;
    if (status == 'rejected') return Colors.red;
    return Colors.orange; 
  }
}