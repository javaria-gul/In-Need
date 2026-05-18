import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageCtrl = PageController();
  double _scrollOffset = 0.0;
  int _page = 0;

  // Animation controller for slide-in text transitions and rotation
  late AnimationController _bgAnimationCtrl;

  // Animation controller for Next button bounce animation
  late AnimationController _buttonBounceCtrl;
  late Animation<double> _buttonBounceAnim;

  // Colors preserved completely with the premium beige background for Screen 3
  static const Color _kYellowRestored = Color.fromRGBO(241, 239, 126, 1.0);
  static const Color _kCharcoal = Color(0xFF1A1A1A);
  static const Color _kWhite = Colors.white;
  static const Color _kPinkBg = Color.fromARGB(255, 209, 69, 181);
  static const Color _kBeigeBg = Color(0xFFFDFBF7);
  static const Color _kPanelSurface = Color(0xFF262118);
  static const Color _kPanelAccent = Color(0xFFF1EF7E);

  @override
  void initState() {
    super.initState();
    _pageCtrl.addListener(() {
      if (_pageCtrl.hasClients) {
        setState(() {
          _scrollOffset = _pageCtrl.page ?? 0.0;
        });
      }
    });

    _bgAnimationCtrl = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat();

    // Initialize bounce animation for Next button - VERY SLOW (5 seconds per cycle)
    _buttonBounceCtrl = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    )..repeat();

    _buttonBounceAnim = Tween<double>(begin: 0.0, end: 12.0).animate(
      CurvedAnimation(parent: _buttonBounceCtrl, curve: Curves.easeInOutSine),
    );

    // Pre-cache all images to avoid loading delays
    _preCacheImages();
  }

  Future<void> _preCacheImages() async {
    try {
      final imageUrls = [
        'assets/images/role1.png',
        'assets/images/role2.png',
        'assets/images/gig1.png',
        'assets/images/gig2.png',
        'assets/images/gig3.png',
        'assets/images/map.png',
      ];

      for (String url in imageUrls) {
        await precacheImage(AssetImage(url), context);
      }
    } catch (e) {
      debugPrint('Warning: Error pre-caching images: $e');
    }
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    _bgAnimationCtrl.dispose();
    _buttonBounceCtrl.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    try {
      // Mark tutorial as seen locally first (most important)
      await StorageService.markTutorialSeen();

      // Then try to sync with backend (non-blocking if fails)
      try {
        await ApiService().markTutorialSeen();
      } catch (e) {
        debugPrint('Warning: Failed to sync tutorial status with backend: $e');
        // Continue anyway - local storage is already set
      }

      // Navigate only if widget is still mounted
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/dashboard');
      }
    } catch (e) {
      debugPrint('Error in _finish: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error: $e'), duration: const Duration(seconds: 2)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: _kWhite,
      body: Stack(
        children: [
          // 1. DYNAMIC BACKGROUND SWITCH WITH MULTIPLE SHADES & PATTERNS
          Positioned.fill(
            child: AnimatedBuilder(
              animation: Listenable.merge([_pageCtrl, _bgAnimationCtrl]),
              builder: (context, child) {
                double fillPercent = _scrollOffset.clamp(0.0, 2.0);
                return CustomPaint(
                  painter: BackgroundPatternPainter(
                    scrollOffset: fillPercent,
                    animValue: _bgAnimationCtrl.value,
                    yellowColor: _kYellowRestored,
                    pinkColor: _kPinkBg,
                    beigeColor: _kBeigeBg,
                  ),
                );
              },
            ),
          ),

          // 2. FLUID DECORATIVE BADGES (Fade out as we move to screen 3)
          Opacity(
            opacity: (1.0 - (_scrollOffset - 1.0).clamp(0.0, 1.0)),
            child: Stack(
              children: _buildFloatingDecorations(size),
            ),
          ),

          // 3. CHARACTERS ORIENTATION PARALLAX CANVAS (Screens 1 & 2)
          if (_scrollOffset < 1.5)
            Positioned.fill(
              child: IgnorePointer(
                child: Stack(
                  children: [
                    // ROLE 1: Poster - UP TO AVOID SWITCH ELEMENT
                    Positioned(
                      right: size.width * 0.18 +
                          (_scrollOffset * size.width * 0.6),
                      bottom: size.height * 0.17,
                      child: Opacity(
                        opacity: (1.0 - _scrollOffset).clamp(0.0, 1.0),
                        child: Image.asset(
                          'assets/images/role1.png',
                          height: size.height * 0.60,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    // Role 2: Seeker - UP TO AVOID SWITCH ELEMENT
                    Positioned(
                      left: size.width * 0.00 +
                          ((1.0 - _scrollOffset) * size.width * 0.6),
                      bottom: size.height * 0.13,
                      child: Opacity(
                        opacity: (_scrollOffset < 1.0
                                ? _scrollOffset
                                : 2.0 - _scrollOffset)
                            .clamp(0.0, 1.0),
                        child: Image.asset(
                          'assets/images/role2.png',
                          height: size.height * 0.60,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // 4. SCREEN 3: MAP & ULTRA ANIMATED GIGS CANVAS (PUSHED UPWARDS)
          Positioned(
            bottom: size.height * 0.11,
            left: 0,
            right: 0,
            height: size.height * 0.65,
            child: IgnorePointer(
              child: Opacity(
                opacity: (_scrollOffset - 1.0).clamp(0.0, 1.0),
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    // Map Base Illustration
                    Positioned(
                      bottom: 0,
                      child: Image.asset(
                        'assets/images/map.png',
                        width: size.width * 1.2,
                        fit: BoxFit.contain,
                      ),
                    ),
                    // Animated floating components stack
                    Positioned(
                      bottom: size.height * 0.11,
                      left: 0,
                      right: 0,
                      height: size.height * 0.47,
                      child: const _AnimatedGigsStack(),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 5. INTERFACE STRATA AND SLIDE-IN CONTENT PANELS
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Global Action Utility Bar
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _page > 0
                          ? IconButton(
                              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                                  color: _kCharcoal),
                              onPressed: () {
                                _pageCtrl.previousPage(
                                  duration: const Duration(milliseconds: 500),
                                  curve: Curves.easeInOutCubic,
                                );
                              },
                            )
                          : const SizedBox(width: 48),
                      _page < 2
                          ? TextButton(
                              onPressed: _finish,
                              child: const Text(
                                'Skip',
                                style: TextStyle(
                                  color: _kCharcoal,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            )
                          : const SizedBox(width: 48),
                    ],
                  ),
                ),

                // Workspace Swapping Panels with horizontal slide-in layout
                Expanded(
                  child: PageView(
                    controller: _pageCtrl,
                    onPageChanged: (i) => setState(() => _page = i),
                    children: [
                      _buildWorkspacePanel(
                        title: "ROLE 1: JOB POSTER",
                        description:
                            "Post jobs, set location,time, and budget.",
                        features: [
                          "Verified Taskers",
                          "Instant Location Matching"
                        ],
                        textOnLeft: true,
                        size: size,
                        index: 0,
                      ),
                      _buildWorkspacePanel(
                        title: "ROLE 2: JOB SEEKER",
                        description:
                            "Create your profile, browse jobs, and earn money.",
                        features: [
                          "Flexible Working Hours",
                          "Direct Client Direct Chat"
                        ],
                        textOnLeft: false,
                        size: size,
                        index: 1,
                      ),
                      // Screen 3: Boxless Centered Border-Styled Header
                      _buildSplitAIWorkspacePanel(
                        heading: "Smart Proximity AI Matching",
                        description:
                            "Our AI instant-checks your live location to match you with verified service provider gigs within the radius in real-time.",
                        size: size,
                        index: 2,
                      ),
                    ],
                  ),
                ),

                // Extra spacing before switcher widget
                SizedBox(height: size.height * 0.18),

                // Rotate middle switcher widget only between screen 1 & 2
                if (_scrollOffset < 1.5) ...[
                  _buildInteractiveSwitchWidget(),
                  SizedBox(height: size.height * 0.02),
                ],

                // Page State Dots Indicator
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    3,
                    (i) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 5),
                      width: i == _page ? 26 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: i == _page
                            ? _kCharcoal
                            : _kCharcoal.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: size.height * 0.02),

                // 9. BEAUTIFUL ANIMATED NEXT BUTTON WITH SLOW BOUNCE
                Center(
                  child: AnimatedBuilder(
                    animation: _buttonBounceAnim,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, -_buttonBounceAnim.value),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: size.width > 600 ? 24 : 16,
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(50),
                              boxShadow: [
                                BoxShadow(
                                  color: _kCharcoal.withValues(alpha: 0.3),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                  spreadRadius: 2,
                                ),
                                BoxShadow(
                                  color: _kCharcoal.withValues(alpha: 0.1),
                                  blurRadius: 35,
                                  offset: const Offset(0, 15),
                                  spreadRadius: 4,
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: _page == 2
                                    ? _finish
                                    : () => _pageCtrl.nextPage(
                                          duration:
                                              const Duration(milliseconds: 500),
                                          curve: Curves.easeInOutCubic,
                                        ),
                                borderRadius: BorderRadius.circular(50),
                                splashColor: _kWhite.withValues(alpha: 0.2),
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: size.width > 600 ? 52 : 42,
                                    vertical: size.width > 600 ? 18 : 16,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(50),
                                    gradient: LinearGradient(
                                      colors: [
                                        _kCharcoal,
                                        _kCharcoal.withRed(50),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    border: Border.all(
                                      color: _kWhite.withValues(alpha: 0.3),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        _page == 2 ? 'GET STARTED' : 'NEXT',
                                        style: TextStyle(
                                          fontSize: size.width > 600 ? 15 : 13,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 1.2,
                                          color: _kWhite,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Transform.translate(
                                        offset: Offset(2, 0),
                                        child: Icon(
                                          Icons.arrow_forward_rounded,
                                          color: _kWhite,
                                          size: size.width > 600 ? 18 : 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkspacePanel({
    required String title,
    required String description,
    required List<String> features,
    required bool textOnLeft,
    required Size size,
    required int index,
  }) {
    final textAlignment =
        textOnLeft ? CrossAxisAlignment.start : CrossAxisAlignment.end;

    double pageOffset = (_scrollOffset - index);
    double slideTranslation = pageOffset * size.width * 0.8;
    double textFade = (1.0 - pageOffset.abs()).clamp(0.0, 1.0);

    return Opacity(
      opacity: textFade,
      child: Transform.translate(
        offset: Offset(slideTranslation, 0),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: size.width > 600 ? 24.0 : 16.0,
            vertical: 3.0,
          ),
          child: Column(
            crossAxisAlignment: textAlignment,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Container(
                width: size.width > 600 ? size.width * 0.70 : size.width * 0.85,
                padding: EdgeInsets.all(size.width > 600 ? 16 : 14),
                decoration: BoxDecoration(
                  color: _kPanelSurface.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: _kPanelAccent.withValues(alpha: 0.7), width: 1.6),
                  boxShadow: const [
                    BoxShadow(color: _kCharcoal, offset: Offset(3, 3)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: _kPanelAccent,
                        fontSize: size.width > 600 ? 19 : 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      description,
                      style: TextStyle(
                        color: _kWhite.withValues(alpha: 0.82),
                        fontSize: size.width > 600 ? 14 : 12,
                        fontWeight: FontWeight.w500,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Features in horizontal layout
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: textOnLeft ? WrapAlignment.start : WrapAlignment.end,
                children: features.map((feature) {
                  return Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: size.width > 600 ? 10 : 8,
                      vertical: size.width > 600 ? 6 : 5,
                    ),
                    decoration: BoxDecoration(
                      color: _kPanelAccent.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _kCharcoal, width: 1.2),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.verified_user_outlined,
                          size: size.width > 600 ? 14 : 12,
                          color: _kCharcoal,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          feature,
                          style: TextStyle(
                            color: _kCharcoal,
                            fontSize: size.width > 700 ? 11 : 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSplitAIWorkspacePanel({
    required String heading,
    required String description,
    required Size size,
    required int index,
  }) {
    double pageOffset = (_scrollOffset - index);
    double slideTranslation = pageOffset * size.width * 0.8;
    double textFade = (1.0 - pageOffset.abs()).clamp(0.0, 1.0);

    return Opacity(
      opacity: textFade,
      child: Transform.translate(
        offset: Offset(slideTranslation, 0),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: size.width > 600 ? 20.0 : 16.0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                child: SizedBox(
                  width: size.width,
                  child: Text(
                    heading,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _kCharcoal,
                      fontSize: size.width > 600 ? 22.0 : 20.0,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                      shadows: [
                        Shadow(
                            offset: const Offset(1, 1),
                            color: _kPanelAccent.withValues(alpha: 0.8)),
                        Shadow(
                            offset: const Offset(-1, -1),
                            color: _kPanelAccent.withValues(alpha: 0.8)),
                        Shadow(
                            offset: const Offset(2, 2),
                            color: _kCharcoal.withValues(alpha: 0.15)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: size.width * 0.90,
                padding: EdgeInsets.all(size.width > 600 ? 14 : 12),
                decoration: BoxDecoration(
                  color: _kPanelSurface.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: _kPanelAccent.withValues(alpha: 0.7), width: 1.6),
                  boxShadow: const [
                    BoxShadow(color: _kCharcoal, offset: Offset(3, 3)),
                  ],
                ),
                child: Text(
                  description,
                  textAlign: TextAlign.left,
                  style: TextStyle(
                    color: _kWhite.withValues(alpha: 0.84),
                    fontSize: size.width > 600 ? 13 : 11.5,
                    fontWeight: FontWeight.w700,
                    height: 1.45,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInteractiveSwitchWidget() {
    return Center(
      child: AnimatedBuilder(
        animation: _pageCtrl,
        builder: (context, child) {
          double angle = _scrollOffset * math.pi;
          return Transform.rotate(
            angle: angle,
            child: Container(
              width: 66,
              height: 66,
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 243, 164, 226)
                    .withValues(alpha: 0.95),
                shape: BoxShape.circle,
                border: Border.all(color: _kCharcoal, width: 2.2),
                boxShadow: const [
                  BoxShadow(color: _kCharcoal, offset: Offset(0, 3)),
                ],
              ),
              child: const Icon(
                Icons.sync_alt_rounded,
                color: _kCharcoal,
                size: 28,
              ),
            ),
          );
        },
      ),
    );
  }

  List<Widget> _buildFloatingDecorations(Size size) {
    return [
      Positioned(
        right: size.width * 0.10,
        bottom: size.height * 0.20,
        child: Opacity(
          opacity: (1.0 - _scrollOffset).clamp(0.0, 1.0),
          child: _buildVectorBadge("BEST RATES"),
        ),
      ),
      Positioned(
        right: size.width * 0.06,
        bottom: size.height * 0.67,
        child: Opacity(
          opacity: (_scrollOffset < 1.0 ? _scrollOffset : 2.0 - _scrollOffset)
              .clamp(0.0, 1.0),
          child: _buildVectorBadge("TOP TALENT"),
        ),
      ),
      Positioned(
        right: size.width * 0.04,
        top: size.height * 0.12,
        child: Opacity(
          opacity: (_scrollOffset < 1.0 ? _scrollOffset : 2.0 - _scrollOffset)
              .clamp(0.0, 1.0),
          child: _buildBigMultiColorComponent(),
        ),
      ),
    ];
  }

  Widget _buildVectorBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: _kPanelAccent.withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _kCharcoal, width: 2),
        boxShadow: const [
          BoxShadow(color: _kCharcoal, offset: Offset(2, 2)),
        ],
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: _kCharcoal,
          fontSize: 11,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildBigMultiColorComponent() {
    return Container(
      width: 75,
      height: 75,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [
            Color.fromARGB(255, 243, 239, 126),
            Color.fromARGB(255, 241, 218, 102),
            _kYellowRestored
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: _kCharcoal, width: 2),
        boxShadow: const [
          BoxShadow(color: _kCharcoal, offset: Offset(3, 3)),
        ],
      ),
      child: const Center(
        child: Icon(Icons.flash_on_rounded, color: _kCharcoal, size: 32),
      ),
    );
  }
}

class _AnimatedGigsStack extends StatefulWidget {
  const _AnimatedGigsStack();

  @override
  State<_AnimatedGigsStack> createState() => _AnimatedGigsStackState();
}

class _AnimatedGigsStackState extends State<_AnimatedGigsStack>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _floatingAnim;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    )..repeat(reverse: true);

    _floatingAnim = Tween<double>(begin: 0.0, end: 18.0).animate(
      CurvedAnimation(
          parent: _animationController, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return AnimatedBuilder(
      animation: _floatingAnim,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.topCenter,
          children: [
            // Gig 2 (Maximized Scale, bottom-left overlapping layer)
            Positioned(
              top: 90 + (_floatingAnim.value * 0.4),
              left: screenWidth * 0.01,
              child: Image.asset(
                'assets/images/gig2.png',
                width: screenWidth * 0.60,
                fit: BoxFit.contain,
              ),
            ),
            // Gig 3 (Maximized Scale, bottom-right overlapping layer)
            Positioned(
              top: 95 + (_floatingAnim.value * 0.3),
              right: screenWidth * 0.01,
              child: Image.asset(
                'assets/images/gig3.png',
                width: screenWidth * 0.60,
                fit: BoxFit.contain,
              ),
            ),
            // Gig 1 (Main Central Top Focus Item - HUGE)
            Positioned(
              top: 10 - _floatingAnim.value,
              child: Image.asset(
                'assets/images/gig1.png',
                width: screenWidth * 0.78,
                fit: BoxFit.contain,
              ),
            ),
          ],
        );
      },
    );
  }
}

class BackgroundPatternPainter extends CustomPainter {
  final double scrollOffset;
  final double animValue;
  final Color yellowColor;
  final Color pinkColor;
  final Color beigeColor;

  BackgroundPatternPainter({
    required this.scrollOffset,
    required this.animValue,
    required this.yellowColor,
    required this.pinkColor,
    required this.beigeColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // ALL SCREENS: White background base
    paint.color = Colors.white;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    // DIFFERENT DECORATIVE ELEMENTS PER SCREEN WITH PARALLAX ANIMATION

    // === SCREEN 1 (0.0 - 1.0): Yellow & charcoal with parallax ===
    if (scrollOffset < 1.0) {
      double screenProgress = scrollOffset.clamp(0.0, 1.0);
      double parallaxOffset = screenProgress * 35;

      // Top-left accent circle with parallax
      paint.color = const Color(0xFFF1EF7E).withValues(alpha: 0.22);
      canvas.drawCircle(
        Offset(size.width * 0.08 - parallaxOffset, size.height * 0.18),
        50,
        paint,
      );

      // Mid-right charcoal circle with parallax
      paint.color = const Color(0xFF1A1A1A).withValues(alpha: 0.10);
      canvas.drawCircle(
        Offset(size.width * 0.92 + parallaxOffset, size.height * 0.65),
        48,
        paint,
      );

      // Extra elements for screen 1
      paint.color = const Color(0xFFE8E57C).withValues(alpha: 0.16);
      canvas.drawCircle(
          Offset(size.width * 0.15, size.height * 0.45), 35, paint);

      paint.color = const Color(0xFF2B2B2B).withValues(alpha: 0.08);
      canvas.drawCircle(
          Offset(size.width * 0.80, size.height * 0.35), 40, paint);

      paint.color = const Color(0xFFF1EF7E).withValues(alpha: 0.11);
      canvas.drawCircle(
          Offset(size.width * 0.54, size.height * 0.14), 26, paint);

      paint.color = const Color(0xFF1A1A1A).withValues(alpha: 0.06);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(size.width * 0.18, size.height * 0.72, 92, 18),
          const Radius.circular(12),
        ),
        paint,
      );
    }
    // === SCREEN 2 (1.0 - 2.0): Yellow & charcoal with parallax ===
    else if (scrollOffset >= 1.0 && scrollOffset < 2.0) {
      double screenProgress = (scrollOffset - 1.0).clamp(0.0, 1.0);
      double parallaxOffset = screenProgress * 35;

      // Top-left yellow circle with parallax
      paint.color = const Color(0xFFF1EF7E).withValues(alpha: 0.20);
      canvas.drawCircle(
        Offset(size.width * 0.10 - parallaxOffset, size.height * 0.22),
        52,
        paint,
      );

      // Bottom-right charcoal circle with parallax
      paint.color = const Color(0xFF1A1A1A).withValues(alpha: 0.10);
      canvas.drawCircle(
        Offset(size.width * 0.90 + parallaxOffset, size.height * 0.72),
        50,
        paint,
      );

      // Extra elements for screen 2
      paint.color = const Color(0xFFE8E57C).withValues(alpha: 0.14);
      canvas.drawCircle(
          Offset(size.width * 0.20, size.height * 0.55), 38, paint);

      paint.color = const Color(0xFF2F2F2F).withValues(alpha: 0.08);
      canvas.drawCircle(
          Offset(size.width * 0.75, size.height * 0.40), 42, paint);

      paint.color = const Color(0xFFF1EF7E).withValues(alpha: 0.10);
      canvas.drawCircle(
          Offset(size.width * 0.48, size.height * 0.16), 28, paint);

      paint.color = const Color(0xFF1A1A1A).withValues(alpha: 0.06);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(size.width * 0.60, size.height * 0.74, 88, 18),
          const Radius.circular(12),
        ),
        paint,
      );
    }
    // === SCREEN 3 (2.0+): Yellow & charcoal with parallax ===
    else {
      double screenProgress = (scrollOffset - 2.0).clamp(0.0, 1.0);
      double parallaxOffset = screenProgress * 35;

      // Top-left yellow circle with parallax
      paint.color = const Color(0xFFF1EF7E).withValues(alpha: 0.20);
      canvas.drawCircle(
        Offset(size.width * 0.12 - parallaxOffset, size.height * 0.20),
        48,
        paint,
      );

      // Bottom-right charcoal circle with parallax
      paint.color = const Color(0xFF1A1A1A).withValues(alpha: 0.10);
      canvas.drawCircle(
        Offset(size.width * 0.88 + parallaxOffset, size.height * 0.68),
        52,
        paint,
      );

      // Extra elements for screen 3
      paint.color = const Color(0xFFE8E57C).withValues(alpha: 0.14);
      canvas.drawCircle(
          Offset(size.width * 0.18, size.height * 0.50), 36, paint);

      paint.color = const Color(0xFF2F2F2F).withValues(alpha: 0.08);
      canvas.drawCircle(
          Offset(size.width * 0.82, size.height * 0.30), 44, paint);

      paint.color = const Color(0xFFF1EF7E).withValues(alpha: 0.10);
      canvas.drawCircle(
          Offset(size.width * 0.52, size.height * 0.12), 28, paint);

      paint.color = const Color(0xFF1A1A1A).withValues(alpha: 0.06);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(size.width * 0.22, size.height * 0.70, 92, 18),
          const Radius.circular(12),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant BackgroundPatternPainter oldDelegate) {
    return oldDelegate.scrollOffset != scrollOffset ||
        oldDelegate.animValue != animValue ||
        oldDelegate.yellowColor != yellowColor ||
        oldDelegate.pinkColor != pinkColor ||
        oldDelegate.beigeColor != beigeColor;
  }
}

class ConnectorLinePainter extends CustomPainter {
  final double scrollOffset;
  final Color lineColor;

  ConnectorLinePainter({required this.scrollOffset, required this.lineColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke;

    if (scrollOffset < 0.5) {
      final path1 = Path()
        ..moveTo(size.width * 0.70, size.height * 0.22)
        ..quadraticBezierTo(size.width * 0.45, size.height * 0.28,
            size.width * 0.55, size.height * 0.48);
      canvas.drawPath(path1, paint);
    } else if (scrollOffset >= 0.5 && scrollOffset <= 1.0) {
      final path2 = Path()
        ..moveTo(size.width * 0.30, size.height * 0.22)
        ..quadraticBezierTo(size.width * 0.55, size.height * 0.28,
            size.width * 0.45, size.height * 0.48);
      canvas.drawPath(path2, paint);
    }
  }

  @override
  bool shouldRepaint(covariant ConnectorLinePainter oldDelegate) {
    return oldDelegate.scrollOffset != scrollOffset ||
        oldDelegate.lineColor != lineColor;
  }
}
