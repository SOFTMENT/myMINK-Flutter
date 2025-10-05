import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mymink/core/constants/app_routes.dart';

import 'package:mymink/core/constants/collections.dart';
import 'package:mymink/core/constants/colors.dart';
import 'package:mymink/core/widgets/custom_button.dart';
import 'package:mymink/core/widgets/search_bar_with_button.dart';
import 'package:mymink/features/livestreaming/data/models/live_streaming_model.dart';
import 'package:mymink/features/livestreaming/data/services/live_stream_service.dart';
import 'package:mymink/features/livestreaming/widgets/live_stream_card.dart';

class LivestreamHomePage extends StatefulWidget {
  const LivestreamHomePage({super.key});

  @override
  State<LivestreamHomePage> createState() => _LivestreamHomePageState();
}

class _LivestreamHomePageState extends State<LivestreamHomePage> {
  final TextEditingController searchController = TextEditingController();

  void _goLive() {
    LivestreamService.startLiveStream(context, shouldShowProgress: true);
  }

  void _joinLive(LiveStreamingModel live) {
    LiveStreamingModel liveStreamingModel = LiveStreamingModel(
        uid: live.uid,
        fullName: live.fullName,
        profilePic: live.profilePic,
        date: live.date,
        token: live.token,
        isOnline: live.isOnline,
        agoraUID: live.agoraUID,
        count: live.count,
        likeCount: live.likeCount);
    context.push(AppRoutes.joinLivestreamPage,
        extra: {'liveStreamModel': liveStreamingModel});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              // header + Go Live
              Row(
                children: [
                  const Text(
                    'Live Streaming',
                    style: TextStyle(
                      fontSize: 24,
                      color: AppColors.textBlack,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  CustomButton(
                    width: 86,
                    height: 38,
                    text: 'Go Live',
                    onPressed: _goLive,
                    backgroundColor: AppColors.primaryRed,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // search
              SearchBarWithButton(
                showPadding: false,
                controller: searchController,
                onPressed: () {
                  // TODO: optional search logic
                },
                hintText: 'Search',
              ),
              const SizedBox(height: 20),

              // grid or “no data”
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection(Collections.liveStreamings)
                      .where('isOnline', isEqualTo: true)
                      .orderBy('date', descending: true)
                      .snapshots(),
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final docs = snap.data?.docs ?? [];
                    if (docs.isEmpty) {
                      return const Center(
                        child: Text(
                          'No live streamings available',
                          style: TextStyle(
                            color: AppColors.textGrey,
                            fontSize: 15,
                          ),
                        ),
                      );
                    }

                    final models = docs
                        .map((d) => LiveStreamingModel.fromMap(
                            d.data() as Map<String, dynamic>))
                        .toList();

                    return GridView.builder(
                      padding: EdgeInsets.zero,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 1,
                      ),
                      itemCount: models.length,
                      itemBuilder: (context, i) {
                        final live = models[i];
                        return LiveStreamCard(
                          live: live,
                          onTap: () => _joinLive(live),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
