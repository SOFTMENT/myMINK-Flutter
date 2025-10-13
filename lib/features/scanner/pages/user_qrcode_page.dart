import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:mymink/core/constants/collections.dart';

import 'package:mymink/core/constants/colors.dart';
import 'package:mymink/core/services/deep_link_service.dart';
import 'package:mymink/core/widgets/custom_app_bar.dart';
import 'package:mymink/core/widgets/custom_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mymink/features/onboarding/data/models/user_model.dart';
import 'package:mymink/core/utils/common_utils.dart';

import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

class UserQrcodePage extends StatefulWidget {
  const UserQrcodePage({Key? key}) : super(key: key);

  @override
  State<UserQrcodePage> createState() => _UserQrcodePageState();
}

class _UserQrcodePageState extends State<UserQrcodePage> {
  final _userModel = UserModel.instance;
  String? _profileLink;
  bool _isLoading = true;

  final GlobalKey _qrKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _prepareProfileLink();
  }

  Future<void> _prepareProfileLink() async {
    final uid = _userModel.uid;
    if (uid == null) {
      setState(() => _isLoading = false);
      return;
    }

    // 1) Already cached?
    if ((_userModel.profileURL ?? '').isNotEmpty) {
      _profileLink = _userModel.profileURL;
      setState(() => _isLoading = false);
      return;
    }

    final doc = await FirebaseFirestore.instance
        .collection(Collections.users)
        .doc(uid)
        .get();
    if (doc.exists) {
      final url = doc.data()?['profileURL'] as String?;
      if (url != null && url.isNotEmpty) {
        _profileLink = url;
        _userModel.profileURL = url;
        setState(() => _isLoading = false);
        return;
      }
    }

    // 3) Create a new deep link
    final newLink =
        await DeepLinkService.createDeepLinkForUserProfile(_userModel);
    if (newLink.hasData) {
      _profileLink = newLink.data;
      _userModel.profileURL = newLink.data;
      FirebaseFirestore.instance
          .collection(Collections.users)
          .doc(uid)
          .set({'profileURL': newLink.data}, SetOptions(merge: true));
    } else {
      print(newLink.error);
    }

    setState(() => _isLoading = false);
  }

  Future<void> _copyLink() async {
    if (_profileLink == null) return;
    CommonUtils.copyToClipboard(context, _profileLink!, '');
  }

  Future<void> _shareProfileQRCode() async {
    try {
      final boundary =
          _qrKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final bytes = (await image.toByteData(format: ImageByteFormat.png))!
          .buffer
          .asUint8List();
      await Share.shareXFiles(
        [XFile.fromData(bytes, name: 'profile_qr.png', mimeType: 'image/png')],
        text: 'Here is my profile QR code',
      );
    } catch (e) {
      print('Error sharing QR code: $e');
    }
  }

  void _scanQr() {
    Navigator.of(context).pushNamed('/scan_qr_page');
  }

  @override
  Widget build(BuildContext context) {
    final user = _userModel;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          CustomAppBar(title: 'Share Profile'),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: CustomImage(
              imageKey: user.profilePic,
              width: 120,
              height: 120,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            user.fullName ?? 'No Name',
            style: const TextStyle(
              fontSize: 18,
              color: AppColors.textBlack,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          RepaintBoundary(
            key: _qrKey,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 50),
              child: AspectRatio(
                aspectRatio: 1, // force height == width
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(child: _buildQrContents()),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 50),
            child: Text(
              'This is your unique QR Code for another person to scan',
              style: TextStyle(
                color: AppColors.textDarkGrey,
                fontSize: 13,
              ),
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.only(bottom: 32, left: 25, right: 25),
            child: SizedBox(
              width: double.infinity,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: _isLoading ? null : _shareProfileQRCode,
                          child: Container(
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                color:
                                    const Color.fromARGB(255, 231, 231, 231)),
                            height: 46,
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.ios_share_outlined,
                                  color: AppColors.textBlack,
                                  size: 18,
                                ),
                                SizedBox(
                                  width: 4,
                                ),
                                const Text(
                                  'Share Profile',
                                  style: TextStyle(
                                      color: AppColors.textBlack, fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(
                        width: 10,
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: _isLoading ? null : _copyLink,
                          child: Container(
                            height: 46,
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                color:
                                    const Color.fromARGB(255, 231, 231, 231)),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.content_copy_outlined,
                                  color: AppColors.textBlack,
                                  size: 18,
                                ),
                                SizedBox(
                                  width: 4,
                                ),
                                const Text(
                                  'Copy Link',
                                  style: TextStyle(
                                      color: AppColors.textBlack, fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  GestureDetector(
                    onTap: _isLoading ? null : _scanQr,
                    child: Container(
                      height: 46,
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: AppColors.textBlack),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.qr_code_scanner_outlined,
                            color: AppColors.white,
                            size: 18,
                          ),
                          SizedBox(
                            width: 8,
                          ),
                          const Text(
                            'Scan QR',
                            style:
                                TextStyle(color: AppColors.white, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // This method MUST return a Widget. QrImage extends StatelessWidget, so it is allowed
  Widget _buildQrContents() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_profileLink == null) {
      return const Center(
        child: Text(
          'Unable to generate QR',
          style: TextStyle(color: Colors.red),
        ),
      );
    }

    return QrImageView(
      data: _profileLink!,
      size: double.infinity,
      backgroundColor: Colors.white,
      embeddedImage: const AssetImage('assets/images/roundicon-2.png'),
      embeddedImageStyle: const QrEmbeddedImageStyle(
        size: const Size(70, 70), // adjust to whatever fits your design
      ),
    );
  }
}
