import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../utils/constants.dart';
import '../student/student_home.dart';
import '../homeowner/homeowner_home.dart';
import '../admin/admin_home.dart';
import 'signup_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _auth = AuthService();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _passwordCtrl = TextEditingController();
  bool _isLoading = false;

  void _login() async {
    setState(() => _isLoading = true);
    var user = await _auth.login(_emailCtrl.text.trim(), _passwordCtrl.text.trim());
    
    if (user != null) {
      String? role = await _auth.getUserRole(user.uid);
      if (!mounted) return;
      if (role == 'Student') Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const StudentHome()));
      else if (role == 'Homeowner') Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeownerHome()));
      else if (role == 'Admin') Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AdminHome()));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Login Failed. Check Email/Password.')));
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
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
              boxShadow:[
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10))
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children:[
                // Top Icon
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: primaryBlue, borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.home_outlined, size: 36, color: Colors.white),
                ),
                const SizedBox(height: 16),
                const Text("Welcome Back", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textDark)),
                const SizedBox(height: 8),
                const Text("Log in to manage your rentals or search for housing.", textAlign: TextAlign.center, style: TextStyle(color: textGrey)),
                const SizedBox(height: 30),

                // Inputs
                _buildInputLabel("UTeM Email / Username"),
                _buildTextField(_emailCtrl, "student@utem.edu.my", false),
                const SizedBox(height: 16),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children:[
                    _buildInputLabel("Password"),
                    GestureDetector(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ForgotPasswordScreen())), // <-- Added Link
                      child: const Text("Forgot password?", style: TextStyle(color: primaryBlue, fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                _buildTextField(_passwordCtrl, "••••••••", true),
                const SizedBox(height: 24),

                // Login Button
                _isLoading 
                  ? const CircularProgressIndicator()
                  : SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryBlue,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text("Log In", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    ),
                
                const SizedBox(height: 24),
                
                // Divider
                Row(
                  children:[
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text("NEW TO UTEM SMART RENTAL?", style: TextStyle(color: Colors.grey[400], fontSize: 10, letterSpacing: 1)),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 24),

                // Create Account Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SignupScreen())),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.grey[300]!),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text("Create an Account", style: TextStyle(color: textDark, fontWeight: FontWeight.bold)),
                  ),
                ),
                
                const SizedBox(height: 20),
                const Text("Protected by secure encryption.", style: TextStyle(color: Colors.grey, fontSize: 12)),
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
        fillColor: const Color(0xFFF8FAFC), // Very light grey inner field
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primaryBlue),
        ),
      ),
    );
  }
}