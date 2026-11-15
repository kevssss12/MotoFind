import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class LogoHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const LogoHeader({
    super.key,
    this.title = "MotoFind",
    this.subtitle = "Motorcycle Parts, Made Easy",
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Logo
        Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.25),
                blurRadius: 15,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(
            Icons.two_wheeler,
            color: Colors.white,
            size: 48,
          ),
        ),

        const SizedBox(height: 18),

        // App name
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),

        const SizedBox(height: 6),

        // Subtitle
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 15,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}