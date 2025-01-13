import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mymink/core/constants/app_routes.dart';
import 'package:mymink/core/constants/colors.dart';
import 'package:mymink/core/constants/email_verification_type.dart';
import 'package:mymink/core/services/encryption_service.dart';
import 'package:mymink/core/utils/common_input_decoration.dart';
import 'package:mymink/core/widgets/custom_button.dart';

import 'package:mymink/core/widgets/custom_dialog.dart';
import 'package:mymink/core/widgets/custom_text_button.dart';
import 'package:mymink/core/widgets/progress_hud.dart';
import 'package:mymink/features/onboarding/data/services/auth_service.dart';

import 'package:mymink/gen/assets.gen.dart';

class SignUpPage extends StatefulWidget {
  SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  var _isLoading = false;
  bool _obscureText = true;

  void _togglePasswordView() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  String firstName = "";
  String lastName = "";
  String emailAddress = "";
  String password = "";

  void _signUpPressed() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      String fullName = firstName + " " + lastName;
      String encryptionKey =
          EncryptionService().generateEncryptionKey(password);
      String encryptPassword =
          EncryptionService().encryptMessage(password, encryptionKey);

      setState(() {
        _isLoading = true;
      });

      int randomNumber = AuthService.generateRandomNumber();
      final error = await AuthService.checkUserAndSendVerification(
          emailAddress, randomNumber);

      error == null
          ? context.push(AppRoutes.emailVerificationCodePage, extra: {
              'email': emailAddress,
              'type': VerificationType.EMAIL_VERIFICATION,
              'verificationCode': randomNumber,
              'encryptionKey': encryptionKey,
              'encryptPassword': encryptPassword,
              'fullName': fullName,
            })
          : await CustomDialog.show(context, title: "ERROR", message: error);
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          SingleChildScrollView(
            physics: ClampingScrollPhysics(),
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.topCenter,
                  clipBehavior: Clip.none,
                  children: [
                    Assets.images.colorfuldesign.image(
                        height: 250, width: double.infinity, fit: BoxFit.fill),
                    Positioned(
                      child: Assets.images.logo.image(width: 100, height: 100),
                      top: 160,
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(25, 220, 25, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GestureDetector(
                            onTap: () {
                              context.pop();
                            },
                            child: Container(
                              padding: EdgeInsets.all(
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
                                    offset: Offset(0, 2), // Shadow position
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.arrow_back_outlined, // Your icon
                                color: Colors.black, // Icon color
                                size: 18, // Icon size
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            "Sign Up",
                            style: TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textBlack),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Enter your details to create a new account",
                            style: TextStyle(
                                fontSize: 14, color: AppColors.textGrey),
                          ),
                          const SizedBox(height: 32),
                          Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: SizedBox(
                                        height: 66,
                                        child: TextFormField(
                                          textCapitalization:
                                              TextCapitalization.words,
                                          autocorrect: false,
                                          onSaved: (newValue) {
                                            firstName = newValue!;
                                          },
                                          validator: (value) {
                                            if (value == null ||
                                                value.isEmpty) {
                                              return "Enter First Name";
                                            }
                                            return null;
                                          },
                                          decoration: buildInputDecoration(
                                              labelText: "First Name",
                                              prefixIcon: Icons
                                                  .person_outline_outlined),
                                        ),
                                      ),
                                    ),

                                    // Add a width spacing between the two TextFormFields (if needed)
                                    SizedBox(width: 10),

                                    // Second TextFormField wrapped in Expanded for equal space
                                    Expanded(
                                      child: SizedBox(
                                        height: 66,
                                        child: TextFormField(
                                          textCapitalization:
                                              TextCapitalization.words,
                                          autocorrect: false,
                                          onSaved: (newValue) {
                                            lastName = newValue!;
                                          },
                                          validator: (value) {
                                            if (value == null ||
                                                value.isEmpty) {
                                              return "Enter Last Name";
                                            }
                                            return null;
                                          },
                                          decoration: buildInputDecoration(
                                              labelText: "Last Name",
                                              prefixIcon: Icons
                                                  .person_outline_outlined),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(
                                  height: 10,
                                ),
                                SizedBox(
                                  height: 66,
                                  width: double.infinity,
                                  child: TextFormField(
                                    keyboardType: TextInputType.emailAddress,
                                    autocorrect: false,
                                    onSaved: (newValue) {
                                      emailAddress = newValue!;
                                    },
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return "Enter Email Address";
                                      }
                                      if (!value.contains('@')) {
                                        return "Enter Valid Email Address";
                                      }
                                      return null;
                                    },
                                    decoration: buildInputDecoration(
                                        labelText: "Email Address",
                                        prefixIcon: Icons.email_outlined),
                                  ),
                                ),
                                const SizedBox(
                                  height: 10,
                                ),
                                SizedBox(
                                  height: 66,
                                  width: double.infinity,
                                  child: TextFormField(
                                    keyboardType: TextInputType.emailAddress,
                                    obscureText: _obscureText,
                                    onSaved: (newValue) {
                                      password = newValue!;
                                    },
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return "Enter Password";
                                      }
                                      if (value.length < 6) {
                                        return "Password must be at least 6 characters long.";
                                      }
                                      return null;
                                    },
                                    decoration: InputDecoration(
                                      prefixIcon: Icon(
                                        Icons.lock_outline,
                                        color: AppColors.primaryRed,
                                      ),
                                      suffixIcon: GestureDetector(
                                        onTap:
                                            _togglePasswordView, // Toggle password visibility
                                        child: Icon(
                                          _obscureText
                                              ? Icons
                                                  .visibility_off // Show eye-off when password is hidden
                                              : Icons
                                                  .visibility, // Show eye when password is visible
                                          color: Colors.grey,
                                        ),
                                      ),
                                      label: Text(
                                        "Password",
                                        style: TextStyle(fontSize: 14.2),
                                      ),
                                      filled: true,
                                      fillColor: AppColors.white,
                                      labelStyle:
                                          TextStyle(color: AppColors.textGrey),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(
                                            8), // Rounded corners
                                        borderSide: BorderSide(
                                          color: AppColors.textGrey.withValues(
                                              alpha:
                                                  0.3), // Light grey color for border
                                          width: 1.0, // Border width
                                        ),
                                      ),
                                      // Border for focused state
                                      errorBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide(
                                          color: AppColors
                                              .primaryRed, // Red color for focus
                                          width:
                                              1.0, // Border width when focused
                                        ),
                                      ),
                                      focusedErrorBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide(
                                          color: AppColors
                                              .primaryRed, // Red color for focus
                                          width:
                                              1.0, // Border width when focused
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide(
                                          color: AppColors
                                              .primaryRed, // Blue color for focus
                                          width:
                                              1.0, // Border width when focused
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(
                                  height: 24,
                                ),
                                CustomButton(
                                    text: "Sign Up",
                                    onPressed: _signUpPressed,
                                    backgroundColor: AppColors.textBlack),
                                const SizedBox(
                                  height: 28,
                                ),
                                Row(
                                  children: [
                                    SizedBox(
                                      width: 38,
                                      child: Divider(
                                        height: 0.5,
                                        color: AppColors.textGrey
                                            .withValues(alpha: 0.4),
                                      ),
                                    ),
                                    const SizedBox(
                                      width: 10,
                                    ),
                                    const Text(
                                      "Or Login With",
                                      style: TextStyle(
                                          color: AppColors.textGrey,
                                          fontSize: 14),
                                    ),
                                    const SizedBox(
                                      width: 10,
                                    ),
                                    Expanded(
                                      child: Divider(
                                        height: 0.5,
                                        color: AppColors.textGrey
                                            .withValues(alpha: 0.4),
                                      ),
                                    ),
                                    const SizedBox(
                                      width: 10,
                                    ),
                                    SizedBox(
                                      height: 40,
                                      width: 40,
                                      child: ElevatedButton(
                                        onPressed: () {
                                          // Handle button press
                                        },
                                        style: ElevatedButton.styleFrom(
                                          padding: EdgeInsets.all(
                                              0), // Remove any default padding
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                                6), // Rounded corners
                                          ),
                                          elevation: 0,
                                          backgroundColor: Colors
                                              .red, // Button background color
                                        ),
                                        child: Container(
                                          alignment: Alignment.center,
                                          child: Assets.images.mobilePhone
                                              .image(height: 20, width: 20),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(
                                      width: 8,
                                    ),
                                    SizedBox(
                                      height: 40,
                                      width: 40,
                                      child: ElevatedButton(
                                        onPressed: () {
                                          // Handle button press
                                        },
                                        style: ElevatedButton.styleFrom(
                                          padding: EdgeInsets.all(
                                              0), // Remove any default padding
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                                6), // Rounded corners
                                          ),
                                          elevation: 0,
                                          backgroundColor: Colors
                                              .red, // Button background color
                                        ),
                                        child: Container(
                                          alignment: Alignment.center,
                                          child: Assets.images.google8
                                              .image(height: 20, width: 20),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(
                                      width: 8,
                                    ),
                                    SizedBox(
                                      height: 40,
                                      width: 40,
                                      child: ElevatedButton(
                                        onPressed: () {
                                          // Handle button press
                                        },
                                        style: ElevatedButton.styleFrom(
                                          padding: EdgeInsets.all(
                                              0), // Remove any default padding
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                                6), // Rounded corners
                                          ),
                                          elevation: 0,
                                          backgroundColor: Colors
                                              .red, // Button background color
                                        ),
                                        child: Container(
                                          alignment: Alignment.center,
                                          child: Assets.images.appleIcon
                                              .image(height: 20, width: 20),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(
                                  height: 42,
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      "Already have an account? ",
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: AppColors.textBlack,
                                      ),
                                    ),
                                    CustomTextButton(
                                        title: "Login",
                                        color: AppColors.primaryRed,
                                        fontSize: 14,
                                        onPressed: () {
                                          context.pop();
                                        }),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (_isLoading)
            Center(
              child: ProgressHud(
                message: "Creating Account...",
              ),
            ),
        ],
      ),
    );
  }
}
