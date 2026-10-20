import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../services/admin_service.dart';
import '../services/feedback_service.dart';
import '../theme/app_theme.dart';
import '../utils/app_links.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final _adminService = AdminService();
  final _feedbackService = FeedbackService();
  final _dateFormat = DateFormat('dd.MM.yyyy HH:mm');

  AdminStats? _stats;
  List<AdminUser> _users = const [];
  List<FeedbackItem> _feedback = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _adminService.stats(),
        _adminService.latestUsers(),
        _feedbackService.latest(),
      ]);
      if (!mounted) return;
      setState(() {
        _stats = results[0] as AdminStats;
        _users = results[1] as List<AdminUser>;
        _feedback = results[2] as List<FeedbackItem>;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Veriler yüklenemedi: $e';
      });
    }
  }

  String _date(DateTime? d) => d == null ? '—' : _dateFormat.format(d);

  Future<void> _markDone(FeedbackItem item) async {
    await _feedbackService.markDone(item.id);
    await _load();
  }

  Future<void> _delete(FeedbackItem item) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Geri bildirim silinsin mi?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Vazgeç'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await _feedbackService.delete(item.id);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Yönetim paneli'),
        titleTextStyle: GoogleFonts.fraunces(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.forest,
        ),
        backgroundColor: AppColors.bg,
        foregroundColor: AppColors.forest,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loading ? null : _load,
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: _loading
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.forest),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(18),
                    children: [
                      if (_error != null)
                        Text(
                          _error!,
                          style: GoogleFonts.outfit(color: AppColors.coral),
                        ),
                      if (_stats != null) _buildStats(_stats!),
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.insights_rounded),
                        label: const Text(
                          'Ziyaretçi istatistikleri (Firebase Analytics)',
                        ),
                        onPressed: () =>
                            AppLinks.open(AppLinks.analyticsConsole),
                      ),
                      const SizedBox(height: 24),
                      _sectionTitle('Son kayıt olanlar'),
                      if (_users.isEmpty) _empty('Henüz kayıt yok.'),
                      ..._users.map(_buildUser),
                      const SizedBox(height: 24),
                      _sectionTitle('Geri bildirimler'),
                      if (_feedback.isEmpty) _empty('Henüz geri bildirim yok.'),
                      ..._feedback.map(_buildFeedback),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildStats(AdminStats s) {
    final items = [
      ('Toplam kullanıcı', s.totalUsers),
      ('Son 7 gün yeni', s.newUsers7d),
      ('Son 30 gün yeni', s.newUsers30d),
      ('Kayıtlı ev', s.totalHomes),
      ('Yeni geri bildirim', s.newFeedback),
    ];
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: items
          .map((e) => _StatCard(label: e.$1, value: e.$2))
          .toList(),
    );
  }

  Widget _sectionTitle(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          text,
          style: GoogleFonts.fraunces(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.forest,
          ),
        ),
      );

  Widget _empty(String text) => Text(
        text,
        style: GoogleFonts.outfit(color: AppColors.muted),
      );

  Widget _buildUser(AdminUser u) {
    final provider = switch (u.provider) {
      'google.com' => 'Google',
      'password' => 'E-posta',
      'apple.com' => 'Apple',
      _ => u.provider,
    };
    return Card(
      color: AppColors.card,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(u.email),
        subtitle: Text(
          'Kayıt: ${_date(u.createdAt)} · Son giriş: ${_date(u.lastSeenAt)}',
        ),
        trailing: Text(
          '$provider\n${u.platform}',
          textAlign: TextAlign.right,
          style: GoogleFonts.outfit(fontSize: 12, color: AppColors.muted),
        ),
      ),
    );
  }

  Widget _buildFeedback(FeedbackItem f) {
    return Card(
      color: f.isNew ? AppColors.goldSoft : AppColors.card,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${FeedbackCategory.labelOf(f.category)} · ${_date(f.createdAt)}',
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.forest2,
              ),
            ),
            const SizedBox(height: 6),
            SelectableText(f.message),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: SelectableText(
                    f.email ?? 'E-posta yok',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: AppColors.muted,
                    ),
                  ),
                ),
                if (f.isNew)
                  TextButton(
                    onPressed: () => _markDone(f),
                    child: const Text('Okundu'),
                  ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, size: 20),
                  onPressed: () => _delete(f),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final int value;

  const _StatCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$value',
            style: GoogleFonts.fraunces(
              fontSize: 28,
              fontWeight: FontWeight.w600,
              color: AppColors.forest,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.outfit(fontSize: 13, color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}
