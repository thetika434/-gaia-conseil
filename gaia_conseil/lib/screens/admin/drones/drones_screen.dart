import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme.dart';
import '../../../data/mock_data.dart';
import 'drone_detail_screen.dart';

class DronesScreen extends StatefulWidget {
  const DronesScreen({super.key});

  @override
  State<DronesScreen> createState() => _DronesScreenState();
}

class _DronesScreenState extends State<DronesScreen> {
  DroneStatus? _filtreActif;
  String _recherche = '';
  String _tri = 'nom'; // 'nom' | 'batterie' | 'activite'
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(
      () => setState(() => _recherche = _searchController.text),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<DroneModel> get _dronesFiltres {
    var liste = mockDrones.where((d) {
      final okStatut = _filtreActif == null || d.status == _filtreActif;
      final okRecherche =
          _recherche.isEmpty ||
          d.id.toLowerCase().contains(_recherche.toLowerCase()) ||
          d.ownerName.toLowerCase().contains(_recherche.toLowerCase());
      return okStatut && okRecherche;
    }).toList();
    switch (_tri) {
      case 'batterie':
        liste.sort((a, b) => b.batteryLevel.compareTo(a.batteryLevel));
      case 'activite':
        liste.sort((a, b) => b.lastSeen.compareTo(a.lastSeen));
      default:
        liste.sort((a, b) => a.id.compareTo(b.id));
    }
    return liste;
  }

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
    final online = mockDrones
        .where((d) => d.status == DroneStatus.online)
        .length;
    final offline = mockDrones
        .where((d) => d.status == DroneStatus.offline)
        .length;
    final maintenance = mockDrones
        .where((d) => d.status == DroneStatus.maintenance)
        .length;
    final filtres = _dronesFiltres;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Title row with sort button ──────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 8, 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Flotte de Drones',
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryGreen,
                  ),
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.sort, color: AppTheme.primaryGreen),
                tooltip: 'Trier par',
                onSelected: (val) => setState(() => _tri = val),
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'nom',
                    child: Row(
                      children: [
                        const Icon(Icons.sort_by_alpha, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Nom',
                          style: GoogleFonts.poppins(
                            fontWeight: _tri == 'nom'
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'batterie',
                    child: Row(
                      children: [
                        const Icon(Icons.battery_full, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Batterie',
                          style: GoogleFonts.poppins(
                            fontWeight: _tri == 'batterie'
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'activite',
                    child: Row(
                      children: [
                        const Icon(Icons.access_time, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Activité',
                          style: GoogleFonts.poppins(
                            fontWeight: _tri == 'activite'
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // ── Filter chips row ────────────────────────────────────────────
        SizedBox(
          height: 48,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _filterChip(
                  label: 'Tous (${mockDrones.length})',
                  color: AppTheme.primaryGreen,
                  isSelected: _filtreActif == null,
                  onTap: () => setState(() => _filtreActif = null),
                ),
                const SizedBox(width: 8),
                _filterChip(
                  label: 'En ligne ($online)',
                  color: AppTheme.successGreen,
                  isSelected: _filtreActif == DroneStatus.online,
                  onTap: () => setState(
                    () => _filtreActif = _filtreActif == DroneStatus.online
                        ? null
                        : DroneStatus.online,
                  ),
                ),
                const SizedBox(width: 8),
                _filterChip(
                  label: 'Hors ligne ($offline)',
                  color: Colors.grey,
                  isSelected: _filtreActif == DroneStatus.offline,
                  onTap: () => setState(
                    () => _filtreActif = _filtreActif == DroneStatus.offline
                        ? null
                        : DroneStatus.offline,
                  ),
                ),
                const SizedBox(width: 8),
                _filterChip(
                  label: 'Maintenance ($maintenance)',
                  color: AppTheme.warningOrange,
                  isSelected: _filtreActif == DroneStatus.maintenance,
                  onTap: () => setState(
                    () => _filtreActif = _filtreActif == DroneStatus.maintenance
                        ? null
                        : DroneStatus.maintenance,
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── Search bar ──────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Rechercher un drone ou un planteur…',
              hintStyle: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.grey[400],
              ),
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              suffixIcon: _recherche.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: Colors.grey),
                      onPressed: () => _searchController.clear(),
                    )
                  : null,
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Colors.grey.withValues(alpha: 0.2),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppTheme.primaryGreen,
                  width: 1.5,
                ),
              ),
            ),
          ),
        ),

        // ── Drone list ──────────────────────────────────────────────────
        Expanded(
          child: filtres.isEmpty
              ? _emptyState()
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: filtres.length,
                  itemBuilder: (_, i) {
                    final drone = filtres[i];
                    final sc = _statusColor(drone.status);
                    final bc = _batteryColor(drone.batteryLevel);
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        splashColor: AppTheme.primaryGreen.withValues(
                          alpha: 0.1,
                        ),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DroneDetailScreen(drone: drone),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Drone id + owner + status + arrow
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: sc.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      Icons.flight_takeoff,
                                      color: sc,
                                      size: 22,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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
                                            fontSize: 13,
                                            color: Colors.grey[600],
                                          ),
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
                                      const SizedBox(width: 4),
                                      Icon(
                                        Icons.chevron_right,
                                        color: Colors.grey[400],
                                        size: 20,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              // Battery level
                              Row(
                                children: [
                                  Icon(
                                    Icons.battery_charging_full,
                                    size: 16,
                                    color: bc,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Batterie',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        value: drone.batteryLevel / 100,
                                        backgroundColor: bc.withValues(
                                          alpha: 0.15,
                                        ),
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
                                  const Icon(
                                    Icons.location_on_outlined,
                                    size: 14,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      drone.location,
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Icon(
                                    Icons.access_time,
                                    size: 14,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _lastSeenLabel(drone.lastSeen),
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _filterChip({
    required String label,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? color : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color, width: 1.5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _emptyState() {
    final hasSearch = _recherche.isNotEmpty;
    final hasFilter = _filtreActif != null;
    final message = hasSearch
        ? 'Aucun drone trouvé pour "$_recherche"'
        : hasFilter
        ? 'Aucun drone dans cette catégorie'
        : 'Aucun drone disponible';

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.airplanemode_inactive, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            message,
            style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
