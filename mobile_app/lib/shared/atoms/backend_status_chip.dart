import 'package:flutter/material.dart';
import '../../core/services/backend_status_service.dart';
import '../../core/theme/app_colors.dart';

/// A compact status chip that reflects the live [BackendStatus] of the Render
/// AI backend.  Intended to be placed near AI-powered features (e.g. the
/// camera scan card) so users understand why the AI might be warming up.
///
/// Layout (small, inline):
///   • 🟢 AI Online          — backend is warm and responding
///   • 🟡 AI Warming Up…     — backend is offline / checking (cold-starting)
///   • 🔴 AI Degraded        — reachable but returned unexpected status
///   • ⚪ Checking AI…       — ping in-flight
///
/// The chip is intentionally subtle (small font, muted border) so it doesn't
/// dominate the camera UI.  Tap to re-trigger a manual ping.
class BackendStatusChip extends StatelessWidget {
  final BackendStatus status;

  /// Optional callback fired when the user taps the chip (e.g. to re-ping).
  final VoidCallback? onTap;

  const BackendStatusChip({
    super.key,
    required this.status,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final config = _configFor(status);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: config.bgColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: config.borderColor, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animated pulsing dot or static dot
            if (status == BackendStatus.checking ||
                status == BackendStatus.offline)
              _PulsingDot(color: config.dotColor)
            else
              _StaticDot(color: config.dotColor),
            const SizedBox(width: 6),
            Text(
              config.label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: config.textColor,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  _ChipConfig _configFor(BackendStatus status) {
    switch (status) {
      case BackendStatus.online:
        return _ChipConfig(
          label: 'AI Online',
          dotColor: const Color(0xFF2E7D32),
          bgColor: const Color(0xFFE8F5E9),
          borderColor: const Color(0xFFA5D6A7),
          textColor: const Color(0xFF1B5E20),
        );
      case BackendStatus.degraded:
        return _ChipConfig(
          label: 'AI Degraded',
          dotColor: const Color(0xFFE65100),
          bgColor: const Color(0xFFFFF3E0),
          borderColor: const Color(0xFFFFCC80),
          textColor: const Color(0xFFBF360C),
        );
      case BackendStatus.offline:
        return _ChipConfig(
          label: 'AI Warming Up…',
          dotColor: const Color(0xFFF57F17),
          bgColor: const Color(0xFFFFFDE7),
          borderColor: const Color(0xFFFFF176),
          textColor: const Color(0xFFF57F17),
        );
      case BackendStatus.checking:
        return _ChipConfig(
          label: 'Checking AI…',
          dotColor: AppColors.textSecondary,
          bgColor: AppColors.surfaceMuted,
          borderColor: AppColors.border,
          textColor: AppColors.textSecondary,
        );
      case BackendStatus.unknown:
        return _ChipConfig(
          label: 'AI Status Unknown',
          dotColor: AppColors.textSecondary,
          bgColor: AppColors.surfaceMuted,
          borderColor: AppColors.border,
          textColor: AppColors.textSecondary,
        );
    }
  }
}

class _ChipConfig {
  final String label;
  final Color dotColor;
  final Color bgColor;
  final Color borderColor;
  final Color textColor;

  const _ChipConfig({
    required this.label,
    required this.dotColor,
    required this.bgColor,
    required this.borderColor,
    required this.textColor,
  });
}

class _StaticDot extends StatelessWidget {
  final Color color;
  const _StaticDot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 7,
      height: 7,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _PulsingDot extends StatefulWidget {
  final Color color;
  const _PulsingDot({required this.color});

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.3, end: 1.0).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _anim,
      child: Container(
        width: 7,
        height: 7,
        decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
      ),
    );
  }
}
