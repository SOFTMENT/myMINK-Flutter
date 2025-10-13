import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mymink/core/widgets/custom_image.dart';

class ImagesPicker extends StatelessWidget {
  /// Local files selected by the user for each slot (null means no new file).
  final List<File?> images;

  /// Existing image URLs to preview (e.g., from an existing product).
  /// If a slot has no File, we show the URL preview instead.
  final List<String> previewUrls;

  /// Tapping a slot should open your picker; returns the slot index.
  final void Function(int index) onTapSlot;

  /// Called when "Add More Images" is tapped.
  final VoidCallback onAddMore;

  /// Optional: Remove slot callback; if null, no remove button is shown.
  final void Function(int index)? onRemove;

  final bool canAddMore;
  final int maxImages;

  const ImagesPicker({
    super.key,
    required this.images,
    required this.onTapSlot,
    required this.onAddMore,
    this.previewUrls = const [],
    this.onRemove,
    this.canAddMore = true,
    this.maxImages = 4,
  });

  @override
  Widget build(BuildContext context) {
    final slotCount = _max3(images.length, previewUrls.length, 1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: List.generate(slotCount, (index) {
            final file = (index < images.length) ? images[index] : null;
            final url =
                (index < previewUrls.length) ? previewUrls[index] : null;

            return _ImageSlot(
              file: file,
              url: url,
              onTap: () => onTapSlot(index),
              onRemove: onRemove == null ? null : () => onRemove!(index),
            );
          }),
        ),
        if (canAddMore && slotCount < maxImages) ...[
          const SizedBox(height: 12),
          GestureDetector(
            onTap: onAddMore,
            child: const Text(
              'Add More Images',
              style: TextStyle(
                decoration: TextDecoration.underline,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ],
    );
  }

  int _max3(int a, int b, int c) => (a > b ? a : b) > c ? (a > b ? a : b) : c;
}

class _ImageSlot extends StatelessWidget {
  final File? file;
  final String? url;
  final VoidCallback onTap;
  final VoidCallback? onRemove;

  const _ImageSlot({
    required this.file,
    required this.onTap,
    this.url,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(8);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        // Full-width cards; if Wrap gives layout issues, wrap this with SizedBox(width: double.infinity)
        width: double.infinity,
        height: 150,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: borderRadius,
          border: Border.all(color: const Color(0xFFE0E0E0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: borderRadius,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (file != null)
                Image.file(
                  file!,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                )
              else if (url != null && url!.isNotEmpty)
                CustomImage(
                  imageKey: url,
                  width: 900,
                  height: 600,
                  boxFit: BoxFit.cover,
                )
              else
                const _PlaceholderCard(),

              // Optional remove button (only if something is shown)
              if (onRemove != null &&
                  (file != null || (url != null && url!.isNotEmpty)))
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: onRemove,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(Icons.close,
                          size: 16, color: Colors.white),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlaceholderCard extends StatelessWidget {
  const _PlaceholderCard();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.image_outlined, size: 24),
          SizedBox(height: 8),
          Text(
            'Click to add product image',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 4),
          Text(
            'JPEG or PNG, no larger than 10MB.',
            style: TextStyle(fontSize: 12, color: Colors.black54),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
