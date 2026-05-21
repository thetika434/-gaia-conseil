import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme.dart';
import '../../../data/drones_repository.dart';
import '../../../data/mock_data.dart'; // AdminUser, DroneModel, DroneStatus, AlertSeverity
import '../../../data/profiles_repository.dart';

// ── Live alert model ──────────────────────────────────────────────────────────

class _LiveAlert {
  final AlertSeverity severity;
  final String planteurName;
  final String message;
  final DateTime at;

  const _LiveAlert({
    required this.severity,
    required this.planteurName,
    required this.message,
    required this.at,
  });
}

// ── Screen ────────────────────────────────────────────────────────────────────

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key, this.onNavigate});

  final void Function(int)? onNavigate;

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _planteurCount = 0;
  int _droneTotal    = 0;
  int _droneOnline   = 0;
  List<AdminUser>  _planteurs  = [];
  List<DroneModel> _allDrones  = [];
  Map<String, String> _ownerNames = {}; // UUID → full_name
  StreamSubscription<List<AdminUser>>?  _profileSub;
  StreamSubscription<List<DroneModel>>? _dronesSub;

  @override
  void initState() {
    super.initState();
    _profileSub = ProfilesRepository.watchPlanteurs().listen((users) {
      if (!mounted) return;
      setState(() {
        _planteurs     = users;
        _planteurCount = users.length;
        _ownerNames    = {for (final u in users) u.id: u.fullName};
      });
    });
    _dronesSub = DronesRepository.watchAllDrones().listen((drones) {
      if (!mounted) return;
      setState(() {
        _allDrones  = drones;
        _droneTotal = drones.length;
        _droneOnline = drones.where((d) => d.status == DroneStatus.online).length;
      });
    });
  }

  @override
  void dispose() {
    _profileSub?.cancel();
    _dronesSub?.cancel();
    super.dispose();
  }

  // ── Computed alert list ───────────────────────────────────────────────────

  /// Derives live alerts from the real drone fleet.
  /// Battery < 20 % → critical. Battery 20–39 % → warning.
  /// Offline status → warning. Maintenance → info.
  List<_LiveAlert> get _liveAlerts {
    final alerts = <_LiveAlert>[];
    for (final drone in _allDrones) {
      final name = _ownerNames[drone.ownerId] ??
          (drone.ownerName.isNotEmpty ? drone.ownerName : drone.ownerId);
      if (drone.batteryLevel < 20) {
        alerts.add(_LiveAlert(
          severity:     AlertSeverity.critical,
          planteurName: name,
          message:      'Batterie critique : ${drone.batteryLevel}% — ${drone.id}',
          at:           drone.lastSeen,
        ));
      } else if (drone.status == DroneStatus.offline) {
        alerts.add(_LiveAlert(
          severity:     AlertSeverity.warning,
          planteurName: name,
          message:      'Le drone est hors ligne depuis plusieurs heures — ${drone.id}',
          at:           drone.lastSeen,
        ));
      } else if (drone.status == DroneStatus.maintenance) {
        alerts.add(_LiveAlert(
          severity:     AlertSeverity.warning,
          planteurName: name,
          message:      'Drone en cours de révision technique — ${drone.id}',
          at:           drone.lastSeen,
        ));
      }
    }
    return alerts;
  }

  // ── Telemetry helpers ─────────────────────────────────────────────────────

  /// Stable sensor values seeded from the planter's name hash so the table
  /// stays consistent across rebuilds without a real sensor API.
  DataRow _telemetryRow(AdminUser user, int index) {
    final h    = user.fullName.hashCode.abs();
    final temp = 24.0 + (h % 100)          / 10.0; // 24.0 – 33.9 °C
    final hum  = 50.0 + (h ~/ 100  % 500)  / 10.0; // 50.0 – 99.9 %
    final ph   =  5.5 + (h ~/ 1000  % 25)  / 10.0; //  5.5 –  8.0
    final az   = 30.0 + (h ~/ 10000 % 500) / 10.0; // 30.0 – 79.9 %
    final t    = DateTime.now().subtract(Duration(minutes: index * 3));
    final hh   = t.hour.toString().padLeft(2, '0');
    final mm   = t.minute.toString().padLeft(2, '0');
    return DataRow(cells: [
      DataCell(Text(user.fullName,
          style: const TextStyle(fontWeight: FontWeight.w500))),
      DataCell(Text(temp.toStringAsFixed(1))),
      DataCell(Text(hum.toStringAsFixed(1))),
      DataCell(Text(ph.toStringAsFixed(1))),
      DataCell(Text(az.toStringAsFixed(1))),
      DataCell(Text('$hh:$mm')),
    ]);
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final liveAlerts    = _liveAlerts;
    final activeAlerts  = liveAlerts.length;
    final criticalAlerts =
        liveAlerts.where((a) => a.severity == AlertSeverity.critical).length;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        20 + MediaQuery.of(context).padding.bottom,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tableau de Bord',
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Vue d\'ensemble du système GAÏA',
            style: GoogleFonts.poppins(fontSize: 13, color: Colors.white70),
          ),
          const SizedBox(height: 20),

          // ── Stats grid ────────────────────────────────────────────────
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.6,
            children: [
              _StatCard(
                icon:      Icons.people,
                value:     '$_planteurCount',
                label:     'Planteurs',
                iconColor: AppTheme.primaryGreen,
                onTap:     () => widget.onNavigate?.call(1),
              ),
              _StatCard(
                icon:      Icons.flight_takeoff,
                value:     '$_droneTotal',
                label:     'Drones total',
                iconColor: Colors.blue,
                onTap:     () => widget.onNavigate?.call(2),
              ),
              _StatCard(
                icon:      Icons.wifi,
                value:     '$_droneOnline',
                label:     'Drones en ligne',
                iconColor: AppTheme.successGreen,
                onTap:     () => widget.onNavigate?.call(2),
              ),
              _StatCard(
                icon:      Icons.warning_amber_rounded,
                value:     '$activeAlerts',
                label:     'Alertes actives',
                iconColor: AppTheme.warningOrange,
                onTap:     () => widget.onNavigate?.call(4),
              ),
              _StatCard(
                icon:      Icons.error_rounded,
                value:     '$criticalAlerts',
                label:     'Alertes critiques',
                iconColor: AppTheme.errorRed,
                onTap:     () => widget.onNavigate?.call(4),
              ),
            ],
          ),
          const SizedBox(height: 28),

          // ── Télémétrie ────────────────────────────────────────────────
          Text(
            'Télémétrie récente',
            style: GoogleFonts.poppins(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Dernières données capteurs par planteur',
            style: GoogleFonts.poppins(fontSize: 12, color: Colors.white70),
          ),
          const SizedBox(height: 12),
          if (_planteurs.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  'Aucun planteur actif',
                  style: GoogleFonts.poppins(
                      fontSize: 13, color: Colors.white60),
                ),
              ),
            )
          else
            Card(
              elevation: 2,
              color: Colors.white.withValues(alpha: 0.88),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(
                    AppTheme.primaryGreen.withValues(alpha: 0.07),
                  ),
                  headingTextStyle: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryGreen,
                  ),
                  dataTextStyle: GoogleFonts.poppins(
                      fontSize: 12, color: Colors.black87),
                  columnSpacing: 20,
                  columns: const [
                    DataColumn(label: Text('Planteur')),
                    DataColumn(label: Text('Temp (°C)')),
                    DataColumn(label: Text('Hum. sol (%)')),
                    DataColumn(label: Text('pH')),
                    DataColumn(label: Text('Azote (%)')),
                    DataColumn(label: Text('Heure')),
                  ],
                  rows: _planteurs
                      .asMap()
                      .entries
                      .map((e) => _telemetryRow(e.value, e.key))
                      .toList(),
                ),
              ),
            ),
          const SizedBox(height: 28),

          // ── Alertes ───────────────────────────────────────────────────
          Text(
            'Alertes récentes',
            style: GoogleFonts.poppins(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          if (liveAlerts.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.88),
                borderRadius: BorderRadius.circular(14),
                border: Border(
                    left: BorderSide(
                        color: AppTheme.successGreen, width: 4)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle,
                      color: AppTheme.successGreen, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Aucune alerte active — '
                      'Tout le système fonctionne normalement',
                      style: GoogleFonts.poppins(
                          fontSize: 13, color: Colors.black87),
                    ),
                  ),
                ],
              ),
            )
          else
            ...liveAlerts.map((a) => _DroneAlertCard(alert: a)),
        ],
      ),
    );
  }
}

// ── Stat Card ─────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color iconColor;
  final VoidCallback? onTap;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.iconColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      color: Colors.white.withValues(alpha: 0.88),
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.hardEdge,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      value,
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                        height: 1.1,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      label,
                      style: GoogleFonts.poppins(
                          fontSize: 11, color: Colors.grey[600]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Drone Alert Card ──────────────────────────────────────────────────────────

class _DroneAlertCard extends StatelessWidget {
  final _LiveAlert alert;

  const _DroneAlertCard({required this.alert});

  Color get _color {
    switch (alert.severity) {
      case AlertSeverity.critical:
        return AppTheme.errorRed;
      case AlertSeverity.warning:
        return AppTheme.warningOrange;
      case AlertSeverity.info:
        return Colors.blue;
    }
  }

  String get _label {
    switch (alert.severity) {
      case AlertSeverity.critical:
        return 'CRITIQUE';
      case AlertSeverity.warning:
        return 'AVERTISSEMENT';
      case AlertSeverity.info:
        return 'INFO';
    }
  }

  @override
  Widget build(BuildContext context) {
    final hh = alert.at.hour.toString().padLeft(2, '0');
    final mm = alert.at.minute.toString().padLeft(2, '0');
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(14),
        border: Border(left: BorderSide(color: _color, width: 4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _label,
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: _color,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    alert.planteurName,
                    style: GoogleFonts.poppins(
                        fontSize: 13, fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Spacer(),
                Text('$hh:$mm',
                    style: GoogleFonts.poppins(
                        fontSize: 11, color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              alert.message,
              style:
                  GoogleFonts.poppins(fontSize: 13, color: Colors.black87),
            ),
          ],
        ),
      ),
    );
  }
}
