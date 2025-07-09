import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mymink/core/constants/colors.dart';
import 'package:mymink/core/services/notification_service.dart';

import 'package:mymink/features/account/pages/profile_page.dart';
import 'package:mymink/features/onboarding/data/models/user_model.dart';
import 'package:mymink/features/onboarding/data/services/user_service.dart';
import 'package:mymink/features/post/pages/home_page.dart';

import 'package:mymink/features/onboarding/pages/under_construction_page.dart';
import 'package:mymink/features/post/pages/reel_page.dart';
import 'package:mymink/features/post/pages/search_page.dart';
import 'package:mymink/gen/assets.gen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MainTabBar extends StatefulWidget {
  @override
  _MainTabBarState createState() => _MainTabBarState();
}

class _MainTabBarState extends State<MainTabBar> {
  int _selectedIndex = 0;
  final GlobalKey<HomePageState> homePageKey = GlobalKey<HomePageState>();

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();

    _initializeNotification();
    _updateNotificationsToken();

    _pages = [
      HomePage(key: homePageKey),
      const SearchPage(),
      UnderConstructionPage(),
      UnderConstructionPage(),
      ReelPage(),
      UnderConstructionPage(),
      ProfilePage(),
    ];
  }

  void _initializeNotification() async {
    await NotificationService.requestNotificationPermission();

    NotificationService.registerMessageHandlers();

    // OPTIONAL: Store token in Firestore under logged-in user
    FirebaseMessaging.instance.getToken().then((fcmToken) {
      if (fcmToken != null) {
        final userModel = UserModel.instance;

        userModel.notificationToken = fcmToken;
        UserService.updateUser(userModel);
      }
    });
  }

  void _updateNotificationsToken() async {
    FirebaseMessaging.instance.onTokenRefresh.listen((fcmToken) async {
      final userModel = UserModel.instance;
      userModel.notificationToken = fcmToken;
      UserService.updateUser(userModel);
    });
  }

  void _onItemTapped(int index) {
    if (_selectedIndex == index) {
      if (index == 0) {
        homePageKey.currentState?.scrollToTop();
      }
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  void hideStatusBar() {
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: [SystemUiOverlay.bottom], // Hides the top (status bar) only
    );
  }

  @override
  Widget build(BuildContext context) {
    hideStatusBar();
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
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
          items: [
            BottomNavigationBarItem(
              label: '',
              icon: Padding(
                padding: const EdgeInsets.only(
                  top: 8.0,
                ),
                child: _selectedIndex == 0
                    ? Assets.images.home2F.image(
                        height: 26,
                        width: 26,
                      )
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
          type: BottomNavigationBarType.fixed,
          backgroundColor: AppColors.white,
          elevation: 10,
        ),
      ),
    );
  }
}
