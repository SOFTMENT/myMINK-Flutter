import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mymink/core/constants/app_routes.dart';
import 'package:mymink/core/constants/colors.dart';
import 'package:mymink/core/services/firebase_service.dart';
import 'package:mymink/core/widgets/custom_app_bar.dart';
import 'package:mymink/core/widgets/search_bar_with_button.dart';
import 'package:mymink/features/marketplace/widgets/marketplace_grid.dart';
import 'package:mymink/features/marketplace/widgets/product_category_selector.dart';

class MarketplaceHomePage extends StatefulWidget {
  const MarketplaceHomePage({super.key});

  @override
  State<MarketplaceHomePage> createState() => _MarketplaceHomePageState();
}

class _MarketplaceHomePageState extends State<MarketplaceHomePage> {
  final TextEditingController _searchController = TextEditingController();
  Future<void> _applySearch() async {}
  String? category;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(children: [
        Column(
          children: [
            CustomAppBar(
              title: 'Marketplace',
              width: 90,
              gestureDetector: GestureDetector(
                onTap: () {
                  context.push(AppRoutes.manageProductStorePage);
                },
                child: Container(
                  height: 34,
                  decoration: BoxDecoration(
                    color: AppColors.primaryRed,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Text(
                      'My Store',
                      style: TextStyle(color: AppColors.white, fontSize: 13),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: SearchBarWithButton(
                controller: _searchController,
                hintText: 'Search',
                onPressed: _applySearch,
              ),
            ),
            const SizedBox(
              height: 16,
            ),
            ProductCategorySelector(onCategorySelected: (cat) {
              setState(() {
                category = cat;
              });
            }),
            const SizedBox(
              height: 24,
            ),
            Expanded(
              child: MarketplaceGrid(
                category: category,
              ),
            ),
          ],
        ),
      ]),
    );
  }
}
