import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Color? color;
  final IconData? icon;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final style = ElevatedButton.styleFrom(
      backgroundColor: color ?? Colors.deepPurpleAccent,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
    );

    if (icon != null) {
      return ElevatedButton.icon(
        onPressed: isLoading ? null : onPressed,
        style: style,
        icon: isLoading
            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
            : Icon(icon),
        label: Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
      );
    }

    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: style,
      child: isLoading
          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
          : Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }
}
