import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/homes_provider.dart';
import '../screens/admin_screen.dart';
import '../screens/auth_screen.dart';
import '../screens/support_screen.dart';
import '../theme/app_theme.dart';
import '../utils/app_links.dart';

Future<void> showAccountSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.bg,
    showDragHandle: true,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => const _AccountSheet(),
  );
}

class _AccountSheet extends StatelessWidget {
  const _AccountSheet();

  void _push(BuildContext context, Widget screen, {bool dialog = false}) {
    final navigator = Navigator.of(context);
    navigator.pop();
    navigator.push(
      MaterialPageRoute(builder: (_) => screen, fullscreenDialog: dialog),
    );
  }

  Future<void> _signOut(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    final homes = context.read<HomesProvider>();
    Navigator.of(context).pop();
    await auth.signOut();
    homes.setCloudMode(false);
  }

  Future<void> _deleteAccount(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    final homes = context.read<HomesProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final password = await showDialog<String>(
      context: context,
      builder: (_) => _DeleteDialog(askPassword: auth.usesPassword),
    );
    if (password == null) return;

    final result = await auth.deleteAccount(
      password: password.isEmpty ? null : password,
    );
    if (result == DeleteAccountResult.cancelled) return;
    if (result == DeleteAccountResult.deleted) {
      homes.setCloudMode(false);
      navigator.pop();
      messenger.showSnackBar(
        const SnackBar(content: Text('Hesabınız ve tüm verileriniz silindi.')),
      );
      return;
    }
    messenger.showSnackBar(
      SnackBar(content: Text(auth.errorMessage ?? 'Hesap silinemedi.')),
    );
    auth.clearError();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                auth.isAuthenticated
                    ? (auth.user?.email ?? 'Hesabım')
                    : 'Misafir olarak kullanıyorsunuz',
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.forest,
                ),
              ),
            ),
            if (!auth.isAuthenticated)
              _Item(
                icon: Icons.login_rounded,
                label: 'Giriş yap / Kayıt ol',
                onTap: () => _push(context, const AuthScreen(), dialog: true),
              ),
            if (auth.isAdmin)
              _Item(
                icon: Icons.dashboard_outlined,
                label: 'Yönetim paneli',
                onTap: () => _push(context, const AdminScreen()),
              ),
            _Item(
              icon: Icons.support_agent_rounded,
              label: 'Destek ve geri bildirim',
              onTap: () => _push(context, const SupportScreen()),
            ),
            _Item(
              icon: Icons.privacy_tip_outlined,
              label: 'Gizlilik Politikası',
              onTap: () => AppLinks.open(AppLinks.privacy),
            ),
            _Item(
              icon: Icons.description_outlined,
              label: 'Kullanım Koşulları',
              onTap: () => AppLinks.open(AppLinks.terms),
            ),
            if (auth.isAuthenticated) ...[
              const Divider(indent: 16, endIndent: 16),
              _Item(
                icon: Icons.logout_rounded,
                label: 'Çıkış yap',
                onTap: () => _signOut(context),
              ),
              _Item(
                icon: Icons.delete_forever_outlined,
                label: 'Hesabımı sil',
                color: AppColors.coral,
                onTap: () => _deleteAccount(context),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Item extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  const _Item({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = AppColors.ink,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(
        label,
        style: GoogleFonts.outfit(fontSize: 15, color: color),
      ),
      onTap: onTap,
    );
  }
}

/// Onaylanırsa şifreyi (e-posta hesabı) ya da boş string döndürür.
class _DeleteDialog extends StatefulWidget {
  final bool askPassword;

  const _DeleteDialog({required this.askPassword});

  @override
  State<_DeleteDialog> createState() => _DeleteDialogState();
}

class _DeleteDialogState extends State<_DeleteDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Hesabınız silinsin mi?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Hesabınız, e-posta adresiniz ve kaydettiğiniz tüm evler kalıcı olarak silinir. Bu işlem geri alınamaz.',
          ),
          if (widget.askPassword) ...[
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              obscureText: true,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Onay için şifreniz',
                border: OutlineInputBorder(),
              ),
            ),
          ] else ...[
            const SizedBox(height: 12),
            const Text(
              'Güvenlik için Google hesabınızla tekrar doğrulama istenecek.',
              style: TextStyle(fontSize: 13),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Vazgeç'),
        ),
        TextButton(
          style: TextButton.styleFrom(foregroundColor: AppColors.coral),
          onPressed: () {
            if (widget.askPassword && _controller.text.isEmpty) return;
            Navigator.pop(context, _controller.text);
          },
          child: const Text('Kalıcı olarak sil'),
        ),
      ],
    );
  }
}
