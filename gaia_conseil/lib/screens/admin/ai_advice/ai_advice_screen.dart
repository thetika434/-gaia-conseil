import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme.dart';
import '../../../data/mock_data.dart';
import '../../../data/profiles_repository.dart';
import '../../../data/drones_repository.dart';
import '../messaging/admin_messaging_screen.dart';
import '../drones/drones_screen.dart';

class AiAdviceScreen extends StatefulWidget {
  final void Function(String userId)? onNavigateToChat;

  const AiAdviceScreen({super.key, this.onNavigateToChat});

  @override
  State<AiAdviceScreen> createState() => _AiAdviceScreenState();
}

class _AiAdviceScreenState extends State<AiAdviceScreen> {
  String? _selectedUserId;
  bool _isGenerating = false;
  String _recommendation = '';
  String _generationStep = '';
  String _searchQuery = '';
  String _categoryFilter = 'Tous';

  List<AdminUser> _users = List.unmodifiable(mockAdminUsers);
  StreamSubscription<List<AdminUser>>? _profileSub;
  List<DroneModel> _allDrones = [];
  int _droneTotal = 0;
  int _droneOnline = 0;
  StreamSubscription<List<DroneModel>>? _dronesSub;
  Map<String, String> _ownerNames = {};

  @override
  void initState() {
    super.initState();
    _profileSub = ProfilesRepository.watchPlanteurs().listen((users) {
      if (!mounted) return;
      setState(() {
        _users = users;
        _ownerNames = {for (final u in users) u.id: u.fullName};
      });
    });
    _dronesSub = DronesRepository.watchAllDrones().listen((drones) {
      if (!mounted) return;
      setState(() {
        _allDrones = drones;
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

  AdminUser? get _selectedUser {
    if (_selectedUserId == null) return null;
    try {
      return _users.firstWhere((u) => u.id == _selectedUserId);
    } catch (_) {
      return null;
    }
  }

  TelemetryRecord? get _telemetry {
    if (_selectedUser == null) return null;
    try {
      return mockTelemetry.firstWhere(
        (t) => t.planteurName == _selectedUser!.fullName,
      );
    } catch (_) {
      return null;
    }
  }

  // Alert counts derived from live drone stream — same logic as AdminDashboardScreen.
  int get _activeAlertCount {
    int n = 0;
    for (final d in _allDrones) {
      final name = _ownerNames[d.ownerId] ??
          (d.ownerName.isNotEmpty ? d.ownerName : d.ownerId);
      if (name.isNotEmpty &&
          (d.batteryLevel < 20 ||
              d.status == DroneStatus.offline ||
              d.status == DroneStatus.maintenance)) {
        n++;
      }
    }
    return n;
  }

  int get _criticalAlertCount =>
      _allDrones.where((d) => d.batteryLevel < 20).length;

  // Users shown in the dropdown — always the full list, search-filtered only.
  // The category filter (Tous/Alertes/Optimaux) is intentionally NOT applied
  // here: it only affects recommendation content, not who is selectable.
  List<AdminUser> get _dropdownUsers {
    if (_searchQuery.isEmpty) return List.unmodifiable(_users);
    final q = _searchQuery.toLowerCase();
    return _users
        .where((u) =>
            u.fullName.toLowerCase().contains(q) ||
            u.region.toLowerCase().contains(q))
        .toList();
  }

  String _generateRecommendation(TelemetryRecord t) {
    final lines = <String>[];
    if (t.soilHumidity < 50) {
      lines.add(
        '⚠️ Irrigation recommandée : le taux d\'humidité du sol est faible (${t.soilHumidity.toStringAsFixed(1)} %). Un arrosage ciblé est conseillé dans les prochaines 24 heures.',
      );
    }
    if (t.temperature > 30) {
      lines.add(
        '🌡️ Attention aux fortes chaleurs : la température relevée est de ${t.temperature.toStringAsFixed(1)} °C. Protéger les jeunes plants avec un filet ombragé et augmenter la fréquence d\'arrosage.',
      );
    }
    if (t.soilPH < 5.5 || t.soilPH > 7.0) {
      lines.add(
        '🧪 Correction du pH nécessaire : le pH actuel est de ${t.soilPH.toStringAsFixed(1)}. Appliquer de la chaux agricole pour remonter le pH ou du soufre pour le réduire selon le cas.',
      );
    }
    if (t.nitrogen < 40) {
      lines.add(
        '🌿 Apport d\'azote conseillé : le niveau d\'azote est bas (${t.nitrogen.toStringAsFixed(1)} %). Prévoir un apport de compost organique ou d\'engrais azoté contrôlé.',
      );
    }
    lines.add(
      '✅ Recommandation globale : maintenir les pratiques agroforestières en place. Un suivi régulier des capteurs est recommandé toutes les 48 heures.',
    );
    return lines.join('\n\n');
  }

  Future<void> _generate() async {
    final user = _selectedUser;
    if (user == null) return;
    setState(() {
      _isGenerating = true;
      _recommendation = '';
      _generationStep = 'Lecture des capteurs...';
    });

    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    setState(() => _generationStep = 'Analyse des données par GAÏA-AI...');

    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    setState(() => _generationStep = 'Génération du rapport agronomique...');

    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;

    final t = _telemetry;
    setState(() {
      _isGenerating = false;
      _recommendation = t != null
          ? _generateRecommendation(t)
          : _generateFallbackRecommendation(user);
    });
  }

  String _generateFallbackRecommendation(AdminUser user) {
    return '⚠️ Données capteurs indisponibles pour ${user.fullName} '
        '(Région : ${user.region}).\n\n'
        '🚁 Mission drone recommandée : planifier un vol de relevé sur la '
        'parcelle pour collecter température, humidité et pH du sol.\n\n'
        '🌿 En attendant les mesures : appliquer les bonnes pratiques '
        'agroforestières standard — maintenir un arrosage régulier et '
        'surveiller visuellement les feuilles pour détecter tout signe de '
        'carence ou de stress hydrique.\n\n'
        '📋 Suivi conseillé : revenir dans cet onglet après la prochaine '
        'mission drone pour obtenir des recommandations précises basées sur '
        'la télémétrie réelle.';
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
    final totalUsers = _users.length;
    final totalDrones = _droneTotal;
    final onlineDrones = _droneOnline;
    final activeAlerts = _activeAlertCount;
    final criticalAlerts = _criticalAlertCount;

    final t = _telemetry;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottomInset),
      child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Dashboard Summary Cards ──────────────────────────────────
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.6,
                children: [
                  _SummaryCard(
                    label: 'Planteurs',
                    value: '$totalUsers',
                    icon: Icons.people_outline,
                    color: AppTheme.primaryGreen,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          // Navigation vers l'écran de messagerie
                          builder: (context) => const AdminMessagingScreen(),
                        ),
                      );
                    },
                  ),
                  _SummaryCard(
                    label: 'Drones total',
                    value: '$totalDrones',
                    icon: Icons.flight,
                    color: Colors.blue,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const DronesScreen(),
                        ), // Navigation vers l'écran des drones
                      );
                    },
                  ),
                  _SummaryCard(
                    label: 'Drones en ligne',
                    value: '$onlineDrones',
                    icon: Icons.wifi,
                    color: AppTheme.successGreen,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const DronesScreen(
                            initialFilter: DroneStatus.online,
                          ),
                        ),
                      );
                    },
                  ),
                  _SummaryCard(
                    label: 'Alertes actives',
                    value: '$activeAlerts',
                    icon: Icons.warning_amber_rounded,
                    color: AppTheme.warningOrange,
                    onTap: () {
                      setState(() {
                        _categoryFilter = 'Alertes';
                        _selectedUserId = null;
                      });
                      // Pour l'instant, cela filtre la vue actuelle.
                      // Si un écran dédié aux alertes existe, la navigation serait ajoutée ici.
                    },
                  ),
                  _SummaryCard(
                    label: 'Alertes critiques',
                    value: '$criticalAlerts',
                    icon: Icons.gpp_maybe,
                    color: AppTheme.errorRed,
                    onTap: () {
                      setState(() {
                        _categoryFilter = 'Alertes';
                        _selectedUserId = null;
                      });
                      // Pour l'instant, cela filtre la vue actuelle.
                      // Si un écran dédié aux alertes critiques existe, la navigation serait ajoutée ici.
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),

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
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: ['Tous', 'Alertes', 'Optimaux'].map((cat) {
                  final isSelected = _categoryFilter == cat;
                  return ChoiceChip(
                    label: Text(
                      cat,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                    selected: isSelected,
                    onSelected: (_) => setState(() {
                      _categoryFilter = cat;
                      _selectedUserId = null;
                      _recommendation = '';
                    }),
                    selectedColor:
                        AppTheme.primaryGreen.withValues(alpha: 0.2),
                    backgroundColor: Colors.white,
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // ── User selector with Filter ────────────────────────────────
              Text(
                'Sélectionner un planteur',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                onChanged: (val) => setState(() => _searchQuery = val),
                style: GoogleFonts.poppins(fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Filtrer par nom ou région...',
                  prefixIcon: const Icon(Icons.search, size: 18),
                  isDense: true,
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFDDDDDD)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedUserId,
                          hint: Text(
                            'Choisir un planteur...',
                            style: GoogleFonts.poppins(fontSize: 14),
                          ),
                          isExpanded: true,
                          onChanged: (val) => setState(() {
                            _selectedUserId = val;
                            _recommendation = '';
                          }),
                          items: _dropdownUsers
                              .map(
                                (u) => DropdownMenuItem(
                                  value: u.id,
                                  child: Text(
                                    u.fullName,
                                    style: GoogleFonts.poppins(fontSize: 14),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    ),
                  ),
                  if (_selectedUserId != null) ...[
                    const SizedBox(width: 8),
                    IconButton.filled(
                      onPressed: widget.onNavigateToChat != null
                          ? () => widget.onNavigateToChat!(_selectedUserId!)
                          : () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Navigation non configurée'),
                                ),
                              );
                            },
                      icon: const Icon(Icons.chat_bubble_outline),
                      style: IconButton.styleFrom(
                        backgroundColor: AppTheme.primaryGreen,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 24),

              // ── Sensor data cards ────────────────────────────────────────
              if (t != null) ...[
                Text(
                  'Données capteurs',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
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
                  onPressed: (_selectedUserId != null && !_isGenerating)
                      ? _generate
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentGold,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  icon: _isGenerating
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.psychology, size: 20),
                  label: Text(
                    _isGenerating ? _generationStep : 'Générer recommandations',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── Recommendation output ────────────────────────────────────
              if (_recommendation.isNotEmpty)
                AnimatedOpacity(
                  opacity: 1.0,
                  duration: const Duration(milliseconds: 500),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppTheme.primaryGreen.withValues(
                              alpha: 0.25,
                            ),
                          ),
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
                                const Icon(
                                  Icons.auto_awesome,
                                  color: AppTheme.accentGold,
                                  size: 18,
                                ),
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
                                height: 1.6,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 50,
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _sendToPlanteur,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryGreen,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                          ),
                          icon: const Icon(Icons.send, size: 18),
                          label: Text(
                            'Envoyer au planteur',
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
    );
  }
}

// ── Summary Card Widget ──────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.onTap,
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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
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
                        fontSize: 24,
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
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
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
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
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
