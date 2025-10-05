import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:material_symbols_icons/symbols.dart';
import 'package:mymink/core/constants/app_routes.dart';
import 'package:mymink/features/account/widgets/feature_item.dart';

class FeaturesList extends StatelessWidget {
  final List<IconData> icons = [
    Symbols.calendar_month,
    Symbols.storefront,
    Symbols.shopping_bag,
    Symbols.list_alt,
    Symbols.currency_bitcoin,
    Symbols.smart_toy,
    Symbols.queue_music,
    Symbols.award_star,
    Symbols.book_5,
    Symbols.forum,
    Symbols.group
  ];

  final List<String> labels = [
    'Friends or Events',
    'Market',
    'Business Promotion',
    'To Do',
    'Cryptocurrency',
    'my MINK Chatbot',
    'Music',
    'Daily Horoscope',
    'Library',
    'Global Chat',
    'Discussion Forum',
  ];
  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      padding: const EdgeInsets.all(0),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: icons.length, // Total items in the list
      itemBuilder: (context, index) {
        return FeatureItem(
            iconData: icons[index],
            label: labels[index],
            onTap: () {
              switch (index) {
                case 0:
                  context.push(AppRoutes.eventHomePage);
                  break;
                case 1:
                  // Handle Market tap
                  context.push(AppRoutes.marketplaceHomePage);
                  break;
                case 2:
                  // Handle Business Promotion tap
                  context.push(AppRoutes.businessHomePage);
                  break;
                case 3:
                  // Handle To Do tap
                  context.push(AppRoutes.todoHomePage);
                  break;
                case 4:
                  // Handle Cryptocurrency tap
                  context.push(AppRoutes.cryptocurrencyPage);
                  break;
                case 5:
                  // Handle my MINK Chatbot tap

                  context.push(AppRoutes.chatbBotPage);
                  break;

                case 6:
                  // Handle Music tap
                  context.push(AppRoutes.musicHomePage);

                  break;
                case 7:
                  // Handle Daily Horoscope tap
                  context.push(AppRoutes.dailyHoroscopePage);
                  break;
                case 8:
                  // Handle Library tap
                  context.push(AppRoutes.libraryHomePage);
                  break;
                case 9:
                  // Handle Discussion tap
                  context.push(AppRoutes.globalChatPage);
                  break;
                case 10:
                  // Handle Discussion tap
                  context.push(AppRoutes.discussionForumPage);
                  break;
              }
            });
      },
      separatorBuilder: (context, index) {
        return const SizedBox(height: 10); // 10 pixels of space between items
      },
    );
  }
}
