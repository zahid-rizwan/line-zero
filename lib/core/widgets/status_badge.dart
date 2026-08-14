import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  final bool isLarge;

  const StatusBadge({
    super.key,
    required this.status,
    this.isLarge = false,
  });

  String get _displayLabel {
    switch (status.toLowerCase()) {
      case 'waiting':
        return 'Waiting';
      case 'in_service':
        return 'In service';
      case 'completed':
        return 'Completed';
      case 'skipped':
        return 'Skipped';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }

  IconData get _icon {
    switch (status.toLowerCase()) {
      case 'waiting':
        return Icons.hourglass_top_rounded;
      case 'in_service':
        return Icons.notifications_active_rounded;
      case 'completed':
        return Icons.check_circle_rounded;
      case 'skipped':
        return Icons.redo_rounded;
      case 'cancelled':
        return Icons.cancel_rounded;
      default:
        return Icons.info_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = AppColors.getStatusColor(status);
    final bgColor = AppColors.getStatusBgColor(status);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      padding: EdgeInsets.symmetric(
        horizontal: isLarge ? 14 : 10,
        vertical: isLarge ? 8 : 4,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: Row(
          key: ValueKey(status),
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _icon,
              size: isLarge ? 16 : 13,
              color: color,
            ),
            const SizedBox(width: 5),
            Text(
              _displayLabel,
              style: GoogleFonts.inter(
                fontSize: isLarge ? 12 : 11,
                fontWeight: FontWeight.w600,
                color: color,
                decoration: status == 'cancelled' ? TextDecoration.lineThrough : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
