import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/homes_provider.dart';
import '../theme/app_theme.dart';
import 'auth_screen.dart';

/// Metinler yayımlanmadan önce kaydolmuş ya da metin sürümü değişmiş
/// kullanıcılar için tek seferlik onay ekranı.
class ConsentScreen extends StatefulWidget {
  const ConsentScreen({super.key});

  @override
  State<ConsentScreen> createState() => _ConsentScreenState();
}

class _ConsentScreenState extends State<ConsentScreen> {
  bool _checked = false;
  bool _saving = false;

  Future<void> _accept() async {
    setState(() => _saving = true);
    await context.read<AuthProvider>().acceptConsent();
    if (mounted) setState(() => _saving = false);
  }

  Future<void> _signOut() async {
    await context.read<AuthProvider>().signOut();
    if (mounted) context.read<HomesProvider>().setCloudMode(false);
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
                  children: [
                    const Icon(
                      Icons.verified_user_outlined,
                      size: 48,
                      color: AppColors.forest,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Gizlilik ve kullanım koşulları',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.fraunces(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: AppColors.forest,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Hesabınızda yalnızca e-posta adresinizi ve kaydettiğiniz hesaplamaları saklıyoruz. '
                      'Devam etmek için güncel metinleri onaylamanız gerekiyor.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        color: AppColors.muted,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 28),
                    ConsentCheckbox(
                      value: _checked,
                      onChanged: (v) => setState(() => _checked = v),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _checked && !_saving ? _accept : null,
                        child: _saving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Onaylıyorum, devam et'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _saving ? null : _signOut,
                      child: const Text('Çıkış yap'),
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
