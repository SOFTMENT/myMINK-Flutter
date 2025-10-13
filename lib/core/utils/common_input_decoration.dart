import 'package:flutter/material.dart';
import 'package:mymink/core/constants/colors.dart'; // Adjust import based on your folder structure

InputDecoration buildInputDecoration(
    {required String labelText,
    required IconData? prefixIcon,
    bool isPasswordField = false,
    void Function()? suffixIconPressed,
    Color fillColor = Colors.white,
    Color prefixColor = AppColors.primaryRed,
    bool isWhiteOrder = false,
    bool alignLabelWithHint = false,
    Color focusedBorderColor = AppColors.primaryRed,
    Widget? suffixIcon,
    double minimumHeight = 42}) {
  return InputDecoration(
    isDense: true,
    prefixIcon: prefixIcon != null
        ? Icon(
            prefixIcon,
            color: prefixColor,
          )
        : null,
    labelText: labelText,
    alignLabelWithHint: alignLabelWithHint,
    labelStyle: const TextStyle(
      fontSize: 13,
      color: AppColors.textGrey,
    ),
    hintStyle: const TextStyle(
      fontSize: 13,
      color: AppColors.textGrey,
    ),
    filled: true,
    fillColor: fillColor,
    prefixIconConstraints:
        BoxConstraints(minWidth: 36, minHeight: minimumHeight),
    contentPadding: prefixIcon == null
        ? const EdgeInsets.symmetric(vertical: 12, horizontal: 10)
        : const EdgeInsets.only(right: 6),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(
        color: isWhiteOrder
            ? const Color.fromARGB(255, 255, 255, 255).withValues(alpha: 0.7)
            : AppColors.textGrey.withValues(alpha: 0.3),
        width: 1.0,
      ),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(
        color: focusedBorderColor,
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
    suffixIcon: suffixIcon == null
        ? null
        : GestureDetector(
            onTap: suffixIconPressed, // Toggle password visibility
            child: suffixIcon),
  );
}
