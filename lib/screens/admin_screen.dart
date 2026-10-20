import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../services/admin_service.dart';
import '../services/feedback_service.dart';
import '../theme/app_theme.dart';
import '../utils/app_links.dart';

enum _UserAction { block, unblock, deleteHomes, deleteProfile, console }

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final _adminService = AdminService();
  final _feedbackService = FeedbackService();
  final _dateFormat = DateFormat('dd.MM.yyyy HH:mm');
  final _searchController = TextEditingController();

  AdminStats? _stats;
  List<AdminUser> _users = const [];
  List<AdminUser>? _searchResults;
  Set<String> _blocked = const {};
  List<FeedbackItem> _feedback = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
        _adminService.blockedEmails(),
      ]);
      if (!mounted) return;
      setState(() {
        _stats = results[0] as AdminStats;
        _users = results[1] as List<AdminUser>;
        _feedback = results[2] as List<FeedbackItem>;
        _blocked = results[3] as Set<String>;
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

  Future<void> _search() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      setState(() => _searchResults = null);
      return;
    }
    final results = await _adminService.findByEmail(query);
    if (mounted) setState(() => _searchResults = results);
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<bool> _confirm(String title, String body, String action) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Vazgeç'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.coral),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(action),
          ),
        ],
      ),
    );
    return ok == true;
  }

  Future<void> _onUserAction(AdminUser u, _UserAction action) async {
    try {
      switch (action) {
        case _UserAction.block:
          if (!await _confirm(
            'Kullanıcı engellensin mi?',
            '${u.email} artık uygulamayı kullanamaz, ev kaydedemez ve geri bildirim gönderemez. '
                'Aynı e-postayla yeniden kayıt olsa da engelli kalır.',
            'Engelle',
          )) {
            return;
          }
          await _adminService.block(u.email);
          _toast('${u.email} engellendi');
        case _UserAction.unblock:
          await _adminService.unblock(u.email);
          _toast('${u.email} engeli kaldırıldı');
        case _UserAction.deleteHomes:
          if (!await _confirm(
            'Kayıtlı evler silinsin mi?',
            '${u.email} kullanıcısının ${u.homeCount} kayıtlı evi kalıcı olarak silinecek.',
            'Sil',
          )) {
            return;
          }
          final n = await _adminService.deleteHomes(u.uid);
          _toast('$n ev silindi');
        case _UserAction.deleteProfile:
          if (!await _confirm(
            'Kullanıcı verileri silinsin mi?',
            '${u.email} kullanıcısının profili ve tüm evleri silinecek. '
                'Giriş hesabını ayrıca Firebase konsolundan silmeniz gerekir.',
            'Sil',
          )) {
            return;
          }
          await _adminService.deleteProfile(u.uid);
          _toast('Kullanıcı verileri silindi');
        case _UserAction.console:
          await AppLinks.open(AppLinks.authConsole);
          return;
      }
      await _load();
      if (_searchResults != null) await _search();
    } catch (e) {
      _toast('İşlem başarısız: $e');
    }
  }

  String _date(DateTime? d) => d == null ? '—' : _dateFormat.format(d);

  Future<void> _markDone(FeedbackItem item) async {
    await _feedbackService.markDone(item.id);
    await _load();
  }

  Future<void> _deleteFeedback(FeedbackItem item) async {
    if (!await _confirm('Geri bildirim silinsin mi?', item.message, 'Sil')) {
      return;
    }
    await _feedbackService.delete(item.id);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final listedEmails = _users.map((u) => u.email).toSet();
    final blockedOnly =
        _blocked.where((e) => !listedEmails.contains(e)).toList()..sort();

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
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          OutlinedButton.icon(
                            icon: const Icon(Icons.insights_rounded),
                            label: const Text('Ziyaretçi istatistikleri'),
                            onPressed: () =>
                                AppLinks.open(AppLinks.analyticsConsole),
                          ),
                          OutlinedButton.icon(
                            icon: const Icon(Icons.manage_accounts_outlined),
                            label: const Text('Giriş hesapları (Firebase)'),
                            onPressed: () =>
                                AppLinks.open(AppLinks.authConsole),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _sectionTitle('Kullanıcı ara'),
                      TextField(
                        controller: _searchController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.search,
                        onSubmitted: (_) => _search(),
                        decoration: InputDecoration(
                          hintText: 'E-posta adresi',
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.search_rounded),
                            onPressed: _search,
                          ),
                        ),
                      ),
                      if (_searchResults != null) ...[
                        const SizedBox(height: 8),
                        if (_searchResults!.isEmpty)
                          _empty('Bu e-postayla kayıtlı kullanıcı yok.'),
                        ..._searchResults!.map(_buildUser),
                      ],
                      const SizedBox(height: 24),
                      _sectionTitle('Son kayıt olanlar'),
                      if (_users.isEmpty) _empty('Henüz kayıt yok.'),
                      ..._users.map(_buildUser),
                      if (blockedOnly.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        _sectionTitle('Diğer engellenenler'),
                        ...blockedOnly.map(_buildBlockedEmail),
                      ],
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
      ('Engelli', s.blockedUsers),
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
    final blocked = _blocked.contains(u.email);
    return Card(
      color: blocked ? const Color(0x1FB85C38) : AppColors.card,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Row(
          children: [
            Flexible(child: Text(u.email, overflow: TextOverflow.ellipsis)),
            if (blocked) ...[
              const SizedBox(width: 8),
              Text(
                'ENGELLİ',
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.coral,
                ),
              ),
            ],
          ],
        ),
        subtitle: Text(
          'Kayıt: ${_date(u.createdAt)} · Son giriş: ${_date(u.lastSeenAt)}\n'
          '$provider · ${u.platform} · ${u.homeCount} ev',
        ),
        isThreeLine: true,
        trailing: PopupMenuButton<_UserAction>(
          onSelected: (a) => _onUserAction(u, a),
          itemBuilder: (_) => [
            if (blocked)
              const PopupMenuItem(
                value: _UserAction.unblock,
                child: Text('Engeli kaldır'),
              )
            else
              const PopupMenuItem(
                value: _UserAction.block,
                child: Text('Engelle'),
              ),
            const PopupMenuItem(
              value: _UserAction.deleteHomes,
              child: Text('Kayıtlı evlerini sil'),
            ),
            const PopupMenuItem(
              value: _UserAction.deleteProfile,
              child: Text('Tüm verilerini sil'),
            ),
            const PopupMenuItem(
              value: _UserAction.console,
              child: Text('Giriş hesabını Firebase\'de aç'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBlockedEmail(String email) {
    return Card(
      color: const Color(0x1FB85C38),
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(email),
        trailing: TextButton(
          onPressed: () async {
            await _adminService.unblock(email);
            _toast('$email engeli kaldırıldı');
            await _load();
          },
          child: const Text('Engeli kaldır'),
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
                if (f.email != null && !_blocked.contains(f.email))
                  IconButton(
                    tooltip: 'Göndereni engelle',
                    icon: const Icon(Icons.block_rounded, size: 20),
                    onPressed: () async {
                      if (!await _confirm(
                        'Gönderen engellensin mi?',
                        '${f.email} artık uygulamayı kullanamaz.',
                        'Engelle',
                      )) {
                        return;
                      }
                      await _adminService.block(f.email!);
                      _toast('${f.email} engellendi');
                      await _load();
                    },
                  ),
                IconButton(
                  tooltip: 'Sil',
                  icon: const Icon(Icons.delete_outline_rounded, size: 20),
                  onPressed: () => _deleteFeedback(f),
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
