import 'package:flutter/material.dart';
import '../theme.dart';

/// Reusable widget for social icon circle button
class SocialCircle extends StatelessWidget {
  final IconData icon;
  final Color color;

  const SocialCircle({
    super.key,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.surface,
        shape: BoxShape.circle,
      ),
      child: IconButton(
        onPressed: () {},
        icon: Icon(icon, color: color),
      ),
    );
  }
}