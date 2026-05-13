import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme.dart';
import '../../../data/mock_data.dart';

class DronesScreen extends StatelessWidget {
  const DronesScreen({super.key});

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
    final online =
        mockDrones.where((d) => d.status == DroneStatus.online).length;
    final offline =
        mockDrones.where((d) => d.status == DroneStatus.offline).length;
    final maintenance =
        mockDrones.where((d) => d.status == DroneStatus.maintenance).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Summary bar ──────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Text(
            'Flotte de Drones',
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryGreen,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
          child: Wrap(
            spacing: 8,
            children: [
              _StatusChip(
                  count: online,
                  label: 'En ligne',
                  color: AppTheme.successGreen),
              _StatusChip(
                  count: offline, label: 'Hors ligne', color: Colors.grey),
              _StatusChip(
                  count: maintenance,
                  label: 'Maintenance',
                  color: AppTheme.warningOrange),
            ],
          ),
        ),
        // ── Drone list ───────────────────────────────────────────────
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            itemCount: mockDrones.length,
            itemBuilder: (_, i) {
              final drone = mockDrones[i];
              final sc = _statusColor(drone.status);
              final bc = _batteryColor(drone.batteryLevel);
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 2,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Drone id + owner + status
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: sc.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(Icons.flight_takeoff,
                                color: sc, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  drone.id,
                                  style: GoogleFonts.poppins(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  drone.ownerName,
                                  style: GoogleFonts.poppins(
                                      fontSize: 13, color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: sc,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                _statusLabel(drone.status),
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: sc,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      // Battery level
                      Row(
                        children: [
                          Icon(Icons.battery_charging_full,
                              size: 16, color: bc),
                          const SizedBox(width: 6),
                          Text(
                            'Batterie',
                            style: GoogleFonts.poppins(
                                fontSize: 12, color: Colors.grey[600]),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: drone.batteryLevel / 100,
                                backgroundColor:
                                    bc.withValues(alpha: 0.15),
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(bc),
                                minHeight: 8,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${drone.batteryLevel}%',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: bc,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // Location + last seen
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined,
                              size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              drone.location,
                              style: GoogleFonts.poppins(
                                  fontSize: 12, color: Colors.grey[600]),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Icon(Icons.access_time,
                              size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            _lastSeenLabel(drone.lastSeen),
                            style: GoogleFonts.poppins(
                                fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  final int count;
  final String label;
  final Color color;

  const _StatusChip(
      {required this.count, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            '$count $label',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
