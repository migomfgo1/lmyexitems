import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../matching.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets.dart';

/// Tab 3 — invent a game: idea, rules, cover photo, date; then record how it went.
class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final TextEditingController _name = TextEditingController();
  final TextEditingController _idea = TextEditingController();
  final TextEditingController _rule = TextEditingController();
  final List<String> _rules = <String>[];
  String _sport = kSports.first.name;
  String? _photo;
  int _players = 6;
  DateTime _date = _nextSaturday();

  static DateTime _nextSaturday() {
    final DateTime n = DateTime.now();
    final int add = (DateTime.saturday - n.weekday) % 7;
    return DateTime(n.year, n.month, n.day + (add == 0 ? 7 : add), 11);
  }

  @override
  void dispose() {
    _name.dispose();
    _idea.dispose();
    _rule.dispose();
    super.dispose();
  }

  void _addRule() {
    final String r = _rule.text.trim();
    if (r.isEmpty) return;
    setState(() => _rules.add(r));
    _rule.clear();
  }

  Future<void> _pickDate() async {
    final DateTime now = DateTime.now();
    final DateTime? d = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (d != null) setState(() => _date = DateTime(d.year, d.month, d.day, 11));
  }

  Future<void> _publish(AppState s) async {
    final String name = _name.text.trim();
    if (name.isEmpty) {
      showToast(context, 'Give your game a name');
      return;
    }
    if (_rules.isEmpty) {
      showToast(context, 'Add at least one rule');
      return;
    }
    final Game g = Game(
      id: newId(),
      name: name,
      idea: _idea.text.trim(),
      rules: List<String>.from(_rules),
      players: _players,
      sport: _sport,
      date: _date,
      photo: _photo,
    );
    s.update(() => s.games.insert(0, g));
    final StringBuffer invite = StringBuffer('Join my game “$name” on ${formatDate(_date)}!\n');
    if (g.idea.isNotEmpty) invite.writeln(g.idea);
    for (int i = 0; i < _rules.length; i++) {
      invite.writeln('${i + 1}. ${_rules[i]}');
    }
    invite.write('Players: $_players');
    await Clipboard.setData(ClipboardData(text: invite.toString()));
    if (!mounted) return;
    showToast(context, '“$name” saved — invite copied to paste in any chat');
    setState(() {
      _name.clear();
      _idea.clear();
      _rules.clear();
      _photo = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final AppState s = AppScope.of(context);
    final bool wide = isWide(context);

    final Widget cover = Pressable(
      semanticLabel: 'Cover photo. Tap to choose.',
      onTap: () async {
        final String? p = await pickPhoto(context);
        if (p != null) setState(() => _photo = p);
      },
      child: Container(
        height: 200,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: const RadialGradient(colors: <Color>[Color(0xFF3B2C17), Color(0xFF17140F)], radius: .9),
          border: Border.all(color: const Color(0x4DE6C27A)),
        ),
        child: Stack(fit: StackFit.expand, children: <Widget>[
          if (_photo != null)
            ItemThumb(photo: _photo, sport: _sport, size: 2000, radius: 0)
          else
            Center(child: _FloatingArt(sport: _sport)),
          Positioned(
            left: 14,
            bottom: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(color: const Color(0x8C000000), borderRadius: BorderRadius.circular(14)),
              child: Row(children: <Widget>[
                const Icon(Icons.photo_camera_outlined, size: 14, color: Color(0xFFF3D99B)),
                const SizedBox(width: 6),
                Text(_photo == null ? 'Add a cover photo' : 'Change cover',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFFF3D99B))),
              ]),
            ),
          ),
        ]),
      ),
    );

    final Widget basics = GlassCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: <Widget>[
        AppField(label: 'Game name', controller: _name, hint: 'e.g. Golden Bounce', titleStyle: true),
        const SizedBox(height: 14),
        AppField(
          label: 'The idea',
          controller: _idea,
          maxLines: 4,
          hint: 'What is the point of the game? How do you score?',
        ),
        const SizedBox(height: 14),
        const Text('Based on', style: TextStyles.label),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: <Widget>[
          for (final Sport sp in kSports.take(5))
            TagChip(label: sp.name, selected: _sport == sp.name, onTap: () => setState(() => _sport = sp.name)),
        ]),
        const SizedBox(height: 14),
        Row(children: <Widget>[
          const Expanded(child: Text('Players', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500))),
          _Stepper(value: _players, onChanged: (int v) => setState(() => _players = v)),
        ]),
        const SizedBox(height: 10),
        Row(children: <Widget>[
          const Expanded(child: Text('Date', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500))),
          GhostButton(label: formatDate(_date), icon: Icons.event_outlined, onPressed: _pickDate),
        ]),
      ]),
    );

    final Widget rules = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: <Widget>[
      Row(children: <Widget>[
        const Expanded(child: Text('Rules', style: TextStyles.h2Big)),
        Text('${_rules.length} rules', style: TextStyles.small),
      ]),
      const SizedBox(height: 10),
      for (int i = 0; i < _rules.length; i++)
        FadeSlideIn(
          key: ValueKey<String>('rule-$i-${_rules[i]}'),
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: AppColors.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0x0FFFFFFF))),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
              Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                    shape: BoxShape.circle, gradient: LinearGradient(colors: <Color>[Color(0xFFF1D48E), AppColors.goldLo])),
                child: Text('${i + 1}', style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w700, fontSize: 13)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: Text(_rules[i], style: const TextStyle(fontSize: 14.5, height: 1.45, color: Color(0xFFE4DCCD))),
                ),
              ),
              IconButton(
                tooltip: 'Delete rule',
                icon: const Icon(Icons.close_rounded, size: 18, color: Color(0xFF7F786C)),
                onPressed: () => setState(() => _rules.removeAt(i)),
              ),
            ]),
          ),
        ),
      Row(children: <Widget>[
        Expanded(
          child: AppField(
            label: 'New rule',
            hideLabel: true,
            controller: _rule,
            hint: 'Add a rule…',
            onSubmitted: (_) => _addRule(),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 48,
          height: 48,
          child: Pressable(
            semanticLabel: 'Add rule',
            onTap: _addRule,
            child: Container(
              decoration: BoxDecoration(color: AppColors.gold, borderRadius: BorderRadius.circular(14)),
              child: const Icon(Icons.add_rounded, color: AppColors.ink),
            ),
          ),
        ),
      ]),
      const SizedBox(height: 16),
      GoldButton(label: 'Save game & copy invite', onPressed: () => _publish(s)),
    ]);

    final List<Game> mine = s.games.where((Game g) => !g.sample).toList();
    final Widget myGames = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: <Widget>[
      const Text('My games', style: TextStyles.h2Big),
      const SizedBox(height: 10),
      if (mine.isEmpty)
        const GlassCard(child: Text('Games you save appear here. After you play, record how it went — it feeds Analytics.', style: TextStyles.body)),
      for (final Game g in mine)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Dismissible(
            key: ValueKey<String>(g.id),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              decoration: BoxDecoration(color: const Color(0x33C9785A), borderRadius: BorderRadius.circular(18)),
              child: const Icon(Icons.delete_outline_rounded, color: AppColors.coral),
            ),
            onDismissed: (_) {
              PhotoStore.instance.delete(g.photo);
              s.update(() => s.games.remove(g));
            },
            child: Pressable(
              semanticLabel: '${g.name}. Tap to record the result.',
              onTap: () => showResultSheet(context, g),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: AppColors.card, borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0x0FFFFFFF))),
                child: Row(children: <Widget>[
                  ItemThumb(photo: g.photo, sport: g.sport, size: 44),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                      Text(g.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                      Text('${formatDate(g.date)} · ${g.players} players', style: TextStyles.small),
                    ]),
                  ),
                  _ResultBadge(game: g),
                ]),
              ),
            ),
          ),
        ),
    ]);

    return ListView(
      padding: _pad(context),
      children: <Widget>[
        const PageHeader(eyebrow: 'Game builder', title: 'Your game'),
        const SizedBox(height: 18),
        if (wide)
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
            Expanded(
              child: Column(children: <Widget>[
                FadeSlideIn(delay: const Duration(milliseconds: 50), child: cover),
                const SizedBox(height: 16),
                FadeSlideIn(delay: const Duration(milliseconds: 100), child: basics),
              ]),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: Column(children: <Widget>[
                FadeSlideIn(delay: const Duration(milliseconds: 120), child: rules),
                const SizedBox(height: 24),
                FadeSlideIn(delay: const Duration(milliseconds: 160), child: myGames),
              ]),
            ),
          ])
        else ...<Widget>[
          FadeSlideIn(delay: const Duration(milliseconds: 50), child: cover),
          const SizedBox(height: 16),
          FadeSlideIn(delay: const Duration(milliseconds: 100), child: basics),
          const SizedBox(height: 20),
          FadeSlideIn(delay: const Duration(milliseconds: 150), child: rules),
          const SizedBox(height: 24),
          myGames,
        ],
      ],
    );
  }

  EdgeInsets _pad(BuildContext context) => pagePadding(context);
}

class _FloatingArt extends StatefulWidget {
  const _FloatingArt({required this.sport});
  final String sport;

  @override
  State<_FloatingArt> createState() => _FloatingArtState();
}

class _FloatingArtState extends State<_FloatingArt> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (BuildContext context, Widget? child) {
        final double t = Curves.easeInOut.transform(_c.value);
        return Transform.translate(offset: Offset(0, -8 * t), child: Transform.rotate(angle: .14 * t, child: child));
      },
      child: ItemThumb(sport: widget.sport, size: 120, radius: 30),
    );
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper({required this.value, required this.onChanged});
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(color: const Color(0x0FFFFFFF), borderRadius: BorderRadius.circular(14)),
      child: Row(mainAxisSize: MainAxisSize.min, children: <Widget>[
        IconButton(
            tooltip: 'Fewer players',
            onPressed: value > 2 ? () => onChanged(value - 1) : null,
            icon: const Icon(Icons.remove_rounded, size: 20)),
        SizedBox(
            width: 32,
            child: Text('$value',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, fontFeatures: <FontFeature>[FontFeature.tabularFigures()]))),
        IconButton(
            tooltip: 'More players',
            onPressed: value < 30 ? () => onChanged(value + 1) : null,
            icon: const Icon(Icons.add_rounded, size: 20)),
      ]),
    );
  }
}

class _ResultBadge extends StatelessWidget {
  const _ResultBadge({required this.game});
  final Game game;

  @override
  Widget build(BuildContext context) {
    final bool? ok = game.success;
    final String text = ok == null ? 'Record result' : (ok ? '✓ ${game.rating?.toStringAsFixed(1) ?? ''} ★' : '✕ Didn’t happen');
    final Color fg = ok == false ? AppColors.coral : AppColors.gold;
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      alignment: Alignment.center,
      decoration: BoxDecoration(color: fg.withValues(alpha: .14), borderRadius: BorderRadius.circular(14)),
      child: Text(text, style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}

/// Record how a game went: did it happen, how many came, rating.
Future<void> showResultSheet(BuildContext context, Game g) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (BuildContext ctx) => _ResultSheet(game: g),
  );
}

class _ResultSheet extends StatefulWidget {
  const _ResultSheet({required this.game});
  final Game game;

  @override
  State<_ResultSheet> createState() => _ResultSheetState();
}

class _ResultSheetState extends State<_ResultSheet> {
  late bool _happened = widget.game.success ?? true;
  late int _came = widget.game.signups == 0 ? widget.game.players : widget.game.signups;
  late double _rating = widget.game.rating ?? 4;

  @override
  Widget build(BuildContext context) {
    final AppState s = AppScope.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: <Widget>[
          Text('How did “${widget.game.name}” go?', style: TextStyles.h2Big),
          const SizedBox(height: 12),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text('The game happened'),
            value: _happened,
            activeTrackColor: const Color(0xFFD9A851),
            onChanged: (bool v) => setState(() => _happened = v),
          ),
          Row(children: <Widget>[
            const Expanded(child: Text('People who signed up', style: TextStyle(fontSize: 15))),
            _Stepper(value: _came, onChanged: (int v) => setState(() => _came = v)),
          ]),
          const SizedBox(height: 12),
          Text('Rating: ${_rating.toStringAsFixed(1)} ★', style: const TextStyle(fontSize: 15)),
          Slider.adaptive(
            value: _rating,
            min: 1,
            max: 5,
            divisions: 8,
            activeColor: AppColors.gold,
            label: _rating.toStringAsFixed(1),
            onChanged: (double v) => setState(() => _rating = v),
          ),
          const SizedBox(height: 8),
          GoldButton(
            label: 'Save result',
            small: true,
            onPressed: () {
              s.update(() {
                widget.game.success = _happened;
                widget.game.signups = _came;
                widget.game.rating = _rating;
              });
              showToast(context, 'Result saved — see Analytics');
              Navigator.pop(context);
            },
          ),
        ]),
      ),
    );
  }
}

String formatDate(DateTime d) {
  const List<String> m = <String>['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  const List<String> w = <String>['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  return '${w[d.weekday - 1]}, ${m[d.month - 1]} ${d.day}';
}
