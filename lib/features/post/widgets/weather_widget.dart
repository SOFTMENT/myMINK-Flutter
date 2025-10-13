// lib/features/weather/widgets/weather_widget.dart

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:mymink/core/constants/api_constants.dart';
import 'package:mymink/core/widgets/custom_dialog.dart';
import 'package:mymink/core/widgets/custom_icon_button.dart';
import 'package:mymink/features/weather/data/models/weather_model.dart';
import 'package:mymink/features/weather/widgets/weather_report_sheet.dart';

class WeatherWidget extends StatefulWidget {
  const WeatherWidget({Key? key}) : super(key: key);

  @override
  _WeatherWidgetState createState() => _WeatherWidgetState();
}

class _WeatherWidgetState extends State<WeatherWidget>
    with WidgetsBindingObserver {
  WeatherModel? _weather;
  bool _loading = true;
  bool _error = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadWeather();
    // Refresh every 30 minutes
    _timer = Timer.periodic(const Duration(minutes: 30), (_) => _loadWeather());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // user returned from settings or background
      _loadWeather();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadWeather() async {
    setState(() {
      _loading = true;
      _error = false;
    });

    try {
      // 1) Permission
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        throw Exception('Location permission denied');
      }

      // 2) Position
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      final apiKey = ApiConstants.openWeatherApiKey;

      // 3) Reverse geocode for city name
      final geoUrl = Uri.parse(
        'https://api.openweathermap.org/geo/1.0/reverse'
        '?lat=${pos.latitude}&lon=${pos.longitude}'
        '&limit=1&appid=$apiKey',
      );
      final geoResp = await http.get(geoUrl);
      final geoJson = json.decode(geoResp.body) as List<dynamic>;
      final cityName = geoJson.isNotEmpty ? geoJson[0]['name'] as String : null;

      // 4) One Call
      final oneCallUrl = Uri.parse(
        'https://api.openweathermap.org/data/3.0/onecall'
        '?lat=${pos.latitude}&lon=${pos.longitude}'
        '&units=metric&exclude=minutely,hourly,daily'
        '&appid=$apiKey',
      );
      final oneResp = await http.get(oneCallUrl);
      final model = weatherModelFromRawJson(oneResp.body);
      model.current?.city = cityName;

      setState(() {
        _weather = model;
        _loading = false;
      });
    } catch (_) {
      setState(() {
        _error = true;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const SizedBox(
        width: 44,
        height: 44,
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    if (_error || _weather?.current?.temp == null) {
      return CustomIconButton(
        width: 44,
        icon: const Icon(Icons.cloud_off, color: Colors.white, size: 18),
        onPressed: () async {
          // 1) check current permission
          var perm = await Geolocator.checkPermission();
          if (perm == LocationPermission.denied) {
            // 2) prompt again
            perm = await Geolocator.requestPermission();
            if (perm == LocationPermission.whileInUse ||
                perm == LocationPermission.always) {
              // if granted, reload
              _loadWeather();
            }
          } else {
            // Permanently denied or restricted → show dialog then go to settings
            const title = 'Enable Location';
            const message =
                'To show local weather, please enable location permission in your device settings.';
            await CustomDialog.show(context, title: title, message: message);

            // After the dialog, open the app settings
            await Geolocator.openAppSettings();
          }
        },
      );
    }

    final temp = _weather!.current!.temp!;
    return CustomIconButton(
      width: 44,
      icon: Text(
        '${temp.toStringAsFixed(1)}°C',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      onPressed: () => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => WeatherDetailSheet(current: _weather!.current!),
      ),
    );
  }
}
