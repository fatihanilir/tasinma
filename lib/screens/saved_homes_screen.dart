import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/home_model.dart';
import '../providers/auth_provider.dart';
import '../providers/homes_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/ad_banner_placeholder.dart';
import '../widgets/home_list_card.dart';
import 'compare_homes_screen.dart';
import 'home_detail_sheet.dart';

class SavedHomesScreen extends StatefulWidget {
  final VoidCallback onAddNew;
  final void Function(String homeId)? onEditHome;

  const SavedHomesScreen({
    super.key,
    required this.onAddNew,
    this.onEditHome,
  });

  @override
  State<SavedHomesScreen> createState() => _SavedHomesScreenState();
}

class _SavedHomesScreenState extends State<SavedHomesScreen> {
  bool _selecting = false;
  bool _comparing = false;
  final List<String> _selectedIds = [];

  void _showHomeDetail(String homeId) {
    final provider = context.read<HomesProvider>();
    final home = provider.homes.firstWhere((h) => h.id == homeId);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => HomeDetailSheet(home: home),
    );
  }

  void _confirmDelete(String homeId, String title) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Evi Sil'),
        content: Text('"$title" silinecek. Emin misin?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<HomesProvider>().deleteHome(homeId);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.coral),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }

  void _toggleSelecting() {
    setState(() {
      _selecting = !_selecting;
      _comparing = false;
      _selectedIds.clear();
    });
  }

  void _toggleSelected(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        if (_selectedIds.length == 2) _selectedIds.removeAt(0);
        _selectedIds.add(id);
      }
    });
  }

  void _openCompare() {
    if (_selectedIds.length != 2) return;
    setState(() {
      _comparing = true;
      _selecting = false;
    });
  }

  void _closeCompare() {
    setState(() {
      _comparing = false;
      _selectedIds.clear();
    });
  }

  void _setCompareHome(int slot, String id) {
    setState(() {
      if (_selectedIds.length < 2) {
        _selectedIds.add(id);
        return;
      }
      final other = _selectedIds[1 - slot];
      if (id == other) {
        // Seçilen zaten diğer taraftaysa yer değiştir
        final tmp = _selectedIds[0];
        _selectedIds[0] = _selectedIds[1];
        _selectedIds[1] = tmp;
      } else {
        _selectedIds[slot] = id;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<HomesProvider>(
      builder: (context, provider, _) {
        final homes = provider.homes;
        _selectedIds.removeWhere((id) => !homes.any((h) => h.id == id));
        if (_comparing && _selectedIds.length < 2) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _comparing = false);
          });
        }
        final canCompare = homes.length >= 2;

        if (_comparing && _selectedIds.length == 2) {
          final a = homes.firstWhere((h) => h.id == _selectedIds[0]);
          final b = homes.firstWhere((h) => h.id == _selectedIds[1]);
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
                child: _ComparePickerBar(
                  homes: homes,
                  idA: _selectedIds[0],
                  idB: _selectedIds[1],
                  onChangedA: (id) => _setCompareHome(0, id),
                  onChangedB: (id) => _setCompareHome(1, id),
                  onBack: _closeCompare,
                ),
              ),
              Expanded(child: CompareHomesView(a: a, b: b)),
            ],
          );
        }

        if (homes.isEmpty) {
          final showAds = context.watch<AuthProvider>().showAds;
          return LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
                  child: Column(
                    children: [
                      _EmptyState(onAddNew: widget.onAddNew),
                      if (showAds) ...[
                        const SizedBox(height: 14),
                        const AdBannerPlaceholder(
                          label: 'Kayıtlı evler · boş liste',
                          unit: AdUnit.inArticle,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        return Column(
          children: [
            Expanded(
              child: Builder(
                builder: (context) {
                  final showAds = context.watch<AuthProvider>().showAds;
                  final insertAdAfterHome =
                      showAds ? (homes.length >= 2 ? 1 : 0) : -1;
                  final adSlots = insertAdAfterHome >= 0 ? 1 : 0;
                  final itemCount = homes.length + 1 + adSlots;

                  return ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
                    itemCount: itemCount,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: _selecting
                              ? _SelectionHint(
                                  count: _selectedIds.length,
                                  onCancel: _toggleSelecting,
                                )
                              : Row(
                                  children: [
                                    Expanded(
                                      child: ElevatedButton(
                                        onPressed: widget.onAddNew,
                                        child: const Text('Yeni ev ekle'),
                                      ),
                                    ),
                                    if (canCompare) ...[
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          onPressed: _toggleSelecting,
                                          style: OutlinedButton.styleFrom(
                                            side: const BorderSide(
                                                color: AppColors.forest,
                                                width: 1.5),
                                          ),
                                          icon: const Icon(
                                              Icons.compare_arrows_rounded,
                                              size: 18),
                                          label: const Text('Karşılaştır'),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                        );
                      }

                      if (insertAdAfterHome >= 0) {
                        final adListIndex = insertAdAfterHome + 2;
                        if (index == adListIndex) {
                          return const Padding(
                            padding: EdgeInsets.only(bottom: 14),
                            child: const AdBannerPlaceholder(
                              label: 'Kayıtlı evler · 2. ilan sonrası',
                              unit: AdUnit.inArticle,
                            ),
                          );
                        }
                      }

                      var homeIndex = index - 1;
                      if (insertAdAfterHome >= 0 &&
                          index > insertAdAfterHome + 2) {
                        homeIndex -= 1;
                      }

                      final home = homes[homeIndex];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: HomeListCard(
                          home: home,
                          isFirst: homeIndex == 0,
                          isLast: homeIndex == homes.length - 1,
                          selectionMode: _selecting,
                          isSelected: _selectedIds.contains(home.id),
                          onTap: _selecting
                              ? () => _toggleSelected(home.id)
                              : () => _showHomeDetail(home.id),
                          onEdit: widget.onEditHome != null
                              ? () => widget.onEditHome!(home.id)
                              : null,
                          onDelete: () =>
                              _confirmDelete(home.id, home.displayTitle),
                          onMoveUp: () => provider.moveHome(home.id, -1),
                          onMoveDown: () => provider.moveHome(home.id, 1),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            if (_selecting)
              Container(
                padding: EdgeInsets.fromLTRB(
                  18,
                  12,
                  18,
                  12 + MediaQuery.of(context).padding.bottom,
                ),
                decoration: const BoxDecoration(
                  color: Color(0xFFEFE6D8),
                  border: Border(
                    top: BorderSide(color: AppColors.line, width: 1),
                  ),
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _selectedIds.length == 2 ? _openCompare : null,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(
                      _selectedIds.length == 2
                          ? 'Karşılaştır'
                          : 'İki ev seç (${_selectedIds.length}/2)',
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _ComparePickerBar extends StatelessWidget {
  final List<HomeModel> homes;
  final String idA;
  final String idB;
  final ValueChanged<String> onChangedA;
  final ValueChanged<String> onChangedB;
  final VoidCallback onBack;

  const _ComparePickerBar({
    required this.homes,
    required this.idA,
    required this.idB,
    required this.onChangedA,
    required this.onChangedB,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.72),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: onBack,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.arrow_back_rounded,
                        size: 18, color: AppColors.forest),
                    const SizedBox(width: 4),
                    Text(
                      'Listeye dön',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.forest,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                'Karşılaştır',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.muted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Karşılaştırılacak evleri değiştir',
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.muted,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _HomeDropdown(
                  homes: homes,
                  valueId: idA,
                  onChanged: onChangedA,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  'vs',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.forest2,
                  ),
                ),
              ),
              Expanded(
                child: _HomeDropdown(
                  homes: homes,
                  valueId: idB,
                  onChanged: onChangedB,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HomeDropdown extends StatelessWidget {
  final List<HomeModel> homes;
  final String valueId;
  final ValueChanged<String> onChanged;

  const _HomeDropdown({
    required this.homes,
    required this.valueId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.goldSoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.line),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: valueId,
          icon: const Icon(Icons.expand_more_rounded,
              color: AppColors.forest, size: 20),
          style: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.forest,
          ),
          dropdownColor: const Color(0xFFFFFDF8),
          items: homes
              .map(
                (h) => DropdownMenuItem(
                  value: h.id,
                  child: Text(
                    h.displayTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(),
          onChanged: (id) {
            if (id != null) onChanged(id);
          },
        ),
      ),
    );
  }
}

class _SelectionHint extends StatelessWidget {
  final int count;
  final VoidCallback onCancel;

  const _SelectionHint({required this.count, required this.onCancel});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
      decoration: BoxDecoration(
        color: AppColors.goldSoft,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.touch_app_outlined,
              size: 18, color: AppColors.forest),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Karşılaştırmak için iki ev seç',
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.forest,
              ),
            ),
          ),
          TextButton(
            onPressed: onCancel,
            child: Text(
              'Vazgeç',
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.coral,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAddNew;

  const _EmptyState({required this.onAddNew});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Henüz ev yok',
                  style: GoogleFonts.fraunces(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: AppColors.forest,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Hesap sekmesinden bir ilan kaydedin.',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    color: AppColors.muted,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: onAddNew,
                  child: const Text('Yeni ev ekle'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
