import 'package:flutter/material.dart';
import 'package:mymink/core/constants/colors.dart';
import 'package:mymink/core/widgets/custom_app_bar.dart';
import 'package:mymink/features/post/data/models/post_model.dart';
import 'package:mymink/features/post/widgets/post_item.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

class UserPostPage extends StatefulWidget {
  final List<PostModel> postModels;

  final int initialIndex;

  UserPostPage(
      {super.key, required this.postModels, required this.initialIndex});

  @override
  State<UserPostPage> createState() => _UserPostPageState();
}

class _UserPostPageState extends State<UserPostPage> {
  final ItemScrollController _scrollController = ItemScrollController();
  bool isFetching = false;
  @override
  void initState() {
    super.initState();
    // Schedule jump after first frame:
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.initialIndex < widget.postModels.length) {
        _scrollController.jumpTo(index: widget.initialIndex);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          CustomAppBar(title: 'Posts'),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25),
              child: ScrollablePositionedList.builder(
                itemCount: widget.postModels.length + (isFetching ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index >= widget.postModels.length) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: 16,
                      ),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  final post = widget.postModels[index];
                  return PostItem(
                    key: ValueKey(post.postID),
                    postModel: post,
                  );
                },
                itemScrollController: _scrollController,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
