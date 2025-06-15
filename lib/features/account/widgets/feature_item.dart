import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:mymink/core/constants/colors.dart';

class FeatureItem extends StatelessWidget {
  final String label;
  final IconData iconData;
  final void Function() onTap;
  FeatureItem(
      {super.key,
      required this.iconData,
      required this.label,
      required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 50,
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8), color: AppColors.white),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                iconData,
                color: AppColors.primaryRed,
              ),
              const SizedBox(
                width: 8,
              ),
              Text(
                label,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textDarkGrey),
              ),
              const Spacer(),
              const Icon(
                Symbols.chevron_forward,
                color: AppColors.textGrey,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
