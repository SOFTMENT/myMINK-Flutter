import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mymink/core/constants/app_routes.dart';

import 'package:mymink/core/constants/colors.dart';
import 'package:mymink/core/constants/email_verification_type.dart';
import 'package:mymink/core/utils/common_input_decoration.dart';
import 'package:mymink/core/widgets/custom_button.dart';
import 'package:mymink/core/widgets/custom_dialog.dart';
import 'package:mymink/core/widgets/dismiss_keyboard_ontap.dart';
import 'package:mymink/core/widgets/progress_hud.dart';
import 'package:mymink/features/onboarding/data/services/auth_service.dart';

import 'package:mymink/gen/assets.gen.dart';

class RetrievePasswordPage extends StatefulWidget {
  RetrievePasswordPage({super.key});

  @override
  State<RetrievePasswordPage> createState() => _RetrievePasswordPageState();
}

class _RetrievePasswordPageState extends State<RetrievePasswordPage> {
  String _emailAddress = "";
  var _isLoading = false;

  GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  void _getCode() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() {
        _isLoading = true;
      });

      int randomNumber = AuthService.generateRandomNumber();
      final error =
          await AuthService.sendResetPasswordCode(_emailAddress, randomNumber);
      if (error == null) {
        context.push(AppRoutes.resetVerificationCodePage, extra: {
          'email': _emailAddress,
          'verificationCode': randomNumber,
          'type': VerificationType.RESET_PASSWORD,
        });
      } else {
        CustomDialog.show(context, title: 'Error', message: error);
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          DismissKeyboardOnTap(
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: Column(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      Assets.images.colorfuldesign.image(
                          height: 250,
                          width: double.infinity,
                          fit: BoxFit.fill),
                      Positioned(
                        child:
                            Assets.images.logo.image(width: 100, height: 100),
                        top: 200,
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 25, vertical: 70),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          onTap: () {
                            context.pop();
                          },
                          child: Container(
                            padding: const EdgeInsets.all(
                                12), // Control the padding for the icon
                            decoration: BoxDecoration(
                              color: Colors
                                  .white, // Background color of the button
                              borderRadius: BorderRadius.circular(
                                  8), // Border radius of the button
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withValues(
                                      alpha: 0.3), // Drop shadow color
                                  spreadRadius: 1,
                                  blurRadius: 4,
                                  offset: const Offset(0, 2), // Shadow position
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.arrow_back_outlined, // Your icon
                              color: Colors.black, // Icon color
                              size: 18, // Icon size
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          "Retrieve Password",
                          style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textBlack),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "Enter your email address to get verification code.",
                          style: TextStyle(
                              fontSize: 14, color: AppColors.textGrey),
                        ),
                        const SizedBox(height: 32),
                        Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              SizedBox(
                                height: 66,
                                width: double.infinity,
                                child: TextFormField(
                                  keyboardType: TextInputType.emailAddress,
                                  autocorrect: false,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Enter email address.';
                                    }
                                    if (!value.contains('@')) {
                                      return 'Enter valid email address';
                                    }
                                    return null;
                                  },
                                  onSaved: (newValue) {
                                    _emailAddress = newValue ?? '';
                                  },
                                  decoration: buildInputDecoration(
                                      labelText: "Email Address",
                                      prefixIcon: Icons.email_outlined),
                                ),
                              ),
                              const SizedBox(
                                height: 32,
                              ),
                              CustomButton(
                                  text: "Get Code",
                                  onPressed: _getCode,
                                  backgroundColor: AppColors.textBlack),
                              const SizedBox(
                                height: 28,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isLoading)
            Center(
              child: ProgressHud(
                message: 'Retrieving Password...',
              ),
            ),
        ],
      ),
    );
  }
}
