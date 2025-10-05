// lib/features/tasks/pages/todo_home_page.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:mymink/core/constants/app_routes.dart';
import 'package:mymink/core/constants/collections.dart';
import 'package:mymink/core/constants/colors.dart';
import 'package:mymink/core/widgets/custom_app_bar.dart';
import 'package:mymink/features/todo/data/models/todo_model.dart';
import 'package:mymink/features/todo/widgets/todo_intro_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TodoHomePage extends StatelessWidget {
  const TodoHomePage({Key? key}) : super(key: key);

  GestureDetector _buildAddButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        context.push(AppRoutes.addUpdateTodoPage);
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
                color: Colors.grey.withAlpha(80),
                spreadRadius: 1,
                blurRadius: 4,
                offset: const Offset(0, 2))
          ],
        ),
        child: const Icon(Icons.add, color: Colors.black, size: 18),
      ),
    );
  }

  String _formatTime(DateTime dt) => DateFormat('hh:mm a').format(dt);

  String _dueDateString(DateTime dueDate) {
    final now = DateTime.now();

    // 1) If the *exact* dueDate is already before "now", it's overdue
    if (dueDate.isBefore(now)) return 'Overdue';

    // 2) Otherwise compare just the calendar days
    final today = DateTime(now.year, now.month, now.day);
    final dueDay = DateTime(dueDate.year, dueDate.month, dueDate.day);
    final diffDays = dueDay.difference(today).inDays;

    if (diffDays == 0) {
      // same calendar-date and dueDate ≥ now
      return 'Due today';
    }
    if (diffDays == 1) {
      return 'Due tomorrow';
    }
    // 3) For anything further out
    return 'Due in $diffDays days';
  }

  @override
  Widget build(BuildContext context) {
    SharedPreferences.getInstance().then((value) {
      final isFirstTime = value.getBool('isFirstTime') ?? true;
      if (isFirstTime) {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          builder: (context) {
            return TodoIntroSheet(
              onPressed: () {
                value.setBool('isFirstTime', false);
                Navigator.of(context).pop();
              },
            );
          },
        );
      }
    });

    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          CustomAppBar(
            title: 'To-Do',
            gestureDetector: _buildAddButton(context),
          ),

          // if not logged in, prompt
          if (user == null)
            const Expanded(
              child: Center(child: Text('Please sign in to see tasks')),
            )
          else
            // real‐time list of tasks
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                // Change your stream to:
                stream: FirebaseFirestore.instance
                    .collection(Collections.tasks)
                    .where('uid', isEqualTo: user.uid)
                    .orderBy(
                        'isFinished') // <-- unfinished (false) first, then finished (true)
                    .orderBy('date') // <-- within each group, sort by date
                    .snapshots(),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snap.hasError) {
                    return Center(child: Text('Error: ${snap.error}'));
                  }
                  final docs = snap.data?.docs ?? [];
                  if (docs.isEmpty) {
                    return const Center(child: Text('No tasks available'));
                  }

                  final tasks = docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return ToDoModel.fromJson(data);
                  }).toList();

                  return ListView.builder(
                    padding: const EdgeInsets.only(top: 10, bottom: 24),
                    itemCount: tasks.length,
                    itemBuilder: (context, index) {
                      final task = tasks[index];
                      final dueLabel = _dueDateString(task.date);
                      final timeLabel = _formatTime(task.date);

                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 25, vertical: 6),
                        child: GestureDetector(
                          onTap: () {
                            // navigate to update page
                            context.push(
                              AppRoutes.addUpdateTodoPage,
                              extra: {
                                'existingId': task.id,
                                'existingDate': task.date,
                                'existingTitle': task.title,
                              },
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.grey.withAlpha(80),
                                    spreadRadius: 0.5,
                                    blurRadius: 4,
                                    offset: const Offset(0, 0.5))
                              ],
                            ),
                            child: Row(
                              children: [
                                // checkbox circle
                                GestureDetector(
                                  onTap: () {
                                    FirebaseFirestore.instance
                                        .collection(Collections.tasks)
                                        .doc(task.id)
                                        .update({
                                      'isFinished': !task.isFinished,
                                    });
                                  },
                                  child: Icon(
                                      task.isFinished
                                          ? Icons.check_circle
                                          : Icons.radio_button_unchecked,
                                      color: AppColors.primaryRed),
                                ),

                                const SizedBox(width: 12),

                                // title + time/due
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        task.title,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.textBlack,
                                          decoration: task.isFinished
                                              ? TextDecoration.lineThrough
                                              : null,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            timeLabel,
                                            style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey),
                                          ),
                                          if (!task.isFinished)
                                            Text(
                                              dueLabel,
                                              style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
