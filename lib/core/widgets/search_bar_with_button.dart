import 'package:flutter/material.dart';
import 'package:mymink/core/constants/colors.dart';
import 'package:mymink/core/utils/common_input_decoration.dart';
import 'package:mymink/core/widgets/custom_icon_button.dart';

class SearchBarWithButton extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onPressed;
  final String hintText;
  final bool showPadding;
  final void Function(String?)? onChanged;

  const SearchBarWithButton({
    super.key,
    required this.controller,
    required this.onPressed,
    required this.hintText,
    this.onChanged = null,
    this.showPadding = true,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: showPadding
          ? const EdgeInsets.symmetric(horizontal: 25)
          : const EdgeInsets.all(0),
      child: SizedBox(
        height: 42,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => onPressed(),
                controller: controller,
                autocorrect: false,
                maxLines: 1,
                minLines: 1,
                onChanged: onChanged,
                textAlignVertical: TextAlignVertical.center,
                style: const TextStyle(
                  color: AppColors.textBlack,
                  fontSize: 13,
                ),
                decoration: buildInputDecoration(
                  labelText: hintText,
                  isWhiteOrder: false,
                  fillColor: Colors.transparent,
                  prefixColor: AppColors.textBlack,
                  focusedBorderColor: AppColors.primaryRed,
                  prefixIcon: Icons.search_outlined,
                ),
              ),
            ),
            const SizedBox(width: 6),
            SizedBox(
              width: 42,
              height: 42,
              child: CustomIconButton(
                icon: const Align(
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.search,
                    color: AppColors.white,
                    size: 25,
                  ),
                ),
                backgroundColor: AppColors.primaryRed,
                onPressed: onPressed,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
