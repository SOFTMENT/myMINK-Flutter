import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mymink/core/constants/app_routes.dart';
import 'package:mymink/core/constants/colors.dart';
import 'package:mymink/core/services/aws_uploader.dart';
import 'package:mymink/core/services/deep_link_service.dart';
import 'package:mymink/core/services/image_service.dart';
import 'package:mymink/core/services/location_service.dart';
import 'package:mymink/core/utils/common_input_decoration.dart';
import 'package:mymink/core/utils/image_picker_dialog.dart';
import 'package:mymink/core/widgets/custom_button.dart';
import 'package:mymink/core/widgets/custom_dialog.dart';
import 'package:mymink/core/widgets/dismiss_keyboard_ontap.dart';
import 'package:mymink/core/widgets/progress_hud.dart';
import 'package:mymink/features/onboarding/data/models/user_model.dart';
import 'package:mymink/features/onboarding/data/services/auth_service.dart';
import 'package:mymink/features/onboarding/data/services/user_service.dart';
import 'package:mymink/gen/assets.gen.dart';

class CompleteProfilePage extends StatefulWidget {
  const CompleteProfilePage({super.key});

  @override
  State<CompleteProfilePage> createState() {
    return _CompleteProfilePage();
  }
}

class _CompleteProfilePage extends State<CompleteProfilePage> {
  GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  TextEditingController _controller = TextEditingController();
  TextEditingController _dateController = TextEditingController();
  List<dynamic> _places = [];
  String _userName = "";
  String _website = "";
  String _bio = "";
  DateTime? _pickedDate;
  final LocationService _locationService = LocationService();
  final ImageService _imageService = ImageService();
  File? _profileImage;
  var _isLoading = false;

  @override
  void dispose() {
    _controller.dispose();
    _dateController.dispose();
    super.dispose();
  }

  void _continueBtnClicked() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      if (_profileImage == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Upload Profile Picture"),
          ),
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });
      final isUsernameAvailable =
          await UserService.isUsernameAvailable(_userName);

      if (isUsernameAvailable) {
        await CustomDialog.show(context,
            title: "Username", message: "$_userName username is not available");
        setState(() {
          _isLoading = false;
        });
      } else {
        final result = await AWSUploader.uploadFile(
            folderName: 'ProfilePictures',
            postType: PostType.image,
            previousKey: UserModel.instance.profilePic,
            photo: _profileImage,
            context: context);
        if (result.hasData) {
          final downloadURL = result.data!;
          final isExplicit = await AWSUploader.checkExplicitImage(downloadURL);
          if (isExplicit) {
            await CustomDialog.show(context,
                title: 'EXPLICIT CONTENT',
                message:
                    "We don't allow explicit content. Please upload a different image.");

            setState(() {
              _isLoading = false;
              _profileImage = null;
            });
          } else {
            UserModel userModel = UserModel.instance;
            userModel.biography = _bio;
            userModel.website = _website;
            userModel.location = _controller.text;
            userModel.dob = _pickedDate;
            userModel.username = _userName;
            userModel.profilePic = downloadURL;

            final result =
                await DeepLinkService.createDeepLinkForUserProfile(userModel);
            userModel.profileURL = result.data ?? null;

            final result2 = await UserService.updateUser(userModel);
            if (result2.hasError) {
              await CustomDialog.show(context,
                  title: "ERROR", message: result2.error!);
            } else {
              context.go(AppRoutes.tabbar);
            }
            setState(() {
              _isLoading = false;
            });
          }
        } else {
          CustomDialog.show(context, title: "ERROR", message: result.error!);
        }
      }
    }
  }

  void _fetchSuggestions(String query) async {
    try {
      final suggestions = await _locationService.fetchSuggestions(query);
      setState(() {
        _places = suggestions;
      });
    } catch (e) {
      print('Error fetching suggestions: $e');
    }
  }

  // Handle selection of a suggestion
  void _selectPlace(String description) {
    setState(() {
      _places = [];
      _controller.text = description;
    });
  }

  void _uploadImage() async {
    String? source = await ImagePickerDialog.show(context);
    if (source != null) {
      File? image = await _imageService.pickImage(context, source);
      if (image != null) {
        setState(() {
          _profileImage = image;
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
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const SizedBox(
                        height: 420,
                        width: double.infinity,
                      ),
                      Assets.images.colorfuldesign.image(
                        height: 260,
                        width: double.infinity,
                        fit: BoxFit.fill,
                      ),
                      Positioned(
                        top: 180, // Adjust vertical positioning
                        left: 0,
                        right: 0,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 25.0),
                          child: Stack(
                            children: [
                              GestureDetector(
                                onTap: () {
                                  AuthService.logout(context);
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: [
                                      BoxShadow(
                                        color:
                                            Colors.grey.withValues(alpha: 0.3),
                                        spreadRadius: 1,
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.arrow_back_outlined,
                                    color: Colors.black,
                                    size: 18,
                                  ),
                                ),
                              ),
                              Center(
                                child: Column(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: _profileImage == null
                                          ? Assets.images.mPlaceholder.image(
                                              width: 140,
                                              height: 140,
                                            )
                                          : Image(
                                              image: FileImage(_profileImage!),
                                              width: 140,
                                              height: 140,
                                            ),
                                    ),
                                    const SizedBox(height: 6),
                                    const Text(
                                      "Upload your picture",
                                      style: TextStyle(
                                        fontSize: 15,
                                        color: AppColors.textBlack,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    SizedBox(
                                      width: 70,
                                      height: 32,
                                      child: CustomButton(
                                        text: "Upload",
                                        onPressed: _uploadImage,
                                        fontSize: 12,
                                        backgroundColor: AppColors.primaryRed,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  Form(
                    key: _formKey,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 25),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: double.infinity,
                            child: TextFormField(
                              keyboardType: TextInputType.name,
                              autocorrect: false,
                              maxLength: 20,
                              onSaved: (newValue) {
                                _userName = newValue!;
                              },
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return "Enter username";
                                }
                                return null;
                              },
                              decoration: buildInputDecoration(
                                  labelText: "Username *",
                                  prefixIcon: Icons.alternate_email_outlined),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: TextFormField(
                              keyboardType: TextInputType.datetime,
                              autocorrect: false,
                              controller: _dateController,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return "Select date of birth";
                                }
                                return null;
                              },
                              readOnly:
                                  true, // Make the TextFormField readonly to prevent manual input
                              onTap: () async {
                                DateTime? pickedDate = await showDatePicker(
                                  context: context,
                                  initialDate: DateTime(1990),
                                  firstDate: DateTime(1900),
                                  lastDate: DateTime(DateTime.now().year - 17),
                                );

                                if (pickedDate != null) {
                                  // Format the date to "23 January 2024"
                                  String formattedDate =
                                      DateFormat('d MMMM yyyy')
                                          .format(pickedDate);
                                  setState(() {
                                    _pickedDate = pickedDate;
                                    _dateController.text = formattedDate;
                                  });
                                }
                              },
                              decoration: buildInputDecoration(
                                  labelText: "Date of Birth *",
                                  prefixIcon: Icons.calendar_month_outlined),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: TextFormField(
                              controller: _controller,
                              maxLines: 1,
                              keyboardType: TextInputType.streetAddress,
                              autocorrect: false,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return "Enter Location";
                                }
                                return null;
                              },
                              onChanged: (value) {
                                _fetchSuggestions(value);
                              },
                              decoration: buildInputDecoration(
                                  labelText: "Location *",
                                  prefixIcon: Icons.location_on_outlined),
                            ),
                          ),

                          // ListView to show suggestions
                          if (_places.isNotEmpty)
                            ListView.builder(
                              padding: const EdgeInsets.all(0),
                              itemCount: _places.length,
                              shrinkWrap:
                                  true, // Ensures ListView takes up only the space it needs

                              itemBuilder: (context, index) {
                                return ListTile(
                                  contentPadding:
                                      const EdgeInsets.symmetric(horizontal: 0),
                                  leading: const Icon(Icons.place_outlined),
                                  title: Text(
                                    _places[index]['description'],
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  onTap: () {
                                    _selectPlace(_places[index]['description']);
                                  },
                                );
                              },
                            ),
                          const SizedBox(
                            height: 12,
                          ),

                          SizedBox(
                            width: double.infinity,
                            child: TextFormField(
                              keyboardType: TextInputType.url,
                              autocorrect: false,
                              textInputAction: TextInputAction.done,
                              onSaved: (newValue) {
                                _website = newValue ?? '';
                              },
                              decoration: buildInputDecoration(
                                  labelText: "Website",
                                  prefixIcon: Icons.public_outlined),
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            "Biography",
                            textAlign: TextAlign.left,
                            style: TextStyle(
                                color: Colors.black,
                                fontSize: 14,
                                fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 180,
                            width: double.infinity,
                            child: TextFormField(
                              textCapitalization: TextCapitalization.sentences,
                              keyboardType: TextInputType.multiline,
                              autocorrect: false,
                              maxLines: 7,
                              minLines: 7,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return "Enter Bio";
                                }
                                return null;
                              },
                              onSaved: (newValue) {
                                _bio = newValue!;
                              },
                              decoration: buildInputDecoration(
                                  labelText: "", prefixIcon: null),
                            ),
                          ),
                          const SizedBox(
                            height: 32,
                          ),
                          CustomButton(
                              text: "Continue",
                              onPressed: _continueBtnClicked,
                              backgroundColor: AppColors.textBlack),
                          const SizedBox(
                            height: 32,
                          ),
                        ],
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
          if (_isLoading)
            Center(
              child: ProgressHud(),
            ),
        ],
      ),
    );
  }
}
