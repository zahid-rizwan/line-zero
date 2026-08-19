import 'package:flutter/material.dart';

/// Design System Color Tokens for Real-Time Q-Token System
abstract class AppColors {
  // Primary (Trust Blue)
  static const Color primary = Color(0xFF2C6FB0);
  static const Color trustBlue = Color(0xFF2C6FB0);
  static const Color primaryLight = Color(0xFFE6F1FB);
  static const Color primaryDark = Color(0xFF1E4E7C);

  // Secondary / Accent (Amber)
  static const Color secondary = Color(0xFFD89419);
  static const Color secondaryLight = Color(0xFFFEF3C7);
  static const Color amber = Color(0xFFD89419);
  static const Color amberLight = Color(0xFFFEF3C7);

  // Success (Green on Soft Green BG)
  static const Color success = Color(0xFF3B6D11);
  static const Color successLight = Color(0xFFEAF3DE);

  // Urgent / Alert (Coral Red)
  static const Color warningUrgent = Color(0xFFD85A30);
  static const Color coralRed = Color(0xFFD85A30);
  static const Color warningLight = Color(0xFFFEE2E2);

  // Skipped / Secondary Status
  static const Color skipped = Color(0xFF6B7280);
  static const Color skippedLight = Color(0xFFF3F4F6);

  // Neutrals
  static const Color neutralDark = Color(0xFF1F2937);  // Charcoal Text
  static const Color neutralMid = Color(0xFF6B7280);   // Slate Gray
  static const Color neutralLight = Color(0xFFF9FAFB); // Off-White Canvas
  static const Color border = Color(0xFFE5E7EB);       // Light Gray Border
  static const Color white = Colors.white;

  // Dark Mode Tokens
  static const Color darkBackground = Color(0xFF111827);
  static const Color slateDark = Color(0xFF111827);
  static const Color darkCard = Color(0xFF1F2937);
  static const Color darkText = Color(0xFFF3F4F6);
  static const Color darkBorder = Color(0xFF374151);

  // Status to Color Mapping (Consistent everywhere)
  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'waiting':
        return primary;
      case 'confirmed':
        return trustBlue;
      case 'called':
      case 'in_service':
        return amber;
      case 'held':
        return warningUrgent;
      case 'pending':
        return const Color(0xFFEA580C); // Burnt Orange
      case 'completed':
        return success;
      case 'skipped':
      case 'no_show':
        return skipped;
      case 'cancelled':
        return warningUrgent;
      default:
        return neutralMid;
    }
  }

  static Color getStatusBgColor(String status) {
    switch (status.toLowerCase()) {
      case 'waiting':
        return primaryLight;
      case 'confirmed':
        return const Color(0xFFEFF6FF);
      case 'called':
      case 'in_service':
        return amberLight;
      case 'held':
      case 'pending':
        return const Color(0xFFFFEDD5);
      case 'completed':
        return successLight;
      case 'skipped':
      case 'no_show':
        return skippedLight;
      case 'cancelled':
        return warningLight;
      default:
        return neutralLight;
    }
  }
}
