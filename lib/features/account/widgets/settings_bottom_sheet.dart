import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:in_app_review/in_app_review.dart';

import 'package:material_symbols_icons/symbols.dart';
import 'package:mymink/core/constants/app_routes.dart';
import 'package:mymink/core/constants/colors.dart';
import 'package:mymink/core/utils/url_utils.dart';
import 'package:mymink/core/widgets/custom_image.dart';
import 'package:mymink/features/onboarding/data/models/user_model.dart';
import 'package:mymink/features/onboarding/data/services/auth_service.dart';
import 'package:mymink/gen/assets.gen.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// Shares the app link with a message.
Future<void> _rateApp() async {
  final InAppReview inAppReview = InAppReview.instance;
  // Check if the in-app review API is available
  if (await inAppReview.isAvailable()) {
    // Request the in-app review (this uses SKStoreReviewController on iOS when available)
    await inAppReview.requestReview();
  } else {
    // Fallback: open the App Store page using your iOS App ID
    final Uri appStoreUri =
        Uri.parse("itms-apps://itunes.apple.com/app/6448769013");
    if (await canLaunchUrl(appStoreUri)) {
      await launchUrl(appStoreUri);
    }
  }
}

// Function to share the app's link
void _shareApp(BuildContext context) {
  final box = context.findRenderObject() as RenderBox?;
  final shareMessage = "Check out this amazing app:\n\n"
      "Android: https://play.google.com/store/apps/details?id=com.softment.mymink\n"
      "iOS: https://apps.apple.com/app/id6448769013";

  Share.share(
    shareMessage,
    subject: 'my MINK',
    sharePositionOrigin: box!.localToGlobal(Offset.zero) & box.size,
  );
}

void showSettingsBottomSheet(
    BuildContext context, void Function() refreshProfile) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true, // Allows the sheet to expand if needed
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (BuildContext context) {
      final mediaQuery = MediaQuery.of(context);
      return ConstrainedBox(
        constraints: BoxConstraints(
          // The bottom sheet can be at most the full height of the screen.
          maxHeight: mediaQuery.size.height,
        ),
        child: SingleChildScrollView(
          // Add padding to account for keyboard if needed.
          padding: EdgeInsets.only(bottom: mediaQuery.viewInsets.bottom),
          child: IntrinsicHeight(
            // IntrinsicHeight makes the Column size itself to its content.
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeaderSection(),
                const Padding(
                  padding:
                      EdgeInsets.only(right: 16, left: 16, top: 10, bottom: 6),
                  child: Text(
                    "Settings",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                _buildListTile(
                  title: "Edit Profile",
                  onTap: () async {
                    Navigator.of(context).pop();
                    // Navigate to edit profile screen.
                    final result =
                        await context.push(AppRoutes.editProfilePage);

                    if (result == true) {
                      refreshProfile();
                    }
                  },
                ),
                _buildListTile(
                  title: "Saved Posts",
                  onTap: () {
                    Navigator.of(context).pop();
                    // Navigate to saved posts.
                    context.push(AppRoutes.savedPostPage);
                  },
                ),
                _buildListTile(
                  title: "Share App",
                  onTap: () {
                    Navigator.of(context).pop();
                    _shareApp(context);
                  },
                ),
                _buildListTile(
                  title: "Rate App",
                  onTap: () {
                    Navigator.of(context).pop();
                    _rateApp();
                  },
                ),
                _buildListTile(
                  title: "Contact Us",
                  onTap: () {
                    Navigator.of(context).pop();
                    UrlUtils.openURL(
                        "https://mymink.com.au/contact-us", context);
                  },
                ),
                _buildListTile(
                  title: "Legal Agreements",
                  onTap: () {
                    Navigator.of(context).pop();
                    // Show legal agreements.
                  },
                ),
                _buildListTile(
                  title: "Account Privacy",
                  onTap: () {
                    Navigator.of(context).pop();
                    // Show privacy settings.
                  },
                ),
                _buildListTile(
                  title: "Language",
                  trailing: const Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'English',
                        style: TextStyle(fontSize: 12, color: Colors.lightBlue),
                      ),
                    ],
                  ),
                  onTap: () {
                    Navigator.of(context).pop();
                    // Show language selection.
                  },
                ),
                const Divider(
                  height: 0.6,
                  color: Color.fromARGB(60, 158, 158, 158),
                ),
                _buildListTile(
                  title: "Logout",
                  titleColor: Colors.red,
                  onTap: () {
                    Navigator.of(context).pop();
                    // Implement logout.
                    AuthService.logout(context);
                  },
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      );
    },
  );
}

/// Example helper: header section.
Widget _buildHeaderSection() {
  UserModel userModel = UserModel.instance;
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    child: Row(
      children: [
        SizedBox(
          width: 40,
          height: 40,
          child: ClipOval(
            child: CustomImage(
                imageKey: userModel.profilePic ?? '', width: 100, height: 100),
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              userModel.fullName ?? '',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(
              height: 1,
            ),
            Text(
              userModel.email ?? userModel.phoneNumber ?? '',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.primaryRed,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(children: [
            Assets.images.clock.image(width: 19, height: 19),
            const SizedBox(
              width: 6,
            ),
            const Text(
              "30 days left",
              style: TextStyle(color: Colors.white, fontSize: 12),
            ),
          ]),
        ),
      ],
    ),
  );
}

/// Example helper: reusable list tile.
Widget _buildListTile({
  required String title,
  Widget? trailing = const Icon(
    Symbols.chevron_forward,
    color: AppColors.textGrey,
  ),
  VoidCallback? onTap,
  Color titleColor = const Color.fromARGB(161, 43, 43, 43),
}) {
  return SizedBox(
    height: 47,
    child: ListTile(
      title: Text(
        title,
        style: TextStyle(
          color: titleColor,
          fontSize: 13,
        ),
      ),
      trailing: trailing,
      onTap: onTap,
    ),
  );
}
