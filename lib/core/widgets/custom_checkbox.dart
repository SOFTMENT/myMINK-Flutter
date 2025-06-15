import 'package:flutter/material.dart';
import 'package:mymink/core/constants/colors.dart';

class CustomCheckbox extends StatefulWidget {
  const CustomCheckbox({super.key, required this.onStatusChanged});
  final Function(bool staus) onStatusChanged;
  @override
  State<CustomCheckbox> createState() => _CustomCheckboxState();
}

class _CustomCheckboxState extends State<CustomCheckbox> {
  var _isCheck = false;
  @override
  Widget build(BuildContext context) {
    return Checkbox(
      side: const BorderSide(
        color: AppColors.primaryRed, // Red border color when unchecked
        width: 2, // Border width
      ),
      fillColor: WidgetStatePropertyAll(
        _isCheck ? AppColors.primaryRed : AppColors.transparent,
      ),
      checkColor: AppColors.white,
      value: _isCheck,
      onChanged: (value) {
        setState(() {
          _isCheck = (value ?? false);
          widget.onStatusChanged(_isCheck);
        });
      },
      visualDensity: const VisualDensity(
          horizontal: VisualDensity.minimumDensity,
          vertical:
              VisualDensity.minimumDensity), // Removes any additional density
      materialTapTargetSize:
          MaterialTapTargetSize.shrinkWrap, // Removes padding
    );
  }
}
