import 'package:flutter/material.dart';
import 'package:mymink/core/constants/colors.dart';

class IconColumn extends StatelessWidget {
  final dynamic icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  const IconColumn({
    Key? key,
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
        ),
        width:
            double.infinity, // Ensures container occupies full width available
        // Grey background
        child: Column(
          // Center content vertically
          mainAxisSize:
              MainAxisSize.min, // Ensures the column stretches to fill height
          children: [
            SizedBox(
              height: 30,
              width: 30,
              child: icon, // The icon can be resized here if necessary
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(color: AppColors.white),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
