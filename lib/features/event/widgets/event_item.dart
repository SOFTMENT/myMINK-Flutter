import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mymink/core/constants/app_routes.dart';
import 'package:mymink/core/constants/colors.dart';
import 'package:mymink/core/widgets/custom_image.dart';
import 'package:mymink/features/event/data/models/event.dart';
import 'package:mymink/gen/assets.gen.dart';

class EventItem extends StatelessWidget {
  final bool isOrganizer;
  final EventModel event;
  const EventItem({super.key, required this.event, this.isOrganizer = false});

  String formatEventDate(DateTime dt, {String? locale}) {
    final local = dt.toLocal(); // show in device’s local time
    return DateFormat('EEE, MMM d • h:mm a', locale).format(local);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        context.push(AppRoutes.showEventPage, extra: {'event': event});
      },
      child: Container(
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8), color: AppColors.white),
        child: Padding(
          padding: const EdgeInsets.all(4.0),
          child: Stack(
            children: [
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      width: 74,
                      height: 74,
                      child: CustomImage(
                          imageKey: event.eventImages.first,
                          width: 100,
                          height: 100),
                    ),
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        formatEventDate(
                          event.startDate ?? DateTime.now(),
                        ),
                        style: const TextStyle(
                            color: AppColors.primaryRed, fontSize: 13),
                      ),
                      Text(
                        event.title,
                        style: const TextStyle(
                            color: AppColors.textBlack, fontSize: 14),
                      ),
                      Text(
                        event.address,
                        style: const TextStyle(
                            color: AppColors.textGrey, fontSize: 13),
                      ),
                    ],
                  )
                ],
              ),
              Positioned(
                top: 6,
                right: 6,
                child: isOrganizer
                    ? Assets.images.dots2.image(width: 20, height: 20)
                    : Assets.images.share7.image(width: 20, height: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
