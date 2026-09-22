import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/homes_provider.dart';
import '../theme/app_theme.dart';
import 'auth_screen.dart';
import 'calculator_screen.dart';
import 'saved_homes_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentTab = 0; // 0: Hesap, 1: Kayıtlı evler

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HomesProvider>().startListening();
    });
  }

  void _showToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.forest,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<bool> _ensureLoggedInForSave() async {
    final auth = context.read<AuthProvider>();
    if (auth.isAuthenticated) return true;

    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => const AuthScreen(forSave: true),
        fullscreenDialog: true,
      ),
    );
    return result == true && context.read<AuthProvider>().isAuthenticated;
  }

  void _onSave() async {
    final loggedIn = await _ensureLoggedInForSave();
    if (!loggedIn) {
      _showToast('Kaydetmek için giriş yapmalısın');
      return;
    }

    // Giriş sonrası cloud moda geç
    context.read<HomesProvider>().setCloudMode(true);

    final provider = context.read<HomesProvider>();
    final success = await provider.saveCurrentHome();
    if (success) {
      _showToast('Kaydedildi');
      setState(() => _currentTab = 1);
    } else if (provider.errorMessage != null) {
      _showToast(provider.errorMessage!);
      provider.clearError();
    }
  }

  void _onNew() {
    context.read<HomesProvider>().resetForm();
    setState(() => _currentTab = 0);
    _showToast('Yeni ev');
  }

  void _onAddFromList() {
    context.read<HomesProvider>().resetForm();
    setState(() => _currentTab = 0);
  }

  void _onEditHome(String homeId) {
    final provider = context.read<HomesProvider>();
    final home = provider.homes.firstWhere((h) => h.id == homeId);
    provider.selectHomeForEdit(home);
    setState(() => _currentTab = 0);
    _showToast('Düzenleme modu');
  }

  Future<void> _onSignOut() async {
    await context.read<AuthProvider>().signOut();
    context.read<HomesProvider>().setCloudMode(false);
  }

  String get _pageLead {
    if (_currentTab == 1) {
      return 'Oklarla sırayı değiştirin; kayıtlar hesabına bağlı.';
    }
    return 'İlan fiyatını gir, eve girene kadar cebinden çıkacak toplam parayı hesaplayalım.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.bgGradient,
        ),
        child: SafeArea(
          bottom: false,
          // Ortala ve max 560px genişlik (CSS: width: min(560px, 100%); margin: 0 auto;)
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 560),
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 4, 18, 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Logo ve başlık
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Logo
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.forest.withOpacity(0.15),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.asset(
                                  'assets/logo.png',
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Başlık ve alt yazı
                            Expanded(
                              child: Consumer<HomesProvider>(
                                builder: (context, provider, _) {
                                  final title = _currentTab == 1
                                      ? 'Kayıtlı Evler'
                                      : (provider.tempHome.title.isNotEmpty
                                          ? provider.tempHome.title
                                          : 'Cebinden Eve');
                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        title,
                                        style: GoogleFonts.fraunces(
                                          fontSize: 24,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: -0.02 * 24,
                                          color: AppColors.forest,
                                        ),
                                      ),
                                      if (_currentTab == 0 && provider.tempHome.title.isEmpty)
                                        Text(
                                          'Ev maliyet hesaplayıcı',
                                          style: GoogleFonts.outfit(
                                            fontSize: 12,
                                            color: AppColors.muted,
                                          ),
                                        ),
                                    ],
                                  );
                                },
                              ),
                            ),
                            // Girişli ise çıkış, misafirse giriş
                            Consumer<AuthProvider>(
                              builder: (context, auth, _) {
                                if (auth.isAuthenticated) {
                                  return GestureDetector(
                                    onTap: _onSignOut,
                                    child: const Icon(
                                      Icons.logout_rounded,
                                      size: 20,
                                      color: AppColors.muted,
                                    ),
                                  );
                                }
                                return GestureDetector(
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => const AuthScreen(forSave: true),
                                        fullscreenDialog: true,
                                      ),
                                    );
                                  },
                                  child: Text(
                                    'Giriş',
                                    style: GoogleFonts.outfit(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.forest,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _pageLead,
                          style: GoogleFonts.outfit(
                            fontSize: 15,
                            color: AppColors.muted,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Tabs
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.goldSoft,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _TabButton(
                              label: 'Hesap',
                              isSelected: _currentTab == 0,
                              onTap: () => setState(() => _currentTab = 0),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _TabButton(
                              label: 'Kayıtlı evler',
                              isSelected: _currentTab == 1,
                              onTap: () => setState(() => _currentTab = 1),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Content
                  Expanded(
                    child: _currentTab == 0
                        ? CalculatorScreen(
                            onSave: _onSave,
                            onNew: _onNew,
                          )
                        : SavedHomesScreen(
                            onAddNew: _onAddFromList,
                            onEditHome: _onEditHome,
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.forest : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.forest.withOpacity(0.22),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isSelected ? AppColors.white : AppColors.forest2,
          ),
        ),
      ),
    );
  }
}
