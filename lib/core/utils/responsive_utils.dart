import 'package:flutter/material.dart';

/// Screen size breakpoints for responsive design
class ResponsiveBreakpoints {
  // Width breakpoints
  static const double mobileSmall = 360;
  static const double mobile = 600;
  static const double tablet = 900;
  static const double desktop = 1200;

  // Height breakpoints
  static const double shortScreen = 700;
  static const double mediumScreen = 900;
}

/// Device type based on screen width
enum DeviceType {
  mobileSmall,
  mobile,
  tablet,
  desktop,
}

/// Extension on BuildContext for responsive utilities
extension ResponsiveSize on BuildContext {
  /// Get screen width
  double get width => MediaQuery.of(this).size.width;

  /// Get screen height
  double get height => MediaQuery.of(this).size.height;

  /// Get device type based on width
  DeviceType get deviceType {
    if (width < ResponsiveBreakpoints.mobileSmall) {
      return DeviceType.mobileSmall;
    } else if (width < ResponsiveBreakpoints.mobile) {
      return DeviceType.mobile;
    } else if (width < ResponsiveBreakpoints.tablet) {
      return DeviceType.tablet;
    } else {
      return DeviceType.desktop;
    }
  }

  /// Check if device is mobile (small or standard)
  bool get isMobile => width < ResponsiveBreakpoints.mobile;

  /// Check if device is tablet
  bool get isTablet =>
      width >= ResponsiveBreakpoints.mobile &&
      width < ResponsiveBreakpoints.tablet;

  /// Check if device is desktop
  bool get isDesktop => width >= ResponsiveBreakpoints.tablet;

  /// Check if screen is short
  bool get isShortScreen => height < ResponsiveBreakpoints.shortScreen;

  /// Get responsive value based on device type
  T responsive<T>({
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    if (isDesktop && desktop != null) return desktop;
    if (isTablet && tablet != null) return tablet;
    return mobile;
  }

  /// Get responsive width percentage
  double widthPercent(double percent) => width * (percent / 100);

  /// Get responsive height percentage
  double heightPercent(double percent) => height * (percent / 100);
}

/// Responsive padding utilities
class ResponsivePadding {
  final BuildContext context;

  ResponsivePadding(this.context);

  /// Get horizontal padding based on screen size
  double get horizontal {
    if (context.width < ResponsiveBreakpoints.mobileSmall) {
      return 16.0;
    } else if (context.width < ResponsiveBreakpoints.mobile) {
      return 20.0;
    } else if (context.width < ResponsiveBreakpoints.tablet) {
      return 24.0;
    } else {
      return 32.0;
    }
  }

  /// Get vertical padding based on screen size
  double get vertical {
    if (context.height < ResponsiveBreakpoints.shortScreen) {
      return 12.0;
    } else if (context.height < ResponsiveBreakpoints.mediumScreen) {
      return 16.0;
    } else {
      return 20.0;
    }
  }

  /// Get small padding
  double get small => horizontal * 0.5;

  /// Get medium padding
  double get medium => horizontal;

  /// Get large padding
  double get large => horizontal * 1.5;

  /// Get extra large padding
  double get extraLarge => horizontal * 2;

  /// Get card padding
  EdgeInsets get card => EdgeInsets.all(medium);

  /// Get screen padding
  EdgeInsets get screen => EdgeInsets.symmetric(horizontal: horizontal);

  /// Get section padding
  EdgeInsets get section => EdgeInsets.symmetric(
        horizontal: horizontal,
        vertical: vertical,
      );
}

/// Responsive spacing utilities
class ResponsiveSpacing {
  final BuildContext context;

  ResponsiveSpacing(this.context);

  /// Get small spacing
  double get small {
    return context.isMobile ? 8.0 : 12.0;
  }

  /// Get medium spacing
  double get medium {
    return context.isMobile ? 16.0 : 20.0;
  }

  /// Get large spacing
  double get large {
    return context.isMobile ? 24.0 : 32.0;
  }

  /// Get extra large spacing
  double get extraLarge {
    return context.isMobile ? 32.0 : 48.0;
  }

  /// Get section spacing
  double get section {
    return context.isMobile ? 24.0 : 40.0;
  }
}

/// Responsive text scaling
class ResponsiveText {
  final BuildContext context;

  ResponsiveText(this.context);

  /// Scale factor based on screen width
  double get scaleFactor {
    final width = context.width;
    if (width < ResponsiveBreakpoints.mobileSmall) {
      return 0.9;
    } else if (width < ResponsiveBreakpoints.mobile) {
      return 1.0;
    } else if (width < ResponsiveBreakpoints.tablet) {
      return 1.1;
    } else {
      return 1.2;
    }
  }

  /// Get scaled font size
  double scale(double size) => size * scaleFactor;

  /// Heading 1 size
  double get h1 => scale(28);

  /// Heading 2 size
  double get h2 => scale(24);

  /// Heading 3 size
  double get h3 => scale(20);

  /// Body large size
  double get bodyLarge => scale(16);

  /// Body medium size
  double get bodyMedium => scale(14);

  /// Body small size
  double get bodySmall => scale(12);

  /// Caption size
  double get caption => scale(10);
}

/// Responsive size utilities
class ResponsiveSizes {
  final BuildContext context;

  ResponsiveSizes(this.context);

  /// Get responsive icon size
  double get iconSize {
    return context.isMobile ? 24.0 : 28.0;
  }

  /// Get responsive large icon size
  double get iconLarge {
    return context.isMobile ? 32.0 : 40.0;
  }

  /// Get responsive extra large icon size
  double get iconExtraLarge {
    return context.isMobile ? 48.0 : 64.0;
  }

  /// Get responsive button height
  double get buttonHeight {
    return context.isMobile ? 48.0 : 56.0;
  }

  /// Get responsive app bar height
  double get appBarHeight {
    return context.isMobile ? 56.0 : 64.0;
  }

  /// Get responsive card image height
  double get cardImageHeight {
    if (context.width < ResponsiveBreakpoints.mobileSmall) {
      return 140.0;
    } else if (context.width < ResponsiveBreakpoints.mobile) {
      return 160.0;
    } else if (context.width < ResponsiveBreakpoints.tablet) {
      return 180.0;
    } else {
      return 200.0;
    }
  }

  /// Get responsive category card size
  double get categoryCardSize {
    if (context.width < ResponsiveBreakpoints.mobileSmall) {
      return 60.0;
    } else if (context.width < ResponsiveBreakpoints.mobile) {
      return 70.0;
    } else {
      return 80.0;
    }
  }

  /// Get responsive promo card width
  double get promoCardWidth {
    if (context.width < ResponsiveBreakpoints.mobileSmall) {
      return context.width * 0.8;
    } else if (context.width < ResponsiveBreakpoints.mobile) {
      return 280.0;
    } else if (context.width < ResponsiveBreakpoints.tablet) {
      return 320.0;
    } else {
      return 400.0;
    }
  }

  /// Get responsive collection card width
  double get collectionCardWidth {
    if (context.width < ResponsiveBreakpoints.mobileSmall) {
      return 130.0;
    } else if (context.width < ResponsiveBreakpoints.mobile) {
      return 150.0;
    } else {
      return 180.0;
    }
  }

  /// Get responsive bottom nav height
  double get bottomNavHeight {
    return context.isMobile ? 60.0 : 70.0;
  }
}

/// Helper extensions for easier access
extension ResponsiveExtensions on BuildContext {
  ResponsivePadding get padding => ResponsivePadding(this);
  ResponsiveSpacing get spacing => ResponsiveSpacing(this);
  ResponsiveText get text => ResponsiveText(this);
  ResponsiveSizes get sizes => ResponsiveSizes(this);
}
