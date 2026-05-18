import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';
import '../services/storage_service.dart';
import '../utils/app_theme.dart';
import 'profile_reviews_screen.dart';
import 'settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  final int? userId;
  const ProfileScreen({super.key, this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _api = ApiService();

  Map<String, dynamic>? _user;
  List<dynamic> _reviews = [];
  bool _loading = true;

  bool get _isOwnProfile => widget.userId == null;
  String get _activeRole => (_user?['activeRole'] ?? 'worker').toString();
  bool get _isWorker => _activeRole == 'worker';

  double get _activeRating => _isWorker
      ? ((_user?['workerRating'] as num?)?.toDouble() ?? 0)
      : ((_user?['employerRating'] as num?)?.toDouble() ?? 0);

  int get _activeRatingCount => _isWorker
      ? ((_user?['workerRatingCount'] as num?)?.toInt() ?? 0)
      : ((_user?['employerRatingCount'] as num?)?.toInt() ?? 0);

  List<Map<String, dynamic>> get _roleReviews {
    final role = _activeRole.toLowerCase();
    return _reviews.whereType<Map<String, dynamic>>().where((review) {
      final reviewRole =
          (review['revieweeRole'] ?? '').toString().toLowerCase();
      if (role == 'employer') {
        return reviewRole == 'employer' || reviewRole == 'poster';
      }
      return reviewRole == 'worker';
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      setState(() => _loading = true);
      final uid = widget.userId;
      final user = uid == null ? await _api.getMe() : await _api.getUser(uid);
      final reviews = await _api.getUserReviews(user['id'] as int);
      if (mounted) {
        setState(() {
          _user = user;
          _reviews = reviews;
        });
      }
    } catch (e) {
      if (mounted) showSnack(context, e.toString(), err: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _logout() async {
    SocketService().disconnect();
    await StorageService.clearAuthData();
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
    }
  }

  Future<void> _openSettings() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SettingsScreen(
          user: _user,
          onLogout: _logout,
          onRefresh: _load,
        ),
      ),
    );
    _load();
  }

  Future<void> _openRoleReviews() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProfileReviewsScreen(
          role: _activeRole,
          reviews: _roleReviews,
        ),
      ),
    );
    _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: kBg,
        body: Center(child: CircularProgressIndicator(color: kBlack)),
      );
    }

    final fullName = (_user?['fullName'] ?? '').toString();
    final initial = fullName.isNotEmpty ? fullName[0].toUpperCase() : 'A';

    return Scaffold(
      backgroundColor: kBg,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: kBlack,
            leading: const BackButton(color: kWhite),
            title: Text(_isOwnProfile ? 'My Profile' : 'Profile'),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Cover page background
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF0D0D0D), Color(0xFF222222)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                  // Profile info centered at top
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 50,
                    child: Column(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: kPrimaryLime,
                            boxShadow: [
                              BoxShadow(
                                color: kPrimaryLime.withValues(alpha: 0.35),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              )
                            ],
                            border: Border.all(color: kBg, width: 4),
                          ),
                          child: Center(
                            child: Text(
                              initial,
                              style: const TextStyle(
                                color: kBlack,
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          fullName,
                          maxLines: 1,
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: kWhite,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _activeRole.toUpperCase(),
                          style: const TextStyle(
                            color: Color(0xFFF9F77E),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        if ((_user?['city'] as String?)?.isNotEmpty ?? false)
                          Text(
                            '📍 ${_user?['city']}',
                            style: const TextStyle(
                              color: kGrey,
                              fontSize: 11,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  const SizedBox(height: 24),
                  GestureDetector(
                    onTap: _openRoleReviews,
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: kWhite,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                            color: kPrimaryLime.withValues(alpha: 0.45)),
                        boxShadow: kShadow,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: kPrimaryLime.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(13),
                            ),
                            child: const Icon(Icons.rate_review_rounded,
                                color: kBlack, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _isWorker
                                      ? 'Worker Reviews'
                                      : 'Employer Reviews',
                                  style: const TextStyle(
                                      color: kBlack,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  'Tap to view all reviews for this role',
                                  style: TextStyle(
                                    color: kGrey.withValues(alpha: 0.9),
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                _activeRating > 0
                                    ? _activeRating.toStringAsFixed(1)
                                    : '—',
                                style: const TextStyle(
                                  color: kBlack,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              Text(
                                '$_activeRatingCount reviews',
                                style:
                                    const TextStyle(color: kGrey, fontSize: 11),
                              ),
                            ],
                          ),
                          const SizedBox(width: 10),
                          const Icon(Icons.chevron_right_rounded, color: kGrey),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildInfoCard(),
                  if (_isWorker) ...[
                    const SizedBox(height: 16),
                    _buildSkillsCard(),
                  ],
                  if (_isOwnProfile) ...[
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: _openSettings,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 16),
                        decoration: BoxDecoration(
                          color: kWhite,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: kShadow,
                        ),
                        child: Row(children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: kBlack.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.settings_rounded,
                                color: kBlack, size: 20),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Text(
                              'Settings & Account',
                              style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: kBlack),
                            ),
                          ),
                          const Icon(Icons.chevron_right_rounded, color: kGrey),
                        ]),
                      ),
                    ),
                  ],
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
            color: kWhite,
            borderRadius: BorderRadius.circular(18),
            boxShadow: kShadow),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Personal Info',
              style: TextStyle(
                  fontWeight: FontWeight.w800, fontSize: 15, color: kBlack)),
          const SizedBox(height: 16),
          _infoRow(Icons.phone_rounded, 'Phone', _user?['phoneNumber'] ?? '—',
              kPrimaryLime),
          Divider(height: 20, color: kDivider),
          _infoRow(Icons.location_city_rounded, 'City',
              _user?['city'] ?? 'Not set', kBlack),
          Divider(height: 20, color: kDivider),
          _infoRow(Icons.map_outlined, 'Area', _user?['area'] ?? 'Not set',
              kPrimaryLime),
          Divider(height: 20, color: kDivider),
          _infoRow(Icons.flag_rounded, 'Country',
              _user?['country'] ?? 'Not set', kBlack),
        ]),
      );

  Widget _buildSkillsCard() {
    final skills = ((_user?['skills'] as String?) ?? '')
        .split(',')
        .where((s) => s.trim().isNotEmpty)
        .toList();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
          color: kWhite,
          borderRadius: BorderRadius.circular(18),
          boxShadow: kShadow),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Skills',
            style: TextStyle(
                fontWeight: FontWeight.w800, fontSize: 15, color: kBlack)),
        const SizedBox(height: 12),
        skills.isEmpty
            ? const Text('No skills added.',
                style: TextStyle(color: kGrey, fontSize: 13))
            : Wrap(
                spacing: 8,
                runSpacing: 8,
                children: skills
                    .map((skill) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(
                            color: kPrimaryLime.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            skill.trim(),
                            style: const TextStyle(
                                color: kBlack,
                                fontSize: 12,
                                fontWeight: FontWeight.w700),
                          ),
                        ))
                    .toList(),
              ),
      ]),
    );
  }

  Widget _infoRow(IconData icon, String label, String value, Color color) =>
      Row(children: [
        Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 17)),
        const SizedBox(width: 12),
        Text(label, style: const TextStyle(color: kGrey, fontSize: 13)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: const TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 13, color: kBlack)),
        ),
      ]);
}
