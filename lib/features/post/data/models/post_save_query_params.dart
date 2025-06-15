class PostSaveQueryParams {
  final String postId;
  final String currentUserUid;
  const PostSaveQueryParams(
      {required this.postId, required this.currentUserUid});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PostSaveQueryParams &&
          runtimeType == other.runtimeType &&
          postId == other.postId &&
          currentUserUid == other.currentUserUid;

  @override
  int get hashCode => postId.hashCode ^ currentUserUid.hashCode;
}
