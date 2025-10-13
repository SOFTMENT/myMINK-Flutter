import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mymink/core/constants/app_routes.dart';
import 'package:mymink/core/constants/colors.dart';
import 'package:mymink/core/utils/common_input_decoration.dart';
import 'package:mymink/core/utils/result.dart';

import 'package:mymink/core/widgets/custom_button.dart';
import 'package:mymink/core/widgets/custom_checkbox.dart';
import 'package:mymink/core/widgets/custom_dialog.dart';
import 'package:mymink/core/widgets/custom_text_button.dart';
import 'package:mymink/core/widgets/dismiss_keyboard_ontap.dart';
import 'package:mymink/core/widgets/progress_hud.dart';
import 'package:mymink/features/onboarding/data/models/user_model.dart';
import 'package:mymink/features/onboarding/data/services/auth_service.dart';
import 'package:mymink/features/onboarding/data/services/user_service.dart';
import 'package:mymink/gen/assets.gen.dart';

class LoginPage extends StatefulWidget {
  LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  void _forgotPassword(BuildContext context) {
    context.push(AppRoutes.retrievePasswordPage);
  }

  bool _isLoading = false;

  String _email = '';
  String _password = '';

  bool _obscureText = true;

  void _googleLogin() async {
    final result = await AuthService.signInWithGoogle();

    if (result.hasData) _continueLoginAppleAndGoogle(result, "google");
  }

  void _appleLogin() async {
    final result = await AuthService.signInWithApple();
    if (result.hasData) _continueLoginAppleAndGoogle(result, "apple");
  }

  void _continueLoginAppleAndGoogle(
      Result<User?> result, String regiType) async {
    setState(() {
      _isLoading = true;
    });
    final result1 = await UserService.getUserByUid(uid: result.data!.uid);
    if (result1.hasData) {
      if (result1.data!.username != null &&
          result1.data!.username!.isNotEmpty) {
        context.go(AppRoutes.tabbar);
      } else {
        context.go(AppRoutes.complete_profile);
      }
      setState(() {
        _isLoading = false;
      });
    } else {
      if (regiType == "google") {
        _addGoogleAndAppleUser(result, regiType);
      } else {
        _addGoogleAndAppleUser(result, regiType);
      }
    }
  }

  void _addGoogleAndAppleUser(Result<User?> result, String regiType) async {
    if (result.hasData) {
      User user = result.data!;

      final result1 = await UserService.addNewUser(
          user.uid,
          user.displayName ?? 'NoName',
          user.email ?? 'NoEmail',
          regiType,
          null,
          null,
          null);
      if (result1.hasError) {
        CustomDialog.show(context, title: "ERROR", message: result1.error!);
      } else {
        context.go(AppRoutes.complete_profile);
      }
      setState(() {
        _isLoading = false;
      });
    } else {
      await CustomDialog.show(context, title: "ERROR", message: result.error!);
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _login() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() {
        _isLoading = true;
      });

      final error = await AuthService.signInUser(_email, _password);
      if (error == null) {
        final result = await UserService.getUserByUid(
            uid: AuthService.currentUser?.uid ?? '');
        if (result.hasError) {
          await CustomDialog.show(context,
              title: 'Error', message: result.error!);
        } else {
          UserModel userModel = result.data!;
          UserModel.data = userModel;
          if (userModel.username != null && !userModel.username!.isEmpty) {
            context.go(AppRoutes.tabbar);
          } else {
            context.push(AppRoutes.complete_profile);
          }
        }
        setState(() {
          _isLoading = false;
        });
      } else {
        await CustomDialog.show(context, title: 'Error', message: error);
        setState(() {
          _isLoading = false;
        });
      }
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
                        top: 150,
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(25, 0, 25, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
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
                          "Login",
                          style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textBlack),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "Enter your email address & password below",
                          style: TextStyle(
                              fontSize: 14, color: AppColors.textGrey),
                        ),
                        const SizedBox(height: 32),
                        Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              SizedBox(
                                width: double.infinity,
                                child: TextFormField(
                                  keyboardType: TextInputType.emailAddress,
                                  autocorrect: false,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Enter email address';
                                    }
                                    if (!value.contains('@')) {
                                      return 'Enter valid email address';
                                    }
                                    return null;
                                  },
                                  onSaved: (newValue) {
                                    _email = newValue!;
                                  },
                                  decoration: buildInputDecoration(
                                      labelText: "Email Address",
                                      prefixIcon: Icons.email_outlined),
                                ),
                              ),
                              const SizedBox(
                                height: 12,
                              ),
                              SizedBox(
                                width: double.infinity,
                                child: TextFormField(
                                    keyboardType: TextInputType.visiblePassword,
                                    obscureText: _obscureText,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Enter Password';
                                      }
                                      if (value.length < 6) {
                                        return "Password must be at least 6 characters long.";
                                      }

                                      return null;
                                    },
                                    onSaved: (newValue) {
                                      _password = newValue!;
                                    },
                                    decoration: buildInputDecoration(
                                        suffixIcon: Icon(
                                          _obscureText
                                              ? Icons
                                                  .visibility_off // Show eye-off when password is hidden
                                              : Icons
                                                  .visibility, // Show eye when password is visible
                                          color: Colors.grey,
                                        ),
                                        suffixIconPressed: () {
                                          setState(() {
                                            _obscureText = !_obscureText;
                                          });
                                        },
                                        labelText: "Password",
                                        prefixIcon: Icons.lock_outline)),
                              ),
                              const SizedBox(
                                height: 8,
                              ),
                              Padding(
                                padding: const EdgeInsets.only(left: 1),
                                child: Row(
                                  children: [
                                    CustomCheckbox(
                                        onStatusChanged: (isChecked) {}),
                                    const SizedBox(
                                      width: 8,
                                    ),
                                    const Text(
                                      "Remember Me",
                                      style: TextStyle(
                                          color: AppColors.textBlack,
                                          fontSize: 13),
                                    ),
                                    const Spacer(),
                                    CustomTextButton(
                                        title: "Forgot Password?",
                                        color: AppColors.textBlack,
                                        fontSize: 14,
                                        onPressed: () {
                                          _forgotPassword(context);
                                        }),
                                  ],
                                ),
                              ),
                              const SizedBox(
                                height: 24,
                              ),
                              CustomButton(
                                  text: "Login",
                                  onPressed: _login,
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
                                        context.push(
                                            AppRoutes.signInPhoneNumberPage);
                                      },
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.all(
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
                                      onPressed: _googleLogin,
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.all(
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
                                      onPressed: _appleLogin,
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.all(
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
                              const SizedBox(
                                height: 36,
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text(
                                    "Don't have an account?  ",
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: AppColors.textBlack,
                                    ),
                                  ),
                                  CustomTextButton(
                                      title: "Sign Up",
                                      color: AppColors.primaryRed,
                                      fontSize: 14,
                                      onPressed: () {
                                        context.push(AppRoutes.signup);
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
            ),
          ),
          if (_isLoading)
            Center(
              child: ProgressHud(
                message: 'Login...',
              ),
            ),
        ],
      ),
    );
  }
}
