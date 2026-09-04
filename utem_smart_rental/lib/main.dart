import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'utils/constants.dart';
import 'services/notification_service.dart';
import 'screens/auth/auth_wrapper.dart';  
import 'package:cloud_firestore/cloud_firestore.dart'; 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // --- (Clears SQLite Cache Deadlocks) ---
  try {
    await FirebaseFirestore.instance.clearPersistence();
    FirebaseFirestore.instance.settings = const Settings(persistenceEnabled: false);
  } catch (e) {
    debugPrint("Firestore Cache Clear Error: $e");
  }

  //  ---
  try {
    await NotificationService.initializeSystemNotifications(); 
  } catch (e) {
    debugPrint("Notification Setup Error: $e");
  }
  
  runApp(const UtemRentalApp());
}

class UtemRentalApp extends StatelessWidget {
  const UtemRentalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UTeM Smart Rental',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: backgroundColor,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryColor,
          primary: primaryColor,
          secondary: secondaryColor,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),
      home: const AuthWrapper(), // Set the AuthWrapper as the first page
    );
  }
}