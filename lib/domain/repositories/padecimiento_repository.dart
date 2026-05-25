import '../entities/padecimiento.dart';

abstract class PadecimientoRepository {
  Future<List<Padecimiento>> getAllPadecimientos();
}
