import 'package:supabase_flutter/supabase_flutter.dart';
import 'mock_data.dart';

class ProfilesRepository {
  ProfilesRepository._();

  static final _client = Supabase.instance.client;

  /// Stream de tous les profils avec rôle 'planteur', triés par date d'inscription.
  static Stream<List<AdminUser>> watchPlanteurs() {
    return _client
        .from('profiles')
        .stream(primaryKey: ['id'])
        .eq('role', 'planteur')
        .order('created_at')
        .map((rows) => rows.map(AdminUser.fromRow).toList());
  }

  /// Met à jour l'état de bannissement d'un profil.
  static Future<void> updateBanStatus(String userId, bool isBanned) {
    return _client
        .from('profiles')
        .update({'is_banned': isBanned})
        .eq('id', userId);
  }

  /// Supprime un profil (la ligne auth.users est conservée mais orpheline).
  static Future<void> deleteProfile(String userId) {
    return _client.from('profiles').delete().eq('id', userId);
  }
}
