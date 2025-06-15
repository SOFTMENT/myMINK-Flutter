import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:mymink/core/services/image_service.dart';

class CustomImage extends StatelessWidget {
  CustomImage(
      {super.key,
      required this.imageKey,
      required this.width,
      required this.height});
  final String? imageKey;
  final double width;
  final double height;
  @override
  Widget build(BuildContext context) {
    return (imageKey == null || imageKey!.isEmpty)
        ? SizedBox(
            width: width,
            height: height,
            child: Image.asset(
              'assets/images/imageload.gif',
              fit: BoxFit.cover,
            ),
          )
        : CachedNetworkImage(
            imageUrl: ImageService.generateImageUrl(
              imagePath: imageKey!,
              width: width.toInt(),
              height: height.toInt(),
            ),
            width: width,
            height: height,
            fit: BoxFit.cover,
            errorWidget: (context, url, error) {
              return SizedBox(
                width: width,
                height: height,
                child: Image.asset(
                  'assets/images/imageload.gif',
                  fit: BoxFit.cover,
                ),
              );
            },
            placeholder: (context, url) => SizedBox(
              width: width,
              height: height,
              child: Image.asset(
                'assets/images/imageload.gif',
                fit: BoxFit.cover,
              ),
            ),
          );
  }
}
