import 'package:material_ui/material_ui.dart';

import '../theme.dart';
import '../widgets.dart';
import 'home_shell.dart';

/// Launch screen with animated gear, a short pitch and one button.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  void _open(BuildContext context) {
    Navigator.of(context).pushReplacement(PageRouteBuilder<void>(
      transitionDuration: const Duration(milliseconds: 650),
      pageBuilder: (_, __, ___) => const HomeShell(),
      transitionsBuilder: (_, Animation<double> a, __, Widget child) {
        final Animation<double> c = CurvedAnimation(parent: a, curve: Motion.ease);
        return FadeTransition(
          opacity: c,
          child: ScaleTransition(scale: Tween<double>(begin: 1.03, end: 1).animate(c), child: child),
        );
      },
    ));
  }

  Widget _loaderView() => Image.asset(
        'assets/video/loader.gif',
        fit: BoxFit.cover,
        excludeFromSemantics: true,
      );

  @override
  Widget build(BuildContext context) {
    final bool wide = isWide(context);
    final EdgeInsets safe = MediaQuery.paddingOf(context);

    final List<Widget> copy = <Widget>[
      const FadeSlideIn(delay: Duration(milliseconds: 100), child: Text('L MY EX ITEMS', style: TextStyles.eyebrow)),
      const SizedBox(height: 12),
      FadeSlideIn(
        delay: const Duration(milliseconds: 180),
        child: Text.rich(
          TextSpan(children: <InlineSpan>[
            const TextSpan(text: 'Turn the gear you own into your '),
            WidgetSpan(
              alignment: PlaceholderAlignment.baseline,
              baseline: TextBaseline.alphabetic,
              child: GoldText('next game',
                  style: TextStyle(fontSize: wide ? 52 : 30, fontWeight: FontWeight.w700, letterSpacing: wide ? -1.8 : -.9, height: 1.05)),
            ),
          ]),
          textAlign: wide ? TextAlign.left : TextAlign.center,
          style: TextStyle(fontSize: wide ? 52 : 30, fontWeight: FontWeight.w700, letterSpacing: wide ? -1.8 : -.9, height: 1.05),
        ),
      ),
      const SizedBox(height: 12),
      FadeSlideIn(
        delay: const Duration(milliseconds: 260),
        child: Text(
          'Snap your stuff, tell us what you enjoy, and get sports and games to play — plus a list of friends to invite.',
          textAlign: wide ? TextAlign.left : TextAlign.center,
          style: TextStyle(fontSize: wide ? 19 : 15, height: 1.45, color: const Color(0xFFC9C1B2)),
        ),
      ),
      SizedBox(height: wide ? 28 : 20),
      FadeSlideIn(
        delay: const Duration(milliseconds: 340),
        child: SizedBox(width: wide ? 280 : double.infinity, child: GoldButton(label: 'Get started', onPressed: () => _open(context))),
      ),
    ];

    if (wide) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(center: Alignment(-.55, 0), radius: 1.1, colors: <Color>[Color(0xFF2E2416), AppColors.bg]),
          ),
          padding: EdgeInsets.fromLTRB(72 + safe.left, safe.top, 72 + safe.right, safe.bottom),
          child: Row(children: <Widget>[
            FadeSlideIn(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 720),
                child: AspectRatio(
                aspectRatio: 9 / 16,
                child: Container(
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: AppColors.bg,
                    borderRadius: BorderRadius.circular(36),
                    border: Border.all(color: const Color(0x4DE6C27A)),
                    boxShadow: const <BoxShadow>[BoxShadow(color: Color(0x8C000000), blurRadius: 90, offset: Offset(0, 40))],
                  ),
                  child: _loaderView(),
                ),
              ),
              ),
            ),
            const SizedBox(width: 64),
            Expanded(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: copy)),
          ]),
        ),
      );
    }

    return Scaffold(
      body: Stack(fit: StackFit.expand, children: <Widget>[
        _loaderView(),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: <Color>[Color(0x00101115), Color(0x00101115), AppColors.bg],
              stops: <double>[0, .5, .78],
            ),
          ),
        ),
        Positioned(
          left: 24 + safe.left,
          right: 24 + safe.right,
          bottom: 28 + safe.bottom,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: copy),
        ),
      ]),
    );
  }
}
