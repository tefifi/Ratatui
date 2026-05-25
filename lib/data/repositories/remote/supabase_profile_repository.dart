import '../../../domain/entities/padecimiento.dart';
import '../../../domain/entities/profile.dart';
import '../../../domain/repositories/profile_repository.dart';
import '../../utils/supabase_client.dart';

class SupabaseProfileRepository implements ProfileRepository {
  @override
  Future<Profile?> getProfile(String userId) async {
    final data = await supabase
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();
    return data == null ? null : Profile.fromMap(data);
  }

  @override
  Future<void> saveProfile(Profile profile) async {
    await supabase.from('profiles').upsert(profile.toMap());
  }

  @override
  Future<List<Padecimiento>> getUserPadecimientos(String userId) async {
    final data = await supabase
        .from('usuario_padecimientos')
        .select('padecimiento_id, padecimientos(id, nombre, label)')
        .eq('usuario_id', userId);

    return (data as List)
        .map((row) =>
            Padecimiento.fromMap(row['padecimientos'] as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> saveUserPadecimientos(
      String userId, List<int> padecimientoIds) async {
    await supabase
        .from('usuario_padecimientos')
        .delete()
        .eq('usuario_id', userId);
    if (padecimientoIds.isEmpty) return;
    await supabase.from('usuario_padecimientos').insert(
          padecimientoIds
              .map((id) => {'usuario_id': userId, 'padecimiento_id': id})
              .toList(),
        );
  }
}
