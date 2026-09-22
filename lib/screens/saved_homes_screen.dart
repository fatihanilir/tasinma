import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/homes_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/home_list_card.dart';
import 'home_detail_sheet.dart';

class SavedHomesScreen extends StatelessWidget {
  final VoidCallback onAddNew;

  const SavedHomesScreen({
    super.key,
    required this.onAddNew,
  });

  void _showHomeDetail(BuildContext context, String homeId) {
    final provider = context.read<HomesProvider>();
    final home = provider.homes.firstWhere((h) => h.id == homeId);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => HomeDetailSheet(home: home),
    );
  }

  void _confirmDelete(BuildContext context, String homeId, String title) {
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

  @override
  Widget build(BuildContext context) {
    return Consumer<HomesProvider>(
      builder: (context, provider, _) {
        final homes = provider.homes;

        return Column(
          children: [
            Expanded(
              child: homes.isEmpty
                  ? _EmptyState(onAddNew: onAddNew)
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(18, 0, 18, 100),
                      itemCount: homes.length + 1, // +1 for add button
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          // Yeni ev ekle butonu
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: onAddNew,
                                child: const Text('Yeni ev ekle'),
                              ),
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
                            onTap: () => _showHomeDetail(context, home.id),
                            onDelete: () => _confirmDelete(
                              context,
                              home.id,
                              home.displayTitle,
                            ),
                            onMoveUp: () => provider.moveHome(home.id, -1),
                            onMoveDown: () => provider.moveHome(home.id, 1),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
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
