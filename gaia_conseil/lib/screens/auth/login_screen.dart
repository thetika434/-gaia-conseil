import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme.dart';
import '../../data/auth_state.dart';
import '../../widgets/main_scaffold.dart';
import '../../widgets/gaia_logo_mark.dart';
import '../admin/admin_scaffold.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isAdmin = false;
  bool _isRegisterMode = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  String _errorMessage = '';
  String? _selectedRegion;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  static const _regions = [
    'Yamoussoukro',
    'Abidjan',
    'Daloa',
    'Bouaké',
    'San-Pédro',
    'Soubré',
    'Gagnoa',
    'Divo',
    'Abengourou',
  ];

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    setState(() {
      _errorMessage = '';
      _isLoading = true;
    });
    await Future.delayed(const Duration(milliseconds: 600));

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (_isAdmin) {
      if (email == 'admin@gaia-ci.com' && password == 'admin123') {
        AuthState.loginAsAdmin('Administrateur GAÏA');
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AdminScaffold()),
        );
        return;
      }
      setState(() {
        _isLoading = false;
        _errorMessage = 'Identifiants administrateur incorrects.';
      });
    } else {
      if (email == 'paul@gaia-ci.com' && password == 'paul123') {
        AuthState.loginAsUser('Paul Kouamé');
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainScaffold()),
        );
        return;
      }
      setState(() {
        _isLoading = false;
        _errorMessage = 'Email ou mot de passe incorrect.';
      });
    }
  }

  Future<void> _handleRegister() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmPasswordController.text;

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      setState(() {
        _errorMessage = 'Veuillez remplir tous les champs.';
      });
      return;
    }
    if (password != confirm) {
      setState(() {
        _errorMessage = 'Les mots de passe ne correspondent pas.';
      });
      return;
    }
    if (_selectedRegion == null) {
      setState(() {
        _errorMessage = 'Veuillez sélectionner votre région.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    await Future.delayed(const Duration(milliseconds: 800));

    AuthState.loginAsUser(name);
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const MainScaffold()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        // Utilisation de Stack pour superposer les widgets
        children: [
          const Positioned.fill(child: _LoginHero()),
          Align(
            // Positionne le formulaire en bas
            alignment: Alignment.bottomCenter,
            child: FractionallySizedBox(
              // Contrôle la hauteur du formulaire dynamiquement
              heightFactor: _isRegisterMode
                  ? 0.8
                  : 0.7, // Ajuste la hauteur selon le mode
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(28, 28, 28, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildModeToggle(),
                      const SizedBox(height: 20),
                      if (!_isRegisterMode) ...[
                        _buildRoleToggle(),
                        const SizedBox(height: 20),
                      ],
                      if (_isRegisterMode) ...[
                        _buildTextField(
                          controller: _nameController,
                          label: 'Nom complet',
                          icon: Icons.person_outline,
                        ),
                        const SizedBox(height: 14),
                      ],
                      _buildTextField(
                        controller: _emailController,
                        label: 'Email',
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 14),
                      _buildPasswordField(
                        controller: _passwordController,
                        label: 'Mot de passe',
                        obscure: _obscurePassword,
                        onToggle: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                      ),
                      if (_isRegisterMode) ...[
                        const SizedBox(height: 14),
                        _buildPasswordField(
                          controller: _confirmPasswordController,
                          label: 'Confirmer le mot de passe',
                          obscure: _obscureConfirmPassword,
                          onToggle: () => setState(
                            () => _obscureConfirmPassword =
                                !_obscureConfirmPassword,
                          ),
                        ),
                        const SizedBox(height: 14),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedRegion,
                          decoration: _inputDecoration(
                            label: 'Région',
                            icon: Icons.location_on_outlined,
                          ),
                          items: _regions
                              .map(
                                (r) => DropdownMenuItem(
                                  value: r,
                                  child: Text(
                                    r,
                                    style: GoogleFonts.poppins(fontSize: 14),
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (v) => setState(() => _selectedRegion = v),
                          hint: Text(
                            'Sélectionner une région',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 14),
                      if (_errorMessage.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(
                            _errorMessage,
                            style: GoogleFonts.poppins(
                              color: AppTheme.errorRed,
                              fontSize: 13,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      SizedBox(
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _isLoading
                              ? null
                              : (_isRegisterMode
                                    ? _handleRegister
                                    : _handleLogin),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryGreen,
                            foregroundColor: AppTheme.accentGold,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: AppTheme.accentGold,
                                  ),
                                )
                              : Text(
                                  _isRegisterMode
                                      ? "S'inscrire"
                                      : 'Se connecter',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.accentGold,
                                  ),
                                ),
                        ),
                      ),
                      if (!_isRegisterMode) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0F7F0),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: AppTheme.primaryGreen.withValues(
                                alpha: 0.2,
                              ),
                            ),
                          ),
                          child: Text(
                            'Démo — Planteur: paul@gaia-ci.com / paul123\nAdmin: admin@gaia-ci.com / admin123',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeToggle() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF0F0F0),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _buildToggleTab(
            label: 'Se connecter',
            selected: !_isRegisterMode,
            onTap: () => setState(() {
              _isRegisterMode = false;
              _errorMessage = '';
            }),
          ),
          _buildToggleTab(
            label: "S'inscrire",
            selected: _isRegisterMode,
            onTap: () => setState(() {
              _isRegisterMode = true;
              _isAdmin = false;
              _errorMessage = '';
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleToggle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Connexion en tant que :',
          style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF0F0F0),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(4),
          child: Row(
            children: [
              _buildToggleTab(
                label: 'Planteur',
                selected: !_isAdmin,
                onTap: () => setState(() => _isAdmin = false),
                color: AppTheme.primaryGreen,
              ),
              _buildToggleTab(
                label: 'Administrateur',
                selected: _isAdmin,
                onTap: () => setState(() => _isAdmin = true),
                color: AppTheme.primaryGreen,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildToggleTab({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    Color? color,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? (color ?? AppTheme.accentGold)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : Colors.grey,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: GoogleFonts.poppins(fontSize: 14),
      decoration: _inputDecoration(label: label, icon: icon),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool obscure,
    required VoidCallback onToggle,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      style: GoogleFonts.poppins(fontSize: 14),
      decoration: _inputDecoration(label: label, icon: Icons.lock_outline)
          .copyWith(
            suffixIcon: IconButton(
              icon: Icon(
                obscure
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: Colors.grey,
              ),
              onPressed: onToggle,
            ),
          ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.poppins(fontSize: 14, color: Colors.grey),
      prefixIcon: Icon(icon, color: AppTheme.primaryGreen, size: 20),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.primaryGreen, width: 1.8),
      ),
      filled: true,
      fillColor: const Color(0xFFFAFAFA),
      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
    );
  }
}

// ─── Login Hero ───────────────────────────────────────────────────────────────

class _LoginHero extends StatelessWidget {
  const _LoginHero();

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          'assets/images/fond.png',
          fit: BoxFit.cover,
          alignment: Alignment.center,
          repeat: ImageRepeat.noRepeat,
        ),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.22),
                Colors.black.withValues(alpha: 0.45),
              ],
            ),
          ),
        ),
        Align(
          alignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const GaiaLogoMark(size: 96),
              const SizedBox(height: 14),
              Text(
                'GAÏA-Conseil',
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "Projet GAÏA-CI · Côte d'Ivoire",
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: Colors.white70,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
