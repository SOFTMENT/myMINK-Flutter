import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mymink/core/constants/collections.dart';
import 'package:mymink/core/services/firebase_service.dart';

import 'package:mymink/core/utils/result.dart';
import 'package:mymink/features/business/data/models/business_model.dart';

class PaginatedBusinessResult {
  final List<BusinessModel> businesses;
  final DocumentSnapshot lastDocument;

  PaginatedBusinessResult({
    required this.businesses,
    required this.lastDocument,
  });
}

class BusinessService {
  static final _collection =
      FirebaseFirestore.instance.collection(Collections.businesses);
  static Future<Result<PaginatedBusinessResult>> getBusinessesPaginated({
    int pageSize = 10,
    DocumentSnapshot? lastDoc,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _collection
          .where('isActive', isEqualTo: true)
          .orderBy('name')
          .limit(pageSize);

      if (lastDoc != null) {
        query = query.startAfterDocument(lastDoc);
      }

      final snapshot = await query.get();

      if (snapshot.docs.isNotEmpty) {
        final businesses =
            snapshot.docs.map((doc) => BusinessModel.fromDoc(doc)).toList();

        final lastDocument = snapshot.docs.last;

        return Result(
            data: PaginatedBusinessResult(
                businesses: businesses, lastDocument: lastDocument));
      }

      return Result(error: 'No businesses available');
    } catch (e) {
      print('Error fetching paginated businesses: \$e');
      return Result(error: e.toString());
    }
  }

  static List<String> _ngramsFrom(String s) {
    final t = s.toLowerCase();
    final runes = t.runes.toList();
    final out = <String>{};
    for (final n in [2, 3]) {
      if (runes.length >= n) {
        for (int i = 0; i <= runes.length - n; i++) {
          out.add(String.fromCharCodes(runes.sublist(i, i + n)));
        }
      }
    }
    return out.toList();
  }

  static Map<String, dynamic> buildSearchFields(String name) {
    final lower = (name).toLowerCase();
    return {
      'nameLower': lower,
      'nameNgrams': _ngramsFrom(lower), // bigrams + trigrams
    };
  }

  static Future<Result<PaginatedBusinessResult>>
      searchBusinessesByTextPaginated({
    required String term,
    int pageSize = 10,
    DocumentSnapshot? lastDoc,
  }) async {
    try {
      final q = term.trim().toLowerCase();
      if (q.isEmpty) return Result(error: 'Search term is empty.');

      // If very short, fall back to prefix search on nameLower
      if (q.length < 2) {
        Query<Map<String, dynamic>> query = _collection
            .where('isActive', isEqualTo: true)
            .orderBy('nameLower')
            .startAt([q]).endAt(['$q\uf8ff']).limit(pageSize);

        if (lastDoc != null) query = query.startAfterDocument(lastDoc);

        final snap = await query.get();
        if (snap.docs.isEmpty) return Result(error: 'No results found.');
        final items = snap.docs.map(BusinessModel.fromDoc).toList();
        return Result(
          data: PaginatedBusinessResult(
            businesses: items,
            lastDocument: snap.docs.last,
          ),
        );
      }

      // For length >= 2 → use n-gram index
      final tokens = _ngramsFrom(q);
      // Firestore array-contains-any accepts up to 10 values → trim if needed
      final searchTokens = tokens.take(10).toList();

      Query<Map<String, dynamic>> query = _collection
          .where('isActive', isEqualTo: true)
          .where('nameNgrams', arrayContainsAny: searchTokens)
          .orderBy('nameLower') // may prompt a composite index in console
          .limit(pageSize);

      if (lastDoc != null) query = query.startAfterDocument(lastDoc);

      final snap = await query.get();
      if (snap.docs.isEmpty) return Result(error: 'No results found.');

      // Optional extra safety: ensure the full substring actually appears.
      // (Keeps results precise without doing a full local search first.)
      final qLower = q;
      final items = snap.docs
          .map(BusinessModel.fromDoc)
          .where((b) => (b.name ?? '').toLowerCase().contains(qLower))
          .toList();

      if (items.isEmpty) return Result(error: 'No results found.');

      return Result(
        data: PaginatedBusinessResult(
          businesses: items,
          lastDocument: snap.docs.last,
        ),
      );
    } catch (e) {
      print('Error searching businesses: $e');
      return Result(error: e.toString());
    }
  }

  /// Get business by UID (first match)
  static Future<Result<BusinessModel>> getBusinessByUid(String uid) async {
    try {
      final snapshot =
          await _collection.where('uid', isEqualTo: uid).limit(1).get();

      if (snapshot.docs.isNotEmpty) {
        final businessModel = BusinessModel.fromDoc(snapshot.docs.first);
        return Result(data: businessModel);
      }

      return Result(error: 'No business found for this UID.');
    } catch (e) {
      return Result(error: e.toString());
    }
  }

  /// Get business by Business ID
  static Future<Result<BusinessModel>> getBusinessById(
      String businessId) async {
    try {
      final doc = await _collection.doc(businessId).get();

      if (doc.exists && doc.data() != null) {
        final businessModel = BusinessModel.fromDoc(doc);
        return Result(data: businessModel);
      }

      return Result(error: 'No business found for this ID.');
    } catch (e) {
      return Result(error: e.toString());
    }
  }

  static Future<bool> isCurrentUserSubscribed(String businessId) async {
    final user = FirebaseService().auth.currentUser;
    if (user == null) {
      return false;
    }

    try {
      final doc = await FirebaseService()
          .db
          .collection(Collections.businesses)
          .doc(businessId)
          .collection(Collections.subscribers)
          .doc(user.uid)
          .get();

      return doc.exists;
    } catch (e) {
      return false;
    }
  }
}
