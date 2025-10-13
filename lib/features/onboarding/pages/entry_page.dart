import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mymink/core/constants/app_routes.dart';
import 'package:mymink/core/constants/colors.dart';

import 'package:mymink/core/utils/url_utils.dart';
import 'package:mymink/core/widgets/custom_button.dart';
import 'package:mymink/core/widgets/custom_checkbox.dart';
import 'package:mymink/core/widgets/custom_text_button.dart';

import 'package:mymink/gen/assets.gen.dart';

class EntryPage extends StatefulWidget {
  const EntryPage({super.key});

  @override
  State<EntryPage> createState() => _EntryPageState();
}

class _EntryPageState extends State<EntryPage> {
  @override
  void initState() {
    super.initState();
  }

  var _isCheck = false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 20),
              child: Assets.images.logo.image(
                width: 120,
                height: 120,
              ),
            ),
            const SizedBox(
              height: 24,
            ),
            Assets.images.wave
                .image(width: double.infinity, height: 165, fit: BoxFit.fill),
            const SizedBox(
              height: 24,
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 25),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Unroll the world with",
                    style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(
                    height: 1,
                  ),
                  Text(
                    "my MINK",
                    style: TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textBlack),
                  ),
                  SizedBox(
                    height: 12,
                  ),
                  Text(
                    "Let’s get started with a login or create your new my MINK account.",
                    style: TextStyle(fontSize: 14, color: AppColors.textGrey),
                  ),
                ],
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.only(left: 25, right: 25),
              child: Row(
                children: [
                  CustomCheckbox(
                    onStatusChanged: (staus) {
                      _isCheck = staus;
                    },
                  ),
                  const SizedBox(
                    width: 8,
                  ),
                  const Text(
                    "I agree to the",
                    style: TextStyle(fontSize: 12, color: AppColors.textBlack),
                  ),
                  CustomTextButton(
                    title: " EULA ",
                    color: AppColors.primaryBlue,
                    onPressed: () {
                      UrlUtils.openURL("https://mymink.com.au/eula", context);
                    },
                  ),
                  const Text(
                    "&",
                    style: TextStyle(fontSize: 12, color: AppColors.textBlack),
                  ),
                  CustomTextButton(
                    title: " Terms Of Use",
                    color: AppColors.primaryBlue,
                    onPressed: () {
                      UrlUtils.openURL(
                          "https://mymink.com.au/terms-of-use", context);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(
              height: 16,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(25, 0, 25, 32),
              child: Column(
                children: [
                  CustomButton(
                      text: "Login",
                      onPressed: () {
                        if (_isCheck) {
                          context.push(AppRoutes.login);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content:
                                  Text("Please accept EULA & Terms Of Use"),
                            ),
                          );
                        }
                      },
                      backgroundColor: AppColors.textBlack),
                  const SizedBox(
                    height: 20,
                  ),
                  CustomButton(
                      text: "Create an account",
                      onPressed: () {
                        if (_isCheck) {
                          context.push(AppRoutes.signup);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content:
                                  Text("Please accept EULA & Terms Of Use"),
                            ),
                          );
                        }
                      },
                      backgroundColor: AppColors.primaryRed),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
