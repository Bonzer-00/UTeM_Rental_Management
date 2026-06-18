import 'package:flutter/material.dart';
import '../../services/booking_service.dart';
import '../../services/notification_service.dart';
import '../../services/chat_service.dart'; // <--- NEW: Import Chat Service
import '../../models/booking_model.dart';
import '../../utils/constants.dart';
import 'package:intl/intl.dart';

class ManageBookingsScreen extends StatelessWidget {
  final String propertyId;
  final String propertyTitle;

  const ManageBookingsScreen({super.key, required this.propertyId, required this.propertyTitle});

  @override
  Widget build(BuildContext context) {
    final BookingService bookingService = BookingService();
    final NotificationService notificationService = NotificationService();

    return Scaffold(
      backgroundColor: backgroundLight,
      appBar: AppBar(
        backgroundColor: backgroundLight, elevation: 0, iconTheme: const IconThemeData(color: textDark),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children:[
            const Text("Manage Requests", style: TextStyle(color: textDark, fontWeight: FontWeight.bold, fontSize: 18)),
            Text(propertyTitle, style: const TextStyle(color: textGrey, fontSize: 12)),
          ],
        ),
      ),
      body: StreamBuilder<List<Booking>>(
        stream: bookingService.getBookingsForProperty(propertyId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: primaryBlue));
          final bookings = snapshot.data!;
          if (bookings.isEmpty) return const Center(child: Text("No viewing requests yet.", style: TextStyle(color: textGrey)));

          return ListView.builder(
            padding: const EdgeInsets.all(defaultPadding),
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              final b = bookings[index];
              bool isPending = b.status == 'pending';
              bool isApproved = b.status == 'approved';

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(color: cardWhite, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200), boxShadow:[BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 4))]),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children:[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children:[
                          Row(
                            children:[
                              CircleAvatar(backgroundColor: primaryBlue.withOpacity(0.1), radius: 18, child: Text(b.studentName[0].toUpperCase(), style: const TextStyle(color: primaryBlue, fontWeight: FontWeight.bold))),
                              const SizedBox(width: 10),
                              Text(b.studentName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textDark)),
                            ],
                          ),
                          if (!isPending)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), 
                              decoration: BoxDecoration(color: _getStatusBgColor(b.status), borderRadius: BorderRadius.circular(20)), 
                              child: Text(b.status.toUpperCase(), style: TextStyle(color: _getStatusTextColor(b.status), fontSize: 10, fontWeight: FontWeight.bold))
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children:[
                          const Icon(Icons.calendar_today_outlined, size: 14, color: textGrey), const SizedBox(width: 6),
                          Text(DateFormat('dd MMM yyyy').format(b.date), style: const TextStyle(color: textGrey, fontSize: 13)),
                          const SizedBox(width: 16),
                          const Icon(Icons.people_outline, size: 14, color: textGrey), const SizedBox(width: 6),
                          Text("${b.groupSize} Pax", style: const TextStyle(color: textGrey, fontSize: 13)),
                        ],
                      ),
                      if (b.additionalNames.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text("Other Tenants: ${b.additionalNames}", style: const TextStyle(color: textGrey, fontSize: 12, fontStyle: FontStyle.italic)),
                      ],

                      // --- 1. ACTION BUTTONS FOR PENDING VIEWINGS ---
                      if (isPending) ...[
                        const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1)),
                        Row(
                          children:[
                            Expanded(
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                                child: const Text("Decline", style: TextStyle(color: Colors.red)),
                                onPressed: () async {
                                  await bookingService.updateBookingStatus(b.id, 'rejected');
                                  await notificationService.sendNotification(b.studentId, "Viewing Declined ❌", "Your viewing request for $propertyTitle was declined.");
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                                child: const Text("Approve"),
                                onPressed: () async {
                                  await bookingService.updateBookingStatus(b.id, 'approved');
                                  await notificationService.sendNotification(b.studentId, "Viewing Approved! ✅", "Your request for $propertyTitle is approved. Waiting for homeowner to issue contract.");
                                },
                              ),
                            ),
                          ],
                        )
                      ],

                      // --- 2. NEW: OPTION FOR HOMEOWNER TO ISSUE CONTRACT (AFTER APPROVAL) ---
                      if (isApproved) ...[
                        const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1)),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                           onPressed: () async {
                              // 1. Change status to contract_issued
                              await bookingService.updateBookingStatus(b.id, 'contract_issued');
                              
                              // --- 2. NEW: AUTO-SEND CONTRACT FILE INTO CHAT ROOM! --- [19, 21]
                              await ChatService().sendMessage(
                                b.studentId, 
                                "Issued Tenancy Contract",
                                type: 'contract',
                                bookingId: b.id, // Links this message to the booking ID!
                              );

                              // 3. Notify the student
                              await notificationService.sendNotification(
                                b.studentId, 
                                "Tenancy Contract Issued! 📜", 
                                "The homeowner has generated your contract for $propertyTitle. Please open your chat to review and sign."
                              );
                              
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(backgroundColor: Colors.green, content: Text("Tenancy Contract Issued!")));
                              }
                            },
                            icon: const Icon(Icons.gavel, size: 18),
                            label: const Text("Issue Tenancy Contract", style: TextStyle(fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryBlue,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        )
                      ]
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Color _getStatusBgColor(String status) {
    if (status == 'approved' || status == 'signed') return Colors.green.withOpacity(0.1);
    if (status == 'contract_issued') return Colors.orange.withOpacity(0.1);
    return Colors.red.withOpacity(0.1);
  }

  Color _getStatusTextColor(String status) {
    if (status == 'approved' || status == 'signed') return Colors.green;
    if (status == 'contract_issued') return Colors.orange;
    return Colors.red;
  }
}