import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../utils/constants.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final AuthService _auth = AuthService();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _passwordCtrl = TextEditingController();
  final TextEditingController _nameCtrl = TextEditingController();
  String _selectedRole = 'Student';
  bool _isLoading = false;

  void _signup() async {
    setState(() => _isLoading = true);
    var user = await _auth.signUp(
      _emailCtrl.text.trim(),
      _passwordCtrl.text.trim(),
      _nameCtrl.text.trim(),
      _selectedRole,
    );
    setState(() => _isLoading = false);

    if (user != null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(backgroundColor: Colors.green, content: Text('Account Created! Please Log In.')));
      Navigator.pop(context); // Go back to login screen
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(backgroundColor: Colors.red, content: Text('Signup Failed. Email might be in use.')));
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
                // Top Icon
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.green.shade100, borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.person_add_alt_1, size: 36, color: Colors.green),
                ),
                const SizedBox(height: 16),
                const Text("Create an Account", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textDark)),
                const SizedBox(height: 8),
                const Text("Join SmartRental to find your home or list your properties.", textAlign: TextAlign.center, style: TextStyle(color: textGrey)),
                const SizedBox(height: 30),

                // Input Fields
                _buildInputLabel("Full Name"),
                _buildTextField(_nameCtrl, "Ahmad Zaki", false),
                const SizedBox(height: 16),

                _buildInputLabel("Email Address"),
                _buildTextField(_emailCtrl, "student@utem.edu.my", false),
                const SizedBox(height: 16),

                _buildInputLabel("Password"),
                _buildTextField(_passwordCtrl, "••••••••", true),
                const SizedBox(height: 16),

                // Role Selection Dropdown
                _buildInputLabel("I am a..."),
                DropdownButtonFormField<String>(
                  value: _selectedRole,
                  icon: const Icon(Icons.keyboard_arrow_down, color: textGrey),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: primaryBlue)),
                  ),
                  items:['Student', 'Homeowner'].map((role) => DropdownMenuItem(value: role, child: Text(role, style: const TextStyle(color: textDark)))).toList(),
                  onChanged: (value) => setState(() => _selectedRole = value!),
                ),
                const SizedBox(height: 24),

                // Signup Button
                _isLoading 
                  ? const CircularProgressIndicator(color: primaryBlue)
                  : SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _signup,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryBlue,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text("Sign Up", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    ),
                
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: () => Navigator.pop(context), // Back to login
                  child: RichText(
                    text: const TextSpan(
                      text: "Already have an account? ",
                      style: TextStyle(color: textGrey),
                      children:[
                        TextSpan(text: "Log In", style: TextStyle(color: primaryBlue, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper Widget for Labels
  Widget _buildInputLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, color: textDark, fontSize: 14)),
      ),
    );
  }

  // Helper Widget for TextFields
  Widget _buildTextField(TextEditingController controller, String hint, bool isPassword) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: primaryBlue)),
      ),
    );
  }
}