import '../entities/receta.dart';

abstract class FavoritoRepository {
  Future<List<Receta>> getFavoritos(String userId);
  Future<void> addFavorito(String userId, Receta receta);
  Future<void> removeFavorito(String userId, int spoonacularId);
  Future<bool> isFavorito(String userId, int spoonacularId);
}
