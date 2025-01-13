import 'package:cloud_firestore/cloud_firestore.dart';

T fromFirestore<T>(
    DocumentSnapshot doc, T Function(Map<String, dynamic>) fromJson) {
  final data = doc.data() as Map<String, dynamic>;
  return fromJson(data);
}
