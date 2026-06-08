import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_screen.dart';
import '../student/student_home.dart';
import '../homeowner/homeowner_home.dart';
import '../admin/admin_home.dart';
import '../../utils/constants.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  // Function to check the user's role from Firestore
  Future<String?> _getUserRole(String uid) async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (doc.exists) {
        return doc['role'];
      }
    } catch (e) {
      debugPrint("Error fetching role: $e");
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      // 1. Automatically listen to Firebase Auth state
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        
        // If checking auth state, show a clean loading screen
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(backgroundColor: backgroundLight, body: Center(child: CircularProgressIndicator(color: primaryBlue)));
        }

        // 2. If user is NOT logged in, show Login Screen
        if (!snapshot.hasData || snapshot.data == null) {
          return const LoginScreen();
        }

        // 3. If user IS logged in, fetch their role and redirect them!
        return FutureBuilder<String?>(
          future: _getUserRole(snapshot.data!.uid),
          builder: (context, roleSnapshot) {
            
            // While fetching the role, show loading screen
            if (roleSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(backgroundColor: backgroundLight, body: Center(child: CircularProgressIndicator(color: primaryBlue)));
            }

            // Redirect based on role
            String? role = roleSnapshot.data;
            if (role == 'Student') return const StudentHome();
            if (role == 'Homeowner') return const HomeownerHome();
            if (role == 'Admin') return const AdminHome();

            // Fallback: If role is broken/missing, log them out and send to login
            FirebaseAuth.instance.signOut();
            return const LoginScreen();
          },
        );
      },
    );
  }
}