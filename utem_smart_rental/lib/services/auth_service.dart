import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'notification_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Sign Up
  Future<User?> signUp(String email, String password, String name, String role) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = userCredential.user;

      // Save user role in Firestore
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'email': email,
          'name': name,
          'role': role,
        });
        // Send notification to admins
        await NotificationService().sendNotificationToAdmins('New User Registered', '$name has registered as a $role.');
      }
      return user;
    } catch (e) {
      print('Sign Up Error: $e');
      return null;
    }
  }

  // Login
  Future<User?> login(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } catch (e) {
      print('Login Error: $e');
      return null;
    }
  }

  // Get User Role
  Future<String?> getUserRole(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return doc['role'];
      }
    } catch (e) {
      print('Get Role Error: $e');
    }
    return null;
  }

  // Reset Password
  Future<String?> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return null; // Return null if successful
    } on FirebaseAuthException catch (e) {
      return e.message; // Return the error message if it fails
    } catch (e) {
      return e.toString();
    }
  }
}