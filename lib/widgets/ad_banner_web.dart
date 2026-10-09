import 'dart:async';
import 'dart:js_interop';
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:web/web.dart' as web;

import '../theme/app_theme.dart';
import 'ad_unit.dart';

export 'ad_unit.dart';

@JS('eval')
external JSAny? _jsEval(String code);

/// Web: Google AdSense — Google'ın verdiği snippet ile birebir.
class AdBannerPlaceholder extends StatefulWidget {
  final String label;
  final bool compact;
  final AdUnit unit;

  const AdBannerPlaceholder({
    super.key,
    this.label = 'Reklam',
    this.compact = false,
    this.unit = AdUnit.display,
  });

  @override
  State<AdBannerPlaceholder> createState() => _AdBannerPlaceholderState();
}

class _AdBannerPlaceholderState extends State<AdBannerPlaceholder> {
  late final String _viewType;
  var _ready = false;
  Timer? _retryTimer;

  double get _height {
    if (widget.compact) return 90;
    return widget.unit.minHeight;
  }

  @override
  void initState() {
    super.initState();
    final heightPx = _height.round();
    final unit = widget.unit;
    _viewType =
        'adsense-${unit.slot}-${identityHashCode(this)}-${DateTime.now().microsecondsSinceEpoch}';

    ui_web.platformViewRegistry.registerViewFactory(_viewType, (int viewId) {
      final host = web.HTMLDivElement()
        ..style.width = '100%'
        ..style.height = '${heightPx}px'
        ..style.display = 'flex'
        ..style.justifyContent = 'center'
        ..style.alignItems = 'center'
        ..style.backgroundColor = '#F0EBE1';

      final ins = web.document.createElement('ins') as web.HTMLElement;
      ins.className = 'adsbygoogle';
      ins.setAttribute('data-ad-client', AdUnit.client);
      ins.setAttribute('data-ad-slot', unit.slot);

      // Google snippet ile birebir attribute'lar
      switch (unit) {
        case AdUnit.display:
          ins.style.display = 'inline-block';
          ins.style.width = '728px';
          ins.style.height = '90px';
          ins.style.maxWidth = '100%';
        case AdUnit.inArticle:
          ins.style.display = 'block';
          ins.style.textAlign = 'center';
          ins.style.width = '100%';
          ins.setAttribute('data-ad-layout', 'in-article');
          ins.setAttribute('data-ad-format', 'fluid');
        case AdUnit.multiplex:
          ins.style.display = 'block';
          ins.style.width = '100%';
          ins.setAttribute('data-ad-format', 'autorelaxed');
      }

      host.append(ins);

      // Script + DOM hazır olunca push (birkaç deneme)
      _schedulePush(attempt: 0);

      return host;
    });

    setState(() => _ready = true);
  }

  void _schedulePush({required int attempt}) {
    _retryTimer?.cancel();
    if (attempt > 8) return;
    _retryTimer = Timer(Duration(milliseconds: 200 + attempt * 300), () {
      if (!mounted) return;
      if (_tryPush()) return;
      _schedulePush(attempt: attempt + 1);
    });
  }

  bool _tryPush() {
    try {
      final ready = _jsEval(
        'typeof window.adsbygoogle !== "undefined"',
      );
      // JS true → continue
      _jsEval('(window.adsbygoogle = window.adsbygoogle || []).push({});');
      return ready != null;
    } catch (_) {
      return false;
    }
  }

  @override
  void dispose() {
    _retryTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final height = _height;

    // Boş görünmesin: altta "Reklam" yeri, üstte AdSense platform view
    return Semantics(
      label: 'Reklam',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          width: double.infinity,
          height: height,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: double.infinity,
                height: height,
                color: const Color(0xFFF0EBE1),
                alignment: Alignment.center,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'REKLAM',
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                        color: AppColors.muted.withValues(alpha: 0.55),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Yükleniyor…',
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        color: AppColors.muted.withValues(alpha: 0.45),
                      ),
                    ),
                  ],
                ),
              ),
              if (_ready)
                HtmlElementView(viewType: _viewType),
            ],
          ),
        ),
      ),
    );
  }
}
