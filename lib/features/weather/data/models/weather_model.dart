// lib/features/weather/data/models/weather_model.dart

import 'dart:convert';

/// Parse from a raw JSON string
WeatherModel weatherModelFromRawJson(String str) =>
    WeatherModel.fromJson(json.decode(str) as Map<String, dynamic>);

/// Convert to a raw JSON string
String weatherModelToRawJson(WeatherModel data) => json.encode(data.toJson());

class WeatherModel {
  final double? lat;
  final double? lon;
  final String? timezone;
  final int? timezoneOffset;
  final Current? current;

  WeatherModel({
    this.lat,
    this.lon,
    this.timezone,
    this.timezoneOffset,
    this.current,
  });

  factory WeatherModel.fromJson(Map<String, dynamic> json) => WeatherModel(
        lat: (json['lat'] as num?)?.toDouble(),
        lon: (json['lon'] as num?)?.toDouble(),
        timezone: json['timezone'] as String?,
        timezoneOffset: json['timezone_offset'] as int?,
        current: json['current'] == null
            ? null
            : Current.fromJson(json['current'] as Map<String, dynamic>),
      );

  Map<String, dynamic> toJson() => {
        'lat': lat,
        'lon': lon,
        'timezone': timezone,
        'timezone_offset': timezoneOffset,
        'current': current?.toJson(),
      };
}

class Current {
  final int? dt;
  final int? sunrise;
  final int? sunset;
  final double? temp;
  final double? feelsLike;
  final int? pressure;
  final int? humidity;
  final double? dewPoint;
  final double? uvi;
  final int? clouds;
  final int? visibility;
  final double? windSpeed;
  final int? windDeg;
  final double? windGust;
  final List<Weather>? weather;

  /// Mutable so you can assign to it later
  String? city;

  Current({
    this.dt,
    this.sunrise,
    this.sunset,
    this.temp,
    this.feelsLike,
    this.pressure,
    this.humidity,
    this.dewPoint,
    this.uvi,
    this.clouds,
    this.visibility,
    this.windSpeed,
    this.windDeg,
    this.windGust,
    this.weather,
    this.city,
  });

  factory Current.fromJson(Map<String, dynamic> json) => Current(
        dt: json['dt'] as int?,
        sunrise: json['sunrise'] as int?,
        sunset: json['sunset'] as int?,
        temp: (json['temp'] as num?)?.toDouble(),
        feelsLike: (json['feels_like'] as num?)?.toDouble(),
        pressure: json['pressure'] as int?,
        humidity: json['humidity'] as int?,
        dewPoint: (json['dew_point'] as num?)?.toDouble(),
        uvi: (json['uvi'] as num?)?.toDouble(),
        clouds: json['clouds'] as int?,
        visibility: json['visibility'] as int?,
        windSpeed: (json['wind_speed'] as num?)?.toDouble(),
        windDeg: json['wind_deg'] as int?,
        windGust: (json['wind_gust'] as num?)?.toDouble(),
        weather: (json['weather'] as List<dynamic>?)
            ?.map((e) => Weather.fromJson(e as Map<String, dynamic>))
            .toList(),
        city: json['city_name'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'dt': dt,
        'sunrise': sunrise,
        'sunset': sunset,
        'temp': temp,
        'feels_like': feelsLike,
        'pressure': pressure,
        'humidity': humidity,
        'dew_point': dewPoint,
        'uvi': uvi,
        'clouds': clouds,
        'visibility': visibility,
        'wind_speed': windSpeed,
        'wind_deg': windDeg,
        'wind_gust': windGust,
        'weather': weather?.map((w) => w.toJson()).toList(),
        'city_name': city,
      };
}

class Weather {
  final int? id;
  final String? main;
  final String? description;
  final String? icon;

  Weather({
    this.id,
    this.main,
    this.description,
    this.icon,
  });

  factory Weather.fromJson(Map<String, dynamic> json) => Weather(
        id: json['id'] as int?,
        main: json['main'] as String?,
        description: json['description'] as String?,
        icon: json['icon'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'main': main,
        'description': description,
        'icon': icon,
      };
}
