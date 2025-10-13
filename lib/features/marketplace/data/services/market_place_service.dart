import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mymink/core/constants/collections.dart';

import '../models/marketplace_model.dart';

class MarketplaceService {
  static Stream<List<MarketplaceModel>> stream(String? uid, String? category) {
    // Start with a typed base query
    Query<Map<String, dynamic>> base = FirebaseFirestore.instance
        .collection(Collections.marketplace)
        .orderBy('dateCreated', descending: true);

    if (category != null) {
      base = base.where('categoryName', isEqualTo: category);
    }
    if (uid != null && uid.isNotEmpty) {
      base = base.where('uid', isEqualTo: uid);
    }

    // Assign the converter result to a typed query
    final Query<MarketplaceModel> query = base.withConverter<MarketplaceModel>(
      fromFirestore: (snap, _) => MarketplaceModel.fromDoc(snap),
      toFirestore: (m, _) => m.toJson(),
    );

    // Now the stream is Stream<QuerySnapshot<MarketplaceModel>>
    return query.snapshots().map(
          (qs) => qs.docs.map((d) => d.data()).toList(),
        );
  }
}
