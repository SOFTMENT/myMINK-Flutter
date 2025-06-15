import 'package:flutter_branch_sdk/flutter_branch_sdk.dart';
import 'package:mymink/core/constants/api_constants.dart';
import 'package:mymink/core/utils/result.dart';
import 'package:mymink/features/post/data/models/post_model.dart';

import 'package:mymink/features/onboarding/data/models/user_model.dart';

class DeepLinkService {
  static Future<Result<String?>> createDeepLinkForPost(
      PostModel postModel) async {
    try {
      // Create a BranchUniversalObject
      BranchUniversalObject buo = BranchUniversalObject(
        canonicalIdentifier: postModel.postID ?? "123",
        title: "my MINK", // Title for your post
        contentDescription: postModel.caption ?? "",
        imageUrl: postModel.postType == "image"
            ? '${ApiConstants.awsImageBaseURL}/fit-in/400x400/public/${postModel.postImages?.first ?? ""}'
            : (postModel.postType == "video"
                ? '${ApiConstants.awsImageBaseURL}/fit-in/400x400/public/${postModel.videoImage ?? ""}'
                : ''),
        contentMetadata: BranchContentMetaData()
          ..addCustomMetadata('postID', postModel.postID ?? "123")
          ..addCustomMetadata('uid', postModel.uid ?? "123"),
      );

      // Create link properties
      BranchLinkProperties linkProperties = BranchLinkProperties(
        feature: 'post', // Feature for your link
        alias: postModel.postType == "image"
            ? "image/${postModel.postID ?? "123"}"
            : "video/${postModel.postID ?? "123"}",
      );
      linkProperties.addControlParam("\$ios_url",
          "https://itunes.apple.com/us/app/my-MINK/id6448769013?ls=1&mt=8");

      // Generate the short link
      BranchResponse response = await FlutterBranchSdk.getShortUrl(
        buo: buo,
        linkProperties: linkProperties,
      );

      if (response.success) {
        return Result(data: response.result);
      } else {
        throw Exception('Failed to create deep link: ${response.errorMessage}');
      }
    } catch (e) {
      return Result(error: e.toString());
    }
  }

  static Future<Result<String?>> createDeepLinkForUserProfile(
      UserModel userModel) async {
    try {
      // Create a BranchUniversalObject
      BranchUniversalObject buo = BranchUniversalObject(
        canonicalIdentifier: 'softment121',
        title: userModel.fullName ?? "Full Name",
        contentDescription: userModel.biography ?? '',
        imageUrl:
            '${ApiConstants.awsImageBaseURL}/public/${userModel.profilePic ?? ""}',
        contentMetadata: BranchContentMetaData()
          ..addCustomMetadata('username', 'softment121')
          ..addCustomMetadata('uid', userModel.uid ?? "123"),
      );

      // Create link properties
      BranchLinkProperties linkProperties = BranchLinkProperties(
        feature: 'user_profile',
        alias: 'softment121',
      );
      linkProperties.addControlParam("\$ios_url",
          "https://itunes.apple.com/us/app/my-MINK/id6448769013?ls=1&mt=8");

      // Generate the short link
      BranchResponse response = await FlutterBranchSdk.getShortUrl(
        buo: buo,
        linkProperties: linkProperties,
      );

      if (response.success) {
        return Result(data: response.result);
      } else {
        throw Exception('Failed to create deep link: ${response.errorMessage}');
      }
    } catch (e) {
      return Result(error: e.toString());
    }
  }
}
