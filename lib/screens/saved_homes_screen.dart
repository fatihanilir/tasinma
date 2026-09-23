import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/homes_provider.dart';
import '../theme/app_theme.dart';
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
    final homes = context.read<HomesProvider>().homes;
    final a = homes.where((h) => h.id == _selectedIds[0]).firstOrNull;
    final b = homes.where((h) => h.id == _selectedIds[1]).firstOrNull;
    if (a == null || b == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => CompareHomesScreen(a: a, b: b)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<HomesProvider>(
      builder: (context, provider, _) {
        final homes = provider.homes;
        _selectedIds.removeWhere((id) => !homes.any((h) => h.id == id));
        final canCompare = homes.length >= 2;

        if (homes.isEmpty) {
          return LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: _EmptyState(onAddNew: widget.onAddNew),
              ),
            ),
          );
        }

        return Column(
          children: [
            Expanded(
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
                itemCount: homes.length + 1,
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

                  final home = homes[index - 1];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: HomeListCard(
                      home: home,
                      isFirst: index == 1,
                      isLast: index == homes.length,
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
