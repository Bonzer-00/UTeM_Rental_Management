import 'package:flutter/material.dart';
//import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:table_calendar/table_calendar.dart'; // <--- NEW IMPORT [2]
import '../../services/booking_service.dart';
import '../../services/notification_service.dart';
import '../../services/chat_service.dart';
import '../../models/booking_model.dart';
import '../../utils/constants.dart';
import 'package:intl/intl.dart';

class ManageBookingsScreen extends StatefulWidget {
  final String propertyId;
  final String propertyTitle;

  const ManageBookingsScreen({super.key, required this.propertyId, required this.propertyTitle});

  @override
  State<ManageBookingsScreen> createState() => _ManageBookingsScreenState();
}

class _ManageBookingsScreenState extends State<ManageBookingsScreen> {
  final BookingService _bookingService = BookingService();
  final NotificationService _notificationService = NotificationService();

  // Calendar States [10]
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay; // Default select today [10]
  }

  // Check if two DateTimes are on the same day
  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundLight,
      appBar: AppBar(
        backgroundColor: backgroundLight,
        elevation: 0,
        iconTheme: const IconThemeData(color: textDark),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children:[
            const Text("Schedule & Requests", style: TextStyle(color: textDark, fontWeight: FontWeight.bold, fontSize: 18)),
            Text(widget.propertyTitle, style: const TextStyle(color: textGrey, fontSize: 12)),
          ],
        ),
      ),
      body: StreamBuilder<List<Booking>>(
        stream: _bookingService.getBookingsForProperty(widget.propertyId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: primaryBlue));
          final bookings = snapshot.data!;

          // --- 1. FILTER BOOKINGS TO MATCH SELECTED CALENDAR DAY --- [10]
          final filteredBookings = bookings.where((b) => _isSameDay(b.date, _selectedDay!)).toList();

          return Column(
            children: [
              // --- 2. INTERACTIVE CALENDAR WIDGET --- [2]
              Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardWhite,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 4, offset: const Offset(0, 2))],
                ),
                child: TableCalendar(
                  firstDay: DateTime.now().subtract(const Duration(days: 365)),
                  lastDay: DateTime.now().add(const Duration(days: 365)),
                  focusedDay: _focusedDay,
                  calendarFormat: _calendarFormat,
                  selectedDayPredicate: (day) => _isSameDay(_selectedDay!, day),
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay; 
                    });
                  },
                  onFormatChanged: (format) {
                    setState(() {
                      _calendarFormat = format;
                    });
                  },
                 
                  eventLoader: (day) {
                    return bookings.where((b) => _isSameDay(b.date, day)).toList();
                  },
                  calendarStyle: CalendarStyle(
                    todayDecoration: BoxDecoration(color: primaryBlue.withOpacity(0.2), shape: BoxShape.circle),
                    selectedDecoration: const BoxDecoration(color: primaryBlue, shape: BoxShape.circle),
                    markerDecoration: const BoxDecoration(color: primaryBlue, shape: BoxShape.circle), 
                    markerSize: 6,
                    todayTextStyle: const TextStyle(color: primaryBlue, fontWeight: FontWeight.bold),
                  ),
                  headerStyle: const HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                    titleTextStyle: TextStyle(fontWeight: FontWeight.bold, color: textDark, fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Title Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Requests for ${DateFormat('dd MMM yyyy').format(_selectedDay!)}",
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textDark),
                  ),
                ),
              ),

              // 4. Scrollable List of Bookings for selected date [10]
              Expanded(
                child: _buildFilteredList(filteredBookings),
              ),
            ],
          );
        },
      ),
    );
  }

  // --- 5. RENDER THE DETAILED BOOKING CARDS BELOW THE CALENDAR ---
  Widget _buildFilteredList(List<Booking> filteredBookings) {
    if (filteredBookings.isEmpty) {
      return const Center(child: Text("No requests scheduled for this date.", style: TextStyle(color: textGrey)));
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: filteredBookings.length,
      itemBuilder: (context, index) {
        final b = filteredBookings[index];
        bool isPending = b.status == 'pending';
        bool isApproved = b.status == 'approved';

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardWhite,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children:[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children:[
                  Row(
                    children:[
                      CircleAvatar(
                        backgroundColor: primaryBlue.withOpacity(0.1), 
                        radius: 18, 
                        child: Text(b.studentName[0].toUpperCase(), style: const TextStyle(color: primaryBlue, fontWeight: FontWeight.bold))
                      ),
                      const SizedBox(width: 10),
                      Text(b.studentName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textDark)),
                    ],
                  ),
                  if (!isPending)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), 
                      decoration: BoxDecoration(color: _getStatusBgColor(b.status), borderRadius: BorderRadius.circular(20)), 
                      child: Text(b.status == 'contract_issued' ? "CONTRACT READY" : b.status.toUpperCase(), style: TextStyle(color: _getStatusTextColor(b.status), fontSize: 10, fontWeight: FontWeight.bold))
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children:[
                  const Icon(Icons.people_outline, size: 14, color: textGrey), 
                  const SizedBox(width: 6),
                  Text("${b.groupSize} Pax", style: const TextStyle(color: textGrey, fontSize: 13)),
                ],
              ),
              if (b.additionalNames.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text("Other Tenants: ${b.additionalNames}", style: const TextStyle(color: textGrey, fontSize: 12, fontStyle: FontStyle.italic)),
              ],

              if (isPending) ...[
                const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1)),
                Row(
                  children:[
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                        child: const Text("Decline", style: TextStyle(color: Colors.red)),
                        onPressed: () async {
                          await _bookingService.updateBookingStatus(b.id, 'rejected');
                          await _notificationService.sendNotification(b.studentId, "Viewing Declined ❌", "Your viewing request for ${widget.propertyTitle} was declined.");
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                        child: const Text("Approve"),
                        onPressed: () async {
                          await _bookingService.updateBookingStatus(b.id, 'approved');
                          await _notificationService.sendNotification(b.studentId, "Viewing Approved! ✅", "Your request for ${widget.propertyTitle} is approved. Waiting for homeowner to issue contract.");
                        },
                      ),
                    ),
                  ],
                )
              ],

              if (isApproved) ...[
                const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1)),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await _bookingService.updateBookingStatus(b.id, 'contract_issued');
                      await ChatService().sendMessage(b.studentId, "Issued Tenancy Contract", type: 'contract', bookingId: b.id);
                      await _notificationService.sendNotification(b.studentId, "Tenancy Contract Issued! 📜", "The homeowner has generated your contract for ${widget.propertyTitle}. Please open your chat to review and sign.");
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(backgroundColor: Colors.green, content: Text("Tenancy Contract Issued!")));
                      }
                    },
                    icon: const Icon(Icons.gavel, size: 18),
                    label: const Text("Issue Tenancy Contract", style: TextStyle(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(backgroundColor: primaryBlue, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), padding: const EdgeInsets.symmetric(vertical: 12)),
                  ),
                )
              ]
            ],
          ),
        );
      },
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