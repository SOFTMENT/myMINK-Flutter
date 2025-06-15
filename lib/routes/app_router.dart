import 'dart:ffi';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mymink/core/constants/app_routes.dart';
import 'package:mymink/core/constants/email_verification_type.dart';
import 'package:mymink/core/navigation/main_tabbar.dart';
import 'package:mymink/core/services/aws_uploader.dart';
import 'package:mymink/features/account/pages/edit_profile_page.dart';
import 'package:mymink/features/account/pages/view_user_profile_page.dart';
import 'package:mymink/features/chatbot/pages/chatbotpage.dart';
import 'package:mymink/features/cryptocurrency/pages/cryptocurrency_page.dart';
import 'package:mymink/features/discussion/data/models/discussion_topic_model.dart';
import 'package:mymink/features/discussion/pages/create_discussion_page.dart';
import 'package:mymink/features/discussion/pages/discussion_detail_page.dart';
import 'package:mymink/features/discussion/pages/discussion_home_page.dart';
import 'package:mymink/features/globalchat/pages/global_chat_page.dart';
import 'package:mymink/features/horoscope/pages/daily_horoscope_page.dart';
import 'package:mymink/features/horoscope/pages/horoscope_view_page.dart';
import 'package:mymink/features/library/pages/book_home_page.dart';
import 'package:mymink/features/library/pages/library_a_to_z_page.dart';
import 'package:mymink/features/music/data/models/music_model.dart';
import 'package:mymink/features/music/pages/music_home_page.dart';
import 'package:mymink/features/music/pages/music_player_page.dart';
import 'package:mymink/features/onboarding/data/models/user_model.dart';
import 'package:mymink/features/post/pages/add_post_page.dart';
import 'package:mymink/features/post/pages/saved_page.dart';
import 'package:mymink/features/post/pages/success_post_page.dart';

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
import 'package:mymink/features/scanner/pages/user_qrcode_page.dart';
import 'package:mymink/features/todo/pages/todo_addUpdate_page.dart';
import 'package:mymink/features/todo/pages/todo_home_page.dart';

final GoRouter appRouter = GoRouter(
  routes: [
    GoRoute(
      path: AppRoutes.welcome,
      builder: (context, state) => const WelcomePage(),
    ),
    GoRoute(
      path: AppRoutes.tabbar,
      builder: (context, state) => MainTabBar(),
    ),
    GoRoute(
      path: AppRoutes.editProfilePage,
      builder: (context, state) => const EditProfilePage(),
    ),
    GoRoute(
      path: AppRoutes.libraryAtoZPage,
      builder: (context, state) => const LibraryAToZPage(),
    ),
    GoRoute(
      path: AppRoutes.userQrcodePage,
      builder: (context, state) => UserQrcodePage(),
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
      path: AppRoutes.cryptocurrencyPage,
      builder: (context, state) => CryptocurrencyPage(),
    ),
    GoRoute(
      path: AppRoutes.horoscopeViewPage,
      builder: (context, state) {
        final data = state.extra as Map<String, String>;
        final horoscope = data['horoscope'];
        final result = data['result'];

        return HoroscopeViewPage(
          horoscope: horoscope!,
          result: result!,
        );
      },
    ),
    GoRoute(
      path: AppRoutes.dailyHoroscopePage,
      builder: (context, state) => DailyHoroscopePage(),
    ),
    GoRoute(
      path: AppRoutes.globalChatPage,
      builder: (context, state) => const GlobalChatRoomPage(),
    ),
    GoRoute(
      path: AppRoutes.musicHomePage,
      builder: (context, state) => MusicHomePage(),
    ),
    GoRoute(
      path: AppRoutes.todoHomePage,
      builder: (context, state) => const TodoHomePage(),
    ),
    GoRoute(
      path: AppRoutes.discussionDetailPage,
      builder: (context, state) {
        final data = state.extra as Map<String, dynamic>;
        final topic = data['topic'] as DiscussionTopic;

        return DiscussionDetailPage(topic: topic);
      },
    ),
    GoRoute(
      path: AppRoutes.discussionForumPage,
      builder: (context, state) => const DiscussionHomePage(),
    ),
    GoRoute(
      path: AppRoutes.addDiscussionTopicPage,
      builder: (context, state) => const CreateDiscussionPage(),
    ),
    GoRoute(
      path: AppRoutes.addUpdateTodoPage,
      builder: (context, state) {
        final data = state.extra as Map<String, dynamic>?;
        if (data != null) {
          final existingDate = data['existingDate'] as DateTime?;
          final existingId = data['existingId'] as String?;
          final existingTitle = data['existingTitle'] as String?;
          return TodoAddupdatePage(
            existingDate: existingDate,
            existingId: existingId,
            existingTitle: existingTitle,
          );
        }
        return const TodoAddupdatePage();
      },
    ),
    GoRoute(
      path: AppRoutes.musicPlayerPage,
      builder: (context, state) {
        final data = state.extra as Map<String, dynamic>;
        final items = data['items'] as List<Result>;
        final index = data['index'] as int;

        return MusicPlayerPage(items: items, initialIndex: index);
      },
    ),
    GoRoute(
      path: AppRoutes.libraryHomePage,
      builder: (context, state) => const LibraryHomePage(),
    ),
    GoRoute(
      path: AppRoutes.chatbBotPage,
      builder: (context, state) => const ChatBotPage(),
    ),
    GoRoute(
        path: AppRoutes.copyPasswordPage,
        builder: (context, state) {
          final data = state.extra as Map<String, String?>;
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
      path: AppRoutes.savedPostPage,
      builder: (context, state) => SavedPage(),
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
      path: AppRoutes.viewUserProfilePage,
      builder: (context, state) {
        final data = state.extra as Map<String, dynamic>;
        final userModel = data['userModel'] as UserModel;

        return ViewUserProfilePage(userModel: userModel);
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
    GoRoute(
      path: AppRoutes.addPost,
      builder: (context, state) {
        final data = state.extra as Map<String, dynamic>;
        final files = data['files'] as List<File>;
        final type = data['type'] as PostType;
        return AddPostPage(files: files, postType: type);
      },
    ),
    GoRoute(
      path: AppRoutes.successPost,
      builder: (context, state) => SuccessPostPage(),
    ),
  ],
  errorBuilder: (context, state) => const Scaffold(
    body: Center(child: Text('Page not found!')),
  ),
);
