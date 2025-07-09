import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mymink/core/constants/colors.dart';

class CustomAppBar extends StatelessWidget {
  final String title;
  final Widget? leadingWidget;
  final GestureDetector? gestureDetector;

  CustomAppBar(
      {super.key,
      required this.title,
      this.leadingWidget = null,
      this.gestureDetector = null});
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Top Row
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 8),
              child: Row(
                children: [
                  // 1. Back button
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
                      child: const Icon(Icons.arrow_back_outlined, size: 18),
                    ),
                  ),
                  if (leadingWidget != null)
                    const SizedBox(
                      width: 16,
                    ),

                  leadingWidget != null
                      ? leadingWidget!
                      :
                      // 2. Spacer + centered title + spacer
                      Expanded(
                          child: Center(
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
                        ),
                  const Spacer(),
                  // 3. Trailing area (either your supplied widget or an empty box)
                  SizedBox(
                    width: 44, // same width as back‐button’s container
                    child: gestureDetector ?? const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Divider(
              color: Color.fromARGB(49, 158, 158, 158),
              height: 0.3,
            )
          ],
        ),
      ),
    );
  }
}
