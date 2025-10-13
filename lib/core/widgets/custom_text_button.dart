import 'package:flutter/material.dart';

class CustomTextButton extends StatelessWidget {
  const CustomTextButton(
      {super.key,
      required this.title,
      required this.color,
      this.fontSize = 12,
      required this.onPressed});
  final String title;
  final Color color;
  final double fontSize;
  final void Function() onPressed;
  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        padding: EdgeInsets.zero, // Remove default padding
        minimumSize: Size.zero, // Remove minimum width and height
        splashFactory: NoSplash.splashFactory,
      ),
      child: Text(
        title,
        style: TextStyle(
          fontSize: fontSize,
          color: color,
        ),
      ),
    );
  }
}
