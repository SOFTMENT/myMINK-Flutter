import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:mymink/core/services/image_service.dart';

class CustomImage extends StatelessWidget {
  CustomImage(
      {super.key,
      required this.imageKey,
      required this.width,
      required this.height,
      this.imageFullUrl = null,
      this.boxFit = BoxFit.cover});
  final String? imageKey;
  final double width;
  final double height;
  final BoxFit boxFit;
  final String? imageFullUrl;
  @override
  Widget build(BuildContext context) {
    return ((imageKey == null || imageKey!.isEmpty) &&
            (imageFullUrl == null || imageFullUrl!.isEmpty))
        ? SizedBox(
            width: width,
            height: height,
            child: Image.asset(
              'assets/images/imageload.gif',
              fit: boxFit,
            ),
          )
        : CachedNetworkImage(
            imageUrl: imageFullUrl != null && imageFullUrl!.isNotEmpty
                ? imageFullUrl!
                : ImageService.generateImageUrl(
                    imagePath: imageKey!,
                    width: width.toInt(),
                    height: height.toInt(),
                  ),
            width: width,
            height: height,
            fit: boxFit,
            errorWidget: (context, url, error) {
              return SizedBox(
                width: width,
                height: height,
                child: Image.asset(
                  'assets/images/imageload.gif',
                  fit: boxFit,
                ),
              );
            },
            placeholder: (context, url) => SizedBox(
              width: width,
              height: height,
              child: Image.asset(
                'assets/images/imageload.gif',
                fit: boxFit,
              ),
            ),
          );
  }
}
