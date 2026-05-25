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

    int? maxCalories;
    if (imc != null && imc >= 25.0) maxCalories = 400;

    final response = await SpoonacularClient.searchRecipes(
      intolerances: intolerances.isNotEmpty ? intolerances : null,
      diet: diet,
      maxCalories: maxCalories,
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
