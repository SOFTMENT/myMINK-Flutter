import 'package:flutter/material.dart';
import 'package:mymink/core/widgets/custom_image.dart';

class DynamicImageLayout extends StatelessWidget {
  final List<String> imageUrls;
  final List<double> imageRatios; // Aspect ratios for images (width / height)

  const DynamicImageLayout({
    required this.imageUrls,
    required this.imageRatios,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        double containerWidth = constraints.maxWidth;

        if (imageUrls.isEmpty) return const SizedBox();

        // Maximum 4 images
        int imageCount = imageUrls.length > 4 ? 4 : imageUrls.length;

        if (imageCount == 1) {
          return _buildSingleImage(
              imageUrls[0], imageRatios[0], containerWidth);
        } else if (imageCount == 2) {
          return _buildTwoImages(imageUrls, imageRatios, containerWidth);
        } else if (imageCount == 3) {
          return _buildThreeImages(imageUrls, imageRatios, containerWidth);
        } else {
          return _buildFourImages(imageUrls, imageRatios, containerWidth);
        }
      },
    );
  }

  Widget _buildSingleImage(
      String imageUrl, double aspectRatio, double containerWidth) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: containerWidth),
      child: AspectRatio(
        aspectRatio: aspectRatio,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: CustomImage(
            imageKey: imageUrl,
            width: containerWidth,
            height: containerWidth / aspectRatio,
          ),
        ),
      ),
    );
  }

  Widget _buildTwoImages(
      List<String> imageUrls, List<double> imageRatios, double containerWidth) {
    double height = containerWidth / (imageRatios[0] + imageRatios[1]);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: (imageRatios[0] * 1000).toInt(),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              height: height,
              child: CustomImage(
                imageKey: imageUrls[0],
                width: containerWidth / 2,
                height: height,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: (imageRatios[1] * 1000).toInt(),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              height: height,
              child: CustomImage(
                imageKey: imageUrls[1],
                width: containerWidth / 2,
                height: height,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildThreeImages(
      List<String> imageUrls, List<double> imageRatios, double containerWidth) {
    double height = containerWidth / (imageRatios[0] + imageRatios[1]);

    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: (imageRatios[0] * 1000).toInt(),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  height: height,
                  child: CustomImage(
                    imageKey: imageUrls[0],
                    width: containerWidth / 2,
                    height: height,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: (imageRatios[1] * 1000).toInt(),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  height: height,
                  child: CustomImage(
                    imageKey: imageUrls[1],
                    width: containerWidth / 2,
                    height: height,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        AspectRatio(
          aspectRatio: imageRatios[2],
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CustomImage(
              imageKey: imageUrls[2],
              width: containerWidth,
              height: containerWidth / imageRatios[2],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFourImages(
      List<String> imageUrls, List<double> imageRatios, double containerWidth) {
    double height = containerWidth / (imageRatios[0] + imageRatios[1]);

    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: (imageRatios[0] * 1000).toInt(),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  height: height,
                  child: CustomImage(
                    imageKey: imageUrls[0],
                    width: containerWidth / 2,
                    height: height,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: (imageRatios[1] * 1000).toInt(),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  height: height,
                  child: CustomImage(
                    imageKey: imageUrls[1],
                    width: containerWidth / 2,
                    height: height,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: (imageRatios[2] * 1000).toInt(),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  height: height,
                  child: CustomImage(
                    imageKey: imageUrls[2],
                    width: containerWidth / 2,
                    height: height,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: (imageRatios[3] * 1000).toInt(),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  height: height,
                  child: CustomImage(
                    imageKey: imageUrls[3],
                    width: containerWidth / 2,
                    height: height,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
