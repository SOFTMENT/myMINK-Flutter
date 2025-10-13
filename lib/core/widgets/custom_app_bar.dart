import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mymink/core/constants/colors.dart';

class CustomAppBar extends StatelessWidget {
  final String title;
  final Widget?
      leadingWidget; // Optional widget next to back button (left side)
  final GestureDetector?
      gestureDetector; // Optional right-side action (same fixed width)
  final double width; // Right-side fixed width to mirror/back-balance

  CustomAppBar({
    super.key,
    required this.title,
    this.leadingWidget,
    this.width = 44,
    this.gestureDetector,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Top area
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 8),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // 1) Row handles LEFT group (back + optional leading) and RIGHT action
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // LEFT group
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Back button
                          GestureDetector(
                            onTap: () => context.pop(),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withAlpha(80),
                                    spreadRadius: 1,
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(Icons.arrow_back_outlined,
                                  size: 18),
                            ),
                          ),

                          if (leadingWidget != null) const SizedBox(width: 16),

                          // Extra spacing for your special case
                          if (title == 'Businesses') const SizedBox(width: 44),

                          if (leadingWidget != null)
                            // Leading widget flexes only as needed; doesn't affect center title
                            Flexible(child: leadingWidget!),
                        ],
                      ),

                      // RIGHT action area with fixed width (to keep layout tidy)
                      SizedBox(
                        width: width,
                        child: gestureDetector ?? const SizedBox.shrink(),
                      ),
                    ],
                  ),

                  // 2) Perfectly centered title on top of the Row
                  // IgnorePointer so it doesn't block taps on back/right actions
                  IgnorePointer(
                    ignoring: true,
                    child: Text(
                      title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textBlack,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
            const Divider(
              color: Color.fromARGB(49, 158, 158, 158),
              height: 0.3,
            ),
          ],
        ),
      ),
    );
  }
}
