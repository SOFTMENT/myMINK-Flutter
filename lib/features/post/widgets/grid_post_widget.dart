import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:mymink/core/constants/account_type.dart';
import 'package:mymink/core/constants/colors.dart';
import 'package:mymink/core/utils/common_input_decoration.dart';
import 'package:mymink/core/widgets/custom_icon_button.dart';

import 'package:mymink/features/post/data/models/post_model.dart';
import 'package:mymink/features/post/data/services/post_service.dart';
import 'package:mymink/features/post/widgets/create_post_sheet_content.dart';
import 'package:mymink/features/post/widgets/grid_post_list.dart';

class GridPostWidget extends ConsumerStatefulWidget {
  final String uid;
  final ScrollController controller;
  final AccountType accountType;
  final bool isMyAccount;
  const GridPostWidget(
      {Key? key,
      required this.uid,
      required this.controller,
      this.isMyAccount = false,
      this.accountType = AccountType.user})
      : super(key: key);

  @override
  _GridPostWidgetState createState() => _GridPostWidgetState();
}

class _GridPostWidgetState extends ConsumerState<GridPostWidget> {
  List<PostModel> posts = [];
  bool isLoading = false;
  bool hasMore = true;
  DocumentSnapshot? lastDoc;
  final int pageSize = 9; // number of posts per fetch

  @override
  void initState() {
    super.initState();

    widget.controller.addListener(_scrollListener);

    _fetchPosts();
  }

  void _scrollListener() {
    if (widget.controller.position.pixels >=
            widget.controller.position.maxScrollExtent - 200 &&
        !isLoading &&
        hasMore &&
        lastDoc != null) {
      _fetchPosts();
    }
  }

  Future<void> _fetchPosts() async {
    if (isLoading || !hasMore) return;

    setState(() {
      isLoading = true;
    });

    final result = await PostService.getPostsPaginated(
      pageSize: pageSize,
      lastDoc: lastDoc,
      accountType: widget.accountType,
      uid: widget.uid,
    );

    if (result.hasData && result.data != null) {
      final newPosts = result.data!.posts;

      lastDoc = result.data!.lastDocument;

      if (newPosts.length < pageSize) {
        hasMore = false;
      }

      posts.addAll(newPosts);
    } else {
      hasMore = false;
    }
    if (!mounted) return;
    setState(() {
      isLoading = false;
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<PostModel?>(PostService.newPostProvider, (previous, next) {
      if (next != null && (next.bid == null || next.bid!.isEmpty)) {
        setState(() {
          posts.insert(0, next);
        });
      }
    });

    return Column(
      children: [
        // Header Row
        Row(
          children: [
            const Text(
              'Posts',
              style: TextStyle(
                color: AppColors.textBlack,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            Text(
              '${posts.length} ${posts.length <= 1 ? 'Post' : 'Posts'}',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textDarkGrey,
              ),
            ),
            if (widget.isMyAccount) const SizedBox(width: 8),
            // Add button
            if (widget.isMyAccount)
              GestureDetector(
                onTap: () {
                  showCreatePostSheet(
                      context: context,
                      businessId: AccountType.business == widget.accountType
                          ? widget.uid
                          : null);
                },
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 0, 0, 0)
                        .withValues(alpha: 0.77),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Icon(
                      Symbols.add,
                      size: 24,
                      color: AppColors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        // Search Field and Filter Button
        SizedBox(
          height: 42,
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  textCapitalization: TextCapitalization.words,
                  autocorrect: false,
                  maxLines: 1,
                  minLines: 1,
                  textAlignVertical: TextAlignVertical.center,
                  style:
                      const TextStyle(color: AppColors.textBlack, fontSize: 13),
                  decoration: buildInputDecoration(
                    labelText: "Search",
                    isWhiteOrder: false,
                    fillColor: Colors.white,
                    prefixColor: AppColors.primaryRed,
                    focusedBorderColor: AppColors.primaryRed.withAlpha(180),
                    prefixIcon: Icons.search_outlined,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              SizedBox(
                width: 42,
                height: 42,
                child: CustomIconButton(
                  icon: const Align(
                    alignment: Alignment.center,
                    child: Icon(
                      Symbols.filter_list,
                      color: AppColors.white,
                      size: 25,
                    ),
                  ),
                  backgroundColor: AppColors.primaryRed,
                  onPressed: () {},
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Pass posts and scrollController to GridPostList without using Expanded.
        GridPostList(
          posts: posts,
          hasMore: hasMore,
        ),
        const SizedBox(height: 20),
        if (posts.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 50),
            child: Text(
              'No posts available',
              style: TextStyle(color: AppColors.textGrey),
            ),
          ),
      ],
    );
  }
}
