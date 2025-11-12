import 'package:flutter/material.dart';

class PinKeypad extends StatelessWidget {
  const PinKeypad({
    super.key,
    required this.onDigit,
    required this.onBackspace,
    required this.onSubmit,
    required this.submitIcon,
  });

  final void Function(String) onDigit;
  final VoidCallback onBackspace;
  final VoidCallback onSubmit;
  final IconData submitIcon;

  @override
  Widget build(BuildContext context) {
    final buttons = [
      '1',
      '2',
      '3',
      '4',
      '5',
      '6',
      '7',
      '8',
      '9',
      'back',
      '0',
      'ok',
    ];
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.0,
        ),
        itemCount: buttons.length,
        itemBuilder: (context, index) {
          final label = buttons[index];
          if (label == 'back') {
            return _KeyButton(
              onPressed: onBackspace,
              child: const Icon(Icons.backspace_outlined),
            );
          }
          if (label == 'ok') {
            return _KeyButton(
              onPressed: onSubmit,
              child: Icon(submitIcon),
            );
          }
          return _KeyButton(
            onPressed: () => onDigit(label),
            child: Text(
              label,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          );
        },
      ),
    );
  }
}

class _KeyButton extends StatelessWidget {
  const _KeyButton({required this.onPressed, required this.child});
  final VoidCallback onPressed;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      child: child,
    );
  }
}


