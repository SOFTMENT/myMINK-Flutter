import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mymink/core/constants/app_routes.dart';
import 'package:mymink/core/constants/collections.dart';
import 'package:mymink/core/constants/colors.dart';
import 'package:mymink/core/widgets/custom_app_bar.dart';

import 'package:mymink/core/widgets/search_bar_with_button.dart';

import 'package:mymink/features/inbox/data/models/last_message.dart';
import 'package:mymink/features/inbox/widgets/inbox_widget.dart';
import 'package:mymink/features/onboarding/data/models/user_model.dart';

class InboxPage extends StatefulWidget {
  const InboxPage({Key? key}) : super(key: key);

  @override
  State<InboxPage> createState() => _InboxPageState();
}

class _InboxPageState extends State<InboxPage> {
  final TextEditingController _searchCtrl = TextEditingController();

  void _onSearch() => setState(() {});

  Future<bool?> _confirmDelete(BuildContext ctx) {
    return showDialog<bool>(
      context: ctx,
      builder: (dCtx) => AlertDialog(
        title: const Text('Delete topic?'),
        content: const Text('Are you sure you want to delete this topic?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(dCtx).pop(false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.of(dCtx).pop(true),
              child: const Text('Delete')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final me = UserModel.instance.uid;
    // final search = _searchCtrl.text.trim();

    // Base query
    Query<Map<String, dynamic>> query = FirebaseFirestore.instance
        .collection(Collections.chats)
        .orderBy('date', descending: true);

    // If searching by title
    // if (search.isNotEmpty) {
    //   query = query
    //       .where('title', isGreaterThanOrEqualTo: search)
    //       .where('title', isLessThanOrEqualTo: '$search\uf8ff');
    // }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          CustomAppBar(
            title: 'Messages',
            gestureDetector: GestureDetector(
              onTap: () => context.push(AppRoutes.addDiscussionTopicPage),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.grey.withAlpha(80),
                        spreadRadius: 1,
                        blurRadius: 4)
                  ],
                ),
                child: const Icon(Icons.add, size: 18),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: SearchBarWithButton(
              controller: _searchCtrl,
              hintText: 'Search...',
              onPressed: _onSearch,
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: query.snapshots(),
              builder: (ctx, snap) {
                if (snap.hasError)
                  return Center(child: Text('Error: ${snap.error}'));
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                // map to model
                final allMessages =
                    snap.data!.docs.map((d) => LastMessage.fromDoc(d)).toList();

                if (allMessages.isEmpty) {
                  return const Center(
                    child: Text(
                      'No messages available.',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: allMessages.length,
                  itemBuilder: (c, i) {
                    final message = allMessages[i];
                    final canDelete = message.senderUid == me;

                    Widget card =
                        InboxWidget(lastMessage: message, onTap: () {});

                    if (!canDelete) return card;

                    // Wrap in Dismissible only if user owns it
                    return Dismissible(
                      key: ValueKey(message.senderUid),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      confirmDismiss: (_) async {
                        final ok = await _confirmDelete(context);
                        if (ok == true) {
                          await FirebaseFirestore.instance
                              .collection(Collections.chats)
                              .doc(message.senderUid)
                              .delete();
                        }
                        return ok;
                      },
                      child: card,
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
