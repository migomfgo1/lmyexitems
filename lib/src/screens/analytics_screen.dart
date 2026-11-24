import 'package:material_ui/material_ui.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../state.dart';
import '../theme.dart';

/// Tab 4 — Analytics. The charts are a bundled HTML page (assets/web/analytics.html)
/// shown in a WebView. It never loads anything from the internet: the app pushes
/// its own saved games into the page through JavaScript.
class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  static const String page = 'assets/web/analytics.html';

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  late final WebViewController _web;
  AppState? _state;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _web = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(AppColors.bg)
      ..addJavaScriptChannel('LNative', onMessageReceived: _onMessage)
      ..setNavigationDelegate(NavigationDelegate(
        // Only the bundled page may load.
        onNavigationRequest: (NavigationRequest r) =>
            r.url.startsWith('file:') || r.url.startsWith('about:') ? NavigationDecision.navigate : NavigationDecision.prevent,
        onPageFinished: (_) {
          _ready = true;
          _push();
        },
      ))
      ..loadFlutterAsset(AnalyticsScreen.page);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final AppState s = AppScope.of(context);
    if (!identical(s, _state)) {
      _state?.removeListener(_push);
      _state = s..addListener(_push);
    }
  }

  @override
  void dispose() {
    _state?.removeListener(_push);
    super.dispose();
  }

  void _onMessage(JavaScriptMessage m) {
    final AppState? s = _state;
    if (s == null) return;
    switch (m.message) {
      case 'ready':
        _ready = true;
        _push();
      case 'addSample':
        s.addSampleGames();
      case 'removeSample':
        s.removeSampleGames();
    }
  }

  void _push() {
    final AppState? s = _state;
    if (!_ready || s == null || !mounted) return;
    final EdgeInsets pad = MediaQuery.paddingOf(context);
    final bool wide = MediaQuery.sizeOf(context).width >= 768;
    _web.runJavaScript(
        'window.LApp && window.LApp.render(${s.analyticsJson()}, {top:${pad.top}, bottom:${wide ? pad.bottom : pad.bottom + 84}, wide:$wide});');
  }

  @override
  Widget build(BuildContext context) {
    // Re-push insets after rotation / size changes.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _push();
    });
    return ColoredBox(color: AppColors.bg, child: WebViewWidget(controller: _web));
  }
}
