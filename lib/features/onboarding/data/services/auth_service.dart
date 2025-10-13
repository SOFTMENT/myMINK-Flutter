import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:go_router/go_router.dart';
import 'package:mymink/core/constants/app_routes.dart';
import 'package:mymink/core/constants/email_verification_type.dart';
import 'package:mymink/core/services/email_service.dart';
import 'package:mymink/core/services/firebase_service.dart';
import 'package:mymink/core/utils/firebase_error_handler.dart';
import 'package:mymink/core/utils/result.dart';
import 'package:mymink/features/onboarding/data/models/user_model.dart';
import 'package:mymink/features/onboarding/data/services/user_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  // Singleton instance
  static final AuthService _instance = AuthService._internal();

  // Private constructor
  AuthService._internal();

  // Factory constructor
  factory AuthService() => _instance;

  // Firebase Auth instance
  static final FirebaseAuth _auth = FirebaseService().auth;

  /// Get current user
  static User? get currentUser => _auth.currentUser;

  /// Check if user is logged in
  static bool get isLoggedIn => _auth.currentUser != null;

  /// Generate a random verification code
  static int generateRandomNumber() {
    return (10000 +
            (99999 - 10000) *
                (DateTime.now().millisecondsSinceEpoch % 1000) ~/
                1000)
        .toInt();
  }

  /// Check if it's the first launch and sign out
  static Future<void> checkFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    final isFirstLaunch = prefs.getBool('isFirstLaunch') ?? true;

    if (isFirstLaunch) {
      await _auth.signOut();
      await prefs.setBool('isFirstLaunch', false);
    }
  }

  /// Sign in with Google
  static Future<Result<User?>> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn(
        scopes: ['email'],
      ).signIn();

      if (googleUser == null) {
        return Result(error: "Google sign-in cancelled.");
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      return Result(data: userCredential.user);
    } catch (e) {
      return Result(error: 'Google sign-in failed: $e');
    }
  }

  static Future<Result<UserCredential?>> signInWithCustomToken(String token,
      {String? fullName}) async {
    try {
      // Sign in with custom token
      UserCredential authResult = await _auth.signInWithCustomToken(token);
      return Result(data: authResult);
    } on FirebaseAuthException catch (error) {
      return Result(error: error.message);
    }
  }

  static Future<Result<String?>> createCustomToken(String userId) async {
    try {
      // Reference to the Firebase Cloud Function
      final HttpsCallable callable =
          FirebaseFunctions.instance.httpsCallable('createCustomToken');

      // Call the function with the userId as a parameter
      final response = await callable.call(<String, dynamic>{
        'uid': userId,
      });

      // Extract the token from the response
      final token = response.data['token'] as String?;
      return Result(data: token);
    } catch (e) {
      // Handle any errors
      return Result(error: e.toString());
    }
  }

  /// Sign in with Apple
  static Future<Result<User?>> signInWithApple() async {
    try {
      final url = Uri.https('appleid.apple.com', '/auth/authorize', {
        'response_type': 'code id_token',
        'client_id': 'com.softment.mymink.apple',
        'redirect_uri': 'https://softment.com/callback',
        'scope': 'email name',
        'response_mode': 'form_post',
      }).toString();

      final result = await FlutterWebAuth2.authenticate(
        url: url,
        callbackUrlScheme: 'com.softment.mymink.apple',
      );

      final uri = Uri.parse(result);
      final code = uri.queryParameters['code'];
      final idToken = uri.queryParameters['id_token'];

      if (code == null || idToken == null) {
        return Result(error: 'Missing authorization code or ID token.');
      }

      final credential = OAuthProvider("apple.com").credential(
        idToken: idToken,
        accessToken: code,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      return Result(data: userCredential.user);
    } catch (e) {
      return Result(error: 'Apple sign-in failed: $e');
    }
  }

  /// Sign in user with email and password
  static Future<String?> signInUser(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return null;
    } on FirebaseAuthException catch (e) {
      return FirebaseErrorHandler.getFriendlyErrorMessage(e.code);
    }
  }

  /// Create user with email and password
  static Future<String?> createUser(String email, String password) async {
    try {
      await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      return null;
    } on FirebaseAuthException catch (e) {
      return FirebaseErrorHandler.getFriendlyErrorMessage(e.code);
    }
  }

  /// Send verification email
  static Future<String?> checkUserAndSendVerification(
      String email, int randomNumber) async {
    try {
      final result =
          await UserService.getUserByEmail(email: email, regiType: 'custom');
      if (result.hasData) {
        return 'You already have an account. Please login.';
      }

      return await EmailService.sendVerificationEmail(
        email,
        randomNumber,
        VerificationType.EMAIL_VERIFICATION,
      );
    } catch (e) {
      return 'Error: $e';
    }
  }

  /// Send reset password code
  static Future<String?> sendResetPasswordCode(
      String email, int randomNumber) async {
    try {
      final result =
          await UserService.getUserByEmail(email: email, regiType: 'custom');
      if (result.hasData) {
        return await EmailService.sendVerificationEmail(
          email,
          randomNumber,
          VerificationType.RESET_PASSWORD,
        );
      } else {
        return result.error;
      }
    } catch (e) {
      return 'Error: $e';
    }
  }

  /// Logout user
  static void logout(BuildContext context) {
    UserModel.data = null;
    _auth.signOut();
    context.go(AppRoutes.entry);
  }
}
