import 'package:material_ui/material_ui.dart';

import '../state.dart';
import '../theme.dart';
import '../widgets.dart';
import 'analytics_screen.dart';
import 'game_screen.dart';
import 'gear_screen.dart';
import 'match_screen.dart';
import 'profile_screen.dart';

class _Tab {
  const _Tab(this.label, this.short, this.icon, this.iconOn);
  final String label;
  final String short;
  final IconData icon;
  final IconData iconOn;
}

const List<_Tab> _tabs = <_Tab>[
  _Tab('Find a game', 'Match', Icons.camera_alt_outlined, Icons.camera_alt),
  _Tab('Gear & players', 'Gear', Icons.inventory_2_outlined, Icons.inventory_2),
  _Tab('Your game', 'Game', Icons.flag_outlined, Icons.flag),
  _Tab('Analytics', 'Analytics', Icons.bar_chart_rounded, Icons.bar_chart_rounded),
  _Tab('Profile', 'Profile', Icons.person_outline_rounded, Icons.person_rounded),
];

/// Tab bar on iPhone, sidebar on iPad; screens cross-fade when switching.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _tab = 0;
  String? _playersFilter;

  void _go(int i) => setState(() {
        _tab = i;
        if (i != 1) _playersFilter = null;
      });

  Widget _page() {
    switch (_tab) {
      case 0:
        return MatchScreen(onFindPlayers: (String sport) => setState(() {
              _playersFilter = sport;
              _tab = 1;
            }));
      case 1:
        return GearScreen(key: ValueKey<String?>(_playersFilter), playersFilter: _playersFilter);
      case 2:
        return const GameScreen();
      case 3:
        return const AnalyticsScreen();
      default:
        return ProfileScreen(onOpenTab: _go);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool wide = isWide(context);
    final Widget body = AnimatedSwitcher(
      duration: Motion.base,
      switchInCurve: Motion.ease,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (Widget child, Animation<double> a) => FadeTransition(
        opacity: a,
        child: SlideTransition(position: Tween<Offset>(begin: const Offset(0, .015), end: Offset.zero).animate(a), child: child),
      ),
      child: KeyedSubtree(key: ValueKey<String>('tab-$_tab-$_playersFilter'), child: _page()),
    );

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: wide ? const Alignment(.2, -1.3) : const Alignment(0, -1.25),
            radius: wide ? 1.1 : 1.0,
            colors: const <Color>[AppColors.warm, AppColors.bg],
          ),
        ),
        child: wide
            ? Row(children: <Widget>[
                _Sidebar(current: _tab, onSelect: _go),
                Expanded(child: body),
              ])
            : Stack(children: <Widget>[
                Positioned.fill(child: body),
                Positioned(left: 0, right: 0, bottom: 0, child: _TabBar(current: _tab, onSelect: _go)),
              ]),
      ),
    );
  }
}

class _TabBar extends StatelessWidget {
  const _TabBar({required this.current, required this.onSelect});
  final int current;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final double bottom = MediaQuery.paddingOf(context).bottom;
    return GlassBar(
      child: Padding(
        padding: EdgeInsets.fromLTRB(8, 8, 8, bottom > 0 ? bottom : 10),
        child: Row(children: <Widget>[
          for (int i = 0; i < _tabs.length; i++)
            Expanded(
              child: Semantics(
                selected: i == current,
                button: true,
                label: _tabs[i].label,
                excludeSemantics: true,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onSelect(i),
                  child: SizedBox(
                    height: 50,
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
                      AnimatedScale(
                        scale: i == current ? 1.08 : 1,
                        duration: Motion.base,
                        curve: Motion.pop,
                        child: Icon(i == current ? _tabs[i].iconOn : _tabs[i].icon,
                            size: 25, color: i == current ? AppColors.gold : AppColors.faint),
                      ),
                      const SizedBox(height: 3),
                      AnimatedDefaultTextStyle(
                        duration: Motion.fast,
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: i == current ? FontWeight.w600 : FontWeight.w500,
                          color: i == current ? AppColors.gold : AppColors.faint,
                        ),
                        child: Text(_tabs[i].short),
                      ),
                    ]),
                  ),
                ),
              ),
            ),
        ]),
      ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({required this.current, required this.onSelect});
  final int current;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final EdgeInsets safe = MediaQuery.paddingOf(context);
    final Profile p = AppScope.of(context).profile;
    return Container(
      width: 260 + safe.left,
      padding: EdgeInsets.fromLTRB(14 + safe.left, safe.top + 26, 14, 20 + safe.bottom),
      decoration: const BoxDecoration(
        color: Color(0xC714151A),
        border: Border(right: BorderSide(color: AppColors.cardLine)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: <Widget>[
        Row(children: <Widget>[
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(11),
              gradient: const LinearGradient(colors: <Color>[Color(0xFF3A2E1C), Color(0xFF17140F)], begin: Alignment.topLeft, end: Alignment.bottomRight),
              border: Border.all(color: const Color(0x73E6C27A)),
            ),
            child: const GoldText('L', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, height: 1)),
          ),
          const SizedBox(width: 10),
          const Text('L my ex items', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, letterSpacing: -.25)),
        ]),
        const SizedBox(height: 22),
        const Padding(
          padding: EdgeInsets.only(left: 12, bottom: 6),
          child: Text('BROWSE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: .7, color: AppColors.faint)),
        ),
        for (int i = 0; i < _tabs.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Pressable(
              selected: i == current,
              semanticLabel: _tabs[i].label,
              onTap: () => onSelect(i),
              child: AnimatedContainer(
                duration: Motion.fast,
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: i == current
                      ? const LinearGradient(colors: <Color>[Color(0x33E6C27A), Color(0x0FE6C27A)])
                      : null,
                  border: Border.all(color: i == current ? const Color(0x59E6C27A) : Colors.transparent),
                ),
                child: Row(children: <Widget>[
                  Icon(i == current ? _tabs[i].iconOn : _tabs[i].icon,
                      size: 22, color: i == current ? const Color(0xFFF3D99B) : const Color(0xFFC9C1B2)),
                  const SizedBox(width: 12),
                  Text(_tabs[i].label,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: i == current ? FontWeight.w600 : FontWeight.w500,
                        color: i == current ? const Color(0xFFF3D99B) : const Color(0xFFC9C1B2),
                      )),
                ]),
              ),
            ),
          ),
        const Spacer(),
        Pressable(
          semanticLabel: 'Open profile',
          onTap: () => onSelect(4),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: AppColors.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.cardLine)),
            child: Row(children: <Widget>[
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                    shape: BoxShape.circle, gradient: LinearGradient(colors: <Color>[Color(0xFFF1D48E), Color(0xFFA8752F)])),
                child: Text(p.initials, style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w700, fontSize: 15)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(p.name.isEmpty ? 'Your profile' : p.name,
                    maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              ),
            ]),
          ),
        ),
      ]),
    );
  }
}
