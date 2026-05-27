import 'package:flutter/material.dart';

class ResizeHandle extends StatelessWidget {
  final double totalWidth;
  final ValueChanged<double> onResized;

  const ResizeHandle({
    super.key,
    required this.totalWidth,
    required this.onResized,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onHorizontalDragUpdate: (details) {
        onResized(details.delta.dx / totalWidth);
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.resizeColumn,
        child: SizedBox(
          width: 8,
          child: Center(
            child: Container(
              width: 3,
              height: 40,
              decoration: BoxDecoration(
                color: colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
