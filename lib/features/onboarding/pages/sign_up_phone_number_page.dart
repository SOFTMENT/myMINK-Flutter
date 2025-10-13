import 'package:devicelocale/devicelocale.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mymink/core/constants/app_routes.dart';
import 'package:mymink/core/constants/colors.dart';
import 'package:mymink/core/constants/contries_list.dart';
import 'package:mymink/core/constants/email_verification_type.dart';
import 'package:mymink/core/services/twilio_service.dart';
import 'package:mymink/core/utils/common_input_decoration.dart';
import 'package:mymink/core/widgets/country_picker.dart';
import 'package:mymink/core/widgets/custom_button.dart';
import 'package:mymink/core/widgets/custom_dialog.dart';
import 'package:mymink/core/widgets/custom_text_button.dart';
import 'package:mymink/core/widgets/dismiss_keyboard_ontap.dart';
import 'package:mymink/core/widgets/progress_hud.dart';
import 'package:mymink/features/onboarding/data/services/user_service.dart';
import 'package:mymink/gen/assets.gen.dart';
import 'package:uuid/uuid.dart';

class SignUpPhoneNumberPage extends StatefulWidget {
  SignUpPhoneNumberPage({super.key});

  @override
  State<SignUpPhoneNumberPage> createState() => _SignUpPhoneNumberPageState();
}

class _SignUpPhoneNumberPageState extends State<SignUpPhoneNumberPage> {
  String _FirstName = '';
  String _LastName = '';
  String _selectedCountryCode = '+61'; // Default country code
  String _selectedFlag = "🇦🇺";
  String _number = "";
  bool _isLoading = false;
  String _isLoadingLbl = "Creating account...";
  GlobalKey<FormState> _globalKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();

    _detectUserCountry();
  }

  void _detectUserCountry() async {
    try {
      // Get the current locale as a String (e.g., "en-US")
      final localeString = await Devicelocale.currentLocale;
      print(localeString);
      if (localeString != null) {
        // Split the string to extract the country code
        final parts = localeString.split('-');
        if (parts.length >= 2) {
          final countryCode = parts[1]; // The country code is the second part
          getCountryDetails(countryCode);
        }
      }
    } catch (e) {
      print("Error detecting locale: $e");
    }
  }

  void getCountryDetails(String code) {
    // Find the country in the list based on the code
    var country = countryList.firstWhere(
      (element) => element['code'] == code,
      orElse: () => {
        "dial_code": "+61",
        "flag": "🇦🇺"
      }, // Default to Australia if not found
    );

    setState(() {
      _selectedCountryCode = country['dial_code'] ?? "+61";
      _selectedFlag = country['flag'] ?? "🇦🇺";
    });
  }

  void _signUpPressed() async {
    if (_globalKey.currentState!.validate()) {
      _globalKey.currentState!.save();
      setState(() {
        _isLoading = true;
      });
      final result = await UserService.getUserByPhone(
          phoneNumber: '$_selectedCountryCode$_number');

      if (result.hasData) {
        await CustomDialog.show(context,
            title: 'Accont Exist',
            message:
                'There is an account already available with the same phone number. Please Sign In.');
        setState(() {
          _isLoading = false;
        });
      } else {
        final error = await TwilioService.sendTwilioVerification(
            '$_selectedCountryCode$_number');
        if (error == null) {
          context.push(AppRoutes.phoneVerificationCodePage, extra: {
            'verificationUid': const Uuid().v4().toString(),
            'phoneNumber': '$_selectedCountryCode$_number',
            'type': VerificationType.PHONE_VERIFICATION,
            'fullName': '$_FirstName $_LastName'
          });
        } else {
          await CustomDialog.show(context, title: 'ERROR', message: error);
        }
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
                    padding: const EdgeInsets.symmetric(
                        horizontal: 25, vertical: 100),
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
                          "Sign Up",
                          style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textBlack),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "Enter your details to create a new account.",
                          style: TextStyle(
                              fontSize: 14, color: AppColors.textGrey),
                        ),
                        const SizedBox(height: 32),
                        Form(
                          key: _globalKey,
                          child: Column(
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // First TextFormField wrapped in Expanded for equal space
                                  Expanded(
                                    child: SizedBox(
                                      child: TextFormField(
                                        keyboardType: TextInputType.name,
                                        textCapitalization:
                                            TextCapitalization.words,
                                        autocorrect: false,
                                        onSaved: (newValue) {
                                          _FirstName = newValue!;
                                        },
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return "Enter First Name";
                                          }
                                          return null;
                                        },
                                        decoration: buildInputDecoration(
                                            labelText: "First Name",
                                            prefixIcon:
                                                Icons.person_outline_outlined),
                                      ),
                                    ),
                                  ),

                                  // Add a width spacing between the two TextFormFields (if needed)
                                  const SizedBox(width: 10),

                                  // Second TextFormField wrapped in Expanded for equal space
                                  Expanded(
                                    child: SizedBox(
                                      child: TextFormField(
                                        keyboardType: TextInputType.name,
                                        textCapitalization:
                                            TextCapitalization.words,
                                        autocorrect: false,
                                        onSaved: (newValue) {
                                          _LastName = newValue!;
                                        },
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return "Enter Last Name";
                                          }
                                          return null;
                                        },
                                        decoration: buildInputDecoration(
                                            labelText: "Last Name",
                                            prefixIcon:
                                                Icons.person_outline_outlined),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(
                                height: 16,
                              ),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
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
                                          style: const TextStyle(fontSize: 15),
                                          decoration: InputDecoration(
                                            isDense: true,
                                            prefix: Text(_selectedFlag),
                                            filled: true,
                                            fillColor: AppColors.white,
                                            labelStyle: const TextStyle(
                                                color: AppColors.textGrey),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(
                                                      8), // Rounded corners
                                              borderSide: BorderSide(
                                                color: AppColors.textGrey
                                                    .withValues(
                                                        alpha:
                                                            0.3), // Light grey color for border
                                                width: 1.0, // Border width
                                              ),
                                            ),
                                            // Border for focused state
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              borderSide: const BorderSide(
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
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: SizedBox(
                                      width: double.infinity,
                                      child: TextFormField(
                                        keyboardType: TextInputType.phone,
                                        autocorrect: false,
                                        style: const TextStyle(fontSize: 15),
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
                                            minimumHeight: 48,
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
                                  text: "Sign Up",
                                  onPressed: _signUpPressed,
                                  backgroundColor: AppColors.textBlack),
                              const SizedBox(
                                height: 36,
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text(
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
