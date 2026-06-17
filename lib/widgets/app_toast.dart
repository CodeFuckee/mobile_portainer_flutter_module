import 'dart:async';
import 'package:flutter/material.dart';
import 'package:remix_icons_flutter/remixicon_ids.dart';

enum ToastType { success, error, warning, info }

class _ToastSlot {
  OverlayEntry? entry;
}

class AppToast {
  static final Map<ToastType, OverlayEntry> _byType = {};
  static final List<_ToastSlot> _slots =
      List.generate(3, (_) => _ToastSlot());

  static void show(BuildContext context, String message, ToastType type) {
    // Remove any existing toast of the same type, but guard against
    // entries whose _overlay has been detached (e.g. displaced by slot
    // reclamation).  The `.mounted` check alone isn't always enough in
    // test/synthetic environments.
    final existing = _byType[type];
    if (existing != null && existing.mounted) {
      try {
        existing.remove();
      } catch (_) {
        // entry was already detached — just clear the stale references.
      }
      for (final slot in _slots) {
        if (slot.entry == existing) slot.entry = null;
      }
    }
    _byType.remove(type);

    _ToastSlot? slot;
    for (final s in _slots) {
      if (s.entry == null || !s.entry!.mounted) {
        // Only call remove() if the entry is actually mounted;
        // otherwise clear the stale reference.
        if (s.entry?.mounted == true) {
          s.entry!.remove();
        }
        s.entry = null;
        slot = s;
        break;
      }
    }
    slot ??= _slots.first;
    // Defensive: only remove if still mounted, then clear the slot.
    if (slot.entry?.mounted == true) {
      slot.entry!.remove();
    }
    slot.entry = null;
    final targetSlot = slot;

    final overlay = Overlay.of(context);
    final topPadding = MediaQuery.of(context).padding.top;
    final slotIndex = _slots.indexOf(targetSlot);

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) => Positioned(
        top: topPadding + 8 + slotIndex * 64.0,
        left: 0,
        right: 0,
        child: Center(
          child: _ToastWidget(
            message: message,
            type: type,
            onDismiss: () {
              entry.remove();
              if (_byType[type] == entry) _byType.remove(type);
              if (targetSlot.entry == entry) targetSlot.entry = null;
            },
          ),
        ),
      ),
    );

    overlay.insert(entry);
    _byType[type] = entry;
    targetSlot.entry = entry;
  }

  static void success(BuildContext context, String message) =>
      show(context, message, ToastType.success);
  static void error(BuildContext context, String message) =>
      show(context, message, ToastType.error);
  static void warning(BuildContext context, String message) =>
      show(context, message, ToastType.warning);
  static void info(BuildContext context, String message) =>
      show(context, message, ToastType.info);
}

class _ToastStyle {
  final IconData icon;
  final Color borderLight;
  final Color borderDark;
  final Color bgLight;
  final Color bgDark;

  const _ToastStyle({
    required this.icon,
    required this.borderLight,
    required this.borderDark,
    required this.bgLight,
    required this.bgDark,
  });

  Color borderColor(Brightness b) =>
      b == Brightness.light ? borderLight : borderDark;

  Color backgroundColor(Brightness b) =>
      b == Brightness.light ? bgLight : bgDark;

  static const _styles = {
    ToastType.success: _ToastStyle(
      icon: RemixIcon.checkboxCircleFill,
      borderLight: Color(0xFF2E7D32),
      borderDark: Color(0xFF66BB6A),
      bgLight: Color(0xFFE8F5E9),
      bgDark: Color(0xFF1B5E20),
    ),
    ToastType.error: _ToastStyle(
      icon: RemixIcon.errorWarningFill,
      borderLight: Color(0xFFC62828),
      borderDark: Color(0xFFFF8A80),
      bgLight: Color(0xFFFFEBEE),
      bgDark: Color(0x50B71C1C),
    ),
    ToastType.warning: _ToastStyle(
      icon: RemixIcon.alertFill,
      borderLight: Color(0xFFEF6C00),
      borderDark: Color(0xFFFFB74D),
      bgLight: Color(0xFFFFF3E0),
      bgDark: Color(0x50E65100),
    ),
    ToastType.info: _ToastStyle(
      icon: RemixIcon.informationFill,
      borderLight: Color(0xFF0A84FF),
      borderDark: Color(0xFF4DA3FF),
      bgLight: Color(0xFFE3F2FD),
      bgDark: Color(0x500D47A1),
    ),
  };

  static _ToastStyle of(ToastType type) => _styles[type]!;
}

class _ToastWidget extends StatefulWidget {
  final String message;
  final ToastType type;
  final VoidCallback onDismiss;

  const _ToastWidget({
    required this.message,
    required this.type,
    required this.onDismiss,
  });

  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  Timer? _dismissTimer;
  bool _dismissing = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    ));
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _controller.forward();
    _dismissTimer = Timer(const Duration(milliseconds: 2500), _dismiss);
  }

  void _dismiss() async {
    if (_dismissing) return;
    _dismissing = true;
    _dismissTimer?.cancel();
    await _controller.reverse();
    widget.onDismiss();
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  IconData _icon() => _ToastStyle.of(widget.type).icon;

  Color _borderColor(ColorScheme cs) =>
      _ToastStyle.of(widget.type).borderColor(cs.brightness);

  Color _backgroundColor(ColorScheme cs) =>
      _ToastStyle.of(widget.type).backgroundColor(cs.brightness);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: GestureDetector(
          onVerticalDragEnd: (details) {
            if (details.primaryVelocity != null &&
                details.primaryVelocity! < -100) {
              _dismiss();
            }
          },
          child: Material(
            color: Colors.transparent,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width - 32,
              ),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: _backgroundColor(cs),
                  borderRadius: BorderRadius.circular(12),
                  border: Border(
                    left: BorderSide(color: _borderColor(cs), width: 4),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: cs.shadow.withAlpha(
                          cs.brightness == Brightness.light ? 30 : 50),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_icon(), color: _borderColor(cs), size: 22),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Text(
                        widget.message,
                        style: TextStyle(
                          color: cs.onSurface,
                          fontSize: 14,
                          height: 1.3,
                        ),
                      ),
                    ),
                  GestureDetector(
                    onTap: _dismiss,
                    child: Icon(
                      RemixIcon.closeFill,
                      color: cs.onSurface.withAlpha(100),
                      size: 18,
                    ),
                  ),
                ],
              ),
            ),
            ),
          ),
        ),
      ),
    );
  }
}
