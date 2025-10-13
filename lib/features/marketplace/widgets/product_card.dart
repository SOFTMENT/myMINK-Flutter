import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mymink/core/constants/app_routes.dart';
import 'package:mymink/core/widgets/custom_image.dart';
import 'package:mymink/features/marketplace/data/models/marketplace_model.dart';

class ProductCard extends StatelessWidget {
  final MarketplaceModel model;

  const ProductCard({required this.model});

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(6);
    final String? firstImage =
        (model.productImages.isNotEmpty) ? model.productImages.first : null;

    return GestureDetector(
      onTap: () {
        context.push(AppRoutes.viewProductPage, extra: {'product': model});
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Let image flex so the column never overflows its grid cell
          Flexible(
            child: ClipRRect(
              borderRadius: radius,
              child: AspectRatio(
                aspectRatio: 1, // square-ish hero image
                child:
                    CustomImage(imageKey: firstImage, width: 300, height: 300),
              ),
            ),
          ),

          const SizedBox(height: 6),

          Text(
            model.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),

          const SizedBox(height: 4),

          Text(
            model.categoryName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w500),
          ),

          const SizedBox(height: 6),

          Text(
            model.cost,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF21A05A),
                fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
