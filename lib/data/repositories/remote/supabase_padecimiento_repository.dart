import '../../../domain/entities/padecimiento.dart';
import '../../../domain/repositories/padecimiento_repository.dart';
import '../../utils/supabase_client.dart';

class SupabasePadecimientoRepository implements PadecimientoRepository {
  @override
  Future<List<Padecimiento>> getAllPadecimientos() async {
    final data = await supabase.from('padecimientos').select().order('id');
    return (data as List)
        .map((row) => Padecimiento.fromMap(row as Map<String, dynamic>))
        .toList();
  }
}
