import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart'; // Added for Date formatting
import '../../models/booking_model.dart';
import '../../models/property_model.dart';
//import '../../services/booking_service.dart';
import '../../services/chat_service.dart'; 
import '../../utils/constants.dart';

class ContractPaymentScreen extends StatefulWidget {
  final Booking booking;
  final Property property;
  final bool isViewOnly; 

  const ContractPaymentScreen({
    super.key, 
    required this.booking, 
    required this.property,
    this.isViewOnly = false, 
  });

  @override
  State<ContractPaymentScreen> createState() => _ContractPaymentScreenState();
}

class _ContractPaymentScreenState extends State<ContractPaymentScreen> {
  final TextEditingController _signatureCtrl = TextEditingController();
  bool _isSignedLocally = false;
  bool _isProcessing = false;
  
  String _realStudentName = "Loading...";
  
  // --- NEW: Dynamic Tenancy & Date States ---
  String _tenancyLength = "12 Months";
  String _signedDate = "";

  @override
  void initState() {
    super.initState();
    _loadRealStudentName();

    if (widget.isViewOnly) {
      _signatureCtrl.text = widget.booking.signatureName.isNotEmpty 
          ? widget.booking.signatureName.toUpperCase()
          : widget.booking.studentName.toUpperCase();
      _isSignedLocally = true;
      
      // Load saved values from the database
      _tenancyLength = widget.booking.tenancyLength;
      _signedDate = widget.booking.signedDate;
    } else {
      // If we are currently signing, automatically set today's date!
      _signedDate = DateFormat('dd MMM yyyy').format(DateTime.now());
    }

    _signatureCtrl.addListener(() {
      setState(() {
        _isSignedLocally = _signatureCtrl.text.trim().isNotEmpty;
      });
    });
  }

  void _loadRealStudentName() async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.booking.studentId)
          .get();

      if (userDoc.exists && mounted) {
        setState(() {
          _realStudentName = userDoc['name'] ?? widget.booking.studentName;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _realStudentName = widget.booking.studentName;
        });
      }
    }
  }

  @override
  void dispose() {
    _signatureCtrl.dispose();
    super.dispose();
  }

  // --- GENERATE THE DYNAMIC PDF --- [21]
  Future<Uint8List> _generateTenancyAgreement(PdfPageFormat format) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: format,
        build: (pw.Context context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(16),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Center(
                  child: pw.Text("UTeM SMART RENTAL SYSTEM", style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
                ),
                pw.Center(
                  child: pw.Text("OFFICIAL TENANCY AGREEMENT", style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                ),
                pw.SizedBox(height: 24),
                pw.Divider(),
                pw.SizedBox(height: 12),

                // 1. Parties & Location [1]
                pw.Text("1. PARTIES & PROPERTY DETAILS", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13)),
                pw.Bullet(text: "Property: ${widget.property.title}"),
                pw.Bullet(text: "Address: ${widget.property.location}"), // <--- NEW: Full Address! [1]
                pw.Bullet(text: "Lead Tenant: $_realStudentName"),
                pw.Bullet(text: "Group Size: ${widget.booking.groupSize} Person(s)"),
                pw.SizedBox(height: 16),

                // 2. Lease Terms (New Section)
                pw.Text("2. LEASE TERMS", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13)),
                pw.Bullet(text: "Tenancy Length: $_tenancyLength"), // <--- NEW: Dynamic Duration
                pw.Bullet(text: "Date of Signing: $_signedDate"),    // <--- NEW: Current/Saved Date
                pw.SizedBox(height: 16),

                // 3. Rental & Deposit Payment
                pw.Text("3. RENTAL & DEPOSIT PAYMENT", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13)),
                pw.Bullet(text: "Monthly Rental: RM ${widget.property.price.toStringAsFixed(2)}"),
                pw.Bullet(text: "Security Deposit (2 Months): RM ${(widget.property.price * 2).toStringAsFixed(2)}"),
                pw.Bullet(text: "Utility Deposit: RM 100.00"),
                pw.SizedBox(height: 16),

                pw.Text("4. COVENANTS AND CONDITIONS", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13)),
                pw.Text("• The Tenant agrees to pay the rental on the 1st of every calendar month."),
                pw.Text("• The Tenant shall keep the premises in clean and habitable condition."),
                pw.Text("• The Tenant shall not perform any illegal activities inside the premises."),
                pw.SizedBox(height: 40),

                pw.Divider(),
                pw.SizedBox(height: 20),

                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text("Issued By:"),
                        pw.SizedBox(height: 15),
                        pw.Text("____________________", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        pw.Text("Homeowner (Verified)", style: pw.TextStyle(fontSize: 11)),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text("Signed Digitally By:"),
                        pw.SizedBox(height: 15),
                        pw.Text(
                          _isSignedLocally ? "/s/ ${_signatureCtrl.text.toUpperCase()}" : "WAITING FOR SIGNATURE", 
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: _isSignedLocally ? PdfColors.blue : PdfColors.red),
                        ),
                        pw.Text("Tenant Digital Signature", style: pw.TextStyle(fontSize: 11)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

  void _processPayment() async {
    setState(() => _isProcessing = true);
    
    // 1. Save signature, date, and tenancy length directly to Firebase! [21]
    await FirebaseFirestore.instance.collection('bookings').doc(widget.booking.id).update({
      'status': 'signed',
      'signatureName': _signatureCtrl.text.trim().toUpperCase(),
      'tenancyLength': _tenancyLength, // <--- NEW: Saves duration
      'signedDate': _signedDate,       // <--- NEW: Saves date
    });

    // 2. Auto-send signed receipt into chat room
    await ChatService().sendMessage(
      widget.property.homeownerId, 
      "Tenancy Agreement Signed & Paid",
      type: 'contract_signed',
      bookingId: widget.booking.id,
    );

    setState(() => _isProcessing = false);

    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children:[
              const Icon(Icons.check_circle, color: Colors.green, size: 60),
              const SizedBox(height: 16),
              const Text("Lease Active!", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textDark)),
              const SizedBox(height: 8),
              const Text("Your deposit has been processed. The signed PDF contract is now active in your chat history.", textAlign: TextAlign.center, style: TextStyle(color: textGrey)),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); 
                    Navigator.pop(context); 
                  },
                  child: const Text("Done"),
                ),
              )
            ],
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    double deposit = widget.property.price * 2;
    double total = widget.property.price + deposit + 100;

    return Scaffold(
      backgroundColor: backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 1, iconTheme: const IconThemeData(color: textDark),
        title: Text(widget.isViewOnly ? "Tenancy Agreement" : "Review & Sign Lease", style: const TextStyle(color: textDark, fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      body: Column(
        children: [
          Expanded(
            child: PdfPreview(
              build: (format) => _generateTenancyAgreement(format), 
              allowPrinting: true, 
              allowSharing: true, 
              canChangePageFormat: false,
              canChangeOrientation: false,
              loadingWidget: const Center(child: CircularProgressIndicator(color: primaryBlue)),
            ),
          ),

          if (!widget.isViewOnly)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children:[
                    // --- NEW: INTERACTIVE DURATION CHIPS --- [21]
                    const Text("Select Tenancy Length", style: TextStyle(fontWeight: FontWeight.bold, color: textDark, fontSize: 13)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildDurationChip("6 Months"),
                        const SizedBox(width: 8),
                        _buildDurationChip("12 Months"),
                        const SizedBox(width: 8),
                        _buildDurationChip("24 Months"),
                      ],
                    ),
                    const SizedBox(height: 16),

                    TextField(
                      controller: _signatureCtrl,
                      decoration: InputDecoration(
                        labelText: "Type Full Name to Sign Digitally",
                        labelStyle: const TextStyle(color: textGrey, fontSize: 13),
                        hintText: "e.g. AHMAD ZAKI",
                        filled: true, fillColor: const Color(0xFFF8FAFC),
                        prefixIcon: const Icon(Icons.draw, color: primaryBlue),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children:[
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children:[
                            const Text("Total Deposit + 1st Month Rent", style: TextStyle(color: textGrey, fontSize: 11)),
                            Text("RM ${total.toStringAsFixed(0)}", style: const TextStyle(color: primaryBlue, fontSize: 20, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: SizedBox(
                            height: 50,
                            child: ElevatedButton(
                              onPressed: (_isSignedLocally && !_isProcessing) ? _processPayment : null, 
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                disabledBackgroundColor: Colors.grey[300],
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: _isProcessing 
                                ? const CircularProgressIndicator(color: Colors.white)
                                : const Text("Pay & Sign", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                            ),
                          ),
                        )
                      ],
                    )
                  ],
                ),
              ),
            )
        ],
      ),
    );
  }

  // Helper builder for the Interactive Duration Chips
  Widget _buildDurationChip(String duration) {
    bool isSelected = _tenancyLength == duration;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _tenancyLength = duration; // Instantly updates PDF [21]
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? primaryBlue : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isSelected ? primaryBlue : Colors.grey.shade300),
          ),
          child: Text(
            duration,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : textDark,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCostRow(String label, String value) {
    return Padding(padding: const EdgeInsets.only(bottom: 8.0), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children:[Text(label, style: const TextStyle(color: textGrey, fontSize: 14)), Text(value, style: const TextStyle(color: textDark, fontWeight: FontWeight.bold, fontSize: 14))]));
  }
}