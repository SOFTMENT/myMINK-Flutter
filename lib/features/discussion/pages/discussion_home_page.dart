import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mymink/core/constants/app_routes.dart';
import 'package:mymink/core/constants/colors.dart';
import 'package:mymink/core/widgets/custom_app_bar.dart';
import 'package:mymink/core/widgets/custom_segmented_control.dart';
import 'package:mymink/core/widgets/search_bar_with_button.dart';
import 'package:mymink/features/discussion/data/models/discussion_topic_model.dart';
import 'package:mymink/features/discussion/widgets/dicussion_topic_list.dart';
import 'package:mymink/features/onboarding/data/models/user_model.dart';

class DiscussionHomePage extends StatefulWidget {
  const DiscussionHomePage({Key? key}) : super(key: key);

  @override
  State<DiscussionHomePage> createState() => _DiscussionHomePageState();
}

class _DiscussionHomePageState extends State<DiscussionHomePage> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _selectedSegment = 'All';

  void _onSearch() => setState(() {});

  void _onSegmentChanged(String newSeg) {
    setState(() {
      _selectedSegment = newSeg;
    });
  }

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
    final search = _searchCtrl.text.trim();

    // Base query
    Query<Map<String, dynamic>> query = FirebaseFirestore.instance
        .collection('Discussions')
        .orderBy('createdAt', descending: true);

    // If searching by title
    if (search.isNotEmpty) {
      query = query
          .where('title', isGreaterThanOrEqualTo: search)
          .where('title', isLessThanOrEqualTo: '$search\uf8ff');
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          CustomAppBar(
            title: 'Discussion Forum',
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
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: SearchBarWithButton(
              controller: _searchCtrl,
              hintText: 'Search topics…',
              onPressed: _onSearch,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25),
            child: SizedBox(
              width: double.infinity,
              child: CustomSegmentedControl(
                segments: ['All Topics', 'My Topics'],
                initialSelectedSegment: 'All Topics',
                onValueChanged: _onSegmentChanged,
              ),
            ),
          ),
          const SizedBox(height: 8),
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
                final allTopics = snap.data!.docs
                    .map((d) => DiscussionTopic.fromDoc(d))
                    .toList();

                // apply segment filter
                final topics = _selectedSegment == 'My Topics' && me != null
                    ? allTopics.where((t) => t.uid == me).toList()
                    : allTopics;

                if (topics.isEmpty) {
                  return Center(
                    child: Text(
                      _selectedSegment == 'My Topics'
                          ? 'You have not created any topics.'
                          : 'No topics found.',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: topics.length,
                  itemBuilder: (c, i) {
                    final topic = topics[i];
                    final canDelete = topic.uid == me;

                    Widget card = TopicCard(
                      topic: topic,
                      onTap: () => context.push(
                        AppRoutes.discussionDetailPage,
                        extra: {'topic': topic},
                      ),
                    );

                    if (!canDelete) return card;

                    // Wrap in Dismissible only if user owns it
                    return Dismissible(
                      key: ValueKey(topic.id),
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
                              .collection('Discussions')
                              .doc(topic.id)
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
