import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mymink/core/constants/app_routes.dart';
import 'package:mymink/core/constants/colors.dart';
import 'package:mymink/core/utils/common_utils.dart';
import 'package:mymink/core/widgets/custom_button.dart';
import 'package:mymink/gen/assets.gen.dart';

class CopyPasswordPage extends StatelessWidget {
  CopyPasswordPage({super.key, required this.email, required this.password});
  final String email;
  final String password;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Assets.images.colorfuldesign
                  .image(height: 260, width: double.infinity, fit: BoxFit.fill),
              Positioned(
                child: Assets.images.logo.image(width: 120, height: 120),
                top: 200,
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Great!, here is your password",
                  style: TextStyle(fontSize: 18, color: AppColors.textBlack),
                ),
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                            alpha: 0.1), // Shadow color with some transparency
                        offset: const Offset(0, 2), // Shadow position
                        blurRadius: 8, // Blur radius for the shadow
                        spreadRadius:
                            0, // Spread radius to control how far the shadow spreads
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          email,
                          style: const TextStyle(
                              color: AppColors.primaryRed, fontSize: 17),
                        ),
                        const SizedBox(
                          height: 6,
                        ),
                        Text(
                          password,
                          style: const TextStyle(
                              color: AppColors.primaryRed, fontSize: 17),
                        ),
                        const SizedBox(
                          height: 20,
                        ),
                        IconButton(
                          onPressed: () {
                            CommonUtils.copyToClipboard(
                                context, email, password);
                          },
                          icon: Assets.images.group1000007771.image(height: 48),
                        )
                      ],
                    ),
                  ),
                ),
                const SizedBox(
                  height: 32,
                ),
                CustomButton(
                    text: "Go to Login Screen",
                    onPressed: () {
                      context.go(AppRoutes.login);
                    },
                    backgroundColor: AppColors.textBlack)
              ],
            ),
          ),
        ],
      ),
    );
  }
}
