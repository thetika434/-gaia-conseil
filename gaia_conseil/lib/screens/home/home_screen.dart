import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme.dart';
import '../../data/auth_state.dart';
import '../../data/mock_data.dart';
import '../auth/login_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = mockPlantation;
    return Scaffold(
      backgroundColor: AppTheme.lightBackground,
      body: Column(
        children: [
          _Header(plantation: p),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _HealthCard(plantation: p),
                  const SizedBox(height: 16),
                  _SensorsSection(plantation: p),
                  const SizedBox(height: 20),
                  _SectionTitle('Actions rapides'),
                  const SizedBox(height: 12),
                  _QuickActions(),
                  const SizedBox(height: 20),
                  _SectionTitle('Alertes & Recommandations'),
                  const SizedBox(height: 12),
                  ...mockAlerts.map((a) => _AlertCard(alert: a)),
                  const SizedBox(height: 20),
                  _SectionTitle('Météo locale'),
                  const SizedBox(height: 12),
                  _WeatherCard(plantation: p),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Header ───────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({required this.plantation});
  final PlantationData plantation;

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    return Container(
      color: AppTheme.primaryGreen,
      padding: EdgeInsets.fromLTRB(20, topPad + 16, 20, 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bonjour, ${plantation.farmerName}',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Votre plantation est sous contrôle',
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.wb_sunny, color: AppTheme.accentGold, size: 26),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _showProfileSheet(context),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.person_outline, color: Colors.white, size: 24),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showProfileSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            CircleAvatar(
              radius: 32,
              backgroundColor: AppTheme.primaryGreen,
              child: Text(
                AuthState.currentUserName.isNotEmpty ? AuthState.currentUserName[0].toUpperCase() : 'P',
                style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
            const SizedBox(height: 12),
            Text(AuthState.currentUserName, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
            Text('Planteur · GAÏA-CI', style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey)),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  AuthState.logout();
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                },
                icon: const Icon(Icons.logout, color: Colors.red),
                label: Text('Se déconnecter', style: GoogleFonts.poppins(color: Colors.red, fontWeight: FontWeight.w600)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Health Card ──────────────────────────────────────────────────────────────

class _HealthCard extends StatelessWidget {
  const _HealthCard({required this.plantation});
  final PlantationData plantation;

  @override
  Widget build(BuildContext context) {
    final isOptimal = plantation.healthStatus == 'Optimale';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SANTÉ GLOBALE',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[500],
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    plantation.healthStatus,
                    style: GoogleFonts.poppins(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: isOptimal
                          ? AppTheme.successGreen
                          : AppTheme.warningOrange,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    plantation.plotName,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: (isOptimal
                        ? AppTheme.successGreen
                        : AppTheme.warningOrange)
                    .withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isOptimal ? Icons.check_circle : Icons.warning_rounded,
                color: isOptimal ? AppTheme.successGreen : AppTheme.warningOrange,
                size: 30,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Sensors Section ──────────────────────────────────────────────────────────

class _SensorsSection extends StatelessWidget {
  const _SensorsSection({required this.plantation});
  final PlantationData plantation;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _SensorCard(
                icon: Icons.thermostat,
                label: 'TEMP. AIR',
                value: '${plantation.airTemp}°C',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SensorCard(
                icon: Icons.water_drop,
                label: 'HUMIDITÉ SOL',
                value: '${plantation.soilHumidity.toInt()}%',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _NutrientCard(value: plantation.soilNutrients),
      ],
    );
  }
}

class _SensorCard extends StatelessWidget {
  const _SensorCard({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppTheme.accentGold, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Colors.grey[500],
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryGreen,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NutrientCard extends StatelessWidget {
  const _NutrientCard({required this.value});
  final double value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppTheme.accentGold.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.eco, color: AppTheme.accentGold, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'NUTRIMENTS SOL',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[500],
                          letterSpacing: 1.1,
                        ),
                      ),
                      Text(
                        '${value.toInt()}%',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryGreen,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: value / 100,
                      minHeight: 8,
                      backgroundColor: Colors.grey[200],
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppTheme.successGreen,
                      ),
                    ),
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

// ─── Quick Actions ────────────────────────────────────────────────────────────

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  static const _actions = [
    (Icons.flight_takeoff, 'Lancer drone', true),
    (Icons.water_drop, 'Irrigation', true),
    (Icons.bar_chart, 'Rapport parcelle', false),
    (Icons.eco, 'Diagnostic plantes', false),
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: _actions
          .map((a) => _ActionButton(icon: a.$1, label: a.$2, filled: a.$3))
          .toList(),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.filled,
  });
  final IconData icon;
  final String label;
  final bool filled;

  void _onTap(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Fonctionnalité bientôt disponible',
          style: GoogleFonts.poppins(fontSize: 13),
        ),
        backgroundColor: AppTheme.primaryGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (filled) {
      return Material(
        color: AppTheme.primaryGreen,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _onTap(context),
          child: _content(Colors.white, Colors.white70),
        ),
      );
    }
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _onTap(context),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.4)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: _content(AppTheme.primaryGreen, Colors.grey[600]!),
        ),
      ),
    );
  }

  Widget _content(Color iconColor, Color labelColor) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: iconColor, size: 26),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: iconColor,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Alert Card ───────────────────────────────────────────────────────────────

class _AlertCard extends StatelessWidget {
  const _AlertCard({required this.alert});
  final AlertModel alert;

  Color get _borderColor {
    switch (alert.type) {
      case AlertType.success:
        return AppTheme.successGreen;
      case AlertType.warning:
        return AppTheme.warningOrange;
      case AlertType.info:
        return const Color(0xFF1E88E5);
    }
  }

  String get _timeAgo {
    final diff = DateTime.now().difference(alert.time);
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Il y a ${diff.inHours}h';
    return 'Il y a ${diff.inDays}j';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                alert.message,
                style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[800]),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _timeAgo,
              style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[400]),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Weather Card ─────────────────────────────────────────────────────────────

class _WeatherCard extends StatelessWidget {
  const _WeatherCard({required this.plantation});
  final PlantationData plantation;

  static const _forecast = [
    (Icons.wb_sunny, '32°'),
    (Icons.cloud, '29°'),
    (Icons.grain, '27°'),
  ];

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppTheme.accentGold.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.wb_sunny,
                    color: AppTheme.accentGold,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${plantation.tempMax.toInt()}°C / ${plantation.tempMin.toInt()}°C',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryGreen,
                      ),
                    ),
                    Text(
                      '${plantation.weather} · ${plantation.city}',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: _forecast
                  .map(
                    (f) => Column(
                      children: [
                        Icon(f.$1, color: AppTheme.accentGold, size: 22),
                        const SizedBox(height: 4),
                        Text(
                          f.$2,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Section Title ────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: AppTheme.primaryGreen,
      ),
    );
  }
}
