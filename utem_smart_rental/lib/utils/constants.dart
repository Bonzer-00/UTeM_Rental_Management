import 'package:flutter/material.dart';

// Brand Colors from the Design
const Color primaryBlue = Color(0xFF2A85F4); // The "SmartRental" Blue
const Color backgroundLight = Color(0xFFF4F7F9); // The light grayish-blue background
const Color textDark = Color(0xFF1E293B); // Dark text color
const Color textGrey = Color(0xFF64748B); // Subtitle grey color
const Color cardWhite = Colors.white;

// --- BACKWARD COMPATIBILITY ---
// This stops your old screens from crashing while we update them
const Color primaryColor = primaryBlue;
const Color secondaryColor = Color(0xFF64748B);
const Color backgroundColor = backgroundLight;
const Color textColor = textDark;
// ------------------------------

const double defaultPadding = 16.0;

// Reusable Logo Widget for the AppBars
class SmartRentalLogo extends StatelessWidget {
  const SmartRentalLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children:[
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: primaryBlue,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.home, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 8),
        RichText(
          text: const TextSpan(
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: -0.5),
            children:[
              TextSpan(text: 'UTeM', style: TextStyle(color: primaryBlue)),
              TextSpan(text: 'Smart', style: TextStyle(color: textDark)),
              TextSpan(text: 'Rental', style: TextStyle(color: textDark)),
            ],
          ),
        ),
      ],
    );
  }
}