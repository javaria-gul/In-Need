import 'package:flutter/material.dart';

// ============================================================
// STRICT IMAGE PALETTE COLORS
// ============================================================

const kPrimaryLime =
    Color.fromARGB(255, 201, 227, 117); // Lime from Progress/Meeting cards
const kBgSage = Color(0xFFFFFFFF); // Main Background color - White
const kBg = kBgSage; // Alias for background
const kBlack = Color(0xFF0D0D0D); // Deep Charcoal from buttons/efficiency card
const kWhite = Color(0xFFFFFFFF); // Card background
const kGrey = Color(0xFF8E8E8E); // Muted text/lines

// Additional UI Colors
const kDivider = Color(0xFFE0E0E0); // Divider and border color
const kRed = Color(0xFFFF3B30); // Error states

// Blue Color Family (Now using Lime)
const kBlue = Color(0xFFFEFD99); // Primary lime (was blue)
const kBlueShade =
    Color.fromARGB(255, 180, 207, 100); // Darker lime shade (was blue)
const kBrightBlue =
    Color.fromARGB(255, 201, 227, 117); // Bright lime accent (was blue)
const kDarkBlue1 = Color(0xFFFEFD99); // Dark lime 1 (was blue)
const kDarkBlue2 = Color(0xFFFEFD99); // Dark lime 2 (was blue)
const kDarkBlue3 = Color(0xFFFEFD99); // Dark lime 3 (was blue)

// Vibrant Color Palette
const kPurple = Color(0xFF5856D6); // Purple
const kPurpleLight = Color(0xFF9B87F5); // Light purple
const kPink = Color(0xFFAF52DE); // Pink
const kGreen = Color(0xFF34C759); // Green
const kTealGreen = Color(0xFF52D9AD); // Teal green
const kOrange = Color(0xFFFF9500); // Orange

// Specific Colors for Multi-color Job Cards (Extracted from Image)
const List<Color> kCardColors = [
  Color(0xFFFEFD99), // Electric Lime
  Color(0xFFFFFFFF), // Pure White
  Color(0xFF0D0D0D), // Efficiency Card Dark
];

// Job Card Colors Palette
const List<Color> kJobCardColors = [
  kBrightBlue, // Blue
  kPurple, // Purple
  kPink, // Pink
  kOrange, // Orange
  kGreen, // Green
];

// Gradients (Strictly Image Based)
const kLimeGrad = LinearGradient(
  colors: [Color(0xFFFEFD99), Color(0xFFFEFD99)], // Solid look as per UI
);

const kBlueGrad = LinearGradient(
  colors: [kBlue, kBlueShade],
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
);

const kGreenGrad = LinearGradient(
  colors: [kGreen, kTealGreen],
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
);

const kOrangeGrad = LinearGradient(
  colors: [kOrange, Color(0xFFFFA500)],
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
);

const kPurpleGrad = LinearGradient(
  colors: [kPurple, kPurpleLight],
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
);

const kHeroGrad = LinearGradient(
  colors: [kDarkBlue1, kDarkBlue3],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

const kSplashGrad = LinearGradient(
  colors: [kDarkBlue1, kDarkBlue2, kDarkBlue3],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

const kCurveGrad = LinearGradient(
  colors: [
    Color.fromARGB(255, 201, 227, 117),
    Color.fromARGB(255, 180, 207, 100)
  ],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

const kCurveGradPurple = LinearGradient(
  colors: [Color(0xFFFEFD99), kPurpleLight],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

// Shadows (Very subtle as per modern UI)
const kShadow = [
  BoxShadow(
    color: Color(0x0A000000),
    blurRadius: 20,
    offset: Offset(0, 10),
  ),
];

const kBlueShadow = [
  BoxShadow(
    color: Color.fromARGB(26, 201, 227, 117),
    blurRadius: 20,
    offset: Offset(0, 10),
  ),
];

const kGreenShadow = [
  BoxShadow(
    color: Color(0x1A34C759),
    blurRadius: 20,
    offset: Offset(0, 10),
  ),
];

// ============================================================
// HELPER FUNCTIONS
// ============================================================

void showSnack(BuildContext context, String message,
    {bool err = false, bool ok = false}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        message,
        style: TextStyle(color: err || ok ? kWhite : kBlack),
      ),
      backgroundColor: err ? kRed : (ok ? kBlack : kPrimaryLime),
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}

Widget buildTag(String label, Color color) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.2),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      label,
      style: TextStyle(
        color: color == kWhite ? kBlack : color, // Contrast check
        fontSize: 10,
        fontWeight: FontWeight.w900,
      ),
    ),
  );
}

// ============================================================
// CUSTOM WIDGETS
// ============================================================

class ACard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;

  const ACard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.color = kWhite,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(32), // High roundness from image
        boxShadow: kShadow,
      ),
      child: DefaultTextStyle(
        style: TextStyle(color: color == kBlack ? kWhite : kBlack),
        child: child,
      ),
    );
  }
}

class GradBtn extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  final bool loading;
  final Gradient? gradient;
  final Color? bgColor;
  final Color foreColor;
  final List<BoxShadow>? shadows;

  const GradBtn({
    super.key,
    required this.text,
    required this.onTap,
    this.loading = false,
    this.gradient,
    this.bgColor,
    this.foreColor = kBlack,
    this.shadows,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          gradient: gradient,
          color: gradient == null ? (bgColor ?? kPrimaryLime) : null,
          borderRadius: BorderRadius.circular(100),
          boxShadow: shadows ?? kShadow,
        ),
        child: Center(
          child: loading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child:
                      CircularProgressIndicator(color: kWhite, strokeWidth: 2))
              : Text(
                  text,
                  style: TextStyle(
                    color: foreColor,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
        ),
      ),
    );
  }
}

// ============================================================
// THEME BUILDER
// ============================================================

ThemeData buildTheme() {
  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: kBgSage,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: kBlack,
        fontSize: 18,
        fontWeight: FontWeight.w900,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: kWhite,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide.none,
      ),
    ),
  );
}
