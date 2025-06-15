import 'package:flutter/material.dart';
import 'package:mymink/features/post/data/models/post_model.dart';
import 'package:mymink/features/post/widgets/post_item.dart';

class PostList extends StatefulWidget {
  final List<PostModel> postModels;
  final Widget? header;
  final ScrollController? controller;

  const PostList({
    Key? key,
    required this.postModels,
    this.header,
    this.controller,
  }) : super(key: key);

  @override
  State<PostList> createState() => _PostListState();
}

class _PostListState extends State<PostList> {
  @override
  Widget build(BuildContext context) {
    print(widget.postModels.length);
    return ListView.builder(
      controller: widget.controller,
      physics: const ClampingScrollPhysics(),
      shrinkWrap: true,
      padding: const EdgeInsets.all(0),
      itemCount: widget.postModels.length + (widget.header != null ? 1 : 0),
      itemBuilder: (context, index) {
        // If header exists, show it at index 0.
        if (widget.header != null && index == 0) {
          return widget.header!;
        }
        // Adjust index if header is present.
        final postIndex = widget.header != null ? index - 1 : index;
        final postModel = widget.postModels[postIndex];

        return PostItem(key: ValueKey(postModel.postID), postModel: postModel);
      },
    );
  }
}
