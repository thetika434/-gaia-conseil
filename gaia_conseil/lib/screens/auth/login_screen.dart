import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import '../../core/theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import '../../data/auth_state.dart';
import '../../widgets/main_scaffold.dart';
import '../../widgets/gaia_background_wrapper.dart';
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
  final _plotCountController = TextEditingController();
  final _totalAreaController = TextEditingController();

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
    _plotCountController.dispose();
    _totalAreaController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    setState(() { _errorMessage = ''; _isLoading = true; });

    final email    = _emailController.text.trim();
    final password = _passwordController.text;

    try {
      final res = await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      final user = res.user;
      if (user == null) throw const AuthException('Connexion échouée.');

      final row = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      final role = row?['role'] as String? ?? 'planteur';
      final name = row?['full_name'] as String? ?? email;

      if (!mounted) return;

      if (role == 'administrateur') {
        AuthState.loginAsAdmin(name: name, userId: user.id);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AdminScaffold()),
        );
      } else {
        AuthState.loginAsUser(name: name, userId: user.id);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainScaffold()),
        );
      }
    } on AuthException catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = _localizeError(e.message);
      });
    } catch (_) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Connexion impossible. Vérifiez votre connexion.';
      });
    }
  }

  String _localizeError(String msg) {
    if (msg.contains('Invalid login credentials')) {
      return 'Email ou mot de passe incorrect.';
    }
    if (msg.contains('Email not confirmed')) {
      return 'Email non confirmé. Vérifiez votre boîte mail.';
    }
    if (msg.contains('User already registered')) {
      return 'Un compte existe déjà avec cet email.';
    }
    if (msg.contains('at least 6 characters')) {
      return 'Le mot de passe doit comporter au moins 6 caractères.';
    }
    return msg;
  }

  Future<void> _handleRegister() async {
    final name    = _nameController.text.trim();
    final raw     = _emailController.text.trim().toLowerCase();
    final password = _passwordController.text;
    final confirm  = _confirmPasswordController.text;

    // Construire l'email complet : ajoute @gaia-ci.com si absent
    final finalEmail = raw.endsWith('@gaia-ci.com')
        ? raw
        : '$raw@gaia-ci.com';

    if (name.isEmpty || raw.isEmpty || password.isEmpty) {
      setState(() { _errorMessage = 'Veuillez remplir tous les champs.'; });
      return;
    }
    if (password != confirm) {
      setState(() { _errorMessage = 'Les mots de passe ne correspondent pas.'; });
      return;
    }
    if (_selectedRegion == null) {
      setState(() { _errorMessage = 'Veuillez sélectionner votre région.'; });
      return;
    }

    setState(() { _isLoading = true; _errorMessage = ''; });

    try {
      final res = await Supabase.instance.client.auth.signUp(
        email: finalEmail,
        password: password,
      );
      final user = res.user;
      if (user == null) throw const AuthException('Inscription échouée.');

      const role = 'planteur';

      final plotCount =
          int.tryParse(_plotCountController.text.trim()) ?? 0;
      final totalArea =
          double.tryParse(_totalAreaController.text.trim().replaceAll(',', '.')) ?? 0.0;

      await Supabase.instance.client.from('profiles').insert({
        'id':         user.id,
        'email':      finalEmail,
        'full_name':  name,
        'role':       role,
        'region':     _selectedRegion,
        'plot_count': plotCount,
        'total_area': totalArea,
      });

      if (!mounted) return;
      AuthState.loginAsUser(name: name, userId: user.id);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainScaffold()),
      );
    } on AuthException catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = _localizeError(e.message);
      });
    } catch (_) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Inscription impossible. Vérifiez votre connexion.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GaiaBackgroundWrapper(
        applyOverlay: true,
        child: Stack(
          children: [
            // Logo and header section
            const Positioned.fill(child: _LoginHero()),
            // Translucent login form card
            Align(
              alignment: Alignment.bottomCenter,
              child: FractionallySizedBox(
                heightFactor: _isRegisterMode ? 0.92 : 0.7,
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(32),
                  ),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(32),
                        ),
                        border: Border(
                          top: BorderSide(
                            color: Colors.white.withValues(alpha: 0.3),
                            width: 1.5,
                          ),
                        ),
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
                            if (_isRegisterMode)
                              _buildIdentifierField()
                            else
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
                                dropdownColor: Colors.white,
                                items: _regions
                                    .map(
                                      (r) => DropdownMenuItem(
                                        value: r,
                                        child: Text(
                                          r,
                                          style: GoogleFonts.poppins(
                                            fontSize: 14,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (v) =>
                                    setState(() => _selectedRegion = v),
                                hint: Text(
                                  'Sélectionner une région',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: Colors.white.withValues(alpha: 0.6),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),
                              _buildTextField(
                                controller: _plotCountController,
                                label: 'Nombre de parcelles',
                                icon: Icons.grid_view_outlined,
                                keyboardType: TextInputType.number,
                              ),
                              const SizedBox(height: 14),
                              _buildTextField(
                                controller: _totalAreaController,
                                label: 'Superficie totale (ha)',
                                icon: Icons.straighten_outlined,
                                keyboardType: const TextInputType.numberWithOptions(
                                  decimal: true,
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
                                  color: Colors.white.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.25),
                                    width: 1.2,
                                  ),
                                ),
                                child: Text(
                                  'Démo — Planteur: paul@gaia-ci.com / paul123\nAdmin: admin@gaia-ci.com / admin123',
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    color: Colors.white.withValues(alpha: 0.85),
                                    fontWeight: FontWeight.w500,
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
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeToggle() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.25),
          width: 1.2,
        ),
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
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.white.withValues(alpha: 0.85),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.25),
              width: 1.2,
            ),
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
              color: selected
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.7),
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
      style: GoogleFonts.poppins(
        fontSize: 14,
        color: Colors.white,
        fontWeight: FontWeight.w500,
      ),
      cursorColor: Colors.white,
      decoration: _inputDecoration(label: label, icon: icon),
    );
  }

  Widget _buildIdentifierField() {
    return TextFormField(
      controller: _emailController,
      keyboardType: TextInputType.text,
      autocorrect: false,
      style: GoogleFonts.poppins(
        fontSize: 14,
        color: Colors.white,
        fontWeight: FontWeight.w500,
      ),
      cursorColor: Colors.white,
      decoration: _inputDecoration(
        label: 'Identifiant',
        icon: Icons.alternate_email,
      ).copyWith(
        hintText: 'ex: kofi.bamba',
        hintStyle: GoogleFonts.poppins(
          fontSize: 13,
          color: Colors.white.withValues(alpha: 0.45),
        ),
        suffixText: '@gaia-ci.com',
        suffixStyle: GoogleFonts.poppins(
          fontSize: 13,
          color: Colors.white.withValues(alpha: 0.55),
          fontWeight: FontWeight.w500,
        ),
      ),
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
      style: GoogleFonts.poppins(
        fontSize: 14,
        color: Colors.white,
        fontWeight: FontWeight.w500,
      ),
      cursorColor: Colors.white,
      decoration: _inputDecoration(label: label, icon: Icons.lock_outline)
          .copyWith(
            suffixIcon: IconButton(
              icon: Icon(
                obscure
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: Colors.white.withValues(alpha: 0.7),
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
      labelStyle: GoogleFonts.poppins(
        fontSize: 14,
        color: Colors.white.withValues(alpha: 0.75),
      ),
      hintStyle: GoogleFonts.poppins(
        fontSize: 14,
        color: Colors.white.withValues(alpha: 0.6),
      ),
      prefixIcon: Icon(
        icon,
        color: AppTheme.primaryGreen.withValues(alpha: 0.95),
        size: 20,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: Colors.white.withValues(alpha: 0.3),
          width: 1.2,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: Colors.white.withValues(alpha: 0.3),
          width: 1.2,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: AppTheme.primaryGreen.withValues(alpha: 0.95),
          width: 1.8,
        ),
      ),
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.08),
      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
    );
  }
}

// ─── Login Hero ───────────────────────────────────────────────────────────────

class _LoginHero extends StatelessWidget {
  const _LoginHero();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
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
    );
  }
}
