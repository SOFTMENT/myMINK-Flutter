import 'package:flutter/material.dart';

class ProgressHud extends StatelessWidget {
  final String? message;

  // Constructor to accept the message
  ProgressHud({super.key, this.message = null});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 56, 54, 54)
            .withValues(alpha: 0.75), // Semi-transparent black background
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(
            color: Colors.white, // White color for the spinner
          ),
          if (message != null) const SizedBox(width: 20),
          if (message != null)
            Text(
              message!,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
        ],
      ),
    );
  }
}
