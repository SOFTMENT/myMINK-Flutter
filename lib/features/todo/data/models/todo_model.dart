// lib/features/tasks/models/todo_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class ToDoModel {
  final String id;
  final String uid;
  final String title;
  final DateTime date;
  final bool isFinished;

  ToDoModel({
    required this.id,
    required this.uid,
    required this.title,
    required this.date,
    this.isFinished = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'uid': uid,
        'title': title,
        'date': Timestamp.fromDate(date),
        'isFinished': isFinished,
      };

  factory ToDoModel.fromJson(Map<String, dynamic> json) => ToDoModel(
        id: json['id'] as String,
        uid: json['uid'] as String,
        title: json['title'] as String,
        date: (json['date'] as Timestamp).toDate(),
        isFinished: json['isFinished'] as bool,
      );
}
