import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:mymink/core/constants/app_routes.dart';
import 'package:mymink/core/constants/colors.dart';

class HoroscopeItem extends StatelessWidget {
  HoroscopeItem(
      {super.key,
      required this.imagePath,
      required this.label,
      required this.height,
      required this.result});
  final String imagePath;
  final String label;
  final double height;
  final String result;
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          context.push(AppRoutes.horoscopeViewPage, extra: {
            'horoscope': label,
            'result': result,
          });
        },
        child: SizedBox(
          height: 138,
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              Image.asset(
                imagePath,
                height: height,
              ),
              const Spacer(),
              Text(
                label.toUpperCase(),
                style:
                    const TextStyle(fontSize: 14, color: AppColors.textBlack),
              )
            ],
          ),
        ),
      ),
    );
  }
}
