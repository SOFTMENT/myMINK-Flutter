import 'package:flutter/material.dart';

import 'package:mymink/features/marketplace/data/models/marketplace_model.dart';
import 'package:mymink/features/marketplace/data/services/market_place_service.dart';
import 'package:mymink/features/marketplace/widgets/product_card.dart';

class MarketplaceGrid extends StatelessWidget {
  final String? uid;
  final EdgeInsetsGeometry padding;
  final double spacing;
  final int crossAxisCount;
  final double childAspectRatio; // tweak to match your design\
  final String? category;

  const MarketplaceGrid({
    super.key,
    this.category,
    this.uid,
    this.padding = const EdgeInsets.symmetric(horizontal: 25, vertical: 0),
    this.spacing = 12,
    this.crossAxisCount = 2,
    this.childAspectRatio = 0.70, // tall card like your screenshot
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<MarketplaceModel>>(
      stream: MarketplaceService.stream(uid, category),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          print(snap.error);
          return Center(child: Text('Error: ${snap.error}'));
        }
        final items = snap.data ?? const [];

        if (items.isEmpty) {
          return const Center(child: Text('No products yet'));
        }

        return GridView.builder(
          physics: const ClampingScrollPhysics(),
          padding: padding,
          itemCount: items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: spacing,
            mainAxisSpacing: spacing,
            childAspectRatio: childAspectRatio,
          ),
          itemBuilder: (context, i) => ProductCard(model: items[i]),
        );
      },
    );
  }
}
