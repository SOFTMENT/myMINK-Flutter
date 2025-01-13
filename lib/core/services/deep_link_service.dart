import 'package:flutter_branch_sdk/flutter_branch_sdk.dart';
import 'package:mymink/core/constants/api_constants.dart';
import 'package:mymink/core/utils/result.dart';

import 'package:mymink/features/onboarding/data/models/user_model.dart';

class DeepLinkService {
  static Future<Result<String?>> createDeepLinkForUserProfile(
      UserModel userModel) async {
    try {
      // Create a BranchUniversalObject
      BranchUniversalObject buo = BranchUniversalObject(
        canonicalIdentifier: userModel.username ?? "123",
        title: userModel.fullName ?? "Full Name",
        contentDescription: userModel.biography ?? '',
        imageUrl:
            '${ApiConstants.awsImageBaseURL}/public/${userModel.profilePic ?? ""}',
        contentMetadata: BranchContentMetaData()
          ..addCustomMetadata('username', userModel.username ?? "123")
          ..addCustomMetadata('uid', userModel.uid ?? "123"),
      );

      // Create link properties
      BranchLinkProperties linkProperties = BranchLinkProperties(
        feature: 'user_profile',
        alias: userModel.username ?? "123",
      );
      linkProperties.addControlParam("\$ios_url",
          "https://itunes.apple.com/us/app/my-MINK/id6448769013?ls=1&mt=8");

      // Generate the short link
      BranchResponse response = await FlutterBranchSdk.getShortUrl(
        buo: buo,
        linkProperties: linkProperties,
      );

      if (response.success) {
        print(response.result);
        return Result(data: response.result);
      } else {
        throw Exception('Failed to create deep link: ${response.errorMessage}');
      }
    } catch (e) {
      return Result(error: e.toString());
    }
  }
}
