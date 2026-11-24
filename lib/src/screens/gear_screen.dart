import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../matching.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets.dart';

/// Tab 2 — your gear (with photos) and the people you can invite.
class GearScreen extends StatefulWidget {
  const GearScreen({super.key, this.playersFilter});
  final String? playersFilter; // set when coming from "Find players"

  @override
  State<GearScreen> createState() => _GearScreenState();
}

class _GearScreenState extends State<GearScreen> {
  late bool _showPlayers = widget.playersFilter != null;
  late String _filter = widget.playersFilter ?? kSports.first.name;

  @override
  Widget build(BuildContext context) {
    final bool wide = isWide(context);
    final Widget gear = _GearList();
    final Widget players = _PlayersList(filter: _filter, onFilter: (String f) => setState(() => _filter = f));

    return ListView(
      padding: pagePadding(context),
      children: <Widget>[
        const PageHeader(eyebrow: 'Collection', title: 'Gear & players'),
        const SizedBox(height: 18),
        if (wide)
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
            Expanded(child: FadeSlideIn(delay: const Duration(milliseconds: 50), child: gear)),
            const SizedBox(width: 24),
            Expanded(child: FadeSlideIn(delay: const Duration(milliseconds: 100), child: players)),
          ])
        else ...<Widget>[
          FadeSlideIn(
            delay: const Duration(milliseconds: 50),
            child: Segmented<bool>(
              large: true,
              options: const <bool, String>{false: 'My gear', true: 'Players'},
              value: _showPlayers,
              onChanged: (bool v) => setState(() => _showPlayers = v),
            ),
          ),
          const SizedBox(height: 16),
          AnimatedSwitcher(
            duration: Motion.base,
            child: KeyedSubtree(key: ValueKey<bool>(_showPlayers), child: _showPlayers ? players : gear),
          ),
        ],
      ],
    );
  }
}

class _GearList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final AppState s = AppScope.of(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: <Widget>[
      Row(children: <Widget>[
        const Expanded(child: Text('My gear', style: TextStyles.h2Big)),
        Text('${s.items.length} items', style: TextStyles.small),
      ]),
      const SizedBox(height: 12),
      DashedAction(label: 'Describe a new item', icon: Icons.add_a_photo_outlined, onTap: () => showAddItemSheet(context)),
      const SizedBox(height: 12),
      if (s.items.isEmpty)
        const GlassCard(child: Text('Nothing here yet. Add the sports things you own — we use them to suggest games.', style: TextStyles.body)),
      for (final GearItem it in s.items)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Dismissible(
            key: ValueKey<String>(it.id),
            direction: DismissDirection.endToStart,
            background: const _DeleteBackground(),
            onDismissed: (_) {
              PhotoStore.instance.delete(it.photo);
              s.update(() {
                s.items.remove(it);
                s.selectedItemIds.remove(it.id);
              });
              showToast(context, '${it.name} removed');
            },
            child: Pressable(
              onTap: () => showAddItemSheet(context, editing: it),
              semanticLabel: '${it.name}, ${it.sport}. Tap to edit, swipe left to delete.',
              child: _Row(
                leading: ItemThumb(photo: it.photo, sport: it.sport, size: 46),
                title: it.name,
                subtitle: it.description.isEmpty ? it.sport : '${it.sport} · ${it.description}',
                trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFF6F695F)),
              ),
            ),
          ),
        ),
    ]);
  }
}

class _PlayersList extends StatelessWidget {
  const _PlayersList({required this.filter, required this.onFilter});
  final String filter;
  final ValueChanged<String> onFilter;

  @override
  Widget build(BuildContext context) {
    final AppState s = AppScope.of(context);
    final List<Person> list = s.people.where((Person p) => p.sport == filter).toList();
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: <Widget>[
      Row(children: <Widget>[
        const Expanded(child: Text('Players to invite', style: TextStyles.h2Big)),
        GhostButton(label: 'Add', icon: Icons.person_add_alt_1_outlined, onPressed: () => _addPerson(context, s)),
      ]),
      const SizedBox(height: 12),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: <Widget>[
          for (final Sport sp in kSports)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TagChip(label: sp.name, selected: sp.name == filter, onTap: () => onFilter(sp.name)),
            ),
        ]),
      ),
      const SizedBox(height: 12),
      if (list.isEmpty)
        GlassCard(
          child: Text('No one in your list for $filter yet. Add friends who might want to play.', style: TextStyles.body),
        ),
      for (int i = 0; i < list.length; i++)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Dismissible(
            key: ValueKey<String>(list[i].id),
            direction: DismissDirection.endToStart,
            background: const _DeleteBackground(),
            onDismissed: (_) => s.update(() => s.people.remove(list[i])),
            child: _Row(
              leading: _Avatar(name: list[i].name, index: i),
              title: list[i].name,
              subtitle: list[i].sport,
              trailing: _InviteButton(person: list[i]),
            ),
          ),
        ),
    ]);
  }

  Future<void> _addPerson(BuildContext context, AppState s) async {
    final TextEditingController c = TextEditingController();
    final String? name = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext ctx) => Padding(
        padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + MediaQuery.viewInsetsOf(ctx).bottom),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: <Widget>[
          Text('Add a player for $filter', style: TextStyles.h2),
          const SizedBox(height: 14),
          AppField(label: 'Full name', controller: c, hint: 'e.g. Maya Brooks', onSubmitted: (String v) => Navigator.pop(ctx, v)),
          const SizedBox(height: 16),
          GoldButton(label: 'Add to list', small: true, onPressed: () => Navigator.pop(ctx, c.text)),
        ]),
      ),
    );
    c.dispose();
    final String n = (name ?? '').trim();
    if (n.isEmpty) return;
    s.update(() => s.people.insert(0, Person(id: newId(), name: n, sport: filter)));
    if (context.mounted) showToast(context, '$n added');
  }
}

class _InviteButton extends StatelessWidget {
  const _InviteButton({required this.person});
  final Person person;

  @override
  Widget build(BuildContext context) {
    final AppState s = AppScope.of(context);
    final bool on = person.invited;
    return Pressable(
      selected: on,
      semanticLabel: on ? 'Invited' : 'Invite ${person.name}',
      onTap: () async {
        if (!on) {
          await Clipboard.setData(ClipboardData(
              text: 'Hey ${person.name.split(' ').first}! Want to play ${person.sport} this week? I have the gear — join me. (L my ex items)'));
          if (context.mounted) showToast(context, 'Invite text copied — paste it in any chat');
        }
        s.update(() => person.invited = !on);
      },
      child: AnimatedContainer(
        duration: Motion.fast,
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: on ? const Color(0x1FE6C27A) : AppColors.gold,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: on ? const Color(0x66E6C27A) : AppColors.gold),
        ),
        child: Text(on ? 'Invited ✓' : 'Invite',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: on ? AppColors.gold : AppColors.ink)),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.leading, required this.title, required this.subtitle, this.trailing});
  final Widget leading;
  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0x0FFFFFFF)),
      ),
      child: Row(children: <Widget>[
        leading,
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
            Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyles.small),
          ]),
        ),
        if (trailing != null) ...<Widget>[const SizedBox(width: 8), trailing!],
      ]),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.name, required this.index});
  final String name;
  final int index;

  static const List<List<Color>> _grads = <List<Color>>[
    <Color>[Color(0xFFF1D48E), Color(0xFFA8752F)],
    <Color>[Color(0xFFE3A189), Color(0xFF9C4E37)],
    <Color>[Color(0xFFD9C7A5), Color(0xFF7E6A4B)],
    <Color>[Color(0xFFC9785A), Color(0xFF7A3326)],
  ];

  @override
  Widget build(BuildContext context) {
    final String initials = name.trim().split(RegExp(r'\s+')).take(2).map((String w) => w.isEmpty ? '' : w[0].toUpperCase()).join();
    return Container(
      width: 44,
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(colors: _grads[index % 4], begin: Alignment.topLeft, end: Alignment.bottomRight)),
      child: Text(initials, style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w700, fontSize: 15)),
    );
  }
}

class _DeleteBackground extends StatelessWidget {
  const _DeleteBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 20),
      decoration: BoxDecoration(color: const Color(0x33C9785A), borderRadius: BorderRadius.circular(18)),
      child: const Icon(Icons.delete_outline_rounded, color: AppColors.coral),
    );
  }
}

/// Add or edit an item: photo (camera or library), name, description, sport.
Future<GearItem?> showAddItemSheet(BuildContext context, {GearItem? editing}) {
  return showModalBottomSheet<GearItem>(
    context: context,
    isScrollControlled: true,
    builder: (BuildContext ctx) => _ItemSheet(editing: editing),
  );
}

class _ItemSheet extends StatefulWidget {
  const _ItemSheet({this.editing});
  final GearItem? editing;

  @override
  State<_ItemSheet> createState() => _ItemSheetState();
}

class _ItemSheetState extends State<_ItemSheet> {
  late final TextEditingController _name = TextEditingController(text: widget.editing?.name ?? '');
  late final TextEditingController _desc = TextEditingController(text: widget.editing?.description ?? '');
  late String _sport = widget.editing?.sport ?? kSports.first.name;
  late String? _photo = widget.editing?.photo;

  @override
  void dispose() {
    _name.dispose();
    _desc.dispose();
    super.dispose();
  }

  void _save() {
    final AppState s = AppScope.of(context);
    final String name = _name.text.trim();
    if (name.isEmpty) {
      showToast(context, 'Give the item a name');
      return;
    }
    final GearItem? e = widget.editing;
    if (e != null) {
      s.update(() {
        e.name = name;
        e.description = _desc.text.trim();
        e.sport = _sport;
        e.photo = _photo;
      });
      Navigator.pop(context, e);
    } else {
      final GearItem it = GearItem(id: newId(), name: name, description: _desc.text.trim(), sport: _sport, photo: _photo);
      s.update(() => s.items.insert(0, it));
      Navigator.pop(context, it);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: <Widget>[
          Text(widget.editing == null ? 'Describe an item' : 'Edit item', style: TextStyles.h2Big),
          const SizedBox(height: 16),
          Row(children: <Widget>[
            Pressable(
              semanticLabel: 'Add photo',
              onTap: () async {
                final String? p = await pickPhoto(context);
                if (p != null) setState(() => _photo = p);
              },
              child: Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: const Color(0x14E6C27A),
                  border: Border.all(color: const Color(0x4DE6C27A)),
                ),
                child: _photo == null
                    ? const Icon(Icons.add_a_photo_outlined, color: AppColors.gold, size: 28)
                    : ItemThumb(photo: _photo, sport: _sport, size: 84, radius: 20),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(child: AppField(label: 'Name', controller: _name, hint: 'e.g. Volleyball, running shoes')),
          ]),
          const SizedBox(height: 14),
          AppField(label: 'Description', controller: _desc, maxLines: 2, hint: 'Condition, size, where it’s kept'),
          const SizedBox(height: 14),
          const Text('Good for', style: TextStyles.label),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: <Widget>[
            for (final Sport sp in kSports)
              TagChip(label: sp.name, selected: _sport == sp.name, onTap: () => setState(() => _sport = sp.name)),
          ]),
          const SizedBox(height: 20),
          GoldButton(label: widget.editing == null ? 'Save to collection' : 'Save changes', small: true, onPressed: _save),
        ]),
      ),
    );
  }
}
