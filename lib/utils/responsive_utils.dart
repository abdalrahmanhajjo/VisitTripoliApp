import 'package:flutter/material.dart';

/// Responsive sizing for detail pages and cards.
/// Prevents extreme sizes on small phones.
class ResponsiveUtils {
  ResponsiveUtils._();

  static double width(BuildContext context) => MediaQuery.sizeOf(context).width;

  /// Very narrow phone (e.g. < 300px width) – cards must be smaller to preserve layout.
  static bool isVerySmallPhone(BuildContext context) => width(context) < 300;

  /// Narrow phone (e.g. 300–340px width).
  static bool isSmallPhone(BuildContext context) => width(context) < 340;

  /// Compact phone (e.g. 340–360px width).
  static bool isCompact(BuildContext context) => width(context) < 360;

  /// Horizontal padding for detail/content pages. Tighter on small phones.
  static double contentPadding(BuildContext context) {
    final w = width(context);
    if (w < 280) return 10;
    if (w < 320) return 12;
    if (w < 340) return 14;
    if (w < 360) return 16;
    if (w < 400) return 18;
    return 20;
  }

  /// Screen horizontal padding for list/content pages. Comfortable on all widths.
  static EdgeInsets screenPadding(BuildContext context) {
    final h = contentPadding(context);
    final v = isVerySmallPhone(context) ? 12.0 : (isSmallPhone(context) ? 14.0 : 16.0);
    return EdgeInsets.symmetric(horizontal: h, vertical: v);
  }

  /// Horizontal-only padding for symmetric page margins.
  static EdgeInsets screenHorizontalOnly(BuildContext context) {
    return EdgeInsets.symmetric(horizontal: contentPadding(context));
  }

  /// Card width for "Similar/Related" horizontal list cards.
  static double similarCardWidth(BuildContext context, {double base = 192}) {
    final w = width(context);
    if (w < 280) return w * 0.42;
    if (w < 320) return w * 0.44;
    if (w < 340) return w * 0.46;
    if (w < 380) return w * 0.48;
    return base;
  }

  /// Height for similar/related card image area.
  static double similarCardImageHeight(BuildContext context, {double base = 118}) {
    final w = width(context);
    if (w < 280) return 72;
    if (w < 320) return 80;
    if (w < 340) return 88;
    if (w < 380) return 98;
    return base;
  }

  /// Height for the horizontal list containing similar cards.
  static double similarListHeight(BuildContext context, {double base = 178}) {
    final w = width(context);
    if (w < 280) return 112;
    if (w < 320) return 120;
    if (w < 340) return 132;
    if (w < 380) return 148;
    return base;
  }

  /// Hero image height on detail pages.
  static double heroHeight(BuildContext context, {double base = 300}) {
    final w = width(context);
    if (w < 320) return 200;
    if (w < 340) return 220;
    if (w < 380) return 260;
    return base;
  }

  /// Tall sliver hero for place/tour/event details — matches [PlaceDetailsScreen].
  static double detailSliverHeroHeight(BuildContext context) {
    final h = MediaQuery.sizeOf(context).height;
    final w = MediaQuery.sizeOf(context).width;
    return (h * 0.55).clamp(280.0, w > 400 ? 520.0 : 420.0);
  }

  /// Map container height.
  static double mapHeight(BuildContext context, {double base = 220}) {
    final w = width(context);
    if (w < 320) return 160;
    if (w < 340) return 180;
    if (w < 380) return 200;
    return base;
  }

  /// Section title font size. Slightly smaller on small phones.
  static double sectionTitleFontSize(BuildContext context) {
    if (isSmallPhone(context)) return 16;
    if (isCompact(context)) return 17;
    return 19;
  }

  /// Max width for detail body content (tablet). Use double.infinity on phones.
  static double contentMaxWidth(BuildContext context) {
    final w = width(context);
    if (w > 600) return 560;
    if (w > 500) return 480;
    return double.infinity;
  }

  /// Vertical gap between sections on detail pages.
  static double sectionGap(BuildContext context) {
    if (isVerySmallPhone(context)) return 14;
    if (isSmallPhone(context)) return 16;
    if (isCompact(context)) return 20;
    return 24;
  }

  /// Top/bottom padding for detail tab content.
  static double detailVerticalPadding(BuildContext context) {
    if (isVerySmallPhone(context)) return 14;
    if (isSmallPhone(context)) return 16;
    if (isCompact(context)) return 18;
    return 20;
  }

  /// Padding for modal bottom sheets. Tighter on small devices.
  static EdgeInsets modalPadding(BuildContext context) {
    final h = contentPadding(context);
    final v = isVerySmallPhone(context) ? 16.0 : (isSmallPhone(context) ? 20.0 : 24.0);
    return EdgeInsets.symmetric(horizontal: h, vertical: v);
  }

  /// Vertical padding for action buttons (Save, Directions, etc.). Comfortable tap targets on small devices.
  static double actionButtonPadding(BuildContext context) {
    if (isVerySmallPhone(context)) return 10;
    if (isSmallPhone(context)) return 12;
    if (isCompact(context)) return 14;
    return 16;
  }

  /// Font size for action button labels on detail pages. Slightly smaller on small devices.
  static double actionButtonFontSize(BuildContext context) {
    if (isVerySmallPhone(context)) return 12;
    if (isSmallPhone(context)) return 13;
    if (isCompact(context)) return 14;
    return 15;
  }

  /// Horizontal or vertical gap between button groups on detail pages.
  static double actionButtonGap(BuildContext context) {
    if (isVerySmallPhone(context)) return 6;
    if (isSmallPhone(context)) return 8;
    if (isCompact(context)) return 10;
    return 12;
  }

  /// Padding for content cards (e.g. transport cards) on detail pages.
  static double cardPadding(BuildContext context) {
    if (isVerySmallPhone(context)) return 10;
    if (isSmallPhone(context)) return 12;
    if (isCompact(context)) return 14;
    return 16;
  }

  /// Padding for icon boxes inside cards. Slightly smaller on small devices.
  static double iconBoxPadding(BuildContext context) {
    if (isVerySmallPhone(context)) return 8;
    if (isSmallPhone(context)) return 10;
    if (isCompact(context)) return 12;
    return 14;
  }

  /// Event "boarding pass" row height in the Explore calendar sheet — tall enough for title, time, location, chips.
  static double eventCalendarTicketHeight(BuildContext context) {
    final w = width(context);
    if (w < 300) return 158;
    if (w < 340) return 150;
    if (w < 380) return 142;
    if (w < 420) return 136;
    return 130;
  }

  /// Left image/date stub width on event tickets (scales slightly with screen).
  static double eventTicketStubWidth(BuildContext context) {
    final w = width(context);
    if (w < 300) return 86;
    if (w < 340) return 80;
    if (w < 400) return 76;
    return 74;
  }
}
