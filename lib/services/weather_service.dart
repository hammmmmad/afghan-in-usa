import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/weather_model.dart';
import '../utils/constants.dart';

/// Weather via Open-Meteo: free, keyless, works out of the box.
class WeatherService {
  WeatherService._();

  static final WeatherService instance = WeatherService._();

  Future<List<GeoPlace>> search(String query) async {
    if (query.trim().length < 2) return <GeoPlace>[];
    final Uri uri = Uri.parse(AppConfig.geocodeApi).replace(
      queryParameters: <String, String>{
        'name': query.trim(),
        'count': '8',
        'language': 'en',
        'format': 'json',
      },
    );
    final http.Response res = await http.get(uri);
    if (res.statusCode != 200) {
      throw Exception('geocoding failed (${res.statusCode})');
    }
    final Map<String, dynamic> json =
        jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    final List<dynamic> results =
        (json['results'] ?? const <dynamic>[]) as List<dynamic>;
    return results.map((dynamic e) {
      final Map<String, dynamic> m = e as Map<String, dynamic>;
      return GeoPlace(
        name: (m['name'] ?? '').toString(),
        country: (m['country'] ?? '').toString(),
        latitude: (m['latitude'] as num).toDouble(),
        longitude: (m['longitude'] as num).toDouble(),
      );
    }).toList();
  }

  Future<WeatherModel> forecast({
    required String city,
    required double latitude,
    required double longitude,
  }) async {
    final Uri uri = Uri.parse(AppConfig.forecastApi).replace(
      queryParameters: <String, String>{
        'latitude': latitude.toString(),
        'longitude': longitude.toString(),
        'current':
            'temperature_2m,relative_humidity_2m,wind_speed_10m,weather_code',
        'daily': 'weather_code,temperature_2m_max,temperature_2m_min',
        'timezone': 'auto',
        'forecast_days': '5',
      },
    );
    final http.Response res = await http.get(uri);
    if (res.statusCode != 200) {
      throw Exception('forecast failed (${res.statusCode})');
    }
    final Map<String, dynamic> json =
        jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    final Map<String, dynamic> current =
        (json['current'] ?? <String, dynamic>{}) as Map<String, dynamic>;
    final Map<String, dynamic> daily =
        (json['daily'] ?? <String, dynamic>{}) as Map<String, dynamic>;

    final List<dynamic> days =
        (daily['time'] ?? const <dynamic>[]) as List<dynamic>;
    final List<dynamic> maxTemps =
        (daily['temperature_2m_max'] ?? const <dynamic>[]) as List<dynamic>;
    final List<dynamic> minTemps =
        (daily['temperature_2m_min'] ?? const <dynamic>[]) as List<dynamic>;
    final List<dynamic> codes =
        (daily['weather_code'] ?? const <dynamic>[]) as List<dynamic>;

    final List<WeatherDay> forecastDays = <WeatherDay>[];
    for (int i = 0; i < days.length; i++) {
      forecastDays.add(
        WeatherDay(
          date: DateTime.tryParse(days[i].toString()) ?? DateTime.now(),
          max: i < maxTemps.length ? (maxTemps[i] as num).toDouble() : 0,
          min: i < minTemps.length ? (minTemps[i] as num).toDouble() : 0,
          code: i < codes.length ? (codes[i] as num).toInt() : 0,
        ),
      );
    }

    return WeatherModel(
      city: city,
      temperature: ((current['temperature_2m'] ?? 0) as num).toDouble(),
      humidity: ((current['relative_humidity_2m'] ?? 0) as num).toInt(),
      windSpeed: ((current['wind_speed_10m'] ?? 0) as num).toDouble(),
      code: ((current['weather_code'] ?? 0) as num).toInt(),
      forecast: forecastDays,
    );
  }
}
