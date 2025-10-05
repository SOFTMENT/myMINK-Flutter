import 'package:flutter_branch_sdk/flutter_branch_sdk.dart';
import 'package:mymink/core/constants/api_constants.dart';
import 'package:mymink/core/services/image_service.dart';
import 'package:mymink/core/utils/result.dart';
import 'package:mymink/features/business/data/models/business_model.dart';
import 'package:mymink/features/event/data/models/event.dart';
import 'package:mymink/features/marketplace/data/models/marketplace_model.dart';
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
        canonicalIdentifier: userModel.username ?? 'username',
        title: userModel.fullName ?? "Name",
        contentDescription: userModel.biography ?? '',
        imageUrl: ImageService.generateImageUrl(
            imagePath: userModel.profilePic ?? ''),
        contentMetadata: BranchContentMetaData()
          ..addCustomMetadata('username', userModel.username ?? 'username')
          ..addCustomMetadata('uid', userModel.uid ?? "123"),
      );

      // Create link properties
      BranchLinkProperties linkProperties = BranchLinkProperties(
        feature: ImageService.generateImageUrl(
            imagePath: userModel.profilePic ?? ''),
        alias: userModel.username ?? 'username',
      );
      linkProperties.addControlParam("\$ios_url",
          "https://itunes.apple.com/us/app/my-MINK/id6448769013?ls=1&mt=8");

      // Generate the short link
      BranchResponse response = await FlutterBranchSdk.getShortUrl(
        buo: buo,
        linkProperties: linkProperties,
      );

      if (response.success) {
        return Result(data: (response.result as String?));
      } else {
        return Result(
            error: 'Failed to create deep link: ${response.errorMessage}');
      }
    } catch (e) {
      return Result(error: e.toString());
    }
  }

  static Future<Result<String?>> createDeepLinkForProduct(
      MarketplaceModel market) async {
    try {
      // Create a BranchUniversalObject
      BranchUniversalObject buo = BranchUniversalObject(
        canonicalIdentifier: market.id,
        title: market.title,
        contentDescription: market.about,
        imageUrl: ImageService.generateImageUrl(
            imagePath: market.productImages.first),
        contentMetadata: BranchContentMetaData()
          ..addCustomMetadata('id', market.id)
          ..addCustomMetadata('uid', market.uid),
      );

      final id = market.id;
      // Create link properties
      BranchLinkProperties linkProperties = BranchLinkProperties(
        feature: ImageService.generateImageUrl(
            imagePath: market.productImages.first),
        alias: 'product/\{$id}',
      );
      linkProperties.addControlParam("\$ios_url",
          "https://itunes.apple.com/us/app/my-MINK/id6448769013?ls=1&mt=8");

      // Generate the short link
      BranchResponse response = await FlutterBranchSdk.getShortUrl(
        buo: buo,
        linkProperties: linkProperties,
      );

      if (response.success) {
        return Result(data: (response.result as String?));
      } else {
        return Result(
            error: 'Failed to create deep link: ${response.errorMessage}');
      }
    } catch (e) {
      return Result(error: e.toString());
    }
  }

  static Future<Result<String?>> createDeepLinkForEvent(
      EventModel evetModel) async {
    try {
      // Create a BranchUniversalObject
      BranchUniversalObject buo = BranchUniversalObject(
        canonicalIdentifier: evetModel.id,
        title: evetModel.title,
        contentDescription: evetModel.description,
        imageUrl: ImageService.generateImageUrl(
            imagePath: evetModel.eventImages.first),
        contentMetadata: BranchContentMetaData()
          ..addCustomMetadata('id', evetModel.id)
          ..addCustomMetadata('uid', evetModel.eventOrganizerUid),
      );

      // Create link properties
      final id = evetModel.id;
      BranchLinkProperties linkProperties = BranchLinkProperties(
        feature: ImageService.generateImageUrl(
            imagePath: evetModel.eventImages.first),
        alias: 'event/\{$id}',
      );
      linkProperties.addControlParam("\$ios_url",
          "https://itunes.apple.com/us/app/my-MINK/id6448769013?ls=1&mt=8");

      // Generate the short link
      BranchResponse response = await FlutterBranchSdk.getShortUrl(
        buo: buo,
        linkProperties: linkProperties,
      );

      if (response.success) {
        return Result(data: (response.result as String?));
      } else {
        return Result(
            error: 'Failed to create deep link: ${response.errorMessage}');
      }
    } catch (e) {
      return Result(error: e.toString());
    }
  }

  static Future<Result<String?>> createDeepLinkForBusiness(
      BusinessModel businessModel) async {
    try {
      final String businessId = businessModel.businessId ?? '123';
      final String imageUrl =
          '${ApiConstants.awsImageBaseURL}/fit-in/400x400/public/${businessModel.profilePicture ?? ""}';

      // Create Branch Universal Object
      BranchUniversalObject buo = BranchUniversalObject(
        canonicalIdentifier: businessId,
        title: businessModel.name ?? '',
        contentDescription: businessModel.aboutBusiness ?? '',
        imageUrl: imageUrl,
        contentMetadata: BranchContentMetaData()
          ..addCustomMetadata('bid', businessId),
      );

      // Create Link Properties
      BranchLinkProperties linkProperties = BranchLinkProperties(
        alias: 'business/$businessId',
        feature: 'business',
        channel: 'app',
      );

      linkProperties.addControlParam("\$ios_url",
          "https://itunes.apple.com/us/app/my-MINK/id6448769013?ls=1&mt=8");

      // Generate short URL
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
