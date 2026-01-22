import 'dart:math';

class WeatherService {
  /// Mocks fetching current weather data
  /// In a real app, this would call a weather API (OpenWeather, etc.)
  Future<Map<String, dynamic>> getCurrentWeather() async {
    // Simulating API latency
    await Future.delayed(const Duration(milliseconds: 500));

    final conditions = ['Sunny', 'Cloudy', 'Rainy', 'Windy', 'Snowy'];
    final random = Random();
    
    return {
      'temperature': 15 + random.nextInt(15), // 15-30 °C
      'condition': conditions[random.nextInt(conditions.length)],
      'location': 'Current Location',
      'unit': '°C',
    };
  }
}
