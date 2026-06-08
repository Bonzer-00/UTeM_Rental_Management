import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../utils/constants.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final AuthService _auth = AuthService();
  final TextEditingController _emailCtrl = TextEditingController();
  bool _isLoading = false;

  void _resetPassword() async {
    if (_emailCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter your email.')));
      return;
    }

    setState(() => _isLoading = true);
    String? error = await _auth.resetPassword(_emailCtrl.text.trim());
    setState(() => _isLoading = false);

    if (!mounted) return;

    if (error == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(backgroundColor: Colors.green, content: Text('Password reset email sent! Check your inbox.')),
      );
      Navigator.pop(context); // Go back to login
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: Colors.red, content: Text(error)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: textDark),
        title: const SmartRentalLogo(),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(defaultPadding),
          child: Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: cardWhite,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.blue.withOpacity(0.2)),
              boxShadow:[BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10))],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children:[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.orange.shade100, borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.lock_reset, size: 36, color: Colors.orange),
                ),
                const SizedBox(height: 16),
                const Text("Reset Password", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textDark)),
                const SizedBox(height: 8),
                const Text("Enter your email address and we will send you a link to reset your password.", textAlign: TextAlign.center, style: TextStyle(color: textGrey)),
                const SizedBox(height: 30),

                // Email Input
                Align(alignment: Alignment.centerLeft, child: const Text("Email Address", style: TextStyle(fontWeight: FontWeight.bold, color: textDark, fontSize: 14))),
                const SizedBox(height: 8),
                TextField(
                  controller: _emailCtrl,
                  decoration: InputDecoration(
                    hintText: "student@utem.edu.my",
                    hintStyle: const TextStyle(color: Colors.grey),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: primaryBlue)),
                  ),
                ),
                const SizedBox(height: 24),

                // Submit Button
                _isLoading 
                  ? const CircularProgressIndicator(color: primaryBlue)
                  : SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _resetPassword,
                        style: ElevatedButton.styleFrom(backgroundColor: primaryBlue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                        child: const Text("Send Reset Link", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}