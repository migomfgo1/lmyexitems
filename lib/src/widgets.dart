import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart' show ImageSource;
import 'package:material_ui/material_ui.dart';

import 'matching.dart';
import 'state.dart';
import 'theme.dart';

bool isWide(BuildContext context) => MediaQuery.sizeOf(context).width >= 768;

/// Shared page padding: room for the floating tab bar on phones.
EdgeInsets pagePadding(BuildContext context) {
  final EdgeInsets safe = MediaQuery.paddingOf(context);
  return isWide(context)
      ? EdgeInsets.fromLTRB(40, safe.top + 36, 40 + safe.right, 36 + safe.bottom)
      : EdgeInsets.fromLTRB(20 + safe.left, safe.top + 16, 20 + safe.right, 110 + safe.bottom);
}

void showToast(BuildContext context, String message) {
  HapticFeedback.lightImpact();
  final ScaffoldMessengerState m = ScaffoldMessenger.of(context);
  m.hideCurrentSnackBar();
  m.showSnackBar(SnackBar(
    content: Row(children: <Widget>[
      Container(
        width: 26,
        height: 26,
        decoration: const BoxDecoration(color: AppColors.gold, shape: BoxShape.circle),
        child: const Icon(Icons.check_rounded, size: 17, color: AppColors.ink),
      ),
      const SizedBox(width: 10),
      Expanded(child: Text(message)),
    ]),
    duration: const Duration(milliseconds: 2400),
  ));
}

/// Fades and lifts its child in once, with an optional delay (staggered entrances).
class FadeSlideIn extends StatefulWidget {
  const FadeSlideIn({super.key, required this.child, this.delay = Duration.zero});
  final Widget child;
  final Duration delay;

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: Motion.slow);

  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      _c.value = 1;
    } else {
      Future<void>.delayed(widget.delay, () {
        if (mounted) _c.forward();
      });
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Animation<double> a = CurvedAnimation(parent: _c, curve: Motion.ease);
    return AnimatedBuilder(
      animation: a,
      builder: (BuildContext context, Widget? child) => Opacity(
        opacity: a.value,
        child: Transform.translate(offset: Offset(0, 14 * (1 - a.value)), child: child),
      ),
      child: widget.child,
    );
  }
}

/// Scales down on touch-down (instant feedback), springs back on release.
class Pressable extends StatefulWidget {
  const Pressable({super.key, required this.child, required this.onTap, this.semanticLabel, this.selected});
  final Widget child;
  final VoidCallback? onTap;
  final String? semanticLabel;
  final bool? selected;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: widget.selected,
      label: widget.semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: widget.onTap == null ? null : (_) => setState(() => _down = true),
        onTapCancel: () => setState(() => _down = false),
        onTapUp: (_) => setState(() => _down = false),
        onTap: widget.onTap == null
            ? null
            : () {
                HapticFeedback.selectionClick();
                widget.onTap!();
              },
        child: AnimatedScale(
          scale: _down ? 0.96 : 1,
          duration: _down ? const Duration(milliseconds: 90) : Motion.base,
          curve: _down ? Curves.easeOut : Motion.pop,
          child: widget.child,
        ),
      ),
    );
  }
}

class GlassCard extends StatelessWidget {
  const GlassCard({super.key, required this.child, this.gold = false, this.padding = const EdgeInsets.all(18)});
  final Widget child;
  final bool gold;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: gold
            ? const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[Color(0x17E6C27A), Color(0x08FFFFFF)])
            : null,
        color: gold ? null : AppColors.card,
        border: Border.all(color: gold ? const Color(0x3DE6C27A) : AppColors.cardLine),
      ),
      child: child,
    );
  }
}

/// Primary action: metallic gold with a slow moving sheen.
class GoldButton extends StatefulWidget {
  const GoldButton({super.key, required this.label, required this.onPressed, this.small = false, this.icon});
  final String label;
  final VoidCallback? onPressed;
  final bool small;
  final IconData? icon;

  @override
  State<GoldButton> createState() => _GoldButtonState();
}

class _GoldButtonState extends State<GoldButton> with SingleTickerProviderStateMixin {
  late final AnimationController _sheen =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 3200));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final bool reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (!reduce && !_sheen.isAnimating) _sheen.repeat();
    if (reduce) _sheen.stop();
  }

  @override
  void dispose() {
    _sheen.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double h = widget.small ? 50 : 56;
    return Opacity(
      opacity: widget.onPressed == null ? .5 : 1,
      child: Pressable(
        onTap: widget.onPressed,
        semanticLabel: widget.label,
        child: Container(
          height: h,
          decoration: BoxDecoration(
            gradient: AppColors.goldButton,
            borderRadius: BorderRadius.circular(widget.small ? 16 : 18),
            boxShadow: const <BoxShadow>[BoxShadow(color: Color(0x40D6A048), blurRadius: 28, offset: Offset(0, 8))],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(fit: StackFit.expand, children: <Widget>[
            AnimatedBuilder(
              animation: _sheen,
              builder: (BuildContext context, _) {
                final double t = Curves.easeInOut.transform(_sheen.value);
                return FractionalTranslation(
                  translation: Offset(-1.2 + 2.6 * t, 0),
                  child: const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: <Color>[Color(0x00FFF8DC), Color(0x8CFFF8DC), Color(0x00FFF8DC)],
                        stops: <double>[.3, .5, .7],
                      ),
                    ),
                  ),
                );
              },
            ),
            Center(
              child: Row(mainAxisSize: MainAxisSize.min, children: <Widget>[
                if (widget.icon != null) ...<Widget>[Icon(widget.icon, color: AppColors.ink, size: 20), const SizedBox(width: 8)],
                Text(widget.label,
                    style: TextStyle(
                        color: AppColors.ink, fontSize: widget.small ? 16 : 17, fontWeight: FontWeight.w600, letterSpacing: -.2)),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

class GhostButton extends StatelessWidget {
  const GhostButton({super.key, required this.label, required this.onPressed, this.icon});
  final String label;
  final VoidCallback onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onPressed,
      semanticLabel: label,
      child: Container(
        height: 38,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: const Color(0x14E6C27A),
          borderRadius: BorderRadius.circular(19),
          border: Border.all(color: const Color(0x73E6C27A)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: <Widget>[
          if (icon != null) ...<Widget>[Icon(icon, size: 18, color: AppColors.gold), const SizedBox(width: 6)],
          Text(label, style: const TextStyle(color: AppColors.gold, fontSize: 14, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }
}

class DashedAction extends StatelessWidget {
  const DashedAction({super.key, required this.label, required this.icon, required this.onTap, this.height = 48});
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      semanticLabel: label,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: const Color(0x0FE6C27A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0x73E6C27A)),
        ),
        child: Center(
          child: Row(mainAxisSize: MainAxisSize.min, children: <Widget>[
            Icon(icon, color: AppColors.gold, size: 20),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(color: AppColors.gold, fontSize: 15, fontWeight: FontWeight.w600)),
          ]),
        ),
      ),
    );
  }
}

class TagChip extends StatelessWidget {
  const TagChip({super.key, required this.label, required this.selected, required this.onTap, this.leading});
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      selected: selected,
      semanticLabel: label,
      child: AnimatedContainer(
        duration: Motion.fast,
        height: 36,
        padding: EdgeInsets.only(left: leading == null ? 14 : 6, right: 14),
        decoration: BoxDecoration(
          color: selected ? AppColors.gold : const Color(0x0DFFFFFF),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: selected ? AppColors.gold : AppColors.fieldLine),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: <Widget>[
          if (leading != null) ...<Widget>[leading!, const SizedBox(width: 6)],
          Text(label,
              style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w500, color: selected ? AppColors.ink : AppColors.text2)),
        ]),
      ),
    );
  }
}

/// iOS-style segmented control with a sliding thumb.
class Segmented<T> extends StatelessWidget {
  const Segmented({super.key, required this.options, required this.value, required this.onChanged, this.large = false});
  final Map<T, String> options;
  final T value;
  final ValueChanged<T> onChanged;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final List<T> keys = options.keys.toList();
    final int index = math.max(0, keys.indexOf(value));
    return Container(
      height: large ? 42 : 36,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(color: const Color(0x0FFFFFFF), borderRadius: BorderRadius.circular(12)),
      child: LayoutBuilder(builder: (BuildContext context, BoxConstraints c) {
        final double w = c.maxWidth.isFinite ? c.maxWidth / keys.length : 90;
        return Stack(children: <Widget>[
          AnimatedPositioned(
            duration: Motion.base,
            curve: Motion.pop,
            left: w * index,
            top: 0,
            bottom: 0,
            width: w,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(9),
                color: large ? null : AppColors.gold,
                gradient: large
                    ? const LinearGradient(
                        begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: <Color>[Color(0xFF3A3226), Color(0xFF2A241B)])
                    : null,
                border: large ? Border.all(color: const Color(0x59E6C27A)) : null,
              ),
            ),
          ),
          Row(
            children: keys.map((T k) {
              final bool on = k == value;
              return SizedBox(
                width: w,
                child: Semantics(
                  selected: on,
                  button: true,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      onChanged(k);
                    },
                    child: Center(
                      child: AnimatedDefaultTextStyle(
                        duration: Motion.fast,
                        style: TextStyle(
                          fontSize: large ? 14 : 13,
                          fontWeight: FontWeight.w600,
                          color: on ? (large ? const Color(0xFFF3D99B) : AppColors.ink) : const Color(0xFFB9B1A2),
                        ),
                        child: Text(options[k]!, maxLines: 1),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ]);
      }),
    );
  }
}

class AppField extends StatelessWidget {
  const AppField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.maxLines = 1,
    this.onChanged,
    this.onSubmitted,
    this.titleStyle = false,
    this.hideLabel = false,
  });
  final String label;
  final TextEditingController controller;
  final String? hint;
  final int maxLines;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool titleStyle;
  final bool hideLabel;

  @override
  Widget build(BuildContext context) {
    final OutlineInputBorder border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: AppColors.fieldLine),
    );
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
      if (!hideLabel) ...<Widget>[Text(label, style: TextStyles.label), const SizedBox(height: 6)],
      Semantics(
        label: hideLabel ? label : null,
        textField: true,
        child: TextField(
        controller: controller,
        maxLines: maxLines,
        minLines: maxLines > 1 ? 2 : 1,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        textCapitalization: TextCapitalization.sentences,
        cursorColor: AppColors.gold,
        style: titleStyle
            ? const TextStyle(color: Color(0xFFF3D99B), fontSize: 19, fontWeight: FontWeight.w700, letterSpacing: -.3)
            : const TextStyle(fontSize: 16, color: AppColors.text, height: 1.4),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0xFF7F786C)),
          filled: true,
          fillColor: AppColors.field,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          enabledBorder: border,
          border: border,
          focusedBorder: border.copyWith(borderSide: const BorderSide(color: Color(0xB3E6C27A), width: 1.5)),
        ),
      ),
      ),
    ]);
  }
}

class PageHeader extends StatelessWidget {
  const PageHeader({super.key, this.eyebrow, required this.title, this.trailing});
  final String? eyebrow;
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return FadeSlideIn(
      child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: <Widget>[
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
            if (eyebrow != null) ...<Widget>[Text(eyebrow!.toUpperCase(), style: TextStyles.eyebrow), const SizedBox(height: 4)],
            Semantics(header: true, child: Text(title, style: TextStyles.h1(isWide(context)))),
          ]),
        ),
        if (trailing != null) trailing!,
      ]),
    );
  }
}

class GoldText extends StatelessWidget {
  const GoldText(this.text, {super.key, required this.style});
  final String text;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (Rect r) => AppColors.goldText.createShader(r),
      child: Text(text, style: style),
    );
  }
}

/// Picture for an item or a sport: the user's photo if there is one, else bundled art or an icon.
class ItemThumb extends StatelessWidget {
  const ItemThumb({super.key, this.photo, required this.sport, this.size = 44, this.radius = 14});
  final String? photo;
  final String sport;
  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) {
    if (photo != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Image.file(PhotoStore.instance.file(photo!), width: size, height: size, fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _fallback()),
      );
    }
    return _fallback();
  }

  Widget _fallback() {
    final Sport s = sportByName(sport);
    if (s.image != null) return Image.asset(s.image!, width: size, height: size);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: const Color(0x1FE6C27A), borderRadius: BorderRadius.circular(radius)),
      child: Icon(s.icon, color: AppColors.gold, size: size * .55),
    );
  }
}

/// Bottom sheet that asks camera or library, then returns the saved photo name.
Future<String?> pickPhoto(BuildContext context) async {
  final ImageSourceChoice? choice = await showModalBottomSheet<ImageSourceChoice>(
    context: context,
    builder: (BuildContext context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
          ListTile(
            leading: const Icon(Icons.photo_camera_outlined, color: AppColors.gold),
            title: const Text('Take a photo'),
            onTap: () => Navigator.pop(context, ImageSourceChoice.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined, color: AppColors.gold),
            title: const Text('Choose from library'),
            onTap: () => Navigator.pop(context, ImageSourceChoice.gallery),
          ),
        ]),
      ),
    ),
  );
  if (choice == null) return null;
  try {
    return await PhotoStore.instance.pick(choice.source);
  } catch (e) {
    if (context.mounted) showToast(context, 'Could not open ${choice == ImageSourceChoice.camera ? 'the camera' : 'your photos'}');
    return null;
  }
}

/// Glass bar used for the phone tab bar.
class GlassBar extends StatelessWidget {
  const GlassBar({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          decoration: const BoxDecoration(
            color: Color(0xB8121317),
            border: Border(top: BorderSide(color: AppColors.cardLine)),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Progress ring that animates to [percent].
class PercentRing extends StatelessWidget {
  const PercentRing({super.key, required this.percent, this.size = 64});
  final int percent;
  final double size;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: percent / 100),
      duration: const Duration(milliseconds: 900),
      curve: Motion.ease,
      builder: (BuildContext context, double v, _) => SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _RingPainter(v),
          child: Center(
            child: Text('${(v * 100).round()}%',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: -.3)),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.v);
  final double v;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect r = (Offset.zero & size).deflate(3);
    final Paint track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..color = const Color(0x14FFFFFF);
    final Paint arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..shader = const SweepGradient(colors: <Color>[AppColors.goldLo, AppColors.goldHi]).createShader(r);
    canvas.drawArc(r, 0, math.pi * 2, false, track);
    canvas.drawArc(r, -math.pi / 2, math.pi * 2 * v, false, arc);
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.v != v;
}

/// Rotating gold ring around a gold "L" — used while matching.
class OrbitLoader extends StatefulWidget {
  const OrbitLoader({super.key, this.size = 170});
  final double size;

  @override
  State<OrbitLoader> createState() => _OrbitLoaderState();
}

class _OrbitLoaderState extends State<OrbitLoader> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 2400))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double s = widget.size;
    const List<String> gearImages = <String>['assets/images/soccer.png', 'assets/images/tennis.png', 'assets/images/basket.png'];
    return SizedBox(
      width: s,
      height: s,
      child: AnimatedBuilder(
        animation: _c,
        builder: (BuildContext context, _) {
          return Stack(alignment: Alignment.center, children: <Widget>[
            Transform.rotate(
              angle: _c.value * math.pi * 2,
              child: Container(
                width: s,
                height: s,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: SweepGradient(colors: <Color>[Color(0x00E6C27A), AppColors.gold, Color(0x00E6C27A)], stops: <double>[0, .85, 1]),
                ),
              ),
            ),
            Container(width: s - 8, height: s - 8, decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.bg)),
            GoldText('L', style: TextStyle(fontSize: s * .42, fontWeight: FontWeight.w900, height: 1)),
            for (int i = 0; i < 3; i++)
              Transform.translate(
                offset: Offset(
                  math.cos(_c.value * math.pi * 2 + i * math.pi * 2 / 3) * s * .32,
                  math.sin(_c.value * math.pi * 2 + i * math.pi * 2 / 3) * s * .12,
                ),
                child: Image.asset(gearImages[i], width: s * .17, height: s * .17),
              ),
          ]);
        },
      ),
    );
  }
}

enum ImageSourceChoice {
  camera,
  gallery;

  ImageSource get source => this == ImageSourceChoice.camera ? ImageSource.camera : ImageSource.gallery;
}
