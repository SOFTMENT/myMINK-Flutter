import 'package:flutter/material.dart';

class DismissKeyboardOnTap extends StatelessWidget {
  final Widget child;

  DismissKeyboardOnTap({required this.child});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Dismiss the keyboard when tapping anywhere outside the TextField
        FocusScope.of(context).unfocus();
      },
      child: child,
    );
  }
}
