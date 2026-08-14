import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

class CustomButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isOutlined;
  final bool isCompact;
  final bool isDisabled;
  final Color? color;
  final IconData? icon;

  const CustomButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
    this.isCompact = false,
    this.isDisabled = false,
    this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? AppColors.primary;
    final activeOnPressed = (isLoading || isDisabled) ? null : onPressed;

    if (isOutlined) {
      return OutlinedButton(
        onPressed: activeOnPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: effectiveColor,
          side: BorderSide(color: effectiveColor, width: 1.5),
          padding: isCompact ? const EdgeInsets.symmetric(horizontal: 16, vertical: 8) : null,
          minimumSize: isCompact ? const Size(0, 38) : null,
        ),
        child: _buildChild(effectiveColor),
      );
    }

    return ElevatedButton(
      onPressed: activeOnPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: effectiveColor,
        padding: isCompact ? const EdgeInsets.symmetric(horizontal: 16, vertical: 8) : null,
        minimumSize: isCompact ? const Size(0, 38) : null,
      ),
      child: _buildChild(AppColors.white),
    );
  }

  Widget _buildChild(Color textColor) {
    if (isLoading) {
      return SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          valueColor: AlwaysStoppedAnimation<Color>(textColor),
        ),
      );
    }

    final effectiveFontSize = isCompact ? 13.0 : 16.0;

    if (icon != null) {
      return Row(
        mainAxisSize: isCompact ? MainAxisSize.min : MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: isCompact ? 16 : 20, color: textColor),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: effectiveFontSize,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );
    }

    return Text(
      label,
      style: GoogleFonts.inter(
        fontSize: effectiveFontSize,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}
