import 'package:flutter/material.dart';

Future<String?> showPasswordPromptDialog(
  BuildContext context, {
  required String title,
  required String message,
  bool requireConfirmation = false,
}) {
  final formKey = GlobalKey<FormState>();
  final passwordController = TextEditingController();
  final confirmController = TextEditingController();
  bool obscure = true;
  bool confirmObscure = true;

  return showDialog<String>(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(title),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(message),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: passwordController,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      suffixIcon: IconButton(
                        icon: Icon(obscure ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setState(() {
                          obscure = !obscure;
                        }),
                      ),
                    ),
                    obscureText: obscure,
                    autofocus: true,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Password is required';
                      }
                      if (value.trim().length < 6) {
                        return 'Use at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  if (requireConfirmation) ...[
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: confirmController,
                      decoration: InputDecoration(
                        labelText: 'Confirm password',
                        suffixIcon: IconButton(
                          icon:
                              Icon(confirmObscure ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setState(() {
                            confirmObscure = !confirmObscure;
                          }),
                        ),
                      ),
                      obscureText: confirmObscure,
                      validator: (value) {
                        if (value != passwordController.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  if (formKey.currentState?.validate() ?? false) {
                    Navigator.of(context).pop(passwordController.text.trim());
                  }
                },
                child: const Text('Confirm'),
              ),
            ],
          );
        },
      );
    },
  );
}

