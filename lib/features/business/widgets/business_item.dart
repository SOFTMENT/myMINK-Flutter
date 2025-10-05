import 'package:flutter/material.dart';
import 'package:mymink/core/constants/app_routes.dart';
import 'package:mymink/core/constants/colors.dart';
import 'package:mymink/core/widgets/custom_icon_button.dart';
import 'package:mymink/core/widgets/custom_image.dart';
import 'package:mymink/features/business/data/models/business_model.dart';

import 'package:go_router/go_router.dart';
import 'package:mymink/gen/assets.gen.dart';

class BusinessItem extends StatelessWidget {
  final BusinessModel business;
  final VoidCallback? onShareTap;

  const BusinessItem({
    Key? key,
    required this.business,
    this.onShareTap,
  }) : super(key: key);

  void _navigateToBusinessProfile(BuildContext context) {
    context.push(AppRoutes.businessDetailsPage, extra: {
      'businessModel': business,
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _navigateToBusinessProfile(context),
      child: Stack(children: [
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: AppColors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.005),
                blurRadius: 4,
                offset: const Offset(0, 2),
              )
            ],
          ),
          child: Row(
            children: [
              ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CustomImage(
                      imageKey: business.profilePicture,
                      width: 60,
                      height: 60)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      business.businessCategory ?? '',
                      style: const TextStyle(
                        color: AppColors.primaryRed,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      business.name ?? '',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textBlack,
                      ),
                    ),
                    if (business.website != null &&
                        business.website!.isNotEmpty)
                      const SizedBox(height: 1),
                    Text(
                      business.website!,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textGrey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Positioned(
          bottom: 12,
          right: 2,
          child: CustomIconButton(
            icon: Assets.images.share7.image(width: 20, height: 20),
            onPressed: onShareTap ?? () {},
          ),
        ),
      ]),
    );
  }
}
