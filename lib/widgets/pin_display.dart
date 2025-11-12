import 'package:flutter/material.dart';

class PinDisplay extends StatelessWidget {
  const PinDisplay({
    super.key,
    required this.length,
    required this.filled,
  });

  final int length;
  final int filled;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(length, (index) {
        final isFilled = index < filled;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 8),
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: isFilled ? scheme.primary : scheme.onSurface.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
        );
      }),
    );
  }
}

