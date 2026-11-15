import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData prefixIcon;

  final bool obscureText;
  final VoidCallback? onTogglePassword;

  final TextInputType? keyboardType;

  const CustomTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    required this.prefixIcon,
    this.obscureText = false,
    this.onTogglePassword,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,

      obscureText: obscureText,

      keyboardType: keyboardType,

      style: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 16,
      ),

      decoration: InputDecoration(
        labelText: label,
        hintText: hint,

        prefixIcon: Icon(
          prefixIcon,
          color: AppColors.primary,
        ),

        suffixIcon: onTogglePassword != null
            ? IconButton(
                onPressed: onTogglePassword,
                icon: Icon(
                  obscureText
                      ? Icons.visibility
                      : Icons.visibility_off,
                ),
              )
            : null,
      ),
    );
  }
}