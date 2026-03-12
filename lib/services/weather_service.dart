import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

/// Service for fetching weather context to inform AI styling suggestions
class WeatherService {
  // Open-Meteo is a free API that doesn't require an API key
  static const String _baseUrl = 'https://api.open-meteo.com/v1/forecast';

  // Default fallback coordinates (San Francisco)
  double _latitude = 37.7749;
  double _longitude = -122.4194;
  String _locationName = 'San Francisco, CA';
  bool _isUsingDeviceLocation = true;

  /// Get current location name
  String get locationName => _locationName;

  /// Check if using device location
  bool get isUsingDeviceLocation => _isUsingDeviceLocation;

  /// Check if location services are enabled
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Request location permission
  Future<LocationPermission> requestPermission() async {
    return await Geolocator.requestPermission();
  }

  /// Check current permission status
  Future<LocationPermission> checkPermission() async {
    return await Geolocator.checkPermission();
  }

  /// Update the location for weather queries (manual override)
  void setLocation(double latitude, double longitude, {String? locationName}) {
    _latitude = latitude;
    _longitude = longitude;
    _locationName = locationName ?? 'Manual Location';
    _isUsingDeviceLocation = false;
  }

  /// Get device's current position
  Future<Position?> _getDevicePosition() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return null;
      }

      // Check permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return null;
      }

      // Get current position
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 10),
        ),
      );
    } catch (e) {
      return null;
    }
  }

  /// Fetches current weather data from Open-Meteo API
  Future<Map<String, dynamic>> getCurrentWeather() async {
    // Try to get device location
    Position? position = await _getDevicePosition();

    if (position != null) {
      _latitude = position.latitude;
      _longitude = position.longitude;
      _locationName = 'Current Location';
      _isUsingDeviceLocation = true;
    } else {
      // Use default location if device location unavailable
      _isUsingDeviceLocation = false;
    }

    try {
      final uri = Uri.parse(
        '$_baseUrl?latitude=$_latitude&longitude=$_longitude&current=temperature_2m,weather_code,is_day&temperature_unit=celsius',
      );

      final response = await http.get(uri).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Weather API timeout');
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return _parseWeatherResponse(data);
      } else {
        // Fallback to simulated data on API error
        return await _getSimulatedWeather();
      }
    } catch (e) {
      // Fallback in case of any error
      return await _getSimulatedWeather();
    }
  }

  /// Parse the Open-Meteo API response into our app's format
  Map<String, dynamic> _parseWeatherResponse(Map<String, dynamic> data) {
    final current = data['current'] as Map<String, dynamic>;
    final temperature = (current['temperature_2m'] as num).toInt();
    final weatherCode = current['weather_code'] as int;
    final isDay = current['is_day'] as int;

    return {
      'temperature': temperature,
      'condition': _getConditionFromCode(weatherCode),
      'icon': _getIconFromCode(weatherCode, isDay == 1),
      'location': _locationName,
      'unit': '°C',
      'timestamp': DateTime.now().toIso8601String(),
      'latitude': _latitude,
      'longitude': _longitude,
    };
  }

  /// Convert WMO weather code to condition string
  String _getConditionFromCode(int code) {
    switch (code) {
      case 0:
        return 'Clear';
      case 1:
      case 2:
      case 3:
        return 'Partly Cloudy';
      case 45:
      case 48:
        return 'Foggy';
      case 51:
      case 53:
      case 55:
        return 'Drizzle';
      case 61:
      case 63:
      case 65:
        return 'Rain';
      case 66:
      case 67:
        return 'Freezing Rain';
      case 71:
      case 73:
      case 75:
        return 'Snow';
      case 77:
        return 'Snow Grains';
      case 80:
      case 81:
      case 82:
        return 'Rain Showers';
      case 85:
      case 86:
        return 'Snow Showers';
      case 95:
        return 'Thunderstorm';
      case 96:
      case 99:
        return 'Thunderstorm with Hail';
      default:
        return 'Unknown';
    }
  }

  /// Get appropriate icon name based on weather code and time of day
  String _getIconFromCode(int code, bool isDay) {
    switch (code) {
      case 0:
        return isDay ? 'sunny' : 'clear_night';
      case 1:
      case 2:
      case 3:
        return isDay ? 'partly_cloudy_day' : 'partly_cloudy_night';
      case 45:
      case 48:
        return 'foggy';
      case 51:
      case 53:
      case 55:
      case 61:
      case 63:
      case 65:
      case 66:
      case 67:
      case 80:
      case 81:
      case 82:
        return 'rainy';
      case 71:
      case 73:
      case 75:
      case 77:
      case 85:
      case 86:
        return 'ac_unit';
      case 95:
      case 96:
      case 99:
        return 'thunderstorm';
      default:
        return 'cloud';
    }
  }

  /// Fallback simulated weather data
  Future<Map<String, dynamic>> _getSimulatedWeather() async {
    await Future.delayed(const Duration(milliseconds: 300));

    final conditions = ['Sunny', 'Partly Cloudy', 'Overcast', 'Light Rain', 'Clear'];
    final icons = ['sunny', 'partly_cloudy_day', 'cloud', 'rainy', 'clear_night'];
    final now = DateTime.now();

    // Use time-based pseudo-random selection
    final index = (now.hour + now.minute) % conditions.length;

    return {
      'temperature': 18 + (now.minute % 12), // 18-29°C range
      'condition': conditions[index],
      'icon': icons[index],
      'location': _locationName,
      'unit': '°C',
      'timestamp': now.toIso8601String(),
    };
  }
}
