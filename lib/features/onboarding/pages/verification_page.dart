import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mymink/core/constants/app_routes.dart';

import 'package:mymink/core/constants/colors.dart';
import 'package:mymink/core/constants/email_verification_type.dart';
import 'package:mymink/core/services/email_service.dart';
import 'package:mymink/core/services/encryption_service.dart';
import 'package:mymink/core/services/twilio_service.dart';
import 'package:mymink/core/utils/common_input_decoration.dart';
import 'package:mymink/core/widgets/custom_button.dart';
import 'package:mymink/core/widgets/custom_dialog.dart';

import 'package:mymink/core/widgets/custom_text_button.dart';
import 'package:mymink/core/widgets/dismiss_keyboard_ontap.dart';
import 'package:mymink/core/widgets/progress_hud.dart';

import 'package:mymink/features/onboarding/data/services/auth_service.dart';
import 'package:mymink/features/onboarding/data/services/user_service.dart';
import 'package:mymink/gen/assets.gen.dart';

class VerificationPage extends StatefulWidget {
  VerificationPage.resetPassword(
      {super.key,
      required this.email,
      required this.verificationCode,
      required this.type})
      : fullName = null,
        encryptionkey = null,
        encryptionPassword = null,
        verificationUid = null,
        phoneNumber = null;

  VerificationPage.phoneNumber(String? fullName,
      {super.key,
      required this.verificationUid,
      required this.phoneNumber,
      required this.type})
      : fullName = fullName,
        email = null,
        encryptionkey = null,
        verificationCode = null,
        encryptionPassword = null;

  VerificationPage(
      {super.key,
      required this.email,
      required this.encryptionkey,
      required this.encryptionPassword,
      required this.fullName,
      required this.type,
      required this.verificationCode})
      : phoneNumber = null,
        verificationUid = null;

  final String? email;
  final String? fullName;
  final String? encryptionkey;
  final String? encryptionPassword;
  final VerificationType type;
  final int? verificationCode;
  final String? verificationUid;
  final String? phoneNumber;

  @override
  State<VerificationPage> createState() => _VerificationPageState();
}

class _VerificationPageState extends State<VerificationPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  int _counter = 60;
  Timer? _timer;
  var _isLoading = false;
  String? _loadingMessage;
  var _code = '';

  void _verifiyCode() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      if (widget.type == VerificationType.EMAIL_VERIFICATION) {
        if (_code != widget.verificationCode.toString()) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Incorrect verification code')));
          return;
        }

        setState(() {
          _loadingMessage = 'Verifying...';
          _isLoading = true;
        });

        final password = EncryptionService()
            .decryptMessage(widget.encryptionPassword!, widget.encryptionkey!);

        if (password == null) {
          setState(() {
            _isLoading = false;
          });
          await CustomDialog.show(context,
              title: 'Error', message: 'Something went wrong.');
          return;
        }

        final error = await AuthService.createUser(widget.email!, password);
        if (error == null) {
          if (AuthService.currentUser != null) {
            final result = await UserService.addNewUser(
                AuthService.currentUser!.uid,
                widget.fullName!,
                widget.email!,
                "custom",
                null,
                widget.encryptionkey,
                widget.encryptionPassword);
            if (result.hasError) {
              await CustomDialog.show(context,
                  title: "ERROR", message: result.error!);
            } else {
              context.push(AppRoutes.complete_profile);
            }
            setState(() {
              _isLoading = false;
            });
          } else {
            setState(() {
              _isLoading = false;
            });
          }
        } else {
          await CustomDialog.show(context, title: "ERROR", message: error);
          setState(() {
            _isLoading = false;
          });
        }
      } else if (widget.type == VerificationType.RESET_PASSWORD) {
        if (_code != widget.verificationCode.toString()) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Incorrect verification code')));
          return;
        }
        setState(() {
          _loadingMessage = 'Verifying...';
          _isLoading = true;
        });

        final result = await UserService.getUserByEmail(
            email: widget.email!, regiType: 'custom');
        if (result.hasError) {
          await CustomDialog.show(context,
              title: "ERROR", message: result.error!);
        } else {
          final password = EncryptionService().decryptMessage(
              result.data!.encryptPassword ?? '',
              result.data!.encryptKey ?? '');

          if (password == null) {
            await CustomDialog.show(context,
                title: 'Error', message: 'Something went wrong.');
          } else {
            context.go(AppRoutes.copyPasswordPage, extra: {
              'email': widget.email,
              'password': password,
            });
          }
        }
        setState(() {
          _isLoading = false;
        });
      } else {
        setState(() {
          _loadingMessage = 'Verifying...';
          _isLoading = true;
        });

        final error =
            await TwilioService.verifyTwilioCode(widget.phoneNumber!, _code);

        if (error == null) {
          final result =
              await AuthService.createCustomToken(widget.verificationUid!);
          if (result.hasData) {
            final token = result.data!;

            final result1 = await AuthService.signInWithCustomToken(token);
            if (result1.hasData) {
              if (widget.fullName != null && widget.fullName!.isNotEmpty) {
                final result2 = await UserService.addNewUser(
                    widget.verificationUid!,
                    widget.fullName!,
                    null,
                    "phone",
                    widget.phoneNumber,
                    null,
                    null);
                if (result2.hasData) {
                  context.go(AppRoutes.complete_profile);
                } else {
                  await UserService.handleUserStateByUid(
                      context, widget.verificationUid!);
                  setState(() {
                    _isLoading = false;
                  });
                }
              } else {
                await UserService.handleUserStateByUid(
                    context, widget.verificationUid!);
                setState(() {
                  _isLoading = false;
                });
              }
            } else {
              await CustomDialog.show(context,
                  title: "ERROR", message: result1.error!);
              setState(() {
                _isLoading = false;
              });
            }
          } else {
            await CustomDialog.show(context,
                title: "ERROR", message: result.error!);
            setState(() {
              _isLoading = false;
            });
          }
        } else {
          await CustomDialog.show(context, title: "ERROR", message: error);
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  Future<String?> safeSignInWithCustomToken(String rawToken) async {
    try {
      // 1) Strip whitespace/newlines and accidental surrounding quotes
      var t = rawToken.trim();
      if (t.startsWith('"') && t.endsWith('"')) {
        t = t.substring(1, t.length - 1);
      }

      // 2) Quick sanity checks: three dot-separated parts
      final dotCount = '.'.allMatches(t).length;
      if (dotCount != 2) {
        return "Received invalid token (not a JWT).";
      }

      // 3) Try sign-in
      await FirebaseAuth.instance.signInWithCustomToken(t);
      return null; // success
    } catch (e) {
      return e.toString();
    }
  }

  void _resendVerificationCode() async {
    setState(() {
      _isLoading = true;
    });
    if (widget.type == VerificationType.PHONE_VERIFICATION) {
      final error =
          await TwilioService.sendTwilioVerification(widget.phoneNumber!);

      error == null
          ? ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Code has been sent'),
              ),
            )
          : CustomDialog.show(context, title: "ERROR", message: error);
    } else {
      final error = await EmailService.sendVerificationEmail(
          widget.email!, widget.verificationCode!, widget.type);
      error == null
          ? ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Code has been sent'),
              ),
            )
          : CustomDialog.show(context, title: "ERROR", message: error);
    }

    setState(() {
      _isLoading = false;
    });
    _startTimer();
  }

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _counter = 60;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_counter > 0) {
          _counter--;
        } else {
          _timer?.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
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
                          height: 260,
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
                    padding: const EdgeInsets.fromLTRB(25, 70, 25, 24),
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
                          "Enter Code",
                          style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textBlack),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Enter one time password sent to your ${widget.type == VerificationType.PHONE_VERIFICATION ? 'phone number.' : 'email address.'}",
                          style: const TextStyle(
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
                                  keyboardType: TextInputType.number,
                                  autocorrect: false,
                                  onSaved: (newValue) {
                                    _code = newValue!;
                                  },
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Enter verification code.';
                                    }

                                    if (widget.type !=
                                            VerificationType
                                                .PHONE_VERIFICATION &&
                                        value.trim() !=
                                            widget.verificationCode
                                                .toString()) {
                                      return 'Incorrect code.';
                                    }

                                    return null;
                                  },
                                  decoration: buildInputDecoration(
                                      labelText: "Code", prefixIcon: null),
                                ),
                              ),
                              const SizedBox(
                                height: 32,
                              ),
                              CustomButton(
                                  text: "Verify",
                                  onPressed: _verifiyCode,
                                  backgroundColor: AppColors.textBlack),
                              SizedBox(
                                height: _counter > 0 ? 40 : 28,
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 40,
                                    child: Divider(
                                      height: 0.6,
                                      color: AppColors.textGrey
                                          .withValues(alpha: 0.3),
                                    ),
                                  ),
                                  const SizedBox(
                                    width: 10,
                                  ),
                                  const Text(
                                    "Or resend",
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: AppColors.textGrey,
                                    ),
                                  ),
                                  const SizedBox(
                                    width: 10,
                                  ),
                                  SizedBox(
                                    width: 40,
                                    child: Divider(
                                      height: 0.6,
                                      color: AppColors.textGrey
                                          .withValues(alpha: 0.3),
                                    ),
                                  ),
                                  const SizedBox(
                                    width: 10,
                                  ),
                                  _counter > 0
                                      ? Text(
                                          '$_counter seconds',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: AppColors.textBlack,
                                          ),
                                        )
                                      : CustomTextButton(
                                          title: "Resend Code",
                                          color: AppColors.primaryBlue,
                                          fontSize: 14,
                                          onPressed: _resendVerificationCode),
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
                message: _loadingMessage,
              ),
            )
        ],
      ),
    );
  }
}
