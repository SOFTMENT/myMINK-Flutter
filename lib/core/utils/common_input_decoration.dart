import 'package:flutter/material.dart';
import 'package:mymink/core/constants/colors.dart'; // Adjust import based on your folder structure

InputDecoration buildInputDecoration({
  required String labelText,
  required IconData? prefixIcon,
  bool isPasswordField = false,
  Widget? suffixIcon,
}) {
  return InputDecoration(
    prefixIcon: Icon(
      prefixIcon,
      color: AppColors.primaryRed,
    ),
    labelText: labelText,
    labelStyle: const TextStyle(
      fontSize: 14.2,
      color: AppColors.textGrey,
    ),
    filled: true,
    fillColor: AppColors.white,
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(
        color: AppColors.textGrey.withValues(alpha: 0.3),
        width: 1.0,
      ),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(
        color: AppColors.primaryRed,
        width: 1.0,
      ),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(
        color: AppColors.primaryRed.withValues(alpha: 0.5),
        width: 1.0,
      ),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(
        color: AppColors.primaryRed,
        width: 1.0,
      ),
    ),
    suffixIcon: isPasswordField ? suffixIcon : null,
  );
}
