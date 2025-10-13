import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mymink/core/constants/app_routes.dart';

import 'package:mymink/core/constants/colors.dart';

import 'package:mymink/core/widgets/custom_app_bar.dart';
import 'package:mymink/core/widgets/custom_button.dart';

import 'package:mymink/core/widgets/custom_image.dart';
import 'package:mymink/features/event/data/models/event.dart';
import 'package:mymink/features/marketplace/widgets/auto_image_slider.dart';
import 'package:mymink/features/onboarding/data/models/user_model.dart';
import 'package:mymink/features/onboarding/data/services/user_service.dart';
import 'package:mymink/gen/assets.gen.dart';
import 'package:share_plus/share_plus.dart';

class EventViewPage extends StatefulWidget {
  final EventModel eventModel;
  const EventViewPage({super.key, required this.eventModel});

  @override
  State<EventViewPage> createState() => _EventViewPageState();
}

class _EventViewPageState extends State<EventViewPage> {
  UserModel? userModel;
  final GlobalKey _shareBtnKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    getUser();
  }

  void getUser() async {
    final result = await UserService.getUserByUid(
        uid: widget.eventModel.eventOrganizerUid);
    if (result.hasData) {
      setState(() => userModel = result.data);
    }
  }

  Future<void> shareProduct({
    required BuildContext context,
    required String? url,
    GlobalKey? anchorKey,
  }) async {
    final shareUrl = url?.trim();
    if (shareUrl == null || shareUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Share URL not found.')),
      );
      return;
    }
    final uri = Uri.tryParse(shareUrl);
    if (uri == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid share URL.')),
      );
      return;
    }

    Rect? origin;
    if (anchorKey != null && anchorKey.currentContext != null) {
      final box = anchorKey.currentContext!.findRenderObject() as RenderBox?;
      if (box != null) {
        final offset = box.localToGlobal(Offset.zero);
        origin = offset & box.size; // iPad popover source rect
      }
    }

    await Share.shareUri(uri, sharePositionOrigin: origin);
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('EEE, MMM d • h:mm a', 'en_US');
    final textDateStart = fmt.format(widget.eventModel.startDate!);
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: Column(
                  children: [
                    CustomAppBar(
                      title: widget.eventModel.title,
                      width: 70,
                      gestureDetector: widget.eventModel.eventOrganizerUid ==
                              UserModel.instance.uid
                          ? GestureDetector(
                              onTap: () async {
                                final bool? isDeleted = await context.push(
                                    AppRoutes.addAndEditEventPage,
                                    extra: {'event': widget.eventModel});

                                if (isDeleted != null && isDeleted) {
                                  context.pop();
                                }
                              },
                              child: Container(
                                height: 40,
                                decoration: BoxDecoration(
                                  color: AppColors.primaryRed,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Center(
                                  child: Text(
                                    'Edit',
                                    style: TextStyle(
                                        color: AppColors.white, fontSize: 13),
                                  ),
                                ),
                              ),
                            )
                          : null,
                    ),

                    // Header media (keeps fixed aspect ratio)
                    AutoImageSlider(imageUrls: widget.eventModel.eventImages),

                    const SizedBox(height: 20),

                    // ↓↓↓ Make content take remaining space and scroll

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 25),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              GestureDetector(
                                onTap: () {
                                  context.push(AppRoutes.viewUserProfilePage,
                                      extra: {'userModel': userModel});
                                },
                                child: Row(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(100),
                                      child: SizedBox(
                                        height: 44,
                                        width: 44,
                                        child: CustomImage(
                                          imageKey: userModel?.profilePic,
                                          width: 100,
                                          height: 100,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          userModel?.fullName ?? 'Full Name',
                                          style: const TextStyle(
                                            color: AppColors.textBlack,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          '@${userModel?.username ?? 'username'}',
                                          style: const TextStyle(
                                            color: AppColors.textGrey,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              const Spacer(),
                              // anchor the popover to this widget
                              GestureDetector(
                                key: _shareBtnKey,
                                onTap: () {
                                  shareProduct(
                                    context: context,
                                    url: widget.eventModel.eventUrl,
                                    anchorKey: _shareBtnKey,
                                  );
                                },
                                child: Assets.images.share7
                                    .image(width: 24, height: 24),
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),

                          Text(
                            widget.eventModel.title,
                            style: const TextStyle(
                              color: AppColors.textBlack,
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 20),

                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.calendar_month,
                                size: 20,
                                color: AppColors.textGrey,
                              ),
                              const SizedBox(
                                width: 12,
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    textDateStart,
                                    style: const TextStyle(
                                        color: AppColors.textBlack,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13),
                                  ),
                                  const SizedBox(
                                    height: 2,
                                  ),
                                  const Text(
                                    'Times are displayed on your local timezone',
                                    style: const TextStyle(
                                        color: AppColors.textGrey,
                                        fontSize: 12),
                                  ),
                                  const SizedBox(
                                    height: 3,
                                  ),
                                  const Text(
                                    'Add to calendar',
                                    style: const TextStyle(
                                        color: AppColors.primaryBlue,
                                        fontSize: 12),
                                  )
                                ],
                              )
                            ],
                          ),
                          const SizedBox(
                            height: 12,
                          ),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.location_on_outlined,
                                size: 22,
                                color: AppColors.textGrey,
                              ),
                              const SizedBox(
                                width: 12,
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.eventModel.addressName,
                                    style: const TextStyle(
                                        color: AppColors.textBlack,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13),
                                  ),
                                  const SizedBox(
                                    height: 2,
                                  ),
                                  Text(
                                    widget.eventModel.address,
                                    style: const TextStyle(
                                        color: AppColors.textGrey,
                                        fontSize: 12),
                                  ),
                                  const SizedBox(
                                    height: 3,
                                  ),
                                ],
                              )
                            ],
                          ),
                          const SizedBox(height: 16),

                          const Text(
                            'About',
                            style: TextStyle(
                              color: AppColors.textBlack,
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.eventModel.description,
                            style: const TextStyle(
                              color: AppColors.textGrey,
                              fontSize: 13,
                            ),
                          ),

                          const SizedBox(height: 16), // a little tail padding
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Column(
              children: [
                Container(
                  height: 0.5,
                  width: double.infinity,
                  color: AppColors.textGrey,
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
                  child: Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Text(
                            'Price',
                            style: TextStyle(
                              color: AppColors.textGrey,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            widget.eventModel.ticketPrice ?? '0',
                            style: const TextStyle(
                                color: AppColors.textBlack,
                                fontSize: 14,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 20),
                          child: CustomButton(
                              height: 44,
                              text: 'Send Invite',
                              onPressed: () {
                                context.push(AppRoutes.viewUserProfilePage,
                                    extra: {'userModel': userModel});
                              },
                              backgroundColor: AppColors.primaryRed),
                        ),
                      )
                    ],
                  ),
                )
              ],
            ),
            const SizedBox(
              height: 16,
            )
          ],
        ),
      ),
    );
  }
}
