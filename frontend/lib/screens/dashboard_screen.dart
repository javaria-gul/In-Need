import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../services/socket_service.dart';
import '../utils/app_theme.dart';
import 'active_job_screen.dart';
import 'profile_screen.dart';
import 'posted_jobs_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  final _api = ApiService();
  int _tab = 0;
  bool _loading = true, _switching = false;
  Map<String, dynamic>? _user;
  AnimationController? _scaleCtrl;

  String get _role => _user?['activeRole']?.toString() ?? 'worker';
  bool get _isPoster => _role == 'employer';
  String get _firstName =>
      (_user?['fullName'] as String?)?.split(' ').first ?? 'there';
  String get _fullName => _user?['fullName'] as String? ?? 'there';
  double get _wRating => (_user?['workerRating'] as num?)?.toDouble() ?? 0;
  double get _eRating => (_user?['employerRating'] as num?)?.toDouble() ?? 0;
  int get _wCount => (_user?['workerRatingCount'] as num?)?.toInt() ?? 0;
  int get _eCount => (_user?['employerRatingCount'] as num?)?.toInt() ?? 0;
  String get _userCity => _user?['city'] ?? 'Your Location';
  String get _userArea => _user?['area'] ?? '';
  String get _userLocation =>
      _userArea.isNotEmpty ? '$_userArea, $_userCity' : _userCity;

  @override
  void initState() {
    super.initState();
    _scaleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _init();
  }

  @override
  void dispose() {
    _scaleCtrl?.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    // Try to load cached user data first
    try {
      final cached = await StorageService.getCachedUser();
      if (cached != null && mounted) {
        setState(() => _user = cached);
        debugPrint('✅ Loaded cached user: ${_user?['fullName']}');
      }
    } catch (e) {
      debugPrint('⚠️ Failed to load cached user: $e');
    }

    // Then fetch fresh data from server
    await _load();
    try {
      await SocketService().connect();
      _setupSockets();
    } catch (e) {
      debugPrint('⚠️ Socket connection failed in dashboard: $e');
      // Continue without socket - app can still function
    }
  }

  void _setupSockets() {
    SocketService().on('bid_accepted', (d) {
      if (mounted) showSnack(context, '🎉 Your bid was accepted!', ok: true);
    });

    SocketService().on('job_relisted', (d) {
      if (mounted) {
        showSnack(context, '🔄 A job was re-listed. You can bid again!');
      }
    });

    SocketService().on('job_completed', (d) {
      if (mounted) {
        final jobId = d['jobId'] as int?;
        final revieweeId = d['revieweeId'] as int?;
        if (jobId != null && revieweeId != null) {
          Navigator.pushNamed(context, '/review', arguments: {
            'jobId': jobId,
            'revieweeId': revieweeId,
            'revieweeName': 'Other Party',
          });
        }
      }
    });

    SocketService().on('counter_bid_accepted', (d) {
      if (mounted) {
        showSnack(
            context, '✅ Your counter offer was accepted! Job is now active.',
            ok: true);
        _load();
      }
    });

    SocketService().on('counter_bid_rejected', (d) {
      if (mounted) {
        showSnack(context, '❌ Your counter offer was rejected.', err: true);
      }
    });

    // ✅ COUNTER-OFFER POPUP FOR POSTER
    SocketService().on('bid_updated', (data) {
      if (!mounted) return;

      final previousPrice = data['previousPrice'];
      final newPrice = data['offeredPrice'];
      final seekerName = data['seekerName'] ?? 'Someone';
      final jobTitle = data['jobTitle'] ?? 'a job';
      final bidId = data['bidId'];
      final jobId = data['jobId'];

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(Icons.swap_horiz_rounded, color: Colors.amber.shade700),
              const SizedBox(width: 8),
              const Text('New Counter Offer!',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$seekerName sent a counter-offer for "$jobTitle":'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Column(
                  children: [
                    Text(
                      'Previous: Rs. $previousPrice',
                      style: const TextStyle(
                          decoration: TextDecoration.lineThrough,
                          color: Colors.grey),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'New Offer: Rs. $newPrice',
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green),
                    ),
                  ],
                ),
              ),
              if (data['message'] != null) ...[
                const SizedBox(height: 12),
                Text('💬 "${data['message']}"',
                    style: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: Colors.grey.shade600)),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.pop(ctx);
                try {
                  await _api.rejectCounterBid(jobId, bidId);
                  if (mounted) {
                    showSnack(context, 'Counter offer rejected', ok: true);
                  }
                } catch (e) {
                  if (mounted) showSnack(context, e.toString(), err: true);
                }
              },
              child: const Text('Reject', style: TextStyle(color: Colors.red)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                try {
                  await _api.acceptCounterBid(jobId, bidId);
                  if (mounted) {
                    showSnack(
                        context, '✅ Counter offer accepted! Tracking started.',
                        ok: true);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const ActiveJobScreen()),
                    );
                  }
                } catch (e) {
                  if (mounted) showSnack(context, e.toString(), err: true);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('Accept Offer'),
            ),
          ],
        ),
      );
    });
  }

  Future<void> _load() async {
    try {
      setState(() => _loading = true);
      final u = await _api.getMe();
      if (mounted) setState(() => _user = u);
    } catch (e) {
      if (mounted) showSnack(context, e.toString(), err: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _switchRole() async {
    setState(() => _switching = true);
    try {
      final r = await _api.switchRole();
      if (mounted) {
        setState(() => _user?['activeRole'] = r['activeRole']);
        showSnack(context,
            'Switched to ${(r['activeRole'] as String).toUpperCase()} mode',
            ok: true);
      }
    } catch (e) {
      if (mounted) showSnack(context, e.toString(), err: true);
    } finally {
      if (mounted) setState(() => _switching = false);
    }
  }

  Future<void> _logout() async {
    SocketService().disconnect();
    await StorageService.clearAuthData();
    if (mounted) Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
          backgroundColor: kBg,
          body: Center(child: CircularProgressIndicator(color: kBlue)));
    }
    return Scaffold(
      backgroundColor: kBg,
      body: IndexedStack(
        index: _tab,
        children: [
          _homeTab(), // 0: Home
          _activeJobTab(), // 1: Active Jobs
          _profileTab(), // 2: Profile
          _alertsTab(), // 3: Alerts
          _settingsTab(), // 4: Settings (repurposed from old settings)
        ],
      ),
      bottomNavigationBar: _buildCustomNavBar(),
    );
  }

  Widget _buildCustomNavBar() {
    const navItems = [
      {'icon': Icons.home_rounded, 'label': 'Home'},
      {'icon': Icons.shopping_bag_rounded, 'label': 'Active'},
      {'icon': Icons.add_rounded, 'label': 'Create'},
      {'icon': Icons.notifications_rounded, 'label': 'Alerts'},
      {'icon': Icons.person_rounded, 'label': 'Profile'},
    ];

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Main navbar container
        Container(
          margin: const EdgeInsets.only(bottom: 16, left: 35, right: 35),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, -3),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: SafeArea(
              top: false,
              child: Stack(
                children: [
                  // Navigation items
                  Padding(
                    padding: const EdgeInsets.only(
                        top: 10, left: 20, right: 20, bottom: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Home
                        _buildNavItem(0, navItems[0]),
                        // Active
                        _buildNavItem(1, navItems[1]),
                        // Spacer for floating button
                        const SizedBox(width: 50),
                        // Alerts
                        _buildNavItem(3, navItems[3]),
                        // Profile
                        _buildNavItem(4, navItems[4]),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Floating plus button (outside clipping)
        Positioned(
          bottom: 38,
          left: 0,
          right: 0,
          child: Center(
            child: _buildFloatingPlusButton(),
          ),
        ),
      ],
    );
  }

  Widget _buildNavItem(int index, Map<String, dynamic> item) {
    final isActive = _tab == index;
    final iconColor = isActive ? const Color(0xFFF9F77E) : Colors.white;

    return GestureDetector(
      onTap: () {
        setState(() => _tab = index);
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            item['icon'] as IconData,
            color: iconColor,
            size: 28,
          ),
          if (isActive) ...[
            const SizedBox(height: 4),
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: Color(0xFFF9F77E),
                shape: BoxShape.circle,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFloatingPlusButton() {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, _isPoster ? '/post-job' : '/job-feed');
      },
      child: Container(
        width: 62,
        height: 62,
        decoration: BoxDecoration(
          color: const Color(0xFFF9F77E),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFF9F77E).withValues(alpha: 0.4),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Icon(
          Icons.add_rounded,
          color: Colors.black,
          size: 30,
        ),
      ),
    );
  }

  Widget _homeTab() => RefreshIndicator(
      onRefresh: _load,
      color: kBlue,
      child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              expandedHeight: 100,
              pinned: true,
              backgroundColor: kWhite,
              automaticallyImplyLeading: false,
              actions: [
                Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: Center(
                        child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9F77E),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _isPoster ? 'Employer' : 'Worker',
                        style: const TextStyle(
                            color: kBlack,
                            fontSize: 11,
                            fontWeight: FontWeight.w700),
                      ),
                    )))
              ],
              elevation: 0,
              flexibleSpace: FlexibleSpaceBar(
                  background: Padding(
                      padding: const EdgeInsets.only(
                          left: 20, right: 20, top: 16, bottom: 16),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Hi, $_fullName',
                                style: const TextStyle(
                                    color: kBlack,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800)),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.location_on_rounded,
                                    color: kBlack, size: 14),
                                const SizedBox(width: 4),
                                Text(_userLocation,
                                    style: TextStyle(
                                        color: kBlack.withValues(alpha: 0.6),
                                        fontSize: 12)),
                              ],
                            ),
                            const SizedBox(height: 10),
                            // Role box removed from here - now in top right
                          ]))),
            ),
            SliverToBoxAdapter(
                child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(children: [
                      _sectionHeader('Quick Actions'),
                      const SizedBox(height: 14),
                      _actionCard(
                        icon: _isPoster
                            ? Icons.add_circle_rounded
                            : Icons.style_rounded,
                        gradient: kBlueGrad,
                        title:
                            _isPoster ? 'Post a New Job' : 'Browse Job Cards',
                        subtitle: _isPoster
                            ? 'Fill the form, AI finds workers'
                            : 'Swipe through jobs for you',
                        badge: _isPoster ? null : 'AI',
                        onTap: () => Navigator.pushNamed(
                            context, _isPoster ? '/post-job' : '/job-feed'),
                      ),
                      const SizedBox(height: 12),
                      if (_isPoster)
                        _actionCard(
                          icon: Icons.list_alt_rounded,
                          gradient: kPurpleGrad,
                          title: 'My Posted Jobs',
                          subtitle: 'View bids and job status',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const PostedJobsScreen()),
                          ),
                        ),
                      _actionCard(
                        icon: Icons.work_history_rounded,
                        gradient: kPurpleGrad,
                        title: _isPoster ? 'Active Job' : 'My Active Job',
                        subtitle: _isPoster
                            ? 'Track your posted active job'
                            : 'Track your current assignment',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const ActiveJobScreen()),
                        ),
                      ),
                      const SizedBox(height: 24),
                      _sectionHeader('My Ratings'),
                      const SizedBox(height: 14),
                      _ratingsRow(),
                      const SizedBox(height: 40),
                    ]))),
          ]));

  Widget _sectionHeader(String t) => Align(
      alignment: Alignment.centerLeft,
      child: Text(t,
          style: const TextStyle(
              fontSize: 17, fontWeight: FontWeight.w800, color: kBlack)));

  Widget _roleSwitchCard() => ACard(
      padding: const EdgeInsets.all(18),
      child: Row(children: [
        Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
                gradient: _isPoster ? kPurpleGrad : kBlueGrad,
                borderRadius: BorderRadius.circular(16)),
            child: Icon(
                _isPoster ? Icons.business_center_rounded : Icons.build_rounded,
                color: kWhite,
                size: 26)),
        const SizedBox(width: 16),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Active Mode',
              style: TextStyle(
                  color: kGrey, fontSize: 11, fontWeight: FontWeight.w600)),
          const SizedBox(height: 3),
          Text(_isPoster ? '📋 POSTER MODE' : '🔧 SEEKER MODE',
              style: const TextStyle(
                  color: kBlack, fontWeight: FontWeight.w900, fontSize: 15)),
          Text(_isPoster ? 'Post jobs & hire workers' : 'Browse & bid on jobs',
              style: const TextStyle(color: kGrey, fontSize: 11)),
        ])),
        const SizedBox(width: 12),
        GestureDetector(
            onTap: _switching ? null : _switchRole,
            child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                    gradient: _isPoster ? kBlueGrad : kPurpleGrad,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: kBlueShadow),
                child: _switching
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                            color: kWhite, strokeWidth: 2))
                    : const Text('Switch',
                        style: TextStyle(
                            color: kWhite,
                            fontWeight: FontWeight.w800,
                            fontSize: 13)))),
      ]));

  Widget _actionCard({
    required IconData icon,
    required Gradient gradient,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    String? badge,
  }) =>
      GestureDetector(
          onTap: onTap,
          child: ACard(
              padding: const EdgeInsets.all(16),
              child: Row(children: [
                Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                        gradient: gradient,
                        borderRadius: BorderRadius.circular(16)),
                    child: Icon(icon, color: kWhite, size: 26)),
                const SizedBox(width: 16),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Row(children: [
                        Text(title,
                            style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                                color: kBlack)),
                        if (badge != null) ...[
                          const SizedBox(width: 8),
                          buildTag(badge, kBlue)
                        ],
                      ]),
                      const SizedBox(height: 3),
                      Text(subtitle,
                          style: const TextStyle(color: kGrey, fontSize: 12)),
                    ])),
                Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                        color: kBg, borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.arrow_forward_ios_rounded,
                        size: 14, color: kGrey)),
              ])));

  Widget _ratingsRow() => Row(children: [
        Expanded(child: _ratingCard('As Worker', _wRating, _wCount, kBlueGrad)),
        const SizedBox(width: 14),
        Expanded(
            child: _ratingCard('As Employer', _eRating, _eCount, kPurpleGrad)),
      ]);

  Widget _ratingCard(String label, double rating, int count, Gradient grad) =>
      Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
            color: kWhite,
            borderRadius: BorderRadius.circular(18),
            boxShadow: kShadow),
        child: Column(children: [
          ShaderMask(
              shaderCallback: (b) => grad.createShader(b),
              child: Text(rating > 0 ? rating.toStringAsFixed(1) : '—',
                  style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: kWhite))),
          const SizedBox(height: 4),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.star_rounded, size: 14, color: Colors.amber.shade600),
            const SizedBox(width: 3),
            Text(label, style: const TextStyle(color: kGrey, fontSize: 11)),
          ]),
          Text('$count reviews',
              style: const TextStyle(color: kGrey, fontSize: 10)),
        ]),
      );

  Widget _activeJobTab() => Scaffold(
        backgroundColor: kBg,
        appBar: AppBar(
          backgroundColor: kBlack,
          title: const Text('Active Jobs'),
          elevation: 0,
          automaticallyImplyLeading: true,
        ),
        body: const ActiveJobScreen(),
      );

  Widget _alertsTab() => CustomScrollView(
        slivers: [
          const SliverAppBar(
            pinned: true,
            backgroundColor: kBlack,
            automaticallyImplyLeading: false,
            title: Text('Notifications'),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 60),
                      child: Column(
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: kBlue.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.notifications_none_rounded,
                              color: kBlue,
                              size: 40,
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'No Notifications Yet',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: kBlack,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'You\'ll see updates about your jobs here',
                            style: TextStyle(
                              fontSize: 14,
                              color: kGrey,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );

  Widget _profileTab() {
    final skills = ((_user?['skills'] as String?) ?? '')
        .split(',')
        .where((s) => s.trim().isNotEmpty)
        .toList();
    final initial = (_user?['fullName'] as String? ?? 'A')[0].toUpperCase();
    return CustomScrollView(slivers: [
      SliverAppBar(
        expandedHeight: 240,
        pinned: true,
        backgroundColor: kBlack,
        automaticallyImplyLeading: false,
        title: const Text('My Profile'),
        actions: [
          IconButton(
              icon: const Icon(Icons.edit_outlined, color: kWhite, size: 20),
              onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ProfileScreen()),
                  ).then((_) => _load()))
        ],
        flexibleSpace: FlexibleSpaceBar(
            background: Stack(children: [
          Container(decoration: const BoxDecoration(gradient: kHeroGrad)),
          Positioned(
              top: -10,
              right: -60,
              child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: kBlue.withValues(alpha: 0.05)))),
          Center(
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                const SizedBox(height: 50),
                Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: kBlueGrad,
                        boxShadow: kBlueShadow),
                    child: Center(
                        child: Text(initial,
                            style: const TextStyle(
                                color: kWhite,
                                fontSize: 34,
                                fontWeight: FontWeight.w900)))),
                const SizedBox(height: 12),
                Text(_user?['fullName'] ?? '',
                    style: const TextStyle(
                        color: kWhite,
                        fontSize: 18,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                buildTag(_role.toUpperCase(), kBlue),
              ])),
        ])),
      ),
      SliverToBoxAdapter(
          child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(children: [
                _ratingsRow(),
                const SizedBox(height: 20),
                ACard(
                    child: Column(children: [
                  const Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Personal Info',
                          style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                              color: kBlack))),
                  const SizedBox(height: 16),
                  _infoRow(Icons.phone_rounded, 'Phone',
                      _user?['phoneNumber'] ?? '—', kBlue),
                  Divider(height: 24, color: kDivider),
                  _infoRow(Icons.location_city_rounded, 'City',
                      _user?['city'] ?? 'Not set', kPurple),
                  Divider(height: 24, color: kDivider),
                  _infoRow(Icons.flag_rounded, 'Country',
                      _user?['country'] ?? 'Not set', kGreen),
                ])),
                if (!_isPoster && skills.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  ACard(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Row(children: [
                          Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                  gradient: kBlueGrad,
                                  borderRadius: BorderRadius.circular(10)),
                              child: const Icon(Icons.build_rounded,
                                  color: kWhite, size: 16)),
                          const SizedBox(width: 12),
                          const Text('My Skills',
                              style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                  color: kBlack)),
                        ]),
                        const SizedBox(height: 14),
                        Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: skills
                                .map((s) => Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 14, vertical: 8),
                                      decoration: BoxDecoration(
                                          gradient: kBlueGrad,
                                          borderRadius:
                                              BorderRadius.circular(20)),
                                      child: Text(s.trim(),
                                          style: const TextStyle(
                                              color: kWhite,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700)),
                                    ))
                                .toList()),
                      ])),
                ],
                const SizedBox(height: 40),
              ]))),
    ]);
  }

  Widget _infoRow(IconData icon, String label, String value, Color color) =>
      Row(children: [
        Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 18)),
        const SizedBox(width: 14),
        Text(label, style: const TextStyle(color: kGrey, fontSize: 13)),
        const Spacer(),
        Text(value,
            style: const TextStyle(
                fontWeight: FontWeight.w700, fontSize: 13, color: kBlack)),
      ]);

  Widget _settingsTab() => CustomScrollView(slivers: [
        const SliverAppBar(
            pinned: true,
            backgroundColor: kBlack,
            automaticallyImplyLeading: false,
            title: Text('Settings')),
        SliverToBoxAdapter(
            child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(children: [
                  ACard(
                      padding: const EdgeInsets.all(16),
                      child: Row(children: [
                        Container(
                            width: 54,
                            height: 54,
                            decoration: BoxDecoration(
                                gradient: kBlueGrad, shape: BoxShape.circle),
                            child: Center(
                                child: Text(
                                    (_user?['fullName'] as String? ?? 'A')[0]
                                        .toUpperCase(),
                                    style: const TextStyle(
                                        color: kWhite,
                                        fontSize: 24,
                                        fontWeight: FontWeight.w900)))),
                        const SizedBox(width: 14),
                        Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              Text(_user?['fullName'] ?? '',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15,
                                      color: kBlack)),
                              Text(_user?['phoneNumber'] ?? '',
                                  style: const TextStyle(
                                      color: kGrey, fontSize: 12)),
                            ])),
                        buildTag(
                            _role.toUpperCase(), _isPoster ? kPurple : kBlue),
                      ])),
                  const SizedBox(height: 24),
                  _settingsGroup('Account', [
                    _settingRow(Icons.lock_outline_rounded, 'Change Password',
                        kBlue, () {}),
                    _settingRow(Icons.notifications_outlined, 'Notifications',
                        kPurple, () {}),
                    _settingRow(
                        Icons.person_outline_rounded,
                        'Edit Profile',
                        kGreen,
                        () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const ProfileScreen()))),
                  ]),
                  const SizedBox(height: 16),
                  _settingsGroup('Support', [
                    _settingRow(Icons.help_outline_rounded, 'Help & Support',
                        kOrange, () {}),
                    _settingRow(Icons.privacy_tip_outlined, 'Privacy Policy',
                        Colors.teal, () {}),
                    _settingRow(Icons.info_outline_rounded, 'About Apka Hunar',
                        kGrey, () {}),
                  ]),
                  const SizedBox(height: 24),
                  GestureDetector(
                      onTap: _logout,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                            color: kRed.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(16),
                            border:
                                Border.all(color: kRed.withValues(alpha: 0.2))),
                        child: Row(children: [
                          Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                  color: kRed.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(12)),
                              child: const Icon(Icons.logout_rounded,
                                  color: kRed, size: 20)),
                          const SizedBox(width: 14),
                          const Text('Logout',
                              style: TextStyle(
                                  color: kRed,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14)),
                          const Spacer(),
                          const Icon(Icons.chevron_right_rounded, color: kRed),
                        ]),
                      )),
                  const SizedBox(height: 40),
                ]))),
      ]);

  Widget _settingsGroup(String label, List<Widget> rows) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label.toUpperCase(),
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: kGrey.withValues(alpha: 0.8),
                letterSpacing: 1.2)),
        const SizedBox(height: 8),
        ACard(
            padding: EdgeInsets.zero,
            child: Column(
                children: List.generate(
                    rows.length,
                    (i) => Column(children: [
                          rows[i],
                          if (i < rows.length - 1)
                            Divider(height: 0, indent: 70, color: kDivider),
                        ])))),
      ]);

  Widget _settingRow(
          IconData icon, String title, Color color, VoidCallback onTap) =>
      ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(11)),
            child: Icon(icon, color: color, size: 19)),
        title: Text(title,
            style: const TextStyle(
                fontWeight: FontWeight.w700, fontSize: 14, color: kBlack)),
        trailing:
            const Icon(Icons.chevron_right_rounded, color: kGrey, size: 18),
        onTap: onTap,
      );
}
