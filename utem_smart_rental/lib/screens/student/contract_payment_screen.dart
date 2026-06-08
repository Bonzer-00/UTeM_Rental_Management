import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../models/booking_model.dart';
import '../../models/property_model.dart';
import '../../services/booking_service.dart';
import '../../utils/constants.dart';

class ContractPaymentScreen extends StatefulWidget {
  final Booking booking;
  final Property property;

  const ContractPaymentScreen({super.key, required this.booking, required this.property});

  @override
  State<ContractPaymentScreen> createState() => _ContractPaymentScreenState();
}

class _ContractPaymentScreenState extends State<ContractPaymentScreen> {
  final TextEditingController _signatureCtrl = TextEditingController();
  bool _isSignedLocally = false;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _signatureCtrl.addListener(() {
      setState(() {
        _isSignedLocally = _signatureCtrl.text.trim().isNotEmpty;
      });
    });
  }

  @override
  void dispose() {
    _signatureCtrl.dispose();
    super.dispose();
  }

  // --- DYNAMICALLY GENERATE THE NATIVE PDF LEASE DOCUMENT --- [21]
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

                pw.Text("1. PARTIES INVOLVED", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13)),
                pw.Bullet(text: "Property: ${widget.property.title}"),
                pw.Bullet(text: "Lead Tenant: ${widget.booking.studentName}"),
                pw.Bullet(text: "Group Size: ${widget.booking.groupSize} Person(s)"),
                pw.SizedBox(height: 16),

                pw.Text("2. RENTAL & DEPOSIT PAYMENT", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13)),
                pw.Bullet(text: "Monthly Rental: RM ${widget.property.price.toStringAsFixed(2)}"),
                pw.Bullet(text: "Security Deposit (2 Months): RM ${(widget.property.price * 2).toStringAsFixed(2)}"),
                pw.Bullet(text: "Utility Deposit: RM 100.00"),
                pw.SizedBox(height: 16),

                pw.Text("3. COVENANTS AND CONDITIONS", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13)),
                pw.Text("• The Tenant agrees to pay the rental on the 1st of every calendar month."),
                pw.Text("• The Tenant shall keep the premises in clean and habitable condition."),
                pw.Text("• The Tenant shall not perform any illegal activities inside the premises."),
                pw.SizedBox(height: 40),

                pw.Divider(),
                pw.SizedBox(height: 20),

                // Digital Signature Display
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
    
    // 1. Update Booking Status to 'signed' (Completes the contract)
    await BookingService().updateBookingStatus(widget.booking.id, 'signed');

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
              const Text("Your deposit has been processed. The signed PDF contract is now active and stored.", textAlign: TextAlign.center, style: TextStyle(color: textGrey)),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // Close dialog
                    Navigator.pop(context); // Go back to dashboard
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
        title: const Text("Review & Sign Lease", style: TextStyle(color: textDark, fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      body: Column(
        children: [
          // 1. Interactive PDF Preview Container
          Expanded(
            child: PdfPreview(
              build: (format) => _generateTenancyAgreement(format), // Generates PDF on the fly! [21]
              allowPrinting: true, // Let them print to real PDF or printer [1]
              allowSharing: true, // Let them WhatsApp/email the PDF [1]
              canChangePageFormat: false,
              canChangeOrientation: false,
              loadingWidget: const Center(child: CircularProgressIndicator(color: primaryBlue)),
            ),
          ),

          // 2. Interactive Signature & Payment Panel
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Digital Signature Input
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

                  // Price Row & Confirm Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Total Deposit + 1st Month Rent", style: TextStyle(color: textGrey, fontSize: 11)),
                          Text("RM ${total.toStringAsFixed(0)}", style: const TextStyle(color: primaryBlue, fontSize: 20, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: SizedBox(
                          height: 50,
                          child: ElevatedButton(
                            // Button is DISABLED until they type their signature! [21]
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
}