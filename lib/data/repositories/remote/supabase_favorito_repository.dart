import '../../../domain/entities/receta.dart';
import '../../../domain/repositories/favorito_repository.dart';
import '../../utils/supabase_client.dart';

class SupabaseFavoritoRepository implements FavoritoRepository {
  @override
  Future<List<Receta>> getFavoritos(String userId) async {
    final data = await supabase
        .from('favoritos')
        .select()
        .eq('usuario_id', userId)
        .order('created_at', ascending: false);
    return (data as List)
        .map((row) => Receta.fromFavoritoMap(row as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> addFavorito(String userId, Receta receta) async {
    await supabase.from('favoritos').upsert(receta.toFavoritoMap(userId));
  }

  @override
  Future<void> removeFavorito(String userId, int spoonacularId) async {
    await supabase
        .from('favoritos')
        .delete()
        .eq('usuario_id', userId)
        .eq('spoonacular_id', spoonacularId);
  }

  @override
  Future<bool> isFavorito(String userId, int spoonacularId) async {
    final data = await supabase
        .from('favoritos')
        .select('id')
        .eq('usuario_id', userId)
        .eq('spoonacular_id', spoonacularId)
        .maybeSingle();
    return data != null;
  }
}
