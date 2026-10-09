import 'dart:js_interop';
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

import 'ad_unit.dart';

export 'ad_unit.dart';

@JS('eval')
external JSAny? _jsEval(String code);

/// Web: Google AdSense birimi.
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

  double get _height {
    if (widget.compact) return 56;
    return widget.unit == AdUnit.inArticle ? 120 : 90;
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
        ..style.overflow = 'hidden'
        ..style.display = 'flex'
        ..style.justifyContent = 'center'
        ..style.alignItems = 'center';

      final ins = web.document.createElement('ins') as web.HTMLElement;
      ins.className = 'adsbygoogle';
      ins.style.display = 'block';
      ins.style.width = '100%';
      ins.style.textAlign = 'center';
      if (unit == AdUnit.inArticle) {
        ins.style.minHeight = '${heightPx}px';
      } else {
        ins.style.height = '${heightPx}px';
        ins.style.maxWidth = '728px';
      }
      ins.setAttribute('data-ad-client', AdUnit.client);
      ins.setAttribute('data-ad-slot', unit.slot);
      ins.setAttribute('data-ad-format', unit.format);
      if (unit.layout != null) {
        ins.setAttribute('data-ad-layout', unit.layout!);
      }
      if (unit == AdUnit.display) {
        ins.setAttribute('data-full-width-responsive', 'true');
      }
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
    final height = _height;
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
