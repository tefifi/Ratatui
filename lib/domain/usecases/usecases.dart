import '../entities/padecimiento.dart';
import '../entities/profile.dart';
import '../entities/receta.dart';
import '../repositories/favorito_repository.dart';
import '../repositories/padecimiento_repository.dart';
import '../repositories/profile_repository.dart';
import '../repositories/receta_repository.dart';

class GetPadecimientosUseCase {
  final PadecimientoRepository _repo;
  GetPadecimientosUseCase(this._repo);
  Future<List<Padecimiento>> execute() => _repo.getAllPadecimientos();
}

class SaveProfileUseCase {
  final ProfileRepository _repo;
  SaveProfileUseCase(this._repo);
  Future<void> execute({
    required Profile profile,
    required List<int> padecimientoIds,
  }) async {
    await _repo.saveProfile(profile);
    await _repo.saveUserPadecimientos(profile.id, padecimientoIds);
  }
}

class GetRecetasUseCase {
  final RecetaRepository _repo;
  GetRecetasUseCase(this._repo);
  Future<List<Receta>> execute({
    required List<Padecimiento> padecimientos,
    double? imc,
    int offset = 0,
  }) =>
      _repo.getRecetas(padecimientos: padecimientos, imc: imc, offset: offset);
}

class GetRecetaDetalleUseCase {
  final RecetaRepository _repo;
  GetRecetaDetalleUseCase(this._repo);
  Future<Receta> execute(int spoonacularId) =>
      _repo.getRecetaDetalle(spoonacularId);
}

class GetFavoritosUseCase {
  final FavoritoRepository _repo;
  GetFavoritosUseCase(this._repo);
  Future<List<Receta>> execute(String userId) => _repo.getFavoritos(userId);
}

class ToggleFavoritoUseCase {
  final FavoritoRepository _repo;
  ToggleFavoritoUseCase(this._repo);
  Future<bool> execute(String userId, Receta receta) async {
    final yaEsFavorito = await _repo.isFavorito(userId, receta.spoonacularId);
    if (yaEsFavorito) {
      await _repo.removeFavorito(userId, receta.spoonacularId);
      return false;
    } else {
      await _repo.addFavorito(userId, receta);
      return true;
    }
  }
}
