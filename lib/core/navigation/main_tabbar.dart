import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mymink/core/constants/colors.dart';
import 'package:mymink/features/home/pages/home_page.dart';

import 'package:mymink/features/onboarding/pages/under_construction_page.dart';
import 'package:mymink/gen/assets.gen.dart';

class MainTabBar extends StatefulWidget {
  @override
  _MainTabBarState createState() => _MainTabBarState();
}

class _MainTabBarState extends State<MainTabBar> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    HomePage(),
    UnderConstructionPage(),
    UnderConstructionPage(),
    UnderConstructionPage(),
    UnderConstructionPage(),
    UnderConstructionPage(),
    UnderConstructionPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
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
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
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
                  ? Assets.images.home2F.image(height: 26, width: 26)
                  : Assets.images.home1F.image(height: 24, width: 24),
            ),
          ),
          BottomNavigationBarItem(
            label: '',
            icon: Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: _selectedIndex == 1
                  ? Assets.images.magnifyingGlass5.image(height: 23, width: 23)
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
    );
  }
}
