import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mymink/core/constants/app_routes.dart';
import 'package:mymink/core/constants/colors.dart';
import 'package:mymink/core/services/firebase_service.dart';
import 'package:mymink/core/widgets/custom_app_bar.dart';
import 'package:mymink/features/marketplace/widgets/marketplace_grid.dart';

class ManageProductStorePage extends StatefulWidget {
  const ManageProductStorePage({super.key});

  @override
  State<ManageProductStorePage> createState() => _ManageProductStorePageState();
}

class _ManageProductStorePageState extends State<ManageProductStorePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(children: [
        Column(
          children: [
            CustomAppBar(
              title: 'My Store',
              width: 90,
              gestureDetector: GestureDetector(
                onTap: () {
                  context.push(AppRoutes.editOrAddProductPage);
                },
                child: Container(
                  height: 34,
                  decoration: BoxDecoration(
                    color: AppColors.primaryRed,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Text(
                      'Add Product',
                      style: TextStyle(color: AppColors.white, fontSize: 13),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(
              height: 16,
            ),
            Expanded(
              child: MarketplaceGrid(
                uid: FirebaseService()
                    .auth
                    .currentUser!
                    .uid, // the UID you want to filter by
                // childAspectRatio: 0.62 // tweak for your exact card height
              ),
            ),
          ],
        ),
      ]),
    );
  }
}
