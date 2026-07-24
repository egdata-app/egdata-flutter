import 'package:flutter/material.dart';

class DesktopTheme {
  DesktopTheme._();

  static const background = Color(0xFF081019);
  static const sidebar = Color(0xFF07111B);
  static const surface = Color(0xFF0D1721);
  static const surfaceRaised = Color(0xFF111D28);
  static const surfaceHover = Color(0xFF162431);
  static const border = Color(0xFF263744);
  static const borderStrong = Color(0xFF355063);
  static const primary = Color(0xFF19C8F2);
  static const primaryStrong = Color(0xFF08AEDD);
  static const success = Color(0xFF12C98A);
  static const warning = Color(0xFFF2B84B);
  static const danger = Color(0xFFFF6B75);
  static const textPrimary = Color(0xFFF6F8FA);
  static const textSecondary = Color(0xFFB0BBC5);
  static const textMuted = Color(0xFF758491);

  static const radiusSmall = 8.0;
  static const radiusMedium = 12.0;
  static const radiusLarge = 16.0;

  static BoxDecoration panel({Color? color, bool emphasized = false}) {
    return BoxDecoration(
      color: color ?? surface,
      borderRadius: BorderRadius.circular(radiusMedium),
      border: Border.all(color: emphasized ? borderStrong : border),
    );
  }
}
