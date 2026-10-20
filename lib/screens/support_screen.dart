import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/feedback_service.dart';
import '../theme/app_theme.dart';
import '../utils/app_links.dart';
import 'auth_screen.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  final _messageController = TextEditingController();
  final _feedbackService = FeedbackService();
  FeedbackCategory _category = FeedbackCategory.suggestion;
  bool _sending = false;
  bool _sent = false;
  String? _error;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final message = _messageController.text.trim();
    if (message.length < 3) {
      setState(() => _error = 'Lütfen mesajınızı yazın.');
      return;
    }
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await _feedbackService.send(category: _category, message: message);
      FirebaseAnalytics.instance
          .logEvent(name: 'feedback_sent', parameters: {'category': _category.id})
          .catchError((_) {});
      if (!mounted) return;
      setState(() {
        _sent = true;
        _sending = false;
      });
    } on FeedbackRateLimitedException {
      if (!mounted) return;
      setState(() {
        _sending = false;
        _error =
            'Kısa süre önce mesaj gönderdiniz. Lütfen birkaç dakika sonra tekrar deneyin.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _sending = false;
        _error =
            'Mesaj gönderilemedi. ${AppLinks.supportEmail} adresine e-posta ile de ulaşabilirsiniz.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final signedInEmail = context.watch<AuthProvider>().user?.email;
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Destek ve geri bildirim'),
        titleTextStyle: GoogleFonts.fraunces(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.forest,
        ),
        backgroundColor: AppColors.bg,
        foregroundColor: AppColors.forest,
        elevation: 0,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              if (signedInEmail == null)
                const _SignInPrompt()
              else if (_sent)
                _SentCard(onAgain: () {
                  _messageController.clear();
                  setState(() => _sent = false);
                })
              else ...[
                Text(
                  'Bir hata mı buldunuz ya da bir öneriniz mi var? Mesajınızı doğrudan ekibimize iletin.',
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    color: AppColors.muted,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: FeedbackCategory.values.map((c) {
                    return ChoiceChip(
                      label: Text(c.label),
                      selected: _category == c,
                      selectedColor: AppColors.goldSoft,
                      onSelected: (_) => setState(() => _category = c),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _messageController,
                  minLines: 5,
                  maxLines: 10,
                  maxLength: 2000,
                  decoration: const InputDecoration(
                    labelText: 'Mesajınız',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Yanıtımız $signedInEmail adresine gönderilecek.',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    color: AppColors.muted,
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      color: AppColors.coral,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _sending ? null : _send,
                    child: _sending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Gönder'),
                  ),
                ),
              ],
              const SizedBox(height: 28),
              const Divider(),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.mail_outline_rounded,
                    color: AppColors.forest),
                title: const Text('E-posta ile ulaşın'),
                subtitle: const Text(AppLinks.supportEmail),
                onTap: AppLinks.mail,
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.help_outline_rounded,
                    color: AppColors.forest),
                title: const Text('Sık sorulan sorular'),
                onTap: () => AppLinks.open(AppLinks.support),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SignInPrompt extends StatelessWidget {
  const _SignInPrompt();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        children: [
          Text(
            'Uygulama içinden geri bildirim göndermek için giriş yapmanız gerekiyor. '
            'Giriş yapmadan aşağıdaki e-posta adresinden bize ulaşabilirsiniz.',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 15,
              color: AppColors.muted,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const AuthScreen(),
                  fullscreenDialog: true,
                ),
              ),
              child: const Text('Giriş yap'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SentCard extends StatelessWidget {
  final VoidCallback onAgain;

  const _SentCard({required this.onAgain});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        children: [
          const Icon(Icons.check_circle_outline_rounded,
              size: 40, color: AppColors.forest),
          const SizedBox(height: 10),
          Text(
            'Mesajınız bize ulaştı. Teşekkür ederiz!',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.forest,
            ),
          ),
          TextButton(
            onPressed: onAgain,
            child: const Text('Yeni mesaj gönder'),
          ),
        ],
      ),
    );
  }
}
