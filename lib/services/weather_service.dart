import 'dart:math';
import 'package:flutter/foundation.dart';

class WeatherService {
  static final WeatherService _singleton = WeatherService._internal();
  factory WeatherService() => _singleton;
  WeatherService._internal();

  Map<String, dynamic>? _cachedWeather;
  DateTime? _cacheTime;
  static const Duration _cacheDuration = Duration(minutes: 30);

  Future<Map<String, dynamic>> getCurrentWeather() async {
    try {
      if (_cachedWeather != null && _cacheTime != null &&
          DateTime.now().difference(_cacheTime!) < _cacheDuration) {
        return _cachedWeather!;
      }

      return await _getSimulatedWeather();
    } catch (e) {
      return await _getSimulatedWeather();
    }
  }

  Future<Map<String, dynamic>> _getSimulatedWeather() async {
    await Future.delayed(const Duration(milliseconds: 100));

    final conditions = ['Sunny', 'Partly Cloudy', 'Overcast', 'Light Rain', 'Clear'];
    final random = Random();

    final tempC = 18 + random.nextInt(10);
    final tempF = (tempC * 9 / 5 + 32).round();

    final result = {
      'temperature': tempF,
      'temperature_celsius': tempC,
      'condition': conditions[random.nextInt(conditions.length)],
      'location': 'Current Location',
      'unit': '°F',
      'unit_celsius': '°C',
      'timestamp': DateTime.now().toIso8601String(),
    };

    _cachedWeather = result;
    _cacheTime = DateTime.now();

    debugPrint('Weather: ${result['temperature']}°F / ${result['temperature_celsius']}°C - ${result['condition']}');
    return result;
  }
}
