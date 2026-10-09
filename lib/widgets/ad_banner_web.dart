import 'dart:async';
import 'dart:js_interop';
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

import 'ad_unit.dart';

export 'ad_unit.dart';

@JS('eval')
external JSAny? _jsEval(String code);

/// Web: Google AdSense birimi. Kutunun yüksekliği reklamın gerçek
/// yüksekliğini takip eder; reklam dolmazsa alan tamamen kapanır.
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
  late double _height;
  bool _unfilled = false;
  web.HTMLElement? _ins;
  web.ResizeObserver? _observer;
  Timer? _pushTimer;
  Timer? _statusTimer;

  double get _minHeight => widget.compact ? 90 : widget.unit.minHeight;

  double get _maxHeight {
    if (widget.compact) return 100;
    switch (widget.unit) {
      case AdUnit.display:
        return 100;
      case AdUnit.inArticle:
        return 420;
      case AdUnit.multiplex:
        return 900;
    }
  }

  @override
  void initState() {
    super.initState();
    _height = _minHeight;
    final unit = widget.unit;
    _viewType =
        'adsense-${unit.slot}-${identityHashCode(this)}-${DateTime.now().microsecondsSinceEpoch}';

    ui_web.platformViewRegistry.registerViewFactory(_viewType, (int viewId) {
      final host = web.HTMLDivElement();
      // AdSense ebeveynlerin yüksekliğini "auto" yapabiliyor; kutu Flutter'ın
      // verdiği boyutun dışına taşmasın.
      host.style
        ..setProperty('width', '100%', 'important')
        ..setProperty('height', '100%', 'important')
        ..setProperty('overflow', 'hidden', 'important')
        ..setProperty('display', 'flex')
        ..setProperty('justify-content', 'center')
        ..setProperty('align-items', 'flex-start');

      final ins = web.document.createElement('ins') as web.HTMLElement;
      ins.className = 'adsbygoogle';
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

      host.append(ins);
      _ins = ins;
      _observeIns(ins);
      _schedulePush(attempt: 0);
      _watchStatus();
      return host;
    });
  }

  void _observeIns(web.HTMLElement ins) {
    _observer = web.ResizeObserver(
      ((JSArray<web.ResizeObserverEntry> _, web.ResizeObserver _) {
        _syncHeight();
      }).toJS,
    );
    _observer!.observe(ins);
  }

  void _syncHeight() {
    final ins = _ins;
    if (ins == null || !mounted || _unfilled) return;
    final h = ins.offsetHeight.toDouble();
    if (h <= 0) return;
    final next = h.clamp(_minHeight, _maxHeight).toDouble();
    if ((next - _height).abs() >= 1) {
      setState(() => _height = next);
    }
  }

  void _watchStatus() {
    var ticks = 0;
    _statusTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      ticks++;
      final status = _ins?.getAttribute('data-ad-status');
      if (status == 'unfilled') {
        t.cancel();
        if (mounted) setState(() => _unfilled = true);
        return;
      }
      if (status == 'filled') _syncHeight();
      if (ticks > 30) t.cancel();
    });
  }

  void _schedulePush({required int attempt}) {
    _pushTimer?.cancel();
    if (attempt > 10) return;
    _pushTimer = Timer(Duration(milliseconds: 250 + attempt * 350), () {
      if (!mounted) return;
      if (_tryPush()) return;
      _schedulePush(attempt: attempt + 1);
    });
  }

  bool _tryPush() {
    try {
      _jsEval('(window.adsbygoogle = window.adsbygoogle || []).push({});');
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  void dispose() {
    _pushTimer?.cancel();
    _statusTimer?.cancel();
    _observer?.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_unfilled) return const SizedBox.shrink();

    return Semantics(
      label: 'Reklam',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          width: double.infinity,
          height: _height,
          child: HtmlElementView(viewType: _viewType),
        ),
      ),
    );
  }
}
