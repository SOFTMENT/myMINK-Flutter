import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:mymink/core/constants/colors.dart';
import 'package:mymink/core/services/aws_uploader.dart';
import 'package:mymink/core/services/encryption_service.dart';
import 'package:mymink/core/services/firebase_service.dart';
import 'package:mymink/core/services/image_service.dart';
import 'package:mymink/core/services/location_service.dart';
import 'package:mymink/core/utils/common_input_decoration.dart';
import 'package:mymink/core/utils/image_picker_dialog.dart';
import 'package:mymink/core/widgets/custom_button.dart';
import 'package:mymink/core/widgets/custom_dialog.dart';
import 'package:mymink/core/widgets/custom_image.dart';
import 'package:mymink/core/widgets/dismiss_keyboard_ontap.dart';
import 'package:mymink/core/widgets/progress_hud.dart';
import 'package:mymink/features/onboarding/data/models/user_model.dart';

import 'package:mymink/features/onboarding/data/services/user_service.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() {
    return _EditProfilePage();
  }
}

class _EditProfilePage extends State<EditProfilePage> {
  UserModel _userModel = UserModel.instance;
  GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  GlobalKey<FormState> _formKeyPassword = GlobalKey<FormState>();
  TextEditingController _controller = TextEditingController();
  TextEditingController _dateController = TextEditingController();
  List<dynamic> _places = [];
  String _fullName = "";
  String _website = "";
  String _bio = "";
  final LocationService _locationService = LocationService();
  final ImageService _imageService = ImageService();
  File? _profileImage;
  var _isLoading = false;

  bool _obscureTextCurrent = true;
  String passwordCurrent = "";

  bool _obscureTextNew = true;
  String passwordNew = "";

  bool _obscureTextAgain = true;
  String passwordAgain = "";

  @override
  void initState() {
    super.initState();
    _controller.text = _userModel.location ?? '';
  }

  @override
  void dispose() {
    _controller.dispose();
    _dateController.dispose();
    super.dispose();
  }

  void _continueBtnClicked() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      UserModel userModel = UserModel.instance;

      setState(() {
        _isLoading = true;
      });

      if (_profileImage != null) {
        final downloadURL = await _uploadProfilePicture();
        userModel.profilePic = downloadURL;
      }

      userModel.biography = _bio;
      userModel.website = _website;
      userModel.location = _controller.text;
      userModel.fullName = _fullName;

      final result2 = await UserService.updateUser(userModel);
      if (result2.hasError) {
        await CustomDialog.show(context,
            title: "ERROR", message: result2.error!);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile Updated'),
          ),
        );
        Navigator.pop(context, true);
      }

      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<String?> _uploadProfilePicture() async {
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
        return null;
      } else {
        return downloadURL;
      }
    } else {
      await CustomDialog.show(context, title: "ERROR", message: result.error!);
      return null;
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

  Future<void> _changePasswordBtnClicked() async {
    // Validate and save form state
    if (_formKeyPassword.currentState!.validate()) {
      _formKeyPassword.currentState!.save();

      // Check if the new password and confirmation match
      if (passwordNew != passwordAgain) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("New passwords do not match")),
        );
        return;
      }

      try {
        setState(() {
          _isLoading = true;
        });
        // Get the current user
        User? user = FirebaseService().auth.currentUser;
        if (user != null && user.email != null) {
          // Re-authenticate the user with the current password
          AuthCredential credential = EmailAuthProvider.credential(
            email: user.email!,
            password: passwordCurrent,
          );
          await user.reauthenticateWithCredential(credential);

          // Update the password to the new one
          await user.updatePassword(passwordNew);

          String encryptPassword = EncryptionService()
              .encryptMessage(passwordNew, _userModel.encryptKey!);

          _userModel.encryptPassword = encryptPassword;
          UserService.updateUser(_userModel);

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Password updated successfully")),
          );

          setState(() {
            _isLoading = false;
          });
        }
      } on FirebaseAuthException catch (e) {
        await CustomDialog.show(context, title: 'ERROR', message: e.toString());
        setState(() {
          _isLoading = false;
        });
      } catch (e) {
        // Handle other errors
        await CustomDialog.show(context, title: 'ERROR', message: e.toString());
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
      body: SafeArea(
        child: Stack(
          children: [
            DismissKeyboardOnTap(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 25.0),
                      child: Stack(
                        children: [
                          GestureDetector(
                            onTap: () {
                              context.pop();
                            },
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withValues(alpha: 0.3),
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
                                    child: SizedBox(
                                      height: 140,
                                      width: 140,
                                      child: _profileImage == null
                                          ? CustomImage(
                                              imageKey: _userModel.profilePic,
                                              width: 140,
                                              height: 140)
                                          : Image.file(_profileImage!),
                                    )),
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
                    const SizedBox(
                      height: 20,
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
                                initialValue: _userModel.fullName ?? '',
                                textCapitalization: TextCapitalization.words,
                                keyboardType: TextInputType.name,
                                autocorrect: false,
                                onSaved: (newValue) {
                                  _fullName = newValue!;
                                },
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return "Enter Full Name";
                                  }
                                  return null;
                                },
                                decoration: buildInputDecoration(
                                    labelText: 'Full Name *',
                                    prefixIcon: Icons.person_outline_outlined),
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
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 0),
                                    leading: const Icon(Icons.place_outlined),
                                    title: Text(
                                      _places[index]['description'],
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    onTap: () {
                                      _selectPlace(
                                          _places[index]['description']);
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
                                initialValue: _userModel.website ?? '',
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
                                initialValue: _userModel.biography ?? '',
                                textCapitalization:
                                    TextCapitalization.sentences,
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
                                text: "Update",
                                onPressed: _continueBtnClicked,
                                backgroundColor: AppColors.textBlack),
                            const SizedBox(
                              height: 24,
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_userModel.regiType == 'custom')
                      Form(
                        key: _formKeyPassword,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Change Password",
                              textAlign: TextAlign.left,
                              style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: TextFormField(
                                keyboardType: TextInputType.visiblePassword,
                                obscureText: _obscureTextCurrent,
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
                                  passwordCurrent = newValue!;
                                },
                                decoration: buildInputDecoration(
                                    suffixIcon: Icon(
                                      _obscureTextCurrent
                                          ? Icons
                                              .visibility_off // Show eye-off when password is hidden
                                          : Icons
                                              .visibility, // Show eye when password is visible
                                      color: Colors.grey,
                                    ),
                                    suffixIconPressed: () {
                                      setState(() {
                                        _obscureTextCurrent =
                                            !_obscureTextCurrent;
                                      });
                                    },
                                    labelText: "Password",
                                    prefixIcon: Icons.lock_outline),
                              ),
                            ),
                            const SizedBox(
                              height: 8,
                            ),
                            SizedBox(
                              width: double.infinity,
                              child: TextFormField(
                                keyboardType: TextInputType.visiblePassword,
                                obscureText: _obscureTextNew,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Enter New Password';
                                  }
                                  if (value.length < 6) {
                                    return "New Password must be at least 6 characters long.";
                                  }

                                  return null;
                                },
                                onSaved: (newValue) {
                                  passwordNew = newValue!;
                                },
                                decoration: buildInputDecoration(
                                    suffixIcon: Icon(
                                      _obscureTextNew
                                          ? Icons
                                              .visibility_off // Show eye-off when password is hidden
                                          : Icons
                                              .visibility, // Show eye when password is visible
                                      color: Colors.grey,
                                    ),
                                    suffixIconPressed: () {
                                      setState(() {
                                        _obscureTextNew = !_obscureTextNew;
                                      });
                                    },
                                    labelText: "New Password",
                                    prefixIcon: Icons.lock_outline),
                              ),
                            ),
                            const SizedBox(
                              height: 8,
                            ),
                            SizedBox(
                              width: double.infinity,
                              child: TextFormField(
                                keyboardType: TextInputType.visiblePassword,
                                obscureText: _obscureTextAgain,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Enter Confirm New Password';
                                  }
                                  if (value.length < 6) {
                                    return "Confirm New Password must be at least 6 characters long.";
                                  }

                                  return null;
                                },
                                onSaved: (newValue) {
                                  passwordAgain = newValue!;
                                },
                                decoration: buildInputDecoration(
                                    suffixIcon: Icon(
                                      _obscureTextAgain
                                          ? Icons
                                              .visibility_off // Show eye-off when password is hidden
                                          : Icons
                                              .visibility, // Show eye when password is visible
                                      color: Colors.grey,
                                    ),
                                    suffixIconPressed: () {
                                      setState(() {
                                        _obscureTextAgain = !_obscureTextAgain;
                                      });
                                    },
                                    labelText: "Confirm New Password",
                                    prefixIcon: Icons.lock_outline),
                              ),
                            ),
                            const SizedBox(
                              height: 32,
                            ),
                            CustomButton(
                                text: "Change Password",
                                onPressed: _changePasswordBtnClicked,
                                backgroundColor: AppColors.textBlack),
                            const SizedBox(
                              height: 32,
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
                child: ProgressHud(),
              ),
          ],
        ),
      ),
    );
  }
}
