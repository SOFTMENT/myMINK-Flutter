import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:mymink/core/constants/colors.dart';
import 'package:mymink/core/utils/date_formatter.dart';
import 'package:mymink/core/widgets/custom_image.dart';
import 'package:mymink/features/onboarding/data/models/user_model.dart';
import 'package:mymink/gen/assets.gen.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

class HoroscopeViewPage extends StatelessWidget {
  final String horoscope;
  final String result;

  HoroscopeViewPage({super.key, required this.horoscope, required this.result});

  final GlobalKey _containerKey = GlobalKey();

  Future<void> _shareContainerImage() async {
    try {
      RenderRepaintBoundary boundary = _containerKey.currentContext!
          .findRenderObject() as RenderRepaintBoundary;
      var image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      final directory = await getTemporaryDirectory();
      final imagePath =
          await File('${directory.path}/horoscope_share.png').create();
      await imagePath.writeAsBytes(pngBytes);

      await Share.shareXFiles([XFile(imagePath.path)],
          text: 'Check out my daily horoscope!');
    } catch (e) {
      print("Error sharing image: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Top background image
          Assets.images.colorfuldesign.image(
            height: 250,
            width: double.infinity,
            fit: BoxFit.fill,
          ),

          // Centered content box
          Align(
            alignment: Alignment.center,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 25),
              child: Column(
                children: [
                  Row(
                    children: [
                      GestureDetector(
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
                            color: Colors.black,
                            size: 18,
                          ),
                        ),
                      ),
                      const Expanded(
                        child: Center(
                          child: Text(
                            'Today\'s Horoscope',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textBlack,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 44),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Shareable container
                  RepaintBoundary(
                    key: _containerKey,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: AppColors.white,
                      ),
                      width: double.infinity,
                      child: Padding(
                        padding: const EdgeInsets.only(
                            top: 16, bottom: 20, right: 20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Assets.images.logo.image(height: 60, width: 60),
                                const SizedBox(
                                  width: 10,
                                ),
                                Column(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: CustomImage(
                                        imageKey:
                                            UserModel.instance.profilePic ?? '',
                                        width: 120,
                                        height: 120,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      UserModel.instance.fullName ?? '',
                                      style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.textBlack),
                                    ),
                                    Text(
                                      horoscope.toUpperCase(),
                                      style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.primaryRed),
                                    ),
                                  ],
                                ),
                                const SizedBox(
                                  width: 10,
                                ),
                                GestureDetector(
                                  onTap: _shareContainerImage,
                                  behavior: HitTestBehavior.opaque,
                                  child: const Icon(
                                    Symbols.ios_share,
                                    color: AppColors.textGrey,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              result,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.textDarkGrey,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                const Spacer(),
                                const Icon(Symbols.calendar_month, size: 18),
                                const SizedBox(width: 5),
                                Text(
                                  DateFormatter.formatDate(
                                      DateTime.now(), 'dd MMM yyyy'),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textDarkGrey,
                                  ),
                                )
                              ],
                            )
                          ],
                        ),
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
}
