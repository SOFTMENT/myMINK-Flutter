import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:mymink/core/constants/colors.dart';
import 'package:mymink/core/services/image_service.dart';
import 'package:mymink/core/utils/common_input_decoration.dart';
import 'package:mymink/core/widgets/custom_icon_button.dart';
import 'package:mymink/features/home/widgets/icon_column.dart';
import 'package:mymink/features/onboarding/data/models/user_model.dart';
import 'package:mymink/gen/assets.gen.dart';

class HomePage extends StatelessWidget {
  final userModel = UserModel.instance;

  void _showCustomBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(15),
          topRight: Radius.circular(15),
        ),
      ),
      builder: (BuildContext context) {
        return Container(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Create a Post",
                  style: TextStyle(
                      color: AppColors.textBlack,
                      fontSize: 18,
                      fontWeight: FontWeight.bold),
                ),
                SizedBox(
                  height: 20,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: IconColumn(
                        icon: Assets.images.quote.image(),
                        label: "Text",
                        color: AppColors.textGrey,
                        onTap: () {
                          Navigator.pop(context);
                          print('Text selected');
                        },
                      ),
                    ),
                    SizedBox(
                      width: 10,
                    ),
                    Expanded(
                      child: IconColumn(
                        icon: Assets.images.gallery.image(),
                        label: "Image",
                        color: AppColors.primaryRed,
                        onTap: () {
                          Navigator.pop(context);
                          print('Image selected');
                        },
                      ),
                    ),
                    SizedBox(
                      width: 16,
                    ),
                    Expanded(
                      child: IconColumn(
                        icon: Assets.images.videoPlayWhite.image(),
                        label: "Reel",
                        color: AppColors.textBlack,
                        onTap: () {
                          Navigator.pop(context);
                          print('Reel selected');
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Function to build each icon column

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        clipBehavior: Clip.none,
        children: [
          Assets.images.homebg.image(width: double.infinity),
          Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(25, 25, 8, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Assets.images.logo.image(height: 77, width: 77),
                  Spacer(),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      CustomIconButton(
                          icon: Text(
                            '28.8°C',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: AppColors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold),
                          ),
                          onPressed: () {}),
                      const SizedBox(
                        width: 4,
                      ),
                      CustomIconButton(
                          icon: Assets.images.tablerScan
                              .image(width: 20, height: 20),
                          onPressed: () {}),
                      CustomIconButton(
                          icon: Assets.images.notificationWhite
                              .image(width: 20, height: 20),
                          onPressed: () {}),
                      CustomIconButton(
                          icon: Assets.images.messageWhite
                              .image(width: 20, height: 20),
                          onPressed: () {}),
                      CustomIconButton(
                          icon: Assets.images.addWhite
                              .image(width: 20, height: 20),
                          onPressed: () {
                            _showCustomBottomSheet(context);
                          }),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(25, 25, 25, 0),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome',
                            style:
                                TextStyle(color: AppColors.white, fontSize: 15),
                          ),
                          const SizedBox(
                            height: 3,
                          ),
                          Text(
                            userModel.fullName ?? 'Full Name',
                            style: TextStyle(
                                color: AppColors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      Spacer(),
                      ClipOval(
                        child: (userModel.profilePic == null ||
                                userModel.profilePic!.isEmpty)
                            ? SizedBox(
                                width: 80,
                                height: 80,
                                child: Image.asset(
                                  'assets/images/imageload.gif',
                                  fit: BoxFit.cover,
                                ),
                              )
                            : CachedNetworkImage(
                                imageUrl: ImageService.generateImageUrl(
                                    imagePath: userModel.profilePic!),
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => SizedBox(
                                  width: 80,
                                  height: 80,
                                  child: Image.asset(
                                    'assets/images/imageload.gif',
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                      )
                    ],
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  SizedBox(
                      height: 50,
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              textCapitalization: TextCapitalization.words,
                              autocorrect: false,
                              decoration: buildInputDecoration(
                                  labelText: "Search Posts",
                                  fillColor: Colors.transparent,
                                  prefixColor: AppColors.white,
                                  prefixIcon: Icons.search_outlined),
                            ),
                          ),
                          const SizedBox(
                            width: 8,
                          ),
                          SizedBox(
                              width: 50,
                              height: 50,
                              child: CustomIconButton(
                                  icon: Icon(
                                    Icons.search,
                                    color: AppColors.white,
                                    size: 28,
                                  ),
                                  backgroundColor: AppColors.primaryRed,
                                  onPressed: () {}))
                        ],
                      )),
                ],
              ),
            ),
          ]),
        ],
      ),
    );
  }
}
