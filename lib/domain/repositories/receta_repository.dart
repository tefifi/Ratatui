import '../entities/receta.dart';
import '../entities/padecimiento.dart';

abstract class RecetaRepository {
  Future<List<Receta>> getRecetas({
    required List<Padecimiento> padecimientos,
    double? imc,
    int offset = 0,
  });
  Future<Receta> getRecetaDetalle(int spoonacularId);
}
