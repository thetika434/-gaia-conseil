import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme.dart';
import '../../../data/mock_data.dart';

class DroneDetailScreen extends StatelessWidget {
  final DroneModel drone;
  const DroneDetailScreen({super.key, required this.drone});

  Color _statusColor(DroneStatus s) {
    switch (s) {
      case DroneStatus.online:
        return AppTheme.successGreen;
      case DroneStatus.offline:
        return Colors.grey;
      case DroneStatus.maintenance:
        return AppTheme.warningOrange;
    }
  }

  String _statusLabel(DroneStatus s) {
    switch (s) {
      case DroneStatus.online:
        return 'En ligne';
      case DroneStatus.offline:
        return 'Hors ligne';
      case DroneStatus.maintenance:
        return 'Maintenance';
    }
  }

  Color _batteryColor(int level) {
    if (level > 60) return AppTheme.successGreen;
    if (level > 30) return AppTheme.warningOrange;
    return AppTheme.errorRed;
  }

  String _lastSeenLabel(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Il y a ${diff.inHours}h';
    return 'Il y a ${diff.inDays}j';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightBackground,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: AppTheme.primaryGreen,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                drone.id,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF0D2B1A), Color(0xFF2D6A4F)],
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.flight,
                          size: 56,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: _statusColor(drone.status),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _statusLabel(drone.status),
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Battery section card
                _buildSectionCard(
                  titre: 'Batterie',
                  icon: Icons.battery_full,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Niveau actuel',
                            style: GoogleFonts.poppins(
                              color: Colors.grey[600],
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            '${drone.batteryLevel}%',
                            style: GoogleFonts.poppins(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: _batteryColor(drone.batteryLevel),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: drone.batteryLevel / 100,
                          minHeight: 14,
                          backgroundColor: Colors.grey[200],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _batteryColor(drone.batteryLevel),
                          ),
                        ),
                      ),
                      if (drone.batteryLevel < 20) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(
                              Icons.warning_amber,
                              color: Colors.red,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Batterie critique — recharge urgente',
                              style: GoogleFonts.poppins(
                                color: Colors.red,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // General info card
                _buildSectionCard(
                  titre: 'Informations générales',
                  icon: Icons.info_outline,
                  child: Column(
                    children: [
                      _infoRow('Planteur assigné', drone.ownerName),
                      _infoRow('Modèle', drone.modele ?? 'Non renseigné'),
                      _infoRow('Localisation', drone.location),
                      _infoRow(
                        'Dernière activité',
                        _lastSeenLabel(drone.lastSeen),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Statistics card
                _buildSectionCard(
                  titre: 'Statistiques',
                  icon: Icons.bar_chart,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _statItem('${drone.missionsTotales}', 'Missions totales'),
                      Container(width: 1, height: 50, color: Colors.grey[200]),
                      _statItem(
                        '${drone.surfaceSurveillee.toStringAsFixed(1)} ha',
                        'Surface surveillée',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Admin actions
                Text(
                  'Actions administrateur',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 10),
                _actionButton(
                  label: 'Envoyer en mission',
                  icon: Icons.flight_takeoff,
                  color: AppTheme.primaryGreen,
                  enabled: drone.status == DroneStatus.online,
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Mission lancée pour ${drone.id}'),
                      backgroundColor: AppTheme.primaryGreen,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                _actionButton(
                  label: 'Mettre en maintenance',
                  icon: Icons.build,
                  color: AppTheme.warningOrange,
                  enabled: drone.status != DroneStatus.maintenance,
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${drone.id} mis en maintenance'),
                      backgroundColor: AppTheme.warningOrange,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                _actionButton(
                  label: 'Désactiver le drone',
                  icon: Icons.power_off,
                  color: AppTheme.errorRed,
                  enabled: true,
                  onTap: () => _confirmerDesactivation(context),
                ),
                const SizedBox(height: 32),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String titre,
    required IconData icon,
    required Widget child,
  }) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: AppTheme.primaryGreen),
                const SizedBox(width: 8),
                Text(
                  titre,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryGreen,
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            child,
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryGreen,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[600]),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _actionButton({
    required String label,
    required IconData icon,
    required Color color,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: enabled ? onTap : null,
        icon: Icon(icon, color: Colors.white, size: 20),
        label: Text(
          label,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: enabled ? color : Colors.grey[300],
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: enabled ? 2 : 0,
        ),
      ),
    );
  }

  void _confirmerDesactivation(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          'Confirmer la désactivation',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Voulez-vous vraiment désactiver ${drone.id} ?',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              final navigator = Navigator.of(context);
              final messenger = ScaffoldMessenger.of(context);
              navigator.pop();
              messenger.showSnackBar(
                SnackBar(
                  content: Text('${drone.id} désactivé.'),
                  backgroundColor: AppTheme.primaryGreen,
                ),
              );
              navigator.pop();
            },
            child: const Text(
              'Désactiver',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
