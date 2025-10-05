import 'package:flutter/material.dart';
import 'package:mymink/core/constants/colors.dart';
import 'package:mymink/core/constants/product_categories.dart';

class ProductCategorySelector extends StatefulWidget {
  final Function(String?) onCategorySelected; // Callback

  const ProductCategorySelector({
    Key? key,
    required this.onCategorySelected,
  }) : super(key: key);

  @override
  State<ProductCategorySelector> createState() =>
      _ProductCategorySelectorState();
}

class _ProductCategorySelectorState extends State<ProductCategorySelector> {
  int selectedIndex = 0; // "All" by default

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 45,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: productCategories.length,
        itemBuilder: (context, index) {
          final bool isSelected = index == selectedIndex;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  selectedIndex = index;
                });
                widget.onCategorySelected(index == 0
                    ? null
                    : productCategories[index]); // Return index
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primaryRed : Colors.transparent,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primaryRed
                        : Colors.grey.shade300,
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    productCategories[index],
                    style: TextStyle(
                        color: isSelected ? Colors.white : Colors.black,
                        fontWeight: FontWeight.w500,
                        fontSize: 12),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
