import 'package:flutter/material.dart';
class Responsive {
  static const double mobileMaxWidth = 600;
  static const double tabletMaxWidth = 1024;

  static bool isMobile(BuildContext context) => MediaQuery.sizeOf(context).width < mobileMaxWidth;

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width >= mobileMaxWidth && width < tabletMaxWidth;
  }

  static bool isDesktop(BuildContext context) => MediaQuery.sizeOf(context).width >= tabletMaxWidth;

  static bool isWideScreen(BuildContext context) => MediaQuery.sizeOf(context).width >= mobileMaxWidth;

  static double screenWidth(BuildContext context) => MediaQuery.sizeOf(context).width;

  static int gridColumns(BuildContext context, {int mobile = 1, int tablet = 2, int desktop = 4}) {
    if (isDesktop(context)) return desktop;
    if (isTablet(context)) return tablet;
    return mobile;
  }
}
