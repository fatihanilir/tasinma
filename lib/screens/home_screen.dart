import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/homes_provider.dart';
import '../theme/app_theme.dart';
import '../utils/page_reload.dart';
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
  bool _compact = false;

  void _selectTab(int tab) {
    setState(() {
      _currentTab = tab;
      _compact = false;
    });
  }

  bool _onScroll(ScrollNotification n) {
    if (n.depth != 0 || n.metrics.axis != Axis.vertical) return false;
    final px = n.metrics.pixels;
    // Eşikler farklı: başlık küçülünce viewport değişip titreme yapmasın.
    if (!_compact && px > 40) {
      setState(() => _compact = true);
    } else if (_compact && px < 8) {
      setState(() => _compact = false);
    }
    return false;
  }

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
      _selectTab(1);
    } else if (provider.errorMessage != null) {
      _showToast(provider.errorMessage!);
      provider.clearError();
    }
  }

  void _onNew() {
    context.read<HomesProvider>().resetForm();
    _selectTab(0);
    _showToast('Yeni ev');
  }

  void _onAddFromList() {
    context.read<HomesProvider>().resetForm();
    _selectTab(0);
  }

  void _onEditHome(String homeId) {
    final provider = context.read<HomesProvider>();
    final home = provider.homes.firstWhere((h) => h.id == homeId);
    provider.selectHomeForEdit(home);
    _selectTab(0);
    _showToast('Düzenleme modu');
  }

  static const double _pullThreshold = 80;
  double _pull = 0;
  bool _pulling = false;
  bool _refreshing = false;

  void _onPullStart() {
    if (_refreshing) return;
    setState(() => _pulling = true);
  }

  void _onPullUpdate(double dy) {
    if (_refreshing) return;
    // Yarı hızda uzasın; çekme hissi versin.
    setState(() => _pull = (_pull + dy * 0.5).clamp(0.0, 110.0));
  }

  Future<void> _onPullEnd() async {
    if (_refreshing) return;
    final trigger = _pull >= _pullThreshold;
    setState(() {
      _pulling = false;
      _pull = 0;
      _refreshing = trigger;
    });
    if (!trigger) return;
    await _onRefresh();
    if (mounted) setState(() => _refreshing = false);
  }

  Future<void> _onRefresh() async {
    if (reloadPage()) return;
    await context.read<HomesProvider>().refresh();
  }

  Future<void> _onSignOut() async {
    await context.read<AuthProvider>().signOut();
    context.read<HomesProvider>().setCloudMode(false);
  }

  String? get _pageLead {
    if (_currentTab == 1) return null;
    return 'İlandaki fiyatı değil, evin gerçek maliyetini hesaplayalım.';
  }

  @override
  Widget build(BuildContext context) {
    // iOS Chrome/Safari klavye açınca Scaffold'u küçültmesin —
    // aksi halde Yeni ev/Kaydet yukarı kayıp altta boşluk oluşuyor.
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
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
                  // Header — aşağı çekince sayfa yenilenir
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onVerticalDragStart: (_) => _onPullStart(),
                    onVerticalDragUpdate: (d) => _onPullUpdate(d.delta.dy),
                    onVerticalDragEnd: (_) => _onPullEnd(),
                    onVerticalDragCancel: _onPullEnd,
                    child: Column(
                      children: [
                        AnimatedContainer(
                          duration: _pulling
                              ? Duration.zero
                              : const Duration(milliseconds: 220),
                          curve: Curves.easeOut,
                          height: _refreshing ? 48 : _pull,
                          alignment: Alignment.center,
                          child: (_pull > 8 || _refreshing)
                              ? SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: AppColors.forest,
                                    backgroundColor: AppColors.forest
                                        .withOpacity(0.1),
                                    value: _refreshing
                                        ? null
                                        : (_pull / _pullThreshold).clamp(
                                            0.0,
                                            1.0,
                                          ),
                                  ),
                                )
                              : null,
                        ),
                        Padding(
                          padding: EdgeInsets.fromLTRB(
                            18,
                            4,
                            18,
                            _compact ? 10 : 18,
                          ),
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
                                          color: AppColors.forest.withOpacity(
                                            0.15,
                                          ),
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
                                            : (provider
                                                      .tempHome
                                                      .title
                                                      .isNotEmpty
                                                  ? provider.tempHome.title
                                                  : 'Cebinden Eve');
                                        return Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
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
                                            if (_currentTab == 0 &&
                                                provider.tempHome.title.isEmpty)
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
                                              builder: (_) => const AuthScreen(
                                                forSave: true,
                                              ),
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
                              AnimatedSize(
                                duration: const Duration(milliseconds: 200),
                                curve: Curves.easeOut,
                                alignment: Alignment.topLeft,
                                child: (_pageLead == null || _compact)
                                    ? const SizedBox(width: double.infinity)
                                    : Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Text(
                                          _pageLead!,
                                          style: GoogleFonts.outfit(
                                            fontSize: 15,
                                            color: AppColors.muted,
                                            height: 1.5,
                                          ),
                                        ),
                                      ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Tabs
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: EdgeInsets.all(_compact ? 4 : 6),
                      decoration: BoxDecoration(
                        color: AppColors.goldSoft,
                        borderRadius: BorderRadius.circular(_compact ? 13 : 16),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _TabButton(
                              label: 'Hesap',
                              isSelected: _currentTab == 0,
                              compact: _compact,
                              onTap: () => _selectTab(0),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _TabButton(
                              label: 'Kayıtlı evler',
                              isSelected: _currentTab == 1,
                              compact: _compact,
                              onTap: () => _selectTab(1),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: _compact ? 10 : 16,
                  ),

                  // Content
                  Expanded(
                    child: NotificationListener<ScrollNotification>(
                      onNotification: _onScroll,
                      child: _currentTab == 0
                          ? CalculatorScreen(onSave: _onSave, onNew: _onNew)
                          : SavedHomesScreen(
                              onAddNew: _onAddFromList,
                              onEditHome: _onEditHome,
                            ),
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
  final bool compact;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.symmetric(vertical: compact ? 6 : 11),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.forest : Colors.transparent,
          borderRadius: BorderRadius.circular(compact ? 10 : 12),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.forest.withOpacity(0.22),
                    blurRadius: compact ? 8 : 18,
                    offset: Offset(0, compact ? 3 : 8),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
            fontSize: compact ? 13 : 14,
            fontWeight: FontWeight.w600,
            color: isSelected ? AppColors.white : AppColors.forest2,
          ),
        ),
      ),
    );
  }
}
