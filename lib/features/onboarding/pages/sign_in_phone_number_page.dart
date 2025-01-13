import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mymink/core/constants/app_routes.dart';
import 'package:mymink/core/constants/colors.dart';
import 'package:mymink/core/constants/email_verification_type.dart';
import 'package:mymink/core/services/twilio_service.dart';
import 'package:mymink/core/utils/common_input_decoration.dart';
import 'package:mymink/core/widgets/country_picker.dart';
import 'package:mymink/core/widgets/custom_button.dart';
import 'package:mymink/core/widgets/custom_dialog.dart';
import 'package:mymink/core/widgets/custom_text_button.dart';
import 'package:mymink/core/widgets/progress_hud.dart';
import 'package:mymink/features/onboarding/data/services/user_service.dart';
import 'package:mymink/gen/assets.gen.dart';

class SignInPhoneNumberPage extends StatefulWidget {
  SignInPhoneNumberPage({super.key});

  @override
  State<SignInPhoneNumberPage> createState() => _SignInPhoneNumberPageState();
}

class _SignInPhoneNumberPageState extends State<SignInPhoneNumberPage> {
  String _selectedCountryCode = '+61'; // Default country code
  String _selectedFlag = "🇦🇺";
  String _number = "";
  bool _isLoading = false;
  String _isLoadingLbl = "Login...";
  GlobalKey<FormState> _globalKey = GlobalKey<FormState>();

  void _loginPressed() async {
    if (_globalKey.currentState!.validate()) {
      _globalKey.currentState!.save();
      setState(() {
        _isLoading = true;
      });
      final result = await UserService.getUserByPhone(
          phoneNumber: '$_selectedCountryCode$_number');

      if (result.hasData) {
        final error = await TwilioService.sendTwilioVerification(
            '$_selectedCountryCode$_number');
        if (error == null) {
          context.push(AppRoutes.phoneVerificationCodePage, extra: {
            'verificationUid': result.data!.uid ?? '',
            'phoneNumber': '$_selectedCountryCode$_number',
            'type': VerificationType.PHONE_VERIFICATION,
          });
        } else {
          await CustomDialog.show(context, title: 'ERROR', message: error);
        }
        setState(() {
          _isLoading = false;
        });
      } else {
        await CustomDialog.show(context,
            title: 'Account Not Found',
            message:
                'There is no account linked with this phone number. Please sign up for a new account first.');
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
          SingleChildScrollView(
            physics: ClampingScrollPhysics(),
            child: Column(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    Assets.images.colorfuldesign.image(
                        height: 260, width: double.infinity, fit: BoxFit.fill),
                    Positioned(
                      child: Assets.images.logo.image(width: 100, height: 100),
                      top: 200,
                    ),
                  ],
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 25, vertical: 100),
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
                          padding: EdgeInsets.all(
                              12), // Control the padding for the icon
                          decoration: BoxDecoration(
                            color:
                                Colors.white, // Background color of the button
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
                        "Login",
                        style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textBlack),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Enter your country code & phone number below",
                        style:
                            TextStyle(fontSize: 14, color: AppColors.textGrey),
                      ),
                      const SizedBox(height: 32),
                      Form(
                        key: _globalKey,
                        child: Column(
                          children: [
                            Row(
                              children: [
                                SizedBox(
                                  height: 66,
                                  width: 80,
                                  child: GestureDetector(
                                    onTap: () {
                                      // Show the country picker when the field is tapped
                                      CountryPicker.show(context,
                                          (selectedCode, flag) {
                                        setState(() {
                                          _selectedFlag = flag;
                                          _selectedCountryCode = selectedCode;
                                        });
                                      });
                                    },
                                    child: AbsorbPointer(
                                      child: TextFormField(
                                        readOnly: true,
                                        controller: TextEditingController(
                                            text: ' $_selectedCountryCode'),
                                        keyboardType: TextInputType.phone,
                                        autocorrect: false,
                                        style: TextStyle(fontSize: 15),
                                        decoration: InputDecoration(
                                          prefix: Text(_selectedFlag),
                                          filled: true,
                                          fillColor: AppColors.white,
                                          labelStyle: TextStyle(
                                              color: AppColors.textGrey),
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
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(8),
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
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: SizedBox(
                                    height: 66,
                                    width: double.infinity,
                                    child: TextFormField(
                                      keyboardType: TextInputType.phone,
                                      autocorrect: false,
                                      style: TextStyle(fontSize: 15),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return "Enter phone number";
                                        }
                                        return null;
                                      },
                                      onSaved: (newValue) {
                                        _number = newValue!;
                                      },
                                      decoration: buildInputDecoration(
                                          labelText: "Phone Number",
                                          prefixIcon: Icons.phone_outlined),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(
                              height: 32,
                            ),
                            CustomButton(
                                text: "Login",
                                onPressed: _loginPressed,
                                backgroundColor: AppColors.textBlack),
                            SizedBox(
                              height: 36,
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
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
                                      context.push(
                                          AppRoutes.signUpPhoneNumberPage);
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
          if (_isLoading)
            Center(
              child: ProgressHud(
                message: _isLoadingLbl,
              ),
            ),
        ],
      ),
    );
  }
}
