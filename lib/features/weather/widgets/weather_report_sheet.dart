import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mymink/core/constants/colors.dart';
import 'package:mymink/features/weather/data/models/weather_model.dart';

class WeatherDetailSheet extends StatelessWidget {
  final Current current;

  const WeatherDetailSheet({
    Key? key,
    required this.current,
  }) : super(key: key);

  Widget _buildStatCard(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          const BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.textBlack),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label,
                style:
                    const TextStyle(fontSize: 14, color: AppColors.textBlack)),
          ),
          Text(value,
              style: const TextStyle(fontSize: 14, color: AppColors.textGrey)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final feels = current.feelsLike != null
        ? '${current.feelsLike!.toStringAsFixed(0)}°C'
        : '--';

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // little pill indicator
          Container(
            width: 50,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // header row
          Row(
            children: [
              InkWell(
                onTap: () {
                  context.pop();
                },
                child: const Icon(
                  Icons.keyboard_arrow_down,
                  size: 28,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  current.city ?? '',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // feels like
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Feels like',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              feels,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // grid of stats
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 8,
            mainAxisSpacing: 10,
            childAspectRatio: 3.5,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildStatCard(
                Icons.thermostat_outlined,
                'Temperature',
                current.temp != null
                    ? '${current.temp!.toStringAsFixed(1)}°C'
                    : '--',
              ),
              _buildStatCard(
                Icons.air,
                'Wind',
                current.windSpeed != null
                    ? '${current.windSpeed!.toStringAsFixed(1)}/km'
                    : '--',
              ),
              _buildStatCard(
                Icons.water_drop,
                'Humidity',
                current.humidity != null ? '${current.humidity}%' : '--',
              ),
              _buildStatCard(
                Icons.wb_sunny,
                'UV Index',
                current.uvi != null
                    ? '${current.uvi!.toStringAsFixed(1)} / 11'
                    : '--',
              ),
              _buildStatCard(
                Icons.remove_red_eye,
                'Visibility',
                current.visibility != null
                    ? '${(current.visibility! / 1000).toStringAsFixed(1)} km'
                    : '--',
              ),
              _buildStatCard(
                Icons.speed,
                'Pressure',
                current.pressure != null ? '${current.pressure} hPa' : '--',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
