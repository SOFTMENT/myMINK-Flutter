import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:mymink/core/constants/collections.dart';
import 'package:mymink/core/constants/colors.dart';
import 'package:mymink/core/services/aws_uploader.dart';
import 'package:mymink/core/services/deep_link_service.dart';
import 'package:mymink/core/services/firebase_service.dart';
import 'package:mymink/core/services/image_service.dart';
import 'package:mymink/core/utils/image_picker_dialog.dart';

import 'package:mymink/core/widgets/custom_button.dart';
import 'package:mymink/core/utils/common_input_decoration.dart';
import 'package:mymink/core/widgets/custom_dialog.dart';
import 'package:mymink/core/widgets/custom_image.dart';
import 'package:mymink/core/widgets/dismiss_keyboard_ontap.dart';
import 'package:mymink/core/widgets/progress_hud.dart';
import 'package:mymink/features/business/data/models/business_model.dart';
import 'package:mymink/features/business/data/services/business_service.dart';
import 'package:mymink/features/onboarding/data/models/user_model.dart';
import 'package:mymink/gen/assets.gen.dart';

class AddBusinessProfilePage extends StatefulWidget {
  /// If null → Add mode; otherwise → Update mode
  final BusinessModel? businessModel;

  /// Called after successful add/update
  final VoidCallback? businessAdded;
  final void Function(BusinessModel)? businessEdit;

  const AddBusinessProfilePage({
    Key? key,
    this.businessModel,
    this.businessAdded = null,
    this.businessEdit = null,
  }) : super(key: key);

  @override
  State<AddBusinessProfilePage> createState() => _AddBusinessProfilePageState();
}

class _AddBusinessProfilePageState extends State<AddBusinessProfilePage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _websiteController;
  late TextEditingController _descriptionController;
  String? _selectedBusinessType;

  final ImageService _imageService = ImageService();
  File? _profileImage;
  File? _coverImage;

  bool _isLoading = false;
  String? _loadingMessage;

  final List<String> businessTypes = [
    "Agriculture and Mining",
    "Arts and Entertainment",
    "Automotive",
    "Beauty and Cosmetics",
    "Biotechnology",
    "Construction",
    "Consulting",
    "Education",
    "Education and Training",
    "Electronics",
    "Energy",
    "Environmental Services",
    "Fashion and Apparel",
    "Finance and Insurance",
    "Food and Beverage",
    "Health and Wellness",
    "Healthcare",
    "Hospitality and Tourism",
    "Information Technology",
    "Legal Services",
    "Logistics",
    "Manufacturing",
    "Marketing and Advertising",
    "Media",
    "Non-Profit",
    "Personal Services",
    "Pharmaceuticals",
    "Professional Services",
    "Publishing",
    "Public Sector",
    "Real Estate",
    "Recreation and Leisure",
    "Retail",
    "Scientific Services",
    "Security Services",
    "Software Development",
    "Technical Services",
    "Telecommunications",
    "Transportation and Warehousing",
    "Utilities",
    "Wholesale Trade"
  ];

  @override
  void initState() {
    super.initState();

    // Initialize controllers—and if editing, preload values:
    _nameController =
        TextEditingController(text: widget.businessModel?.name ?? '');
    _websiteController =
        TextEditingController(text: widget.businessModel?.website ?? '');
    _descriptionController =
        TextEditingController(text: widget.businessModel?.aboutBusiness ?? '');
    _selectedBusinessType = widget.businessModel?.businessCategory;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _websiteController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _uploadImage(String imageType) async {
    final source = await ImagePickerDialog.show(context);
    if (source == null) return;

    final picked = await _imageService.pickImage(
      context,
      source,
      ratioX: imageType == 'cover' ? 8 : 1,
      ratioY: imageType == 'cover' ? 5 : 1,
    );
    if (picked == null) return;

    setState(() {
      if (imageType == 'cover') {
        _coverImage = picked;
      } else {
        _profileImage = picked;
      }
    });
  }

  Future<void> _saveBtnClicked() async {
    if (!_formKey.currentState!.validate()) return;
    if (widget.businessModel == null && _coverImage == null) {
      // In Add mode, both images are required
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Upload Cover Picture")),
      );
      return;
    }
    if (widget.businessModel == null && _profileImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Upload Profile Picture")),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _loadingMessage = 'Uploading images…';
    });

    // 1) Upload only new images; else reuse existing URLs
    String profileLink = widget.businessModel?.profilePicture ?? '';
    String coverLink = widget.businessModel?.coverPicture ?? '';

    if (_profileImage != null) {
      final res = await AWSUploader.uploadFile(
        folderName: 'BusinessProfilePictures',
        postType: PostType.image,
        photo: _profileImage!,
        context: context,
      );
      if (res.hasData) profileLink = res.data!;
    }
    if (_coverImage != null) {
      final res = await AWSUploader.uploadFile(
        folderName: 'BusinessCoverPictures',
        postType: PostType.image,
        photo: _coverImage!,
        context: context,
      );
      if (res.hasData) coverLink = res.data!;
    }

    setState(() {
      _loadingMessage = null;
    });

    // 2) Build the BusinessModel instance
    final now = DateTime.now();
    final currentUser = FirebaseService().auth.currentUser!;
    final bool isNew = widget.businessModel == null;
    final String docId = isNew
        ? FirebaseService().db.collection(Collections.businesses).doc().id
        : widget.businessModel!.businessId!;

    BusinessModel business = BusinessModel(
      businessId: docId,
      createdAt: widget.businessModel?.createdAt ?? now,
      isActive: widget.businessModel?.isActive ?? true,
      name: _nameController.text.trim(),
      website: _websiteController.text.trim(),
      aboutBusiness: _descriptionController.text.trim(),
      businessCategory: _selectedBusinessType!,
      profilePicture: profileLink,
      coverPicture: coverLink,
      uid: widget.businessModel?.uid ?? currentUser.uid,
      notificationToken: widget.businessModel?.notificationToken ??
          UserModel.instance.notificationToken,
      shareLink: widget.businessModel?.shareLink ?? '',
    );

    // 3) If new, maybe generate a deep link:
    if (isNew) {
      final dl = await DeepLinkService.createDeepLinkForBusiness(business);
      if (dl.hasData) business.shareLink = dl.data!;
    }

    try {
      final ref =
          FirebaseService().db.collection(Collections.businesses).doc(docId);
      if (isNew) {
        await ref.set({
          ...business.toMap(),
          ...BusinessService.buildSearchFields(business.name ?? ''),
        }, SetOptions(merge: true));
      } else {
        await ref.update({
          ...business.toMap(),
          ...BusinessService.buildSearchFields(business.name ?? ''),
        });
      }

      widget.businessAdded != null
          ? widget.businessAdded!()
          : widget.businessEdit!(business);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isNew ? 'Business Added' : 'Business Updated',
          ),
          duration: const Duration(milliseconds: 1500),
        ),
      );

      // Give the user a moment to read the SnackBar, then pop:
      Future.delayed(const Duration(milliseconds: 1500), () {
        Navigator.of(context).pop();
      });
    } catch (err) {
      setState(() => _isLoading = false);
      CustomDialog.show(
        context,
        title: 'ERROR',
        message: err.toString(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isNew = widget.businessModel == null;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Stack(
          children: [
            DismissKeyboardOnTap(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: Column(
                  children: [
                    // ****** Cover & Profile Section ******
                    SizedBox(
                      height: 360,
                      child: Stack(
                        alignment: Alignment.center,
                        clipBehavior: Clip.none,
                        children: [
                          // Cover Image
                          Positioned(
                            top: 0,
                            left: 0,
                            right: 0,
                            child: _coverImage != null
                                ? Image(
                                    image: FileImage(_coverImage!),
                                    width: double.infinity,
                                    height: 220,
                                    fit: BoxFit.cover,
                                  )
                                : (widget.businessModel?.coverPicture
                                            ?.isNotEmpty ??
                                        false)
                                    ? SizedBox(
                                        width: double.infinity,
                                        height: 220,
                                        child: CustomImage(
                                          imageKey: widget
                                              .businessModel!.coverPicture,
                                          width: 300,
                                          height: 300,
                                          boxFit: BoxFit.cover,
                                        ),
                                      )
                                    : Assets.images
                                        .greyAndWhiteMinimalistTwitterHeader
                                        .image(
                                        width: double.infinity,
                                        height: 220,
                                        fit: BoxFit.cover,
                                      ),
                          ),
                          // Change Cover Button
                          Positioned(
                            top: 60,
                            right: 25,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(100),
                              onTap: () => _uploadImage('cover'),
                              child: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: AppColors.white,
                                  borderRadius: BorderRadius.circular(100),
                                ),
                                child: const Center(
                                  child: Icon(
                                    Symbols.camera_alt,
                                    fill: 1,
                                    size: 20,
                                    color: AppColors.textGrey,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // Back Button
                          Positioned(
                            top: 240,
                            left: 25,
                            child: GestureDetector(
                              onTap: () => context.pop(),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey.withAlpha(80),
                                      spreadRadius: 1,
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.arrow_back_outlined,
                                  size: 18,
                                ),
                              ),
                            ),
                          ),
                          // Profile Image + Upload
                          Positioned(
                            top: 160,
                            child: Column(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(1000),
                                  child: _profileImage != null
                                      ? Image(
                                          image: FileImage(_profileImage!),
                                          width: 120,
                                          height: 120,
                                        )
                                      : (widget.businessModel?.profilePicture
                                                  ?.isNotEmpty ??
                                              false)
                                          ? CustomImage(
                                              imageKey: widget.businessModel!
                                                  .profilePicture,
                                              width: 120,
                                              height: 120)
                                          : Assets.images.mPlaceholder.image(
                                              width: 120,
                                              height: 120,
                                            ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  "Upload business picture",
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textBlack,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                SizedBox(
                                  height: 30,
                                  width: 56,
                                  child: CustomButton(
                                    text: 'Upload',
                                    onPressed: () => _uploadImage('profile'),
                                    fontSize: 10,
                                    backgroundColor: AppColors.primaryRed,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ****** Form Section ******
                    Form(
                      key: _formKey,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 25),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _nameController,
                              decoration: buildInputDecoration(
                                labelText: "Business Name",
                                prefixIcon: null,
                              ),
                              validator: (v) => v == null || v.isEmpty
                                  ? "Please enter business name"
                                  : null,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _websiteController,
                              decoration: buildInputDecoration(
                                labelText: "Website URL",
                                prefixIcon: null,
                              ),
                              validator: (v) => v == null || v.isEmpty
                                  ? "Please enter website"
                                  : null,
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<String>(
                              decoration: buildInputDecoration(
                                labelText: "Business Type",
                                prefixIcon: null,
                              ),
                              value: _selectedBusinessType,
                              items: businessTypes
                                  .map((t) => DropdownMenuItem(
                                        value: t,
                                        child: Text(t),
                                      ))
                                  .toList(),
                              onChanged: (v) =>
                                  setState(() => _selectedBusinessType = v),
                              validator: (v) =>
                                  v == null ? "Select a business type" : null,
                            ),
                            const SizedBox(height: 16),
                            const Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                "Description",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 3),
                            const Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Add more details about your business',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textDarkGrey,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _descriptionController,
                              maxLines: 5,
                              decoration: buildInputDecoration(
                                labelText: '',
                                prefixIcon: null,
                              ),
                              validator: (v) => v == null || v.isEmpty
                                  ? "Please enter a description"
                                  : null,
                            ),
                            const SizedBox(height: 24),

                            // ****** Save Button ******
                            CustomButton(
                              text: isNew ? 'Add' : 'Update',
                              onPressed: _saveBtnClicked,
                              backgroundColor: AppColors.textBlack,
                            ),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ****** Loading HUD ******
            if (_isLoading)
              Center(
                child: ProgressHud(
                  message: _loadingMessage,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
