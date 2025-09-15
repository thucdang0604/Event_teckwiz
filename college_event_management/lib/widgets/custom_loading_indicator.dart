import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class CustomLoadingIndicator extends StatelessWidget {
  final String? message;
  final double size;
  final Color? color;

  const CustomLoadingIndicator({
    super.key,
    this.message,
    this.size = 50.0,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            valueColor: AlwaysStoppedAnimation<Color>(
              color ?? AppColors.primary,
            ),
          ),
        ),
        if (message != null) ...[
          const SizedBox(height: 16),
          Text(
            message!,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}
