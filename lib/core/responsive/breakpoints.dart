enum ScreenSize { mobile, tablet, desktop }

/// One place that decides what "mobile", "tablet" and "desktop" mean.
class Breakpoints {
  Breakpoints._();

  static const double tablet = 600;
  static const double desktop = 1024;

  static ScreenSize of(double width) {
    if (width >= desktop) return ScreenSize.desktop;
    if (width >= tablet) return ScreenSize.tablet;
    return ScreenSize.mobile;
  }
}