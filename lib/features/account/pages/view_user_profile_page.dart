import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:mymink/core/constants/app_routes.dart';
import 'package:mymink/core/constants/colors.dart';
import 'package:mymink/core/utils/date_formatter.dart';
import 'package:mymink/core/widgets/custom_button.dart';

import 'package:mymink/core/widgets/custom_image.dart';
import 'package:mymink/core/widgets/dismiss_keyboard_ontap.dart';

import 'package:mymink/features/account/widgets/stats_container.dart';
import 'package:mymink/features/onboarding/data/models/user_model.dart';
import 'package:mymink/features/post/widgets/grid_post_widget.dart';
import 'package:mymink/gen/assets.gen.dart';
import 'package:url_launcher/url_launcher.dart';

class ViewUserProfilePage extends StatefulWidget {
  final UserModel userModel;
  const ViewUserProfilePage({super.key, required this.userModel});
  @override
  State<ViewUserProfilePage> createState() => _ViewUserProfilePageState();
}

class _ViewUserProfilePageState extends State<ViewUserProfilePage> {
  final ScrollController _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    final userModel = widget.userModel;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: DismissKeyboardOnTap(
        child: SingleChildScrollView(
          controller: _scrollController,
          physics: const ClampingScrollPhysics(),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Assets.images.frame10000035542.image(
                  width: double.infinity, height: 400, fit: BoxFit.fitHeight),
              Padding(
                padding: const EdgeInsets.only(top: 44, left: 25, right: 25),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        context.pop();
                      },
                      child: Assets.images.em1688517695TrimmyBack
                          .image(width: 38, height: 38),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () {
                        //showSettingsBottomSheet(context, _refreshProfile);
                      },
                      child: Assets.images.em1688517721TrimmyDots
                          .image(width: 38, height: 38),
                    )
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 144, left: 25, right: 25),
                child: Align(
                  alignment: Alignment.center,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      ClipOval(
                        child: CustomImage(
                            imageKey: userModel.profilePic,
                            width: 180,
                            height: 180),
                      ),
                      const SizedBox(
                        height: 8,
                      ),
                      Text(
                        '@${userModel.username ?? 'NoUserName'}',
                        style: const TextStyle(color: AppColors.textGrey),
                      ),
                      const SizedBox(
                        height: 2,
                      ),
                      Text(
                        userModel.fullName ?? 'NoFullName',
                        style: const TextStyle(
                            color: AppColors.textBlack,
                            fontSize: 19,
                            fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(
                        height: 1,
                      ),
                      Text(
                        'Joined on ${DateFormatter.formatDate(userModel.registredAt ?? DateTime.now(), 'dd MMM yyyy')}',
                        style: const TextStyle(
                          color: AppColors.textGrey,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(
                        height: 24,
                      ),
                      if (widget.userModel.uid != UserModel.instance.uid)
                        Row(
                          children: [
                            Expanded(
                              child: CustomButton(
                                  height: 50,
                                  text: 'Chat',
                                  onPressed: () {
                                    context.push(AppRoutes.showInboxChatPage,
                                        extra: {
                                          'current': UserModel.instance,
                                          'friend': widget.userModel
                                        });
                                  },
                                  backgroundColor: AppColors.textBlack),
                            ),
                            const SizedBox(
                              width: 12,
                            ),
                            Expanded(
                              child: CustomButton(
                                  height: 50,
                                  text: 'Follow',
                                  onPressed: () {},
                                  backgroundColor: AppColors.primaryRed),
                            ),
                          ],
                        ),
                      if (widget.userModel.uid != UserModel.instance.uid)
                        const SizedBox(
                          height: 20,
                        ),

                      StatsContainer(
                        uid: widget.userModel.uid ?? '',
                      ),
                      const SizedBox(
                        height: 20,
                      ),
                      if (userModel.phoneNumber != null &&
                          userModel.phoneNumber!.isNotEmpty)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.phone_outlined,
                              color: AppColors.textGrey,
                            ),
                            const SizedBox(width: 12),
                            InkWell(
                              onTap: () async {
                                final phone = userModel.phoneNumber;
                                final url = Uri(scheme: 'tel', path: phone);
                                if (await canLaunchUrl(url)) {
                                  await launchUrl(url);
                                } else {
                                  // Optionally show an error message or snackbar
                                  print('Could not launch $url');
                                }
                              },
                              child: Text(
                                userModel.phoneNumber!,
                                style: const TextStyle(
                                  color: AppColors.textGrey,
                                  fontSize: 13,
                                  decoration: TextDecoration.none,
                                ),
                              ),
                            ),
                          ],
                        ),
                      if (userModel.phoneNumber != null &&
                          userModel.phoneNumber!.isNotEmpty)
                        const SizedBox(
                          height: 12,
                        ),
                      if (userModel.email != null &&
                          userModel.email!.isNotEmpty)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.email_outlined,
                              color: AppColors.textGrey,
                            ),
                            const SizedBox(width: 12),
                            InkWell(
                              onTap: () async {
                                final email = userModel.email;
                                final url = Uri(scheme: 'mailto', path: email);
                                if (await canLaunchUrl(url)) {
                                  await launchUrl(url);
                                } else {
                                  // Optionally show an error message or snackbar
                                  print('Could not launch $url');
                                }
                              },
                              child: Text(
                                userModel.email ?? '',
                                style: const TextStyle(
                                  color: AppColors.textGrey,
                                  fontSize: 13,
                                  decoration: TextDecoration.none,
                                ),
                              ),
                            ),
                          ],
                        ),
                      if (userModel.email != null &&
                          userModel.email!.isNotEmpty)
                        const SizedBox(
                          height: 12,
                        ),
                      if (userModel.website != null &&
                          userModel.website!.isNotEmpty)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.language_outlined,
                              color: AppColors.textGrey,
                            ),
                            const SizedBox(
                              width: 12,
                            ),
                            Text(
                              userModel.website!,
                              style: const TextStyle(
                                color: AppColors.textGrey,
                                fontSize: 13,
                              ),
                            )
                          ],
                        ),
                      if (userModel.website != null &&
                          userModel.website!.isNotEmpty)
                        const SizedBox(
                          height: 12,
                        ),
                      if (userModel.location != null &&
                          userModel.location!.isNotEmpty)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.place_outlined,
                              color: AppColors.textGrey,
                              size: 25,
                            ),
                            const SizedBox(
                              width: 12,
                            ),
                            Expanded(
                              child: Text(
                                userModel.location!,
                                style: const TextStyle(
                                  color: AppColors.textGrey,
                                  fontSize: 13,
                                ),
                              ),
                            )
                          ],
                        ),
                      if (userModel.location != null &&
                          userModel.location!.isNotEmpty)
                        const SizedBox(
                          height: 12,
                        ),
                      if (userModel.biography != null &&
                          userModel.biography!.isNotEmpty)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Symbols.person_book,
                              color: AppColors.textGrey,
                            ),
                            const SizedBox(
                              width: 12,
                            ),
                            Expanded(
                              child: Text(
                                userModel.biography!.trim(),
                                style: const TextStyle(
                                  color: AppColors.textGrey,
                                  fontSize: 13,
                                ),
                              ),
                            )
                          ],
                        ),
                      if (userModel.biography != null &&
                          userModel.biography!.isNotEmpty)
                        const SizedBox(
                          height: 16,
                        ),
                      // Row(
                      //   crossAxisAlignment: CrossAxisAlignment.center,
                      //   children: [
                      //     const Icon(
                      //       Symbols.stylus_note,
                      //       color: AppColors.textGrey,
                      //     ),
                      //     const SizedBox(
                      //       width: 12,
                      //     ),
                      //     CustomButton(
                      //       text: 'Add Autograph',
                      //       onPressed: () {},
                      //       fontSize: 10,
                      //       fontWeight: FontWeight.normal,
                      //       height: 28,
                      //       width: null,
                      //       backgroundColor: AppColors.primaryRed,
                      //     ),
                      //   ],
                      // ),

                      GridPostWidget(
                        uid: userModel.uid ?? '',
                        controller: _scrollController,
                      ),
                    ],
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();

    super.dispose();
  }
}
