import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/homes_provider.dart';
import '../theme/app_theme.dart';
import '../utils/app_links.dart';

class BlockedScreen extends StatelessWidget {
  const BlockedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.block_rounded,
                      size: 48,
                      color: AppColors.coral,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Hesabınız askıya alındı',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.fraunces(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: AppColors.forest,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Bu hesap kullanım koşullarına aykırı kullanım nedeniyle askıya alındı. '
                      'Bir hata olduğunu düşünüyorsanız ${AppLinks.supportEmail} adresine yazabilirsiniz.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        color: AppColors.muted,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextButton(
                      onPressed: () async {
                        final homes = context.read<HomesProvider>();
                        await context.read<AuthProvider>().signOut();
                        homes.setCloudMode(false);
                      },
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
