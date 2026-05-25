import '../entities/profile.dart';
import '../entities/padecimiento.dart';

abstract class ProfileRepository {
  Future<Profile?> getProfile(String userId);
  Future<void> saveProfile(Profile profile);
  Future<List<Padecimiento>> getUserPadecimientos(String userId);
  Future<void> saveUserPadecimientos(String userId, List<int> padecimientoIds);
}
