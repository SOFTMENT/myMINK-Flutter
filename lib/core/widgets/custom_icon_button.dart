import 'package:flutter/material.dart';

class CustomIconButton extends StatelessWidget {
  const CustomIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.backgroundColor = const Color.fromARGB(25, 255, 255, 255),
    this.width = 36,
    this.height = 36,
  });

  final icon;
  final backgroundColor;
  final double? width;
  final double? height;
  final void Function() onPressed;
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: width,
      child: IconButton(
        padding: const EdgeInsets.all(0),
        highlightColor: Colors.transparent, // Disable highlight effect
        style: IconButton.styleFrom(
            backgroundColor: backgroundColor,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
        onPressed: onPressed,
        icon: icon,
      ),
    );
  }
}
