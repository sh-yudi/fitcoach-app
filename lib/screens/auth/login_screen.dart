import 'package:flutter/material.dart';

import '../../services/api_client.dart';
import '../../services/session.dart';
import '../../theme.dart';
import '../../widgets/profile_avatar.dart';
import '../home/home_shell.dart';
import 'one_tap_consent.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  String? _error;

  // One-tap login state.
  String? _oneTapToken;
  String? _oneTapEmail;
  String? _oneTapName;
  String? _oneTapPhoto;
  bool _oneTapLoading = false;

  @override
  void initState() {
    super.initState();
    _loadOneTap();
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _loadOneTap() async {
    final token = await Session.rememberToken();
    final email = await Session.rememberEmail();
    final name = await Session.rememberName();
    final photo = await Session.rememberPhoto();
    if (!mounted) return;
    setState(() {
      _oneTapToken = token;
      _oneTapEmail = email;
      _oneTapName = name;
      _oneTapPhoto = photo;
    });
  }

  Future<void> _oneTapLogin() async {
    final token = _oneTapToken;
    if (token == null || _oneTapLoading) return;
    setState(() {
      _oneTapLoading = true;
      _error = null;
    });
    try {
      final result = await ApiClient.instance.oneTapLogin(token);
      await Session.save(
        result.token,
        result.user.email,
        name: result.user.name,
        rememberToken: token,
        photo: result.user.displayPhoto,
      );
      ApiClient.instance.setToken(result.token);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeShell()),
      );
    } on ApiException catch (e) {
      setState(() {
        _oneTapLoading = false;
        _error = e.message;
      });
      if (e.statusCode == 401) {
        await Session.clearAll();
        if (!mounted) return;
        setState(() {
          _oneTapToken = null;
          _oneTapEmail = null;
          _oneTapName = null;
          _oneTapPhoto = null;
        });
      }
    }
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await ApiClient.instance.login(_email.text.trim(), _password.text);
      await Session.save(
        result.token,
        result.user.email,
        name: result.user.name,
      );
      ApiClient.instance.setToken(result.token);
      if (!mounted) return;
      // One-time consent dialog (only the very first login on this device).
      await maybePromptOneTapConsent(context);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeShell()),
      );
    } on ApiException catch (e) {
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_oneTapToken != null && _oneTapToken!.isNotEmpty)
                      _OneTapHero(
                        name: _oneTapName,
                        email: _oneTapEmail ?? '',
                        photo: _oneTapPhoto,
                        loading: _oneTapLoading,
                        onTap: _oneTapLogin,
                      )
                    else ...[
                      Container(
                        width: 72,
                        height: 72,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child:  Icon(Icons.fitness_center, color: AppColors.onPrimary, size: 38),
                      ),
                      const SizedBox(height: 24),
                    ],
                    const SizedBox(height: 28),
                    if (_oneTapToken != null && _oneTapToken!.isNotEmpty) ...[
                      const _OrDivider(),
                      const SizedBox(height: 24),
                       Text(
                        'Log in with a different account',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 18),
                    ],
                     Text(
                      'Welcome back',
                      style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 6),
                     Text(
                      'Log in to see your plan',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                    ),
                    const SizedBox(height: 28),
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      autocorrect: false,
                      decoration: const InputDecoration(hintText: 'Email'),
                      validator: (v) =>
                          (v == null || !v.contains('@')) ? 'Enter a valid email' : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _password,
                      obscureText: _obscure,
                      decoration: InputDecoration(
                        hintText: 'Password',
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscure ? Icons.visibility_off : Icons.visibility,
                            color: AppColors.textSecondary,
                          ),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                      validator: (v) => (v == null || v.length < 6) ? 'Minimum 6 characters' : null,
                      onFieldSubmitted: (_) => _login(),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 14),
                      Text(
                        _error!,
                        style:  TextStyle(color: AppColors.danger, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _loading ? null : _login,
                      child: _loading
                          ?  SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.onPrimary),
                            )
                          : const Text('Log in'),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                         Text(
                          "New client? ",
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const RegisterScreen()),
                          ),
                          child:  Text(
                            'Create account',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OneTapHero extends StatelessWidget {
  final String? name;
  final String email;
  final String? photo;
  final bool loading;
  final VoidCallback onTap;
  const _OneTapHero({
    required this.name,
    required this.email,
    this.photo,
    required this.loading,
    required this.onTap,
  });

  String get _initial {
    final n = (name ?? '').trim();
    if (n.isNotEmpty) return n[0].toUpperCase();
    final e = email.trim();
    return e.isNotEmpty ? e[0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: loading ? null : onTap,
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: [
            Container(
              width: 110,
              height: 110,
              clipBehavior: Clip.antiAlias,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF24321A), Color(0xFF4A6B1E)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(40),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.35),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: loading
                  ?  SizedBox(
                      width: 30,
                      height: 30,
                      child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white),
                    )
                  : (photo != null
                      ? ProfileAvatar(
                          photoUrl: !photo!.startsWith('data:') ? photo : null,
                          base64: photo!.startsWith('data:') ? photo : null,
                          size: 30,
                          fallbackIcon: Icons.person,
                        )
                      : _initialText()),
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.bolt, color: AppColors.primary, size: 16),
                const SizedBox(width: 5),
                 Text(
                  'One-tap login · tap to continue',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _initialText() {
    return Center(
      child: Text(
        _initial,
        style: const TextStyle(
          color: Color(0xFFFFF7E2),
          fontSize: 48,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Container(height: 1, color: AppColors.surfaceLight)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child:  Text('OR', style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w700)),
        ),
        Expanded(child: Container(height: 1, color: AppColors.surfaceLight)),
      ],
    );
  }
}
