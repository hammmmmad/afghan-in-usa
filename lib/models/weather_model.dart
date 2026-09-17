class WeatherDay {
  const WeatherDay({
    required this.date,
    required this.min,
    required this.max,
    required this.code,
  });

  final DateTime date;
  final double min;
  final double max;
  final int code;
}

class WeatherModel {
  const WeatherModel({
    required this.city,
    required this.temperature,
    required this.humidity,
    required this.windSpeed,
    required this.code,
    required this.forecast,
  });

  final String city;
  final double temperature;
  final int humidity;
  final double windSpeed;
  final int code;
  final List<WeatherDay> forecast;
}

class GeoPlace {
  const GeoPlace({
    required this.name,
    required this.country,
    required this.latitude,
    required this.longitude,
  });

  final String name;
  final String country;
  final double latitude;
  final double longitude;

  String get label => country.isEmpty ? name : '$name, $country';
}
