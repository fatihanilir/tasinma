import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';

class AuthScreen extends StatefulWidget {
  final bool forSave;
  final VoidCallback? onSuccess;

  const AuthScreen({
    super.key,
    this.forSave = false,
    this.onSuccess,
  });

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _showEmailForm = false;
  bool _isRegister = false;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSuccess(bool ok) async {
    if (!ok || !mounted) return;
    widget.onSuccess?.call();
    if (widget.forSave && Navigator.canPop(context)) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo
                    ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Image.asset(
                        'assets/logo.png',
                        width: 72,
                        height: 72,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Cebinden Eve',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.fraunces(
                        fontSize: 32,
                        fontWeight: FontWeight.w600,
                        color: AppColors.forest,
                        letterSpacing: -0.03 * 32,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      widget.forSave
                          ? 'Kaydetmek için giriş yapman gerekiyor.'
                          : 'Evin fiyatını değil, gerçek maliyetini hesapla.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        color: AppColors.muted,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 36),
                    Consumer<AuthProvider>(
                      builder: (context, auth, _) {
                        if (auth.isLoading) {
                          return const Padding(
                            padding: EdgeInsets.all(24),
                            child: CircularProgressIndicator(
                              color: AppColors.forest,
                            ),
                          );
                        }

                        return Column(
                          children: [
                            if (!_showEmailForm) ...[
                              _SignInButton(
                                label: 'Google ile devam et',
                                icon: Icons.g_mobiledata_rounded,
                                backgroundColor: Colors.white,
                                textColor: AppColors.ink,
                                onTap: () async {
                                  final ok = await auth.signInWithGoogle();
                                  await _handleSuccess(ok);
                                },
                              ),
                              const SizedBox(height: 12),
                              _SignInButton(
                                label: 'E-posta ile devam et',
                                icon: Icons.mail_outline_rounded,
                                backgroundColor: AppColors.forest,
                                textColor: Colors.white,
                                onTap: () => setState(() => _showEmailForm = true),
                              ),
                              if (!widget.forSave) ...[
                                const SizedBox(height: 20),
                                TextButton(
                                  onPressed: () async {
                                    await auth.continueAsGuest();
                                  },
                                  child: Text(
                                    'Hesapsız devam et',
                                    style: GoogleFonts.outfit(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.forest2,
                                    ),
                                  ),
                                ),
                              ],
                            ] else ...[
                              TextField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                decoration: const InputDecoration(
                                  labelText: 'E-posta',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: _passwordController,
                                obscureText: true,
                                decoration: const InputDecoration(
                                  labelText: 'Şifre',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: () async {
                                    final email = _emailController.text.trim();
                                    final password = _passwordController.text;
                                    if (email.isEmpty || password.isEmpty) {
                                      return;
                                    }
                                    final ok = _isRegister
                                        ? await auth.registerWithEmail(email, password)
                                        : await auth.signInWithEmail(email, password);
                                    await _handleSuccess(ok);
                                  },
                                  child: Text(_isRegister ? 'Kayıt ol' : 'Giriş yap'),
                                ),
                              ),
                              TextButton(
                                onPressed: () => setState(() => _isRegister = !_isRegister),
                                child: Text(
                                  _isRegister
                                      ? 'Zaten hesabın var mı? Giriş yap'
                                      : 'Hesabın yok mu? Kayıt ol',
                                ),
                              ),
                              TextButton(
                                onPressed: () => setState(() => _showEmailForm = false),
                                child: const Text('Geri'),
                              ),
                            ],
                            if (auth.errorMessage != null) ...[
                              const SizedBox(height: 12),
                              Text(
                                auth.errorMessage!,
                                style: GoogleFonts.outfit(
                                  color: AppColors.coral,
                                  fontSize: 13,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'Kişisel veri istemiyoruz.\nSadece hesaplamalarını kaydetmek için.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: AppColors.muted,
                        height: 1.5,
                      ),
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

class _SignInButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color backgroundColor;
  final Color textColor;
  final VoidCallback onTap;

  const _SignInButton({
    required this.label,
    required this.icon,
    required this.backgroundColor,
    required this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.line),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 22, color: textColor),
              const SizedBox(width: 10),
              Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
