import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import '../../core/theme.dart';
import '../../data/auth_state.dart';
import '../../widgets/gaia_background_wrapper.dart';
import '../auth/login_screen.dart';
import 'dashboard/admin_dashboard_screen.dart';
import 'users/users_screen.dart';
import 'drones/drones_screen.dart';
import 'messaging/admin_messaging_screen.dart';
import 'ai_advice/ai_advice_screen.dart';

class AdminScaffold extends StatefulWidget {
  const AdminScaffold({super.key});

  @override
  State<AdminScaffold> createState() => _AdminScaffoldState();
}

class _AdminScaffoldState extends State<AdminScaffold> {
  int _selectedIndex = 0;
  late final List<Widget> _screens;

  static const List<_NavItem> _navItems = [
    _NavItem(icon: Icons.dashboard_outlined, label: 'Tableau de Bord'),
    _NavItem(icon: Icons.people_outline, label: 'Utilisateurs'),
    _NavItem(icon: Icons.flight_takeoff_outlined, label: 'Drones'),
    _NavItem(icon: Icons.chat_bubble_outline, label: 'Messagerie'),
    _NavItem(icon: Icons.auto_awesome_outlined, label: 'Conseil IA'),
  ];

  @override
  void initState() {
    super.initState();
    _screens = [
      AdminDashboardScreen(onNavigate: _navigateTo),
      const UsersScreen(),
      const DronesScreen(),
      const AdminMessagingScreen(),
      AiAdviceScreen(onNavigateToChat: _navigateToChat),
    ];
  }

  void _navigateTo(int index) => setState(() => _selectedIndex = index);

  // Called from AiAdviceScreen chat button — switches to Messagerie tab.
  void _navigateToChat(String userId) => setState(() => _selectedIndex = 3);

  void _logout() {
    AuthState.logout();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 600;

    return GaiaBackgroundWrapper(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBody: true,
        drawer: isWide ? null : _buildDrawer(),
        body: Column(
          children: [
            // ── Fixed header ────────────────────────────────────────────
            _AdminHeader(
              onLogout: _logout,
              showMenuIcon: !isWide,
            ),
            // ── Body ───────────────────────────────────────────────────
            Expanded(
              child: isWide
                  ? Row(
                      children: [
                        _Sidebar(
                          selectedIndex: _selectedIndex,
                          navItems: _navItems,
                          onSelect: (i) => setState(() => _selectedIndex = i),
                        ),
                        Expanded(
                          child: IndexedStack(
                            index: _selectedIndex,
                            children: _screens,
                          ),
                        ),
                      ],
                    )
                  : IndexedStack(
                      index: _selectedIndex,
                      children: _screens,
                    ),
            ),
          ],
        ),
        bottomNavigationBar: isWide
            ? null
            : ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: BottomNavigationBar(
                    currentIndex: _selectedIndex,
                    onTap: (i) => setState(() => _selectedIndex = i),
                    backgroundColor: Colors.black.withValues(alpha: 0.35),
                    selectedItemColor: AppTheme.accentGold,
                    unselectedItemColor: Colors.white54,
                    type: BottomNavigationBarType.fixed,
                    selectedLabelStyle: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                    unselectedLabelStyle: GoogleFonts.poppins(fontSize: 10),
                    items: _navItems
                        .map((item) => BottomNavigationBarItem(
                              icon: Icon(item.icon),
                              label: item.label,
                            ))
                        .toList(),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: Colors.black.withValues(alpha: 0.75),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  const Icon(Icons.eco, color: AppTheme.accentGold, size: 28),
                  const SizedBox(width: 10),
                  Text(
                    'RELYAS',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.white24),
            Expanded(
              child: ListView.builder(
                itemCount: _navItems.length,
                itemBuilder: (_, i) => _SidebarTile(
                  item: _navItems[i],
                  selected: _selectedIndex == i,
                  onTap: () {
                    setState(() => _selectedIndex = i);
                    Navigator.pop(context);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _AdminHeader extends StatelessWidget {
  final VoidCallback onLogout;
  final bool showMenuIcon;

  const _AdminHeader({required this.onLogout, required this.showMenuIcon});

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: _AdminHeaderContent(onLogout: onLogout, showMenuIcon: showMenuIcon),
      ),
    );
  }
}

class _AdminHeaderContent extends StatelessWidget {
  final VoidCallback onLogout;
  final bool showMenuIcon;

  const _AdminHeaderContent({
    required this.onLogout,
    required this.showMenuIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.35),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        bottom: 8,
        left: 16,
        right: 8,
      ),
      child: Row(
        children: [
          if (showMenuIcon)
            Builder(
              builder: (ctx) => IconButton(
                icon: const Icon(Icons.menu, color: Colors.white),
                onPressed: () => Scaffold.of(ctx).openDrawer(),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ),
          if (showMenuIcon) const SizedBox(width: 8),
          const Icon(Icons.eco, color: AppTheme.accentGold, size: 22),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'RELYAS Centre de Commande',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Flexible(
            child: Text(
              AuthState.currentUserName,
              style: GoogleFonts.poppins(
                color: Colors.white70,
                fontSize: 12,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white70, size: 20),
            onPressed: onLogout,
            tooltip: 'Déconnexion',
          ),
        ],
      ),
    );
  }
}

// ── Sidebar ───────────────────────────────────────────────────────────────────

class _Sidebar extends StatelessWidget {
  final int selectedIndex;
  final List<_NavItem> navItems;
  final void Function(int) onSelect;

  const _Sidebar({
    required this.selectedIndex,
    required this.navItems,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: 200,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.45),
            border: Border(
              right: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
            ),
          ),
          child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.eco, color: AppTheme.accentGold, size: 22),
                const SizedBox(width: 8),
                Text(
                  'GAÏA Admin',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white24, height: 1),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: navItems.length,
              itemBuilder: (_, i) => _SidebarTile(
                item: navItems[i],
                selected: selectedIndex == i,
                onTap: () => onSelect(i),
              ),
            ),
          ),
        ],
          ),
        ),
      ),
    );
  }
}

class _SidebarTile extends StatelessWidget {
  final _NavItem item;
  final bool selected;
  final VoidCallback onTap;

  const _SidebarTile({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppTheme.accentGold : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(
              item.icon,
              color: selected ? Colors.white : Colors.white54,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                item.label,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight:
                      selected ? FontWeight.w600 : FontWeight.normal,
                  color: selected ? Colors.white : Colors.white54,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Nav item model ────────────────────────────────────────────────────────────

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}
