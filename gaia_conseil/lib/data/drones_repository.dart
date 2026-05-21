import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import 'auth_state.dart';
import 'mock_data.dart';

class DronesRepository {
  static final _client = Supabase.instance.client;

  /// Admins receive the full global fleet (no filter).
  /// Planters receive only the drones assigned to their own UUID.
  /// Rows are created by the DB trigger on public.profiles — no client inserts.
  static Stream<List<DroneModel>> watchAllDrones() {
    final userId = _client.auth.currentUser?.id;
    final base   = _client.from('drones').stream(primaryKey: ['id']);
    final scoped = (userId != null && !AuthState.isAdmin)
        ? base.eq('assigned_to', userId)
        : base;
    return scoped
        .order('id')
        .map((rows) => rows.map(DroneModel.fromRow).toList());
  }
}
