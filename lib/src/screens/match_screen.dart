import 'package:material_ui/material_ui.dart';

import '../matching.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets.dart';
import 'gear_screen.dart';

enum _Stage { input, loading, result }

/// Tab 1 — pick photos of your gear, describe what you like, get sport matches.
class MatchScreen extends StatefulWidget {
  const MatchScreen({super.key, required this.onFindPlayers});
  final ValueChanged<String> onFindPlayers;

  @override
  State<MatchScreen> createState() => _MatchScreenState();
}

class _MatchScreenState extends State<MatchScreen> {
  _Stage _stage = _Stage.input;
  List<MatchResult> _results = <MatchResult>[];
  late final TextEditingController _wish = TextEditingController();
  bool _init = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_init) {
      _wish.text = AppScope.of(context).wish;
      _init = true;
    }
  }

  @override
  void dispose() {
    _wish.dispose();
    super.dispose();
  }

  Future<void> _run(AppState s) async {
    FocusScope.of(context).unfocus();
    final List<GearItem> gear = s.items.where((GearItem i) => s.selectedItemIds.contains(i.id)).toList();
    setState(() => _stage = _Stage.loading);
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    if (!mounted) return;
    setState(() {
      _results = matchSports(gear: gear, wish: s.wish, tags: s.tags);
      _stage = _Stage.result;
    });
  }

  @override
  Widget build(BuildContext context) {
    final AppState s = AppScope.of(context);
    final bool wide = isWide(context);

    final Widget gearCard = GlassCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: <Widget>[
        Row(children: <Widget>[
          const Expanded(child: Text('Photos of your gear', style: TextStyles.h2)),
          Text('${s.selectedItemIds.length} selected', style: TextStyles.small),
        ]),
        const SizedBox(height: 14),
        if (s.items.isEmpty)
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Text('Add a photo of a ball, racket, sneakers or anything sporty you own.', style: TextStyles.body),
          )
        else
          GridView.count(
            crossAxisCount: wide ? 5 : 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: .86,
            children: s.items.map((GearItem it) {
              final bool on = s.selectedItemIds.contains(it.id);
              return Pressable(
                selected: on,
                semanticLabel: it.name,
                onTap: () => s.update(() => on ? s.selectedItemIds.remove(it.id) : s.selectedItemIds.add(it.id)),
                child: AnimatedContainer(
                  duration: Motion.fast,
                  decoration: BoxDecoration(
                    color: on ? const Color(0x1FE6C27A) : AppColors.card,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: on ? const Color(0x99E6C27A) : const Color(0x14FFFFFF)),
                  ),
                  child: Stack(children: <Widget>[
                    Center(
                      child: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
                        ItemThumb(photo: it.photo, sport: it.sport, size: 48, radius: 12),
                        const SizedBox(height: 6),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Text(it.name,
                              maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11.5, color: Color(0xFFCFC7B8))),
                        ),
                      ]),
                    ),
                    Positioned(
                      top: 6,
                      right: 6,
                      child: AnimatedScale(
                        scale: on ? 1 : 0,
                        duration: Motion.base,
                        curve: Motion.pop,
                        child: Container(
                          width: 19,
                          height: 19,
                          decoration: const BoxDecoration(color: AppColors.gold, shape: BoxShape.circle),
                          child: const Icon(Icons.check_rounded, size: 13, color: AppColors.ink),
                        ),
                      ),
                    ),
                  ]),
                ),
              );
            }).toList(),
          ),
        const SizedBox(height: 12),
        DashedAction(
          label: 'Add a photo of an item',
          icon: Icons.photo_camera_outlined,
          onTap: () async {
            final GearItem? added = await showAddItemSheet(context);
            if (added != null) s.update(() => s.selectedItemIds.add(added.id));
          },
        ),
      ]),
    );

    final Widget wishCard = GlassCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: <Widget>[
        const Text('What kind of sport do you enjoy?', style: TextStyles.h2),
        const SizedBox(height: 12),
        AppField(
          label: 'What kind of sport do you enjoy?',
          hideLabel: true,
          controller: _wish,
          maxLines: 3,
          hint: 'e.g. I want to play outdoors with friends on weekends, I like running, not into rough contact',
          onChanged: (String v) {
            s.wish = v;
            s.saveQuietly();
          },
        ),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: <Widget>[
          for (final String t in kTags)
            TagChip(
              label: t,
              selected: s.tags.contains(t),
              onTap: () => s.update(() => s.tags.contains(t) ? s.tags.remove(t) : s.tags.add(t)),
            ),
        ]),
      ]),
    );

    final Widget results = GlassCard(
      gold: true,
      child: AnimatedSwitcher(
        duration: Motion.base,
        switchInCurve: Motion.ease,
        transitionBuilder: (Widget child, Animation<double> a) => FadeTransition(
          opacity: a,
          child: SlideTransition(position: Tween<Offset>(begin: const Offset(0, .04), end: Offset.zero).animate(a), child: child),
        ),
        child: switch (_stage) {
          _Stage.loading => const Padding(
              key: ValueKey<String>('loading'),
              padding: EdgeInsets.symmetric(vertical: 26),
              child: Column(children: <Widget>[
                OrbitLoader(),
                SizedBox(height: 18),
                Text('Analyzing your gear…', style: TextStyles.h2),
                SizedBox(height: 4),
                Text('Comparing it with 8 sports', style: TextStyles.small),
              ]),
            ),
          _Stage.result => Column(
              key: const ValueKey<String>('result'),
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Row(children: <Widget>[
                  const Expanded(child: Text('Your matches', style: TextStyles.h2Big)),
                  GhostButton(label: 'Reset', onPressed: () => setState(() => _stage = _Stage.input)),
                ]),
                const SizedBox(height: 12),
                for (int i = 0; i < _results.length; i++)
                  FadeSlideIn(
                    delay: Duration(milliseconds: 80 * i),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _ResultCard(result: _results[i], best: i == 0),
                    ),
                  ),
                if (_results.isNotEmpty)
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 320),
                    child: GhostButton(
                      label: 'Find players for ${_results.first.sport.name}',
                      icon: Icons.group_add_outlined,
                      onPressed: () => widget.onFindPlayers(_results.first.sport.name),
                    ),
                  ),
              ],
            ),
          _Stage.input => Padding(
              key: const ValueKey<String>('input'),
              padding: const EdgeInsets.symmetric(vertical: 18),
              child: Column(children: <Widget>[
                Row(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
                  Image.asset('assets/images/soccer.png', width: 44),
                  Image.asset('assets/images/tennis.png', width: 36),
                  Image.asset('assets/images/basket.png', width: 44),
                ]),
                const SizedBox(height: 12),
                const Text('Pick your gear, then tap Match', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                const Text('Results appear here.', style: TextStyles.small, textAlign: TextAlign.center),
              ]),
            ),
        },
      ),
    );

    final Widget button = GoldButton(
      label: 'Match me with a game',
      onPressed: _stage == _Stage.loading ? null : () => _run(s),
    );

    final List<Widget> left = <Widget>[
      FadeSlideIn(delay: const Duration(milliseconds: 50), child: gearCard),
      const SizedBox(height: 16),
      FadeSlideIn(delay: const Duration(milliseconds: 100), child: wishCard),
      const SizedBox(height: 16),
      FadeSlideIn(delay: const Duration(milliseconds: 150), child: button),
    ];

    return ListView(
      padding: pagePadding(context),
      children: <Widget>[
        const PageHeader(eyebrow: 'L my ex items', title: 'Find a game'),
        const SizedBox(height: 20),
        if (wide)
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
            Expanded(flex: 135, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: left)),
            const SizedBox(width: 24),
            Expanded(flex: 100, child: FadeSlideIn(delay: const Duration(milliseconds: 120), child: results)),
          ])
        else ...<Widget>[
          ...left,
          const SizedBox(height: 16),
          results,
        ],
      ],
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.result, required this.best});
  final MatchResult result;
  final bool best;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: best
            ? const LinearGradient(colors: <Color>[Color(0x29E6C27A), Color(0x14C9785A)], begin: Alignment.topLeft, end: Alignment.bottomRight)
            : null,
        color: best ? null : AppColors.card,
        border: Border.all(color: best ? const Color(0x66E6C27A) : AppColors.cardLine),
      ),
      child: Row(children: <Widget>[
        PercentRing(percent: result.percent),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
            Row(children: <Widget>[
              ItemThumb(sport: result.sport.name, size: 22, radius: 6),
              const SizedBox(width: 8),
              Expanded(child: Text(result.sport.name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600))),
            ]),
            const SizedBox(height: 4),
            Text(result.why, style: const TextStyle(fontSize: 13, height: 1.4, color: Color(0xFFB9B1A2))),
          ]),
        ),
      ]),
    );
  }
}
