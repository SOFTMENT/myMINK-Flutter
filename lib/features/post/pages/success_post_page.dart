import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:mymink/core/constants/app_routes.dart';
import 'package:mymink/core/constants/colors.dart';

class SuccessPostPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    Future.delayed(const Duration(seconds: 2, milliseconds: 500), () {
      context.go(AppRoutes.tabbar);
    });
    return Scaffold(
      body: Center(
          child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.asset(
            'assets/animations/success.json',
            width: 300,
            height: 300,
            fit: BoxFit.cover,
          ),
          const Text(
            'Post Created',
            style: TextStyle(
                color: AppColors.textBlack,
                fontSize: 22,
                fontWeight: FontWeight.bold),
          ),
        ],
      )),
    );
  }
}
