import 'dart:js_interop';
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

const _adClient = 'ca-pub-8974319907510791';
const _adSlot = '7727699704';

@JS('eval')
external JSAny? _jsEval(String code);

/// Web: Google AdSense display birimi (home1 · 7727699704).
class AdBannerPlaceholder extends StatefulWidget {
  final String label;
  final bool compact;

  const AdBannerPlaceholder({
    super.key,
    this.label = 'Reklam',
    this.compact = false,
  });

  @override
  State<AdBannerPlaceholder> createState() => _AdBannerPlaceholderState();
}

class _AdBannerPlaceholderState extends State<AdBannerPlaceholder> {
  late final String _viewType;
  var _ready = false;

  @override
  void initState() {
    super.initState();
    final heightPx = widget.compact ? 56 : 90;
    _viewType =
        'adsense-home1-${identityHashCode(this)}-${DateTime.now().microsecondsSinceEpoch}';

    ui_web.platformViewRegistry.registerViewFactory(_viewType, (int viewId) {
      final host = web.HTMLDivElement()
        ..style.width = '100%'
        ..style.height = '${heightPx}px'
        ..style.overflow = 'hidden'
        ..style.display = 'flex'
        ..style.justifyContent = 'center'
        ..style.alignItems = 'center';

      final ins = web.document.createElement('ins') as web.HTMLElement;
      ins.className = 'adsbygoogle';
      ins.style.display = 'block';
      ins.style.width = '100%';
      ins.style.height = '${heightPx}px';
      ins.style.maxWidth = '728px';
      ins.setAttribute('data-ad-client', _adClient);
      ins.setAttribute('data-ad-slot', _adSlot);
      ins.setAttribute('data-ad-format', 'horizontal');
      ins.setAttribute('data-full-width-responsive', 'true');
      host.append(ins);

      web.window.setTimeout(
        (() {
          _pushAd();
        }).toJS,
        80.toJS,
      );

      return host;
    });

    setState(() => _ready = true);
  }

  void _pushAd() {
    try {
      _jsEval('(window.adsbygoogle = window.adsbygoogle || []).push({});');
    } catch (_) {
      web.window.setTimeout((() {
        try {
          _jsEval('(window.adsbygoogle = window.adsbygoogle || []).push({});');
        } catch (_) {}
      }).toJS, 1000.toJS);
    }
  }

  @override
  Widget build(BuildContext context) {
    final height = widget.compact ? 56.0 : 90.0;
    if (!_ready) {
      return SizedBox(width: double.infinity, height: height);
    }

    return Semantics(
      label: 'Reklam',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          width: double.infinity,
          height: height,
          child: HtmlElementView(viewType: _viewType),
        ),
      ),
    );
  }
}
