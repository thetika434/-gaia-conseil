import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme.dart';
import '../../../data/mock_data.dart';

class AiAdviceScreen extends StatefulWidget {
  const AiAdviceScreen({super.key});

  @override
  State<AiAdviceScreen> createState() => _AiAdviceScreenState();
}

class _AiAdviceScreenState extends State<AiAdviceScreen> {
  String? _selectedUserId;
  bool _isGenerating = false;
  String _recommendation = '';

  AdminUser? get _selectedUser {
    if (_selectedUserId == null) return null;
    try {
      return mockAdminUsers.firstWhere((u) => u.id == _selectedUserId);
    } catch (_) {
      return null;
    }
  }

  TelemetryRecord? get _telemetry {
    if (_selectedUser == null) return null;
    try {
      return mockTelemetry
          .firstWhere((t) => t.planteurName == _selectedUser!.fullName);
    } catch (_) {
      return null;
    }
  }

  String _generateRecommendation(TelemetryRecord t) {
    final lines = <String>[];
    if (t.soilHumidity < 50) {
      lines.add(
          '⚠️ Irrigation recommandée : le taux d\'humidité du sol est faible (${t.soilHumidity.toStringAsFixed(1)} %). Un arrosage ciblé est conseillé dans les prochaines 24 heures.');
    }
    if (t.temperature > 30) {
      lines.add(
          '🌡️ Attention aux fortes chaleurs : la température relevée est de ${t.temperature.toStringAsFixed(1)} °C. Protéger les jeunes plants avec un filet ombragé et augmenter la fréquence d\'arrosage.');
    }
    if (t.soilPH < 5.5 || t.soilPH > 7.0) {
      lines.add(
          '🧪 Correction du pH nécessaire : le pH actuel est de ${t.soilPH.toStringAsFixed(1)}. Appliquer de la chaux agricole pour remonter le pH ou du soufre pour le réduire selon le cas.');
    }
    if (t.nitrogen < 40) {
      lines.add(
          '🌿 Apport d\'azote conseillé : le niveau d\'azote est bas (${t.nitrogen.toStringAsFixed(1)} %). Prévoir un apport de compost organique ou d\'engrais azoté contrôlé.');
    }
    lines.add(
        '✅ Recommandation globale : maintenir les pratiques agroforestières en place. Un suivi régulier des capteurs est recommandé toutes les 48 heures.');
    return lines.join('\n\n');
  }

  Future<void> _generate() async {
    final t = _telemetry;
    if (t == null) return;
    setState(() {
      _isGenerating = true;
      _recommendation = '';
    });
    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;
    setState(() {
      _isGenerating = false;
      _recommendation = _generateRecommendation(t);
    });
  }

  void _sendToPlanteur() {
    if (_selectedUser == null || _recommendation.isEmpty) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Recommandation envoyée à ${_selectedUser!.fullName}',
          style: GoogleFonts.poppins(fontSize: 13),
        ),
        backgroundColor: AppTheme.primaryGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = _telemetry;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Conseil IA',
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryGreen,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Recommandations personnalisées basées sur la télémétrie',
            style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey),
          ),
          const SizedBox(height: 24),

          // ── User selector ────────────────────────────────────────────
          Text(
            'Sélectionner un planteur',
            style: GoogleFonts.poppins(
                fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFDDDDDD)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedUserId,
                hint: Text('Choisir un planteur...',
                    style: GoogleFonts.poppins(
                        fontSize: 14, color: Colors.grey)),
                isExpanded: true,
                style: GoogleFonts.poppins(
                    fontSize: 14, color: Colors.black87),
                icon: const Icon(Icons.keyboard_arrow_down,
                    color: AppTheme.primaryGreen),
                onChanged: (val) => setState(() {
                  _selectedUserId = val;
                  _recommendation = '';
                }),
                items: mockAdminUsers
                    .map((u) => DropdownMenuItem(
                          value: u.id,
                          child: Text(u.fullName),
                        ))
                    .toList(),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // ── Sensor data cards ────────────────────────────────────────
          if (t != null) ...[
            Text(
              'Données capteurs',
              style: GoogleFonts.poppins(
                  fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.8,
              children: [
                _SensorCard(
                  icon: Icons.thermostat,
                  label: 'Température',
                  value: '${t.temperature.toStringAsFixed(1)} °C',
                  color: Colors.orange,
                ),
                _SensorCard(
                  icon: Icons.water_drop_outlined,
                  label: 'Humidité air',
                  value: '${t.airHumidity.toStringAsFixed(1)} %',
                  color: Colors.blue,
                ),
                _SensorCard(
                  icon: Icons.grass,
                  label: 'Humidité sol',
                  value: '${t.soilHumidity.toStringAsFixed(1)} %',
                  color: AppTheme.primaryGreen,
                ),
                _SensorCard(
                  icon: Icons.science_outlined,
                  label: 'pH sol',
                  value: t.soilPH.toStringAsFixed(1),
                  color: Colors.purple,
                ),
                _SensorCard(
                  icon: Icons.eco_outlined,
                  label: 'Azote',
                  value: '${t.nitrogen.toStringAsFixed(1)} %',
                  color: AppTheme.successGreen,
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],

          // ── Generate button ──────────────────────────────────────────
          SizedBox(
            height: 50,
            child: ElevatedButton.icon(
              onPressed:
                  (_selectedUserId != null && !_isGenerating) ? _generate : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentGold,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              icon: _isGenerating
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.auto_awesome, size: 20),
              label: Text(
                _isGenerating
                    ? 'Analyse en cours...'
                    : 'Générer recommandations',
                style: GoogleFonts.poppins(
                    fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Recommendation output ────────────────────────────────────
          if (_recommendation.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: AppTheme.primaryGreen.withValues(alpha: 0.25)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.auto_awesome,
                          color: AppTheme.accentGold, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Recommandations IA',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryGreen,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _recommendation,
                    style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.black87,
                        height: 1.6),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _sendToPlanteur,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                icon: const Icon(Icons.send, size: 18),
                label: Text(
                  'Envoyer au planteur',
                  style: GoogleFonts.poppins(
                      fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Sensor Card ───────────────────────────────────────────────────────────────

class _SensorCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _SensorCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.poppins(
                        fontSize: 11, color: Colors.grey[600]),
                  ),
                  Text(
                    value,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
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
