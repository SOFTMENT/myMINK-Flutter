import 'package:flutter/material.dart';
import 'package:mymink/core/constants/colors.dart';
import 'package:mymink/features/account/widgets/stats_item.dart';

class StatsContainer extends StatefulWidget {
  final String uid;
  const StatsContainer({super.key, required this.uid});

  @override
  State<StatsContainer> createState() => _StatsContainerState();
}

class _StatsContainerState extends State<StatsContainer> {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 74,
      width: double.infinity,
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12), color: AppColors.white),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          StatsItem(label: 'Followers', count: 0),
          Container(
            width: 0.8,
            height: 44,
            color: const Color.fromARGB(150, 158, 158, 158),
          ),
          StatsItem(label: 'Following', count: 0),
          Container(
            width: 0.8,
            height: 44,
            color: const Color.fromARGB(150, 158, 158, 158),
          ),
          StatsItem(label: 'Posts', count: 0),
          Container(
            width: 0.8,
            height: 44,
            color: const Color.fromARGB(150, 158, 158, 158),
          ),
          StatsItem(label: 'Views', count: 0),
        ],
      ),
    );
  }
}
