import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mymink/core/constants/app_routes.dart';
import 'package:mymink/core/constants/email_verification_type.dart';
import 'package:mymink/core/navigation/main_tabbar.dart';

import 'package:mymink/features/onboarding/pages/complete_profile_page.dart';
import 'package:mymink/features/onboarding/pages/copy_password_page.dart';
import 'package:mymink/features/onboarding/pages/sign_in_phone_number_page.dart';
import 'package:mymink/features/onboarding/pages/sign_up_phone_number_page.dart';
import 'package:mymink/features/onboarding/pages/verification_page.dart';
import 'package:mymink/features/onboarding/pages/entry_page.dart';
import 'package:mymink/features/onboarding/pages/login_page.dart';
import 'package:mymink/features/onboarding/pages/retrieve_password_page.dart';
import 'package:mymink/features/onboarding/pages/sign_up_page.dart';
import 'package:mymink/features/onboarding/pages/welcome_page.dart';

final GoRouter appRouter = GoRouter(
  routes: [
    GoRoute(
      path: AppRoutes.welcome,
      builder: (context, state) => WelcomePage(),
    ),
    GoRoute(
      path: AppRoutes.tabbar,
      builder: (context, state) => MainTabBar(),
    ),
    GoRoute(
      path: AppRoutes.entry,
      builder: (context, state) => const EntryPage(),
    ),
    GoRoute(
      path: AppRoutes.login,
      builder: (context, state) => LoginPage(),
    ),
    GoRoute(
      path: AppRoutes.signup,
      builder: (context, state) => SignUpPage(),
    ),
    GoRoute(
      path: AppRoutes.complete_profile,
      builder: (context, state) => const CompleteProfilePage(),
    ),
    GoRoute(
      path: AppRoutes.retrievePasswordPage,
      builder: (context, state) => RetrievePasswordPage(),
    ),
    GoRoute(
        path: AppRoutes.copyPasswordPage,
        builder: (context, state) {
          final data = state.extra as Map<String, String>;
          final email = data['email'] ?? '';
          final password = data['password'] ?? '';
          return CopyPasswordPage(
            email: email,
            password: password,
          );
        }),
    GoRoute(
      path: AppRoutes.signInPhoneNumberPage,
      builder: (context, state) => SignInPhoneNumberPage(),
    ),
    GoRoute(
      path: AppRoutes.signUpPhoneNumberPage,
      builder: (context, state) => SignUpPhoneNumberPage(),
    ),
    GoRoute(
      path: AppRoutes.emailVerificationCodePage,
      builder: (context, state) {
        final data = state.extra as Map<String, dynamic>;
        final email = data['email'] as String;
        final encryptionKey = data['encryptionKey'] as String;
        final verificationCode = data['verificationCode'] as int;
        final encryptPassword = data['encryptPassword'] as String;
        final fullName = data['fullName'] as String;
        final type = data['type'] as VerificationType;
        return VerificationPage(
          email: email,
          type: type,
          verificationCode: verificationCode,
          fullName: fullName,
          encryptionkey: encryptionKey,
          encryptionPassword: encryptPassword,
        );
      },
    ),
    GoRoute(
      path: AppRoutes.resetVerificationCodePage,
      builder: (context, state) {
        final data = state.extra as Map<String, dynamic>;
        final email = data['email'] as String;
        final verificationCode = data['verificationCode'] as int;
        final type = data['type'] as VerificationType;
        return VerificationPage.resetPassword(
          email: email,
          type: type,
          verificationCode: verificationCode,
        );
      },
    ),
    GoRoute(
      path: AppRoutes.phoneVerificationCodePage,
      builder: (context, state) {
        final data = state.extra as Map<String, dynamic>;
        final phone = data['phoneNumber'] as String;
        final fullName = data['fullName'] as String?;
        final verificationUid = data['verificationUid'] as String;
        final type = data['type'] as VerificationType;
        return VerificationPage.phoneNumber(
          fullName,
          phoneNumber: phone,
          type: type,
          verificationUid: verificationUid,
        );
      },
    ),
  ],
  errorBuilder: (context, state) => Scaffold(
    body: Center(child: Text('Page not found!')),
  ),
);
