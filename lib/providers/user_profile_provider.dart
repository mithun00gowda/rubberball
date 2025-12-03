import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rubberball/models/user_profile_model.dart';
import 'package:rubberball/services/auth_service.dart'; // Needed for logout

class UserProfileProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  UserProfileModel? _user;
  bool _isLoading = false;

  UserProfileModel? get user => _user;
  bool get isLoading => _isLoading;

  UserProfileProvider() {
    _init();
  }

  void _init() {
    // Listen to auth state to fetch profile automatically
    _auth.authStateChanges().listen((User? firebaseUser) {
      if (firebaseUser != null) {
        fetchUserProfile();
      } else {
        _user = null;
        notifyListeners();
      }
    });
  }

  Future<void> fetchUserProfile() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    try {
      _isLoading = true;
      notifyListeners();

      // Fetch document from 'users' collection
      DocumentSnapshot doc = await _firestore.collection('users').doc(currentUser.uid).get();

      if (doc.exists && doc.data() != null) {
        _user = UserProfileModel.fromMap(doc.data() as Map<String, dynamic>, currentUser.uid);
      } else {
        // Fallback if doc doesn't exist yet (rare if created on signup)
        _user = UserProfileModel(
          id: currentUser.uid,
          name: currentUser.displayName ?? 'Player',
          email: currentUser.email ?? '',
          phoneNumber: '',
          role: 'Player',
          jerseyNumber: '--',
          teamName: 'Free Agent',
          profileImageUrl: currentUser.photoURL ?? '',
          matchesPlayed: 0,
          totalRuns: 0,
          wicketsTaken: 0,
          manOfTheMatchCount: 0,
        );
      }
    } catch (e) {
      debugPrint("Error fetching profile: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Logout Action
  Future<void> logout(BuildContext context) async {
    try {
      // We use the AuthService to ensure consistent state clearing
      // Assuming AuthService is available via Provider in the widget tree
      // But for safety, we can direct call if needed, or better:
      await AuthService().signOut();
      // Note: Since AuthService.signOut() calls FirebaseAuth.signOut(),
      // the authStateChanges listener above will trigger and set _user = null.
    } catch (e) {
      debugPrint("Logout error: $e");
    }
  }
}