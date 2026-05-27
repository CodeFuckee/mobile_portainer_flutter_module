import 'package:flutter/material.dart';
import '../theme/theme_extensions.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  final double fontSize;

  const StatusBadge({super.key, required this.status, this.fontSize = 12});

  Color _getColor(BuildContext context) {
    final dockerColors = Theme.of(context).extension<DockerColors>();
    switch (status.toLowerCase()) {
      case 'running':
        return dockerColors?.statusRunning ?? Colors.green;
      case 'exited':
        return dockerColors?.statusExited ?? Colors.red;
      case 'created':
        return dockerColors?.statusCreated ?? Colors.blue;
      case 'restarting':
        return dockerColors?.statusRestarting ?? Colors.orange;
      case 'paused':
        return dockerColors?.statusPaused ?? Colors.amber;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getColor(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: color.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(12),
        color: color.withValues(alpha: 0.1),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
