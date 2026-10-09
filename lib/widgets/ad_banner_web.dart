import 'dart:async';
import 'dart:js_interop';
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

import 'ad_unit.dart';

export 'ad_unit.dart';

@JS('eval')
external JSAny? _jsEval(String code);

/// Web: Google AdSense — Google snippet + HTML içinde yedek "Reklam" yazısı.
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
        ..style.position = 'relative'
        ..style.overflow = 'hidden'
        ..style.backgroundColor = '#F0EBE1'
        ..style.borderRadius = '14px';

      // AdSense dolmazsa görünsün diye HTML fallback
      final fallback = web.HTMLDivElement()
        ..style.position = 'absolute'
        ..style.inset = '0'
        ..style.display = 'flex'
        ..style.flexDirection = 'column'
        ..style.alignItems = 'center'
        ..style.justifyContent = 'center'
        ..style.pointerEvents = 'none'
        ..style.zIndex = '0';
      final title = web.HTMLDivElement()
        ..textContent = 'REKLAM'
        ..style.font = '700 11px system-ui,sans-serif'
        ..style.letterSpacing = '1px'
        ..style.color = '#5D6B64';
      final sub = web.HTMLDivElement()
        ..textContent = 'AdSense'
        ..style.font = '400 11px system-ui,sans-serif'
        ..style.color = '#5D6B64'
        ..style.opacity = '0.7'
        ..style.marginTop = '4px';
      fallback.append(title);
      fallback.append(sub);
      host.append(fallback);

      final ins = web.document.createElement('ins') as web.HTMLElement;
      ins.className = 'adsbygoogle';
      ins.style.position = 'relative';
      ins.style.zIndex = '1';
      ins.setAttribute('data-ad-client', AdUnit.client);
      ins.setAttribute('data-ad-slot', unit.slot);

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

      // Ortala
      final wrap = web.HTMLDivElement()
        ..style.position = 'relative'
        ..style.zIndex = '1'
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.display = 'flex'
        ..style.justifyContent = 'center'
        ..style.alignItems = 'center';
      wrap.append(ins);
      host.append(wrap);

      _schedulePush(attempt: 0);
      return host;
    });

    setState(() => _ready = true);
  }

  void _schedulePush({required int attempt}) {
    _retryTimer?.cancel();
    if (attempt > 10) return;
    _retryTimer = Timer(Duration(milliseconds: 250 + attempt * 350), () {
      if (!mounted) return;
      if (_tryPush()) return;
      _schedulePush(attempt: attempt + 1);
    });
  }

  bool _tryPush() {
    try {
      _jsEval(
        'if(typeof adsbygoogle==="undefined"){window.adsbygoogle=[];}'
        '(adsbygoogle=window.adsbygoogle||[]).push({});',
      );
      return true;
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
    if (!_ready) {
      return SizedBox(width: double.infinity, height: height);
    }

    return Semantics(
      label: 'Reklam',
      child: SizedBox(
        width: double.infinity,
        height: height,
        child: HtmlElementView(viewType: _viewType),
      ),
    );
  }
}
