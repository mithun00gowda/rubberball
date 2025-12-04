import 'dart:io';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

// Custom User model to bridge Firebase User and our App's needs
class AuthUser {
  final String uid;
  final String email;
  final String? displayName;
  final String? photoUrl;

  AuthUser({
    required this.uid,
    required this.email,
    this.displayName,
    this.photoUrl,
  });

  // Factory to create from Firebase User
  factory AuthUser.fromFirebase(User user) {
    return AuthUser(
      uid: user.uid,
      email: user.email ?? '',
      displayName: user.displayName,
      photoUrl: user.photoURL,
    );
  }
}

class AuthService with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  AuthUser? _currentUser;
  AuthUser? get currentUser => _currentUser;

  bool _isLoading = false;
  bool get isLoading => _isLoading;
  static bool isInitialize = false;

  Stream<AuthUser?> get authStateChanges {
    return _auth.authStateChanges().map((User? user) {
      if (user != null) {
        _currentUser = AuthUser.fromFirebase(user);
        return _currentUser;
      } else {
        _currentUser = null;
        return null;
      }
    });
  }

   Future<void> initSignIn() async{
    if(!isInitialize){
      await _googleSignIn.initialize(
          serverClientId:"142783030266-76ctro1chuul269ohtlhja6olcnapc7l.apps.googleusercontent.com"
      );
    }
    isInitialize = true;
  }

  // --- Sign In with Email/Password ---
  Future<bool> signIn(String email, String password) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _auth.signInWithEmailAndPassword(email: email, password: password);

      // authStateChanges stream handles the user update
      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      notifyListeners();
      throw Exception(_handleAuthError(e));
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      throw Exception("An unknown error occurred.");
    }
  }

  // --- Sign Up with Email, Password & Image ---
  Future<bool> signUp(String email, String password, String name, File? profileImage) async {
    try {
      _isLoading = true;
      notifyListeners();

      // 1. Create User in Auth
      UserCredential cred = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password
      );

      String? photoUrl;

      // 2. Upload Image to Storage (if selected)
      if (profileImage != null) {
        final ref = _storage.ref().child('user_profile_images').child('${cred.user!.uid}.jpg');
        await ref.putFile(profileImage);
        photoUrl = await ref.getDownloadURL();
      }

      // 3. Update Firebase Auth Profile
      await cred.user!.updateDisplayName(name);
      if (photoUrl != null) {
        await cred.user!.updatePhotoURL(photoUrl);
      }

      // 4. Save Additional Data to Firestore
      await _saveUserToFirestore(cred.user!, name, photoUrl);

      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      notifyListeners();
      throw Exception(_handleAuthError(e));
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      throw Exception("Registration failed: $e");
    }
  }

  // --- Google Sign In ---
  Future<bool> signInWithGoogle() async {
    initSignIn();
    try {
      _isLoading = true;
      notifyListeners();

      // 1. Trigger Google Sign In flow
      final GoogleSignInAccount googleUser = await _googleSignIn.authenticate();
      final idToken = googleUser.authentication.idToken;
      final authenticationClient = googleUser.authorizationClient;
      GoogleSignInClientAuthorization? authorization = await authenticationClient.authorizationForScopes(['email','profile']);

      final accessToken = authorization?.accessToken;
      if(accessToken == null){
        final authorization2 = await authenticationClient.authorizationForScopes(['email','profile']);

        if(authorization2 == null){
          throw FirebaseAuthException(code: "error",message: "error");
        }
        authorization = authorization2;
      }
      final credential = GoogleAuthProvider.credential(
          idToken: idToken,
          accessToken: accessToken
      );

      // 4. Sign in to Firebase
      UserCredential cred = await _auth.signInWithCredential(credential);

      // 5. Check if new user -> Save to Firestore
      if (cred.additionalUserInfo?.isNewUser ?? false) {
        await _saveUserToFirestore(
            cred.user!,
            cred.user!.displayName ?? 'Player',
            cred.user!.photoURL
        );
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      notifyListeners();
      throw Exception(_handleAuthError(e));
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      print(e);
      throw Exception("Google Sign In failed: $e");
    }
  }

  // --- Helper: Save to Firestore ---
  Future<void> _saveUserToFirestore(User user, String name, String? photoUrl) async {
    await _firestore.collection('users').doc(user.uid).set({
      'uid': user.uid,
      'name': name,
      'email': user.email,
      'photoUrl': photoUrl,
      'createdAt': FieldValue.serverTimestamp(),
      'role': 'Player', // Default role
      // Initialize stats
      'matchesPlayed': 0,
      'totalRuns': 0,
      'wicketsTaken': 0,
    }, SetOptions(merge: true));
  }

  // --- Sign Out ---
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut(); // Ensure Google session is cleared
      await _auth.signOut();
      _currentUser = null;
      notifyListeners();
    } catch (e) {
      print("Error signing out: $e");
    }
  }

  // --- Error Handling ---
  String _handleAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'This email is already registered.';
      case 'invalid-email':
        return 'The email address is invalid.';
      case 'weak-password':
        return 'The password is too weak.';
      case 'user-not-found':
        return 'No user found with this email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'account-exists-with-different-credential':
        return 'An account already exists with this email.';
      default:
        return 'Authentication failed. Please try again.';
    }
  }
}