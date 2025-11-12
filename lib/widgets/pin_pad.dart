import 'package:flutter/material.dart';

class PinPad extends StatelessWidget {
  const PinPad({
    super.key,
    required this.onDigit,
    required this.onBackspace,
    this.onClear,
    this.isDisabled = false,
  });

  final void Function(String digit) onDigit;
  final VoidCallback onBackspace;
  final VoidCallback? onClear;
  final bool isDisabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget buildButton({
      Widget? child,
      String? digit,
      VoidCallback? onPressed,
    }) {
      final effectiveOnPressed = isDisabled ? null : onPressed;
      return Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(32),
          onTap: effectiveOnPressed,
          child: Container(
            height: 72,
            alignment: Alignment.center,
            child: child ??
                Text(
                  digit!,
                  style: theme.textTheme.headlineMedium,
                ),
          ),
        ),
      );
    }

    Widget buildDigit(String value) => buildButton(
          digit: value,
          onPressed: () => onDigit(value),
        );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildRow(
          buildDigit('1'),
          buildDigit('2'),
          buildDigit('3'),
        ),
        _buildRow(
          buildDigit('4'),
          buildDigit('5'),
          buildDigit('6'),
        ),
        _buildRow(
          buildDigit('7'),
          buildDigit('8'),
          buildDigit('9'),
        ),
        _buildRow(
          onClear != null
              ? buildButton(
                  child: Text(
                    'Clear',
                    style: theme.textTheme.titleMedium,
                  ),
                  onPressed: onClear,
                )
              : const SizedBox(
                  height: 72,
                  width: 72,
                ),
          buildDigit('0'),
          buildButton(
            child: const Icon(Icons.backspace_outlined),
            onPressed: onBackspace,
          ),
        ),
      ],
    );
  }

  Widget _buildRow(Widget first, Widget second, Widget third) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        SizedBox(width: 96, child: Center(child: first)),
        SizedBox(width: 96, child: Center(child: second)),
        SizedBox(width: 96, child: Center(child: third)),
      ],
    );
  }
}

