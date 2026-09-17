import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/weather_model.dart';
import '../services/storage_service.dart';
import '../services/weather_service.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';

IconData weatherIcon(int code) {
  if (code == 0) return Icons.wb_sunny_rounded;
  if (code <= 2) return Icons.wb_cloudy_rounded;
  if (code == 3) return Icons.cloud_rounded;
  if (code >= 45 && code <= 48) return Icons.foggy;
  if (code >= 51 && code <= 67) return Icons.grain_rounded;
  if (code >= 71 && code <= 77) return Icons.ac_unit_rounded;
  if (code >= 80 && code <= 82) return Icons.beach_access_rounded;
  if (code >= 95) return Icons.thunderstorm_rounded;
  return Icons.wb_cloudy_rounded;
}

class WeatherWidget extends StatefulWidget {
  const WeatherWidget({super.key});

  @override
  State<WeatherWidget> createState() => _WeatherWidgetState();
}

class _WeatherWidgetState extends State<WeatherWidget> {
  final TextEditingController _search = TextEditingController();
  WeatherModel? _weather;
  List<GeoPlace> _places = <GeoPlace>[];
  bool _loading = true;
  bool _searching = false;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _load(
      StorageService.instance.weatherCity,
      StorageService.instance.weatherLat,
      StorageService.instance.weatherLon,
    );
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load(String city, double lat, double lon) async {
    setState(() {
      _loading = true;
      _error = '';
    });
    try {
      final WeatherModel data = await WeatherService.instance
          .forecast(city: city, latitude: lat, longitude: lon);
      if (!mounted) return;
      setState(() {
        _weather = data;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'network';
      });
    }
  }

  Future<void> _searchCity(String query) async {
    setState(() => _searching = true);
    try {
      final List<GeoPlace> results =
          await WeatherService.instance.search(query);
      if (!mounted) return;
      setState(() {
        _places = results;
        _searching = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _places = <GeoPlace>[];
        _searching = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);
    final String lang = l10n.languageCode;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        TextField(
          controller: _search,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: l10n.searchCityHint,
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: _searching
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : IconButton(
                    icon: const Icon(Icons.my_location_rounded),
                    onPressed: () => _load(AppConfig.defaultCity,
                        AppConfig.defaultLat, AppConfig.defaultLon),
                  ),
          ),
          onSubmitted: _searchCity,
          onChanged: (String value) {
            if (value.trim().length >= 3) _searchCity(value);
            if (value.trim().isEmpty) setState(() => _places = <GeoPlace>[]);
          },
        ),
        if (_places.isNotEmpty) ...<Widget>[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _places
                .map((GeoPlace place) => ActionChip(
                      label: Text(place.label),
                      onPressed: () async {
                        await StorageService.instance.setWeatherPlace(
                            place.name, place.latitude, place.longitude);
                        _search.clear();
                        setState(() => _places = <GeoPlace>[]);
                        await _load(
                            place.name, place.latitude, place.longitude);
                      },
                    ))
                .toList(),
          ),
        ],
        const SizedBox(height: 14),
        if (_loading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(22),
              child: CircularProgressIndicator(),
            ),
          )
        else if (_error.isNotEmpty)
          Row(
            children: <Widget>[
              const Icon(Icons.wifi_off_rounded, color: AppColors.inactive),
              const SizedBox(width: 8),
              Expanded(child: Text(l10n.errorNetwork)),
              TextButton(
                onPressed: () => _load(
                  StorageService.instance.weatherCity,
                  StorageService.instance.weatherLat,
                  StorageService.instance.weatherLon,
                ),
                child: Text(l10n.retry),
              ),
            ],
          )
        else if (_weather != null)
          _WeatherBody(
              weather: _weather!, lang: lang, l10n: l10n, theme: theme),
      ],
    );
  }
}

class _WeatherBody extends StatelessWidget {
  const _WeatherBody({
    required this.weather,
    required this.lang,
    required this.l10n,
    required this.theme,
  });

  final WeatherModel weather;
  final String lang;
  final AppLocalizations l10n;
  final ThemeData theme;

  String _num(num value) => Helpers.localizedNumber(lang, value.round());

  String _weekday(DateTime date) {
    const List<List<String>> names = <List<String>>[
      <String>['دوشنبه', 'Mon'],
      <String>['سه‌شنبه', 'Tue'],
      <String>['چهارشنبه', 'Wed'],
      <String>['پنجشنبه', 'Thu'],
      <String>['جمعه', 'Fri'],
      <String>['شنبه', 'Sat'],
      <String>['یکشنبه', 'Sun'],
    ];
    final int index = (date.weekday - 1) % 7;
    return names[index][lang == 'fa' ? 0 : 1];
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[AppColors.primaryDark, AppColors.primaryLight],
            ),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Row(
            children: <Widget>[
              Icon(weatherIcon(weather.code), size: 54, color: Colors.white),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(weather.city,
                        style: theme.textTheme.titleLarge
                            ?.copyWith(color: Colors.white)),
                    const SizedBox(height: 4),
                    Text('${_num(weather.temperature)}°C',
                        style: theme.textTheme.displayLarge
                            ?.copyWith(color: Colors.white)),
                    const SizedBox(height: 6),
                    Text(
                      '${l10n.humidity}: ${_num(weather.humidity)}%   ·   ${l10n.wind}: ${_num(weather.windSpeed)} km/h',
                      style: theme.textTheme.labelSmall
                          ?.copyWith(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Text(l10n.forecast, style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        SizedBox(
          height: 118,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: weather.forecast.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (BuildContext context, int index) {
              final WeatherDay day = weather.forecast[index];
              return Container(
                width: 92,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    Text(_weekday(day.date), style: theme.textTheme.labelSmall),
                    Icon(weatherIcon(day.code),
                        color: theme.colorScheme.primary, size: 26),
                    Text('${_num(day.max)}° / ${_num(day.min)}°',
                        style: theme.textTheme.labelSmall),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
