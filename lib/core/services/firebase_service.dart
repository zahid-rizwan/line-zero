import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class FirebaseService {
  static bool _isFirebaseInitialized = false;

  /// Set to [false] to connect to your live Firebase Cloud Firestore database.
  /// Set to [true] if you want to fall back to the local Mock Database.
  static bool forceMockMode = false;

  static bool get isInitialized => _isFirebaseInitialized && !forceMockMode;

  static Future<void> initialize() async {
    try {
      await Firebase.initializeApp();
      _isFirebaseInitialized = true;
      if (forceMockMode) {
        debugPrint('Q-Token App running in Mock Mode.');
      } else {
        debugPrint('Firebase initialized successfully with live Cloud Firestore backend.');
        await seedAdminAccount();
      }
    } catch (e) {
      _isFirebaseInitialized = false;
      debugPrint('Firebase initialization notice: $e (Falling back to Mock Database Service).');
    }
  }

  /// Automatically provisions the Super Admin account in Firebase Auth & Firestore
  static Future<void> seedAdminAccount({
    String email = 'admin@queuetoken.app',
    String password = 'admin123',
  }) async {
    if (!isInitialized) return;

    try {
      final auth = FirebaseAuth.instance;
      final firestore = FirebaseFirestore.instance;

      UserCredential? credential;
      try {
        credential = await auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
      } on FirebaseAuthException catch (e) {
        if (e.code == 'email-already-in-use') {
          debugPrint('Admin account $email already exists in Firebase Auth.');
        }
      }

      final uid = credential?.user?.uid;
      if (uid != null) {
        await firestore.collection('users').doc(uid).set({
          'name': 'Super Admin',
          'phone': email,
          'email': email,
          'role': 'admin',
        }, SetOptions(merge: true));
        debugPrint('Super Admin Firestore user document created for UID: $uid');
      } else {
        final query = await firestore.collection('users').where('email', isEqualTo: email).get();
        if (query.docs.isEmpty) {
          final newAdminDoc = firestore.collection('users').doc('admin-user-id');
          await newAdminDoc.set({
            'name': 'Super Admin',
            'phone': email,
            'email': email,
            'role': 'admin',
          }, SetOptions(merge: true));
        }
      }
    } catch (e) {
      debugPrint('seedAdminAccount notice: $e');
    }
  }

  /// Creates a secondary user account in Firebase Auth and Firestore without logging out current Admin
  static Future<String?> createFirebaseOwnerAuthAccount({
    required String email,
    required String password,
    required String name,
  }) async {
    if (!isInitialized) return null;

    FirebaseApp? tempApp;
    try {
      final appName = 'TempOwnerAuthApp_${DateTime.now().millisecondsSinceEpoch}';
      tempApp = await Firebase.initializeApp(
        name: appName,
        options: Firebase.app().options,
      );

      final tempAuth = FirebaseAuth.instanceFor(app: tempApp);
      final credential = await tempAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = credential.user?.uid;
      if (uid != null) {
        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          'name': name,
          'phone': email,
          'email': email,
          'role': 'owner',
        }, SetOptions(merge: true));
        debugPrint('Firebase Auth owner account created with UID: $uid');
      }

      await tempApp.delete();
      return uid;
    } catch (e) {
      debugPrint('createFirebaseOwnerAuthAccount notice: $e');
      try {
        await tempApp?.delete();
      } catch (_) {}
      return null;
    }
  }
}
