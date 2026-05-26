import '../../../domain/entities/padecimiento.dart';
import '../../../domain/entities/receta.dart';
import '../../../domain/repositories/receta_repository.dart';
import '../../utils/spoonacular_client.dart';

class SpoonacularRecetaRepository implements RecetaRepository {
  @override
  Future<List<Receta>> getRecetas({
    required List<Padecimiento> padecimientos,
    double? imc,
    int offset = 0,
  }) async {
    final int? maxCalories = (imc != null && imc >= 25.0) ? 400 : null;

    // ── Parámetros que van como intolerance/diet (una sola llamada) ──────────
    final intolerances = padecimientos
        .map((p) => p.spoonacularIntolerance)
        .whereType<String>()
        .toSet()
        .join(',');

    String? diet;
    final diets = padecimientos
        .map((p) => p.spoonacularDiet)
        .whereType<String>()
        .toSet();
    if (diets.contains('vegan')) {
      diet = 'vegan';
    } else if (diets.contains('vegetarian')) {
      diet = 'vegetarian';
    }

    // ── Padecimientos que usan `query` (uno por término para no mezclarlos) ──
    // Si se combinan en un solo query ("low sugar diabetic low sodium heart healthy")
    // Spoonacular devuelve resultados erráticos o vacíos.
    final queryTerms = padecimientos
        .map((p) => p.spoonacularQuery)
        .whereType<String>()
        .toList();

    // Número de recetas por llamada distribuido equitativamente
    final int totalCalls = queryTerms.isEmpty ? 1 : queryTerms.length;
    final int numberPerCall = (20 / totalCalls).ceil();

    final futures = <Future<List<Receta>>>[];

    if (queryTerms.isEmpty) {
      // Solo intolerances / diet — una sola llamada
      futures.add(_fetchPage(
        intolerances: intolerances.isNotEmpty ? intolerances : null,
        diet: diet,
        query: null,
        maxCalories: maxCalories,
        number: 20,
        offset: offset,
      ));
    } else {
      // Una llamada por cada término de query
      for (final term in queryTerms) {
        futures.add(_fetchPage(
          intolerances: intolerances.isNotEmpty ? intolerances : null,
          diet: diet,
          query: term,
          maxCalories: maxCalories,
          number: numberPerCall,
          offset: offset,
        ));
      }
    }

    final results = await Future.wait(futures);

    // Combinar, deduplicar por id y mezclar para no agrupar por padecimiento
    final seen = <int>{};
    final combined = <Receta>[];
    for (final list in results) {
      for (final r in list) {
        if (seen.add(r.spoonacularId)) combined.add(r);
      }
    }
    combined.shuffle();
    return combined;
  }

  Future<List<Receta>> _fetchPage({
    String? intolerances,
    String? diet,
    String? query,
    int? maxCalories,
    required int number,
    required int offset,
  }) async {
    final response = await SpoonacularClient.searchRecipes(
      intolerances: intolerances,
      diet: diet,
      query: query,
      maxCalories: maxCalories,
      number: number,
      offset: offset,
    );
    final results = response['results'] as List<dynamic>? ?? [];
    return results
        .map((r) => Receta.fromSpoonacularSearch(r as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<Receta> getRecetaDetalle(int spoonacularId) async {
    final data = await SpoonacularClient.getRecipeDetail(spoonacularId);
    return Receta.fromSpoonacularDetail(data);
  }
}