// lib/features/events/data/event_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mymink/core/constants/collections.dart';
import 'package:mymink/core/utils/result.dart';
import 'package:mymink/features/event/data/models/event.dart';

class PaginatedEventResult {
  final List<EventModel> events;
  final DocumentSnapshot<Map<String, dynamic>> lastDocument;

  PaginatedEventResult({
    required this.events,
    required this.lastDocument,
  });
}

class EventService {
  static final CollectionReference<Map<String, dynamic>> _collection =
      FirebaseFirestore.instance.collection(Collections.events);

  static Future<Result<PaginatedEventResult>> getEventsPaginated({
    required String countryCode,
    String? eventOrganizerUid,
    int pageSize = 10,
    DocumentSnapshot<Map<String, dynamic>>? lastDoc,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _collection
          .where('isActive', isEqualTo: true)
          .where('countryCode', isEqualTo: countryCode)
          .orderBy('eventCreateDate', descending: true)
          .limit(pageSize);

      if (eventOrganizerUid != null) {
        query = query.where('eventOrganizerUid', isEqualTo: eventOrganizerUid);
      }
      if (lastDoc != null) {
        query = query.startAfterDocument(lastDoc);
      }

      final snapshot = await query.get();

      if (snapshot.docs.isEmpty) {
        return Result(error: 'No events available');
      }

      // EITHER: use your `fromDoc(...)`
      final events =
          snapshot.docs.map((doc) => EventModel.fromDoc(doc)).toList();

      // OR (if you prefer): use fromJson + ensure eventId present
      // final events = snapshot.docs.map((doc) {
      //   final data = doc.data();
      //   return EventModel.fromJson({...data, 'eventId': data['eventId'] ?? doc.id});
      // }).toList();

      return Result(
        data: PaginatedEventResult(
          events: events,
          lastDocument: snapshot.docs.last,
        ),
      );
    } catch (e) {
      return Result(error: e.toString());
    }
  }

  static Future<Result<EventModel>> getEventById(String eventId) async {
    try {
      final doc = await _collection.doc(eventId).get();
      if (!doc.exists) return Result(error: 'No event found for this ID.');
      return Result(data: EventModel.fromDoc(doc));
    } catch (e) {
      return Result(error: e.toString());
    }
  }
}
