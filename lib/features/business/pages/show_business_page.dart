import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:mymink/core/constants/account_type.dart';
import 'package:mymink/core/constants/app_routes.dart';
import 'package:mymink/core/constants/colors.dart';
import 'package:mymink/core/widgets/custom_image.dart';
import 'package:mymink/core/widgets/progress_hud.dart';
import 'package:mymink/features/business/data/models/business_model.dart';
import 'package:mymink/features/business/data/services/business_service.dart';
import 'package:mymink/features/onboarding/data/models/user_model.dart';
import 'package:mymink/features/post/data/models/post_model.dart';
import 'package:mymink/features/post/data/services/post_service.dart';
import 'package:mymink/features/post/widgets/grid_post_widget.dart';
import 'package:mymink/features/post/widgets/upload_progress_banner.dart';
import 'package:mymink/gen/assets.gen.dart';

class ShowBusinessPage extends ConsumerStatefulWidget {
  final BusinessModel? businessModel;

  ShowBusinessPage({super.key, this.businessModel});

  @override
  ConsumerState<ShowBusinessPage> createState() => _ShowBusinessPageState();
}

class _ShowBusinessPageState extends ConsumerState<ShowBusinessPage> {
  final ScrollController _scrollController = ScrollController();
  bool _isMyAccount = false;
  late BusinessModel? _model;
  bool _isLoading = false;
  bool _hasSubscribed = false;
  @override
  void initState() {
    _model = widget.businessModel;
    _isMyAccount = UserModel.instance.uid == _model!.uid ? true : false;
    checkIsSubscribed();
    super.initState();
  }

  void checkIsSubscribed() async {
    setState(() {
      _isLoading = true;
    });
    _hasSubscribed =
        await BusinessService.isCurrentUserSubscribed(_model!.businessId ?? '');
    setState(() {
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void businessEditCallback(BusinessModel businessModel) {
    setState(() {
      _model = businessModel;
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<PostModel?>(PostService.newPostProvider, (prev, next) {
      if (next != null && next.bid == _model!.businessId) {
        Future.delayed(const Duration(milliseconds: 500), () {
          ref.read(PostService.newPostProvider.notifier).state = null;
        });
      }
    });

    // Total header height: cover (220) + overlap (140) = 360
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          SingleChildScrollView(
            controller: _scrollController,
            physics: const ClampingScrollPhysics(),
            child: Column(
              children: [
                // -------------------
                // 1) Header with Stack
                // -------------------
                SizedBox(
                  height: 360,
                  width: double.infinity,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // Cover image (220px high)
                      _model!.coverPicture == null
                          ? Assets.images.greyAndWhiteMinimalistTwitterHeader
                              .image(
                              width: double.infinity,
                              height: 220,
                              fit: BoxFit.cover,
                            )
                          : SizedBox(
                              width: double.infinity,
                              height: 220,
                              child: CustomImage(
                                imageKey: _model!.coverPicture,
                                width: 550,
                                height: 220,
                                boxFit: BoxFit.cover,
                              ),
                            ),

                      // Top Row: back / chat / edit
                      Positioned(
                        top: 60,
                        left: 25,
                        right: 25,
                        child: Row(
                          children: [
                            // Back button
                            GestureDetector(
                              onTap: () => context.pop(),
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: AppColors.textBlack
                                      .withValues(alpha: 0.28),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.arrow_back_ios_new,
                                    size: 20,
                                    color: AppColors.white,
                                  ),
                                ),
                              ),
                            ),
                            const Spacer(),
                            // Chat button
                            if (_isMyAccount)
                              Row(
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: AppColors.textBlack
                                          .withValues(alpha: 0.28),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Center(
                                      child: Icon(
                                        Icons.chat_bubble_outline,
                                        size: 19,
                                        color: AppColors.white,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  // Edit button
                                  InkWell(
                                    onTap: () {
                                      context.push(AppRoutes.businessEditPage,
                                          extra: {
                                            'callback': businessEditCallback,
                                            'businessModel': _model!
                                          });
                                    },
                                    child: Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: AppColors.textBlack
                                            .withValues(alpha: 0.28),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Center(
                                        child: Icon(
                                          Symbols.edit_square,
                                          size: 20,
                                          color: AppColors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),

                      // Profile overlap & action buttons
                      Positioned(
                        top: 140,
                        left: 0,
                        right: 0,
                        child: Column(
                          children: [
                            // Buttons + profile in one row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Message
                                if (!_isMyAccount)
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.only(
                                          left: 1.5, top: 54.5),
                                      child: GestureDetector(
                                        onTap: () {
                                          // TODO: implement message
                                        },
                                        child: Container(
                                          height: 50,
                                          color: AppColors.textBlack,
                                          child: const Center(
                                            child: Text(
                                              'Message',
                                              style: TextStyle(
                                                color: AppColors.white,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),

                                // Profile picture
                                ClipRRect(
                                  borderRadius:
                                      BorderRadiusGeometry.circular(12),
                                  child: SizedBox(
                                    width: 160,
                                    height: 160,
                                    child: CustomImage(
                                      imageKey: _model!.profilePicture,
                                      width: 160,
                                      height: 160,
                                    ),
                                  ),
                                ),
                                if (!_isMyAccount)
                                  // Subscribe
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.only(
                                          right: 1.5, top: 54.5),
                                      child: GestureDetector(
                                        onTap: () {
                                          // TODO: implement subscribe
                                        },
                                        child: Container(
                                          height: 50,
                                          color: _hasSubscribed
                                              ? AppColors.textGrey
                                              : AppColors.primaryRed,
                                          child: Center(
                                            child: Text(
                                              _hasSubscribed
                                                  ? 'Subscribed'
                                                  : 'Subscribe',
                                              style: const TextStyle(
                                                color: AppColors.white,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),

                            const SizedBox(height: 12),

                            // Business name
                            Text(
                              _model!.name ?? '',
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textBlack,
                              ),
                            ),

                            const SizedBox(height: 2),

                            // Website
                            Text(
                              _model!.website ?? '',
                              style: const TextStyle(
                                fontSize: 15,
                                color: AppColors.textGrey,
                              ),
                            ),

                            const SizedBox(height: 2),

                            // Category + subscriber count
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  (_model!.businessCategory ?? '') + ',',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.primaryBlue,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Text(
                                  '0 Subscriber',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textGrey,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // --------------------------
                // 2) About + Grid of posts
                // --------------------------
                Padding(
                  padding: const EdgeInsets.only(
                      top: 32, left: 25, right: 25, bottom: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'About',
                        style: TextStyle(
                          color: AppColors.textBlack,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        (_model!.aboutBusiness ?? '').trim(),
                        style: const TextStyle(
                          color: AppColors.textGrey,
                          fontSize: 14,
                        ),
                      ),

                      const UploadProgressBanner(),

                      const SizedBox(height: 20),

                      // Posts grid (will scroll inside main scroll)
                      GridPostWidget(
                        uid: _model!.businessId ?? '',
                        isMyAccount: _isMyAccount,
                        accountType: AccountType.business,
                        controller: _scrollController,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_isLoading)
            Center(
              child: ProgressHud(),
            )
        ],
      ),
    );
  }
}
