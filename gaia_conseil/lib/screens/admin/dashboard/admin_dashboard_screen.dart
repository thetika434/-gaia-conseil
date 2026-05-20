import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme.dart';
import '../../../data/mock_data.dart';
import '../../../data/profiles_repository.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key, this.onNavigate});

  /// Callback to switch the admin scaffold to a given tab index.
  final void Function(int)? onNavigate;

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _planteurCount = mockAdminUsers.length;
  StreamSubscription<List<AdminUser>>? _profileSub;

  @override
  void initState() {
    super.initState();
    _profileSub = ProfilesRepository.watchPlanteurs().listen((users) {
      if (mounted) setState(() => _planteurCount = users.length);
    });
  }

  @override
  void dispose() {
    _profileSub?.cancel();
    super.dispose();
  }

  void _resolveAlert(AdminAlert alert) {
    setState(() {
      alert.isResolved = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final onlineDrones =
        mockDrones.where((d) => d.status == DroneStatus.online).length;
    final activeAlerts =
        mockAdminAlerts.where((a) => !a.isResolved).length;
    final criticalAlerts = mockAdminAlerts
        .where((a) => a.severity == AlertSeverity.critical && !a.isResolved)
        .length;

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
                icon: Icons.people,
                value: '$_planteurCount',
                label: 'Planteurs',
                iconColor: AppTheme.primaryGreen,
                onTap: () => widget.onNavigate?.call(1),
              ),
              _StatCard(
                icon: Icons.flight_takeoff,
                value: '${mockDrones.length}',
                label: 'Drones total',
                iconColor: Colors.blue,
                onTap: () => widget.onNavigate?.call(2),
              ),
              _StatCard(
                icon: Icons.wifi,
                value: '$onlineDrones',
                label: 'Drones en ligne',
                iconColor: AppTheme.successGreen,
                onTap: () => widget.onNavigate?.call(2),
              ),
              _StatCard(
                icon: Icons.warning_amber_rounded,
                value: '$activeAlerts',
                label: 'Alertes actives',
                iconColor: AppTheme.warningOrange,
                onTap: () => widget.onNavigate?.call(4),
              ),
              _StatCard(
                icon: Icons.error_rounded,
                value: '$criticalAlerts',
                label: 'Alertes critiques',
                iconColor: AppTheme.errorRed,
                onTap: () => widget.onNavigate?.call(4),
              ),
            ],
          ),
          const SizedBox(height: 28),

          // ── Telemetry section ─────────────────────────────────────────
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
                dataTextStyle:
                    GoogleFonts.poppins(fontSize: 12, color: Colors.black87),
                columnSpacing: 20,
                columns: const [
                  DataColumn(label: Text('Planteur')),
                  DataColumn(label: Text('Temp (°C)')),
                  DataColumn(label: Text('Hum. sol (%)')),
                  DataColumn(label: Text('pH')),
                  DataColumn(label: Text('Azote (%)')),
                  DataColumn(label: Text('Heure')),
                ],
                rows: mockTelemetry.map((t) {
                  final hour = t.recordedAt.hour.toString().padLeft(2, '0');
                  final min = t.recordedAt.minute.toString().padLeft(2, '0');
                  return DataRow(cells: [
                    DataCell(Text(t.planteurName,
                        style: const TextStyle(fontWeight: FontWeight.w500))),
                    DataCell(Text(t.temperature.toStringAsFixed(1))),
                    DataCell(Text(t.soilHumidity.toStringAsFixed(1))),
                    DataCell(Text(t.soilPH.toStringAsFixed(1))),
                    DataCell(Text(t.nitrogen.toStringAsFixed(1))),
                    DataCell(Text('$hour:$min')),
                  ]);
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 28),

          // ── Alerts section ────────────────────────────────────────────
          Text(
            'Alertes récentes',
            style: GoogleFonts.poppins(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          ...mockAdminAlerts.map((alert) => _AlertCard(
                alert: alert,
                onResolve: () => _resolveAlert(alert),
              )),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.hardEdge,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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

// ── Alert Card ────────────────────────────────────────────────────────────────

class _AlertCard extends StatelessWidget {
  final AdminAlert alert;
  final VoidCallback onResolve;

  const _AlertCard({required this.alert, required this.onResolve});

  Color get _borderColor {
    switch (alert.severity) {
      case AlertSeverity.critical:
        return AppTheme.errorRed;
      case AlertSeverity.warning:
        return AppTheme.warningOrange;
      case AlertSeverity.info:
        return Colors.blue;
    }
  }

  String get _severityLabel {
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
    final hour = alert.createdAt.hour.toString().padLeft(2, '0');
    final min = alert.createdAt.minute.toString().padLeft(2, '0');

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(14),
        border: Border(left: BorderSide(color: _borderColor, width: 4)),
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _borderColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _severityLabel,
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: _borderColor,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    alert.planteurName,
                    style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Spacer(),
                Text(
                  '$hour:$min',
                  style:
                      GoogleFonts.poppins(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              alert.message,
              style:
                  GoogleFonts.poppins(fontSize: 13, color: Colors.black87),
            ),
            if (!alert.isResolved) ...[
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: onResolve,
                  icon: const Icon(Icons.check_circle_outline, size: 16),
                  label: Text('Résoudre',
                      style: GoogleFonts.poppins(fontSize: 12)),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.successGreen,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                  ),
                ),
              ),
            ] else
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle,
                        size: 14, color: Colors.green),
                    const SizedBox(width: 4),
                    Text(
                      'Résolu',
                      style: GoogleFonts.poppins(
                          fontSize: 11, color: Colors.green),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
