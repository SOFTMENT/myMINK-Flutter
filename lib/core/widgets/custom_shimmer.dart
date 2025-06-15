import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class CustomShimmer extends StatelessWidget {
  final double? width;
  final double? height;
  final Color? baseColor;
  final Color? highlightColor;

  const CustomShimmer({
    Key? key,
    this.width,
    this.height,
    this.baseColor,
    this.highlightColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: baseColor ?? Colors.grey[900]!,
      highlightColor: highlightColor ?? Colors.grey[800]!,
      child: Container(
        width: width ?? MediaQuery.of(context).size.width,
        height: height ?? MediaQuery.of(context).size.height,
        color: Colors.grey[900],
      ),
    );
  }
}
