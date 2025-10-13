import 'package:flutter/material.dart';
import 'package:mymink/core/constants/app_routes.dart';
import 'package:go_router/go_router.dart';
import 'package:mymink/features/onboarding/data/services/auth_service.dart';
import 'package:mymink/features/onboarding/data/services/user_service.dart';
import 'package:mymink/features/post/data/services/post_service.dart';
import 'package:mymink/gen/assets.gen.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  _WelcomePageState createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleNavigation();
    });
  }

  Future<void> _handleNavigation() async {
    await AuthService.checkFirstLaunch();

    if (AuthService.isLoggedIn) {
      await PostService.loadInitialHomePosts(5);
      await PostService.loadInitialReelPosts(5);

      await UserService.handleUserStateByUid(
        context,
        AuthService.currentUser!.uid,
      );
    } else {
      PostService.loadInitialHomePosts(15);
      PostService.loadInitialReelPosts(15);
      context.go(AppRoutes.entry);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Assets.images.logo.image(width: 160),
      ),
    );
  }
}
