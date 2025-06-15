// lib/features/tasks/pages/todo_add_update_page.dart
import 'package:flutter/material.dart';
import 'package:mymink/core/utils/common_input_decoration.dart';
import 'package:mymink/core/widgets/dismiss_keyboard_ontap.dart';
import 'package:mymink/features/todo/data/models/todo_model.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:mymink/core/constants/colors.dart';
import 'package:mymink/core/widgets/custom_app_bar.dart';
import 'package:mymink/core/widgets/custom_button.dart';
import 'package:mymink/core/widgets/progress_hud.dart';

class TodoAddupdatePage extends StatefulWidget {
  final String? existingId;
  final DateTime? existingDate;
  final String? existingTitle;

  const TodoAddupdatePage({
    Key? key,
    this.existingId,
    this.existingDate,
    this.existingTitle,
  }) : super(key: key);

  @override
  State<TodoAddupdatePage> createState() => _TodoAddupdatePageState();
}

class _TodoAddupdatePageState extends State<TodoAddupdatePage> {
  late DateTime _focusedDay;
  late DateTime _selectedDay;
  late TimeOfDay _selectedTime;
  final TextEditingController _titleCtrl = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _focusedDay = widget.existingDate ?? now;
    _selectedDay = widget.existingDate ?? now;
    _selectedTime = TimeOfDay.fromDateTime(widget.existingDate ?? now);
    if (widget.existingTitle != null) {
      _titleCtrl.text = widget.existingTitle!;
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked == null) return;

    // If same day as today, disallow past times
    final combined = DateTime(
      _selectedDay.year,
      _selectedDay.month,
      _selectedDay.day,
      picked.hour,
      picked.minute,
    );
    if (combined.isBefore(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot select past time')),
      );
      return;
    }

    setState(() => _selectedTime = picked);
  }

  Future<void> _saveTask() async {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Enter task title')));
      return;
    }
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('User not logged in')));
      return;
    }

    setState(() => _isLoading = true);
    final when = DateTime(
      _selectedDay.year,
      _selectedDay.month,
      _selectedDay.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    final col = FirebaseFirestore.instance.collection('Tasks');
    final docId = widget.existingId ?? col.doc().id;
    final model = ToDoModel(
      id: docId,
      uid: user.uid,
      title: title,
      date: when,
      isFinished: false,
    );

    try {
      await col.doc(docId).set(model.toJson());
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Task saved')));
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final monthLabel = DateFormat.yMMMM().format(_focusedDay);
    final timeLabel = _selectedTime.format(context);
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            DismissKeyboardOnTap(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: Column(
                  children: [
                    CustomAppBar(
                      title: widget.existingId == null
                          ? 'Add Task'
                          : 'Update Task',
                    ),

                    // Month header with arrows
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 25, vertical: 8),
                      child: Row(
                        children: [
                          Text(
                            monthLabel,
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.chevron_left),
                            onPressed: () {
                              setState(() {
                                _focusedDay = DateTime(
                                  _focusedDay.year,
                                  _focusedDay.month - 1,
                                  1,
                                );
                              });
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.chevron_right),
                            onPressed: () {
                              setState(() {
                                _focusedDay = DateTime(
                                  _focusedDay.year,
                                  _focusedDay.month + 1,
                                  1,
                                );
                              });
                            },
                          ),
                        ],
                      ),
                    ),

                    // Inline calendar with past dates disabled
                    TableCalendar(
                      firstDay: DateTime(2000),
                      lastDay: DateTime(2100),
                      focusedDay: _focusedDay,
                      calendarFormat: CalendarFormat.month,
                      headerVisible: false,
                      selectedDayPredicate: (day) =>
                          isSameDay(_selectedDay, day),
                      onDaySelected: (day, focus) {
                        if (day.isBefore(todayDate)) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Cannot select past date')),
                          );
                          return;
                        }
                        setState(() {
                          _selectedDay = day;
                          _focusedDay = focus;
                        });
                      },
                      enabledDayPredicate: (day) =>
                          !day.isBefore(todayDate), // disables past days
                      calendarStyle: const CalendarStyle(
                        todayDecoration: BoxDecoration(
                          color: Colors.grey,
                          shape: BoxShape.circle,
                        ),
                        selectedDecoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                      daysOfWeekStyle: const DaysOfWeekStyle(
                        weekendStyle: TextStyle(color: Colors.grey),
                        weekdayStyle: TextStyle(color: Colors.black87),
                      ),
                    ),

                    // Time picker
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 25, vertical: 8),
                      child: Row(
                        children: [
                          const Text(
                            'Time',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(width: 12),
                          GestureDetector(
                            onTap: _pickTime,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 8, horizontal: 12),
                              decoration: BoxDecoration(
                                border: Border.all(color: AppColors.primaryRed),
                                color: AppColors.transparent,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(timeLabel,
                                  style: const TextStyle(fontSize: 14)),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Title field
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 25, vertical: 16),
                      child: TextFormField(
                        controller: _titleCtrl,
                        textCapitalization: TextCapitalization.words,
                        decoration: buildInputDecoration(
                          labelText: 'Enter task title',
                          isWhiteOrder: false,
                          fillColor: Colors.transparent,
                          prefixColor: AppColors.textBlack,
                          focusedBorderColor: AppColors.primaryRed,
                          prefixIcon: Icons.task_alt_outlined,
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 24,
                    ),
                    // Add/Update button
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 25, vertical: 12),
                      child: SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: CustomButton(
                          backgroundColor: AppColors.textBlack,
                          onPressed: _saveTask,
                          text: widget.existingId == null
                              ? 'Add Task'
                              : 'Update Task',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_isLoading) Center(child: ProgressHud()),
          ],
        ),
      ),
    );
  }
}
