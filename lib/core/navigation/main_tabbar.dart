import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mymink/core/constants/colors.dart';
import 'package:mymink/core/services/notification_service.dart';
import 'package:mymink/features/account/pages/profile_page.dart';
import 'package:mymink/features/camera/pages/camera_page.dart';
import 'package:mymink/features/livestreaming/pages/livestream_home_page.dart';
import 'package:mymink/features/notification/pages/notification_home_page.dart';
import 'package:mymink/features/onboarding/data/models/user_model.dart';
import 'package:mymink/features/onboarding/data/services/user_service.dart';
import 'package:mymink/features/post/pages/home_page.dart';
import 'package:mymink/features/post/pages/reel_page.dart';
import 'package:mymink/features/post/pages/search_page.dart';
import 'package:mymink/gen/assets.gen.dart';

final GlobalKey<MainTabBarState> mainTabKey = GlobalKey<MainTabBarState>();

class MainTabBar extends StatefulWidget {
  const MainTabBar({Key? key}) : super(key: key);

  @override
  MainTabBarState createState() => MainTabBarState();
}

class MainTabBarState extends State<MainTabBar> {
  int _selectedIndex = 0;
  void jumpToTab(int index) => _onItemTapped(index);

  BuildContext getContext() => context;
  int get selectedIndex => _selectedIndex;

  // Keep keys only for places you need to call methods on *before* dispose.
  final GlobalKey<HomePageState> homePageKey = GlobalKey<HomePageState>();

  Future<bool> _isIosSimulator() async {
    if (!Platform.isIOS) return false;
    final info = await DeviceInfoPlugin().iosInfo;
    // false on simulator, true on real device
    return !(info.isPhysicalDevice);
  }

  @override
  void initState() {
    super.initState();
    _initializeNotification();
    _updateNotificationsToken();
  }

  void _initializeNotification() async {
    if (await _isIosSimulator()) return;

    await NotificationService.requestNotificationPermission();
    NotificationService.registerMessageHandlers();
    FirebaseMessaging.instance.getToken().then((token) {
      if (token != null) {
        final userModel = UserModel.instance;
        userModel.notificationToken = token;
        UserService.updateUser(userModel);
      }
    });
  }

  void _updateNotificationsToken() async {
    if (await _isIosSimulator()) return;

    FirebaseMessaging.instance.onTokenRefresh.listen((token) {
      final userModel = UserModel.instance;
      userModel.notificationToken = token;
      UserService.updateUser(userModel);
    });
  }

  void _onItemTapped(int index) {
    // Tapping the same tab: e.g., scroll Home to top
    if (_selectedIndex == index) {
      if (index == 0) homePageKey.currentState?.scrollToTop();
      return;
    }

    // Switch tab: this will remove (dispose) the old page subtree.
    setState(() => _selectedIndex = index);

    // ARRIVING at Camera: a fresh CameraPage will build/init; no resume needed.
  }

  void _hideStatusBar() {
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: [SystemUiOverlay.bottom],
    );
  }

  Widget _buildPage(int index) {
    switch (index) {
      case 0:
        return HomePage(key: homePageKey);
      case 1:
        return const SearchPage();
      case 2:
        return const LivestreamHomePage();
      case 3:
        // Fresh instance each time; the previous one is disposed on tab change.
        return const CameraPage();
      case 4:
        return ReelPage();
      case 5:
        return const NotificationHomePage();
      case 6:
        return ProfilePage();
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    _hideStatusBar();
    return Scaffold(
      // AnimatedSwitcher ensures the previous child is removed (disposed)
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 150),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        // KeyedSubtree with ValueKey forces a brand-new subtree per tab index
        child: KeyedSubtree(
          key: ValueKey(_selectedIndex),
          child: _buildPage(_selectedIndex),
        ),
      ),
      bottomNavigationBar: Theme(
        data: ThemeData(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          showSelectedLabels: false,
          showUnselectedLabels: false,
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed,
          backgroundColor: AppColors.white,
          elevation: 10,
          items: [
            BottomNavigationBarItem(
              label: '',
              icon: Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: _selectedIndex == 0
                    ? Assets.images.home2F.image(height: 26, width: 26)
                    : Assets.images.home1F.image(height: 24, width: 24),
              ),
            ),
            BottomNavigationBarItem(
              label: '',
              icon: Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: _selectedIndex == 1
                    ? Assets.images.magnifyingGlass5
                        .image(height: 23, width: 23)
                    : Assets.images.loupe2.image(height: 22, width: 22),
              ),
            ),
            BottomNavigationBarItem(
              label: '',
              icon: Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: _selectedIndex == 2
                    ? Assets.images.signalStream.image(height: 29, width: 28)
                    : Assets.images.signal.image(height: 29, width: 28),
              ),
            ),
            BottomNavigationBarItem(
              label: '',
              icon: Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: _selectedIndex == 3
                    ? Assets.images.camera2F.image(height: 24, width: 24)
                    : Assets.images.camera1F.image(height: 24, width: 24),
              ),
            ),
            BottomNavigationBarItem(
              label: '',
              icon: Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: _selectedIndex == 4
                    ? Assets.images.videoPlay.image(height: 24, width: 24)
                    : Assets.images.video1F.image(height: 24, width: 24),
              ),
            ),
            BottomNavigationBarItem(
              label: '',
              icon: Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: _selectedIndex == 5
                    ? Assets.images.notification2F.image(height: 24, width: 24)
                    : Assets.images.notification1F.image(height: 24, width: 24),
              ),
            ),
            BottomNavigationBarItem(
              label: '',
              icon: Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: _selectedIndex == 6
                    ? Assets.images.user2F.image(height: 24, width: 24)
                    : Assets.images.user1F.image(height: 24, width: 24),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
