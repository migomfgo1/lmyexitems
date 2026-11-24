import 'package:material_ui/material_ui.dart';

import '../state.dart';
import '../theme.dart';
import '../widgets.dart';

/// Tab 5 — editable profile (name, photo, birth date, about) and your stats.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, required this.onOpenTab});
  final ValueChanged<int> onOpenTab;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _editing = false;
  final TextEditingController _name = TextEditingController();
  final TextEditingController _about = TextEditingController();
  DateTime? _birth;

  @override
  void dispose() {
    _name.dispose();
    _about.dispose();
    super.dispose();
  }

  void _startEdit(AppState s) {
    _name.text = s.profile.name;
    _about.text = s.profile.about;
    _birth = s.profile.birthDate;
    setState(() => _editing = true);
  }

  void _save(AppState s) {
    s.update(() {
      s.profile.name = _name.text.trim();
      s.profile.about = _about.text.trim();
      s.profile.birthDate = _birth;
    });
    setState(() => _editing = false);
    showToast(context, 'Profile saved');
  }

  Future<void> _pickBirth() async {
    final DateTime now = DateTime.now();
    final DateTime? d = await showDatePicker(
      context: context,
      initialDate: _birth ?? DateTime(now.year - 25, 1, 1),
      firstDate: DateTime(1920),
      lastDate: now,
      initialEntryMode: DatePickerEntryMode.calendarOnly,
    );
    if (d != null) setState(() => _birth = d);
  }

  Future<void> _confirmReset(AppState s) async {
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: const Text('Delete all data?'),
        content: const Text('This removes your gear, players, games, photos and profile from this device. It can’t be undone.'),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: AppColors.coral)),
          ),
        ],
      ),
    );
    if (ok == true) {
      await s.resetAll();
      if (mounted) showToast(context, 'All data deleted');
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppState s = AppScope.of(context);
    final Profile p = s.profile;
    final bool wide = isWide(context);

    final Widget card = GlassCard(
      gold: true,
      padding: const EdgeInsets.fromLTRB(20, 26, 20, 22),
      child: Column(children: <Widget>[
        Pressable(
          semanticLabel: 'Profile photo. Tap to change.',
          onTap: () async {
            final String? photo = await pickPhoto(context);
            if (photo == null) return;
            await PhotoStore.instance.delete(p.photo);
            s.update(() => p.photo = photo);
          },
          child: _HaloAvatar(initials: p.initials, photo: p.photo),
        ),
        const SizedBox(height: 14),
        AnimatedSwitcher(
          duration: Motion.base,
          child: _editing
              ? Column(
                  key: const ValueKey<String>('edit'),
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    AppField(label: 'Name', controller: _name, hint: 'Your name'),
                    const SizedBox(height: 12),
                    const Text('Date of birth', style: TextStyles.label),
                    const SizedBox(height: 6),
                    Pressable(
                      semanticLabel: 'Date of birth',
                      onTap: _pickBirth,
                      child: Container(
                        height: 48,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        alignment: Alignment.centerLeft,
                        decoration: BoxDecoration(
                            color: AppColors.field,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.fieldLine)),
                        child: Row(children: <Widget>[
                          Expanded(
                            child: Text(_birth == null ? 'Choose a date' : _longDate(_birth!),
                                style: TextStyle(fontSize: 16, color: _birth == null ? const Color(0xFF7F786C) : AppColors.text)),
                          ),
                          const Icon(Icons.event_outlined, color: AppColors.gold, size: 20),
                        ]),
                      ),
                    ),
                    const SizedBox(height: 12),
                    AppField(label: 'About me', controller: _about, maxLines: 3, hint: 'What do you like to play?'),
                    const SizedBox(height: 16),
                    GoldButton(label: 'Save', small: true, onPressed: () => _save(s)),
                  ],
                )
              : Column(
                  key: const ValueKey<String>('view'),
                  children: <Widget>[
                    Text(p.name.isEmpty ? 'Add your name' : p.name,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700, letterSpacing: -.5)),
                    const SizedBox(height: 4),
                    Text(
                      <String>[
                        if (p.birthDate != null) 'Born ${_longDate(p.birthDate!)}',
                        'Member since ${_longDate(p.joined).split(' ').first} ${p.joined.year}',
                      ].join(' · '),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 14, color: AppColors.muted),
                    ),
                    const SizedBox(height: 10),
                    Text(p.about.isEmpty ? 'Tell people what you like to play — tap Edit.' : p.about,
                        textAlign: TextAlign.center, style: TextStyles.body),
                  ],
                ),
        ),
      ]),
    );

    final List<(String, int, String, int)> stats = <(String, int, String, int)>[
      ('items saved', s.items.length, 'Gear', 1),
      ('games played', s.gamesPlayed, 'Analytics', 3),
      ('games created', s.gamesCreated, 'Your game', 2),
      ('people invited', s.invitedCount, 'Players', 1),
    ];

    final Widget right = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: <Widget>[
      GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: wide ? 1.9 : 1.45,
        children: <Widget>[
          for (int i = 0; i < stats.length; i++)
            Pressable(
              semanticLabel: '${stats[i].$2} ${stats[i].$1}. Open ${stats[i].$3}.',
              onTap: () => widget.onOpenTab(stats[i].$4),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: AppColors.card, borderRadius: BorderRadius.circular(22), border: Border.all(color: AppColors.cardLine)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: <Widget>[
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0, end: stats[i].$2.toDouble()),
                    duration: Duration(milliseconds: 700 + i * 120),
                    curve: Motion.ease,
                    builder: (BuildContext context, double v, _) => GoldText('${v.round()}',
                        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w700, letterSpacing: -1)),
                  ),
                  Text(stats[i].$1, style: const TextStyle(fontSize: 13, color: Color(0xFFB9B1A2))),
                ]),
              ),
            ),
        ],
      ),
      const SizedBox(height: 18),
      Container(
        decoration: BoxDecoration(
            color: AppColors.card, borderRadius: BorderRadius.circular(22), border: Border.all(color: AppColors.cardLine)),
        clipBehavior: Clip.antiAlias,
        child: Column(children: <Widget>[
          ListTile(
            leading: const Icon(Icons.info_outline_rounded, color: AppColors.gold),
            title: const Text('About L my ex items'),
            onTap: () => showAboutDialog(
              context: context,
              applicationName: 'L my ex items',
              applicationLegalese:
                  'Suggests sports and games for the gear you already own, and helps you invite friends. Everything you add stays on this device.',
            ),
          ),
          const Divider(height: 1, color: Color(0x0FFFFFFF)),
          ListTile(
            leading: const Icon(Icons.delete_outline_rounded, color: AppColors.coral),
            title: const Text('Delete all my data', style: TextStyle(color: AppColors.coral)),
            onTap: () => _confirmReset(s),
          ),
        ]),
      ),
    ]);

    return ListView(
      padding: pagePadding(context),
      children: <Widget>[
        PageHeader(
          title: 'Profile',
          trailing: _editing
              ? GhostButton(label: 'Cancel', onPressed: () => setState(() => _editing = false))
              : GhostButton(label: 'Edit', icon: Icons.edit_outlined, onPressed: () => _startEdit(s)),
        ),
        const SizedBox(height: 18),
        if (wide)
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
            Expanded(child: FadeSlideIn(delay: const Duration(milliseconds: 50), child: card)),
            const SizedBox(width: 24),
            Expanded(child: FadeSlideIn(delay: const Duration(milliseconds: 100), child: right)),
          ])
        else ...<Widget>[
          FadeSlideIn(delay: const Duration(milliseconds: 50), child: card),
          const SizedBox(height: 18),
          FadeSlideIn(delay: const Duration(milliseconds: 100), child: right),
        ],
      ],
    );
  }

  static String _longDate(DateTime d) {
    const List<String> m = <String>[
      'January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${m[d.month - 1]} ${d.day}, ${d.year}';
  }
}

class _HaloAvatar extends StatefulWidget {
  const _HaloAvatar({required this.initials, this.photo});
  final String initials;
  final String? photo;

  @override
  State<_HaloAvatar> createState() => _HaloAvatarState();
}

class _HaloAvatarState extends State<_HaloAvatar> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120,
      height: 120,
      child: Stack(alignment: Alignment.center, children: <Widget>[
        RotationTransition(
          turns: _c,
          child: Container(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: SweepGradient(colors: <Color>[AppColors.goldHi, AppColors.goldLo, AppColors.copper, AppColors.goldHi]),
            ),
          ),
        ),
        Container(margin: const EdgeInsets.all(4), decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF121317))),
        Container(
          margin: const EdgeInsets.all(10),
          clipBehavior: Clip.antiAlias,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(colors: <Color>[Color(0xFFF1D48E), Color(0xFFA8752F)], begin: Alignment.topLeft, end: Alignment.bottomRight),
          ),
          alignment: Alignment.center,
          child: widget.photo != null
              ? Image.file(PhotoStore.instance.file(widget.photo!), fit: BoxFit.cover, width: 100, height: 100)
              : Text(widget.initials,
                  style: const TextStyle(fontSize: 38, fontWeight: FontWeight.w700, color: AppColors.ink, letterSpacing: -.5)),
        ),
        Positioned(
          right: 2,
          bottom: 4,
          child: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
                shape: BoxShape.circle, color: AppColors.gold, border: Border.all(color: const Color(0xFF121317), width: 3)),
            child: const Icon(Icons.photo_camera_rounded, size: 16, color: AppColors.ink),
          ),
        ),
      ]),
    );
  }
}
