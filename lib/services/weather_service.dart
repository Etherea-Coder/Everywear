import 'dart:math';

/// Service for fetching weather context to inform AI styling suggestions
class WeatherService {
  // TODO: Add real weather API key from env/secrets
  // static const String _apiKey = String.fromEnvironment('WEATHER_API_KEY');
  
  /// Fetches current weather data
  /// In production, this will use an external API like OpenWeatherMap
  Future<Map<String, dynamic>> getCurrentWeather() async {
    try {
      // Logic for real API would go here:
      // final response = await http.get(Uri.parse('https://api.openweathermap.org/data/2.5/weather?q=London&appid=$_apiKey'));
      
      // For now, we use high-quality simulated data to ensure AI context is always available
      return await _getSimulatedWeather();
    } catch (e) {
      // Fallback in case of API failure
      return await _getSimulatedWeather();
    }
  }

  Future<Map<String, dynamic>> _getSimulatedWeather() async {
    await Future.delayed(const Duration(milliseconds: 300));
    
    final conditions = ['Sunny', 'Partly Cloudy', 'Overcast', 'Light Rain', 'Clear'];
    final random = Random();
    
    return {
      'temperature': 18 + random.nextInt(10), // 18-28 °C
      'condition': conditions[random.nextInt(conditions.length)],
      'location': 'Current Location',
      'unit': '°C',
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
}
