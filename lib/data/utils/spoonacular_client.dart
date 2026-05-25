import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class SpoonacularClient {
  static const String _baseUrl = 'https://api.spoonacular.com';
  static String get _apiKey => dotenv.env['SPOONACULAR_API_KEY']!;

  static Future<Map<String, dynamic>> searchRecipes({
    String? intolerances,
    String? diet,
    int? maxCalories,
    int number = 20,
    int offset = 0,
  }) async {
    final params = {
      'apiKey': _apiKey,
      'number': number.toString(),
      'offset': offset.toString(),
      'addRecipeNutrition': 'true',
      if (intolerances != null && intolerances.isNotEmpty)
        'intolerances': intolerances,
      if (diet != null) 'diet': diet,
      if (maxCalories != null) 'maxCalories': maxCalories.toString(),
    };

    final uri = Uri.parse('$_baseUrl/recipes/complexSearch')
        .replace(queryParameters: params);
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Spoonacular searchRecipes error: ${response.statusCode}');
  }

  static Future<Map<String, dynamic>> getRecipeDetail(int id) async {
    final uri = Uri.parse(
        '$_baseUrl/recipes/$id/information?apiKey=$_apiKey&includeNutrition=true');
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Spoonacular getRecipeDetail error: ${response.statusCode}');
  }
}
