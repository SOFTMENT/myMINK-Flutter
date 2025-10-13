import 'package:flutter/material.dart';
import 'package:mymink/core/constants/colors.dart';

class StatsItem extends StatelessWidget {
  final int count;
  final String label;
  StatsItem({super.key, required this.label, required this.count});
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          count.toString(),
          style: const TextStyle(
              fontSize: 18,
              color: AppColors.primaryRed,
              fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textDarkGrey,
          ),
        )
      ],
    );
  }
}
