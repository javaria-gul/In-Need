import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../utils/app_theme.dart';

class ProfileScreen extends StatefulWidget {
  final int? userId; // null = own profile (editable), non-null = view-only
  const ProfileScreen({super.key, this.userId});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _api = ApiService();
  Map<String, dynamic>? _user;
  List<dynamic> _reviews = [];
  bool _loading = true, _saving = false, _editing = false;

  final _nameCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _areaCtrl = TextEditingController();
  final _countryCtrl = TextEditingController();
  final _skillsCtrl = TextEditingController();

  bool get _isOwnProfile => widget.userId == null;
  bool get _isWorker => (_user?['activeRole'] ?? 'worker') == 'worker';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _cityCtrl.dispose();
    _areaCtrl.dispose();
    _countryCtrl.dispose();
    _skillsCtrl.dispose();
    super.dispose();
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
          if (_isOwnProfile) {
            _nameCtrl.text = user['fullName'] ?? '';
            _cityCtrl.text = user['city'] ?? '';
            _areaCtrl.text = user['area'] ?? '';
            _countryCtrl.text = user['country'] ?? '';
            _skillsCtrl.text = user['skills'] ?? '';
          }
        });
      }
    } catch (e) {
      if (mounted) showSnack(context, e.toString(), err: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final updated = await _api.updateMe({
        'fullName': _nameCtrl.text.trim(),
        'city': _cityCtrl.text.trim(),
        'area': _areaCtrl.text.trim(),
        'country': _countryCtrl.text.trim(),
        if (_isWorker) 'skills': _skillsCtrl.text.trim(),
      });
      if (mounted) {
        setState(() {
          _user = updated;
          _editing = false;
        });
        showSnack(context, 'Profile updated!', ok: true);
      }
    } catch (e) {
      if (mounted) showSnack(context, e.toString(), err: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: kBg,
        body: _loading
            ? const Center(child: CircularProgressIndicator(color: kBlue))
            : CustomScrollView(slivers: [
                SliverAppBar(
                  expandedHeight: 220,
                  pinned: true,
                  backgroundColor: kBlack,
                  leading: const BackButton(color: kWhite),
                  title: Text(_isOwnProfile
                      ? 'My Profile'
                      : '${_user?['fullName'] ?? ''} Profile'),
                  actions: [
                    if (_isOwnProfile)
                      TextButton(
                          onPressed: _editing
                              ? (_saving ? null : _save)
                              : () => setState(() => _editing = true),
                          child: _saving
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                      color: kWhite, strokeWidth: 2))
                              : Text(_editing ? 'Save' : 'Edit',
                                  style: TextStyle(
                                      color: _editing ? kGreen : kWhite,
                                      fontWeight: FontWeight.w800))),
                  ],
                  flexibleSpace: FlexibleSpaceBar(
                      background: Stack(children: [
                    Container(
                        decoration: const BoxDecoration(gradient: kHeroGrad)),
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
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                  gradient: kBlueGrad,
                                  shape: BoxShape.circle,
                                  boxShadow: kBlueShadow),
                              child: Center(
                                  child: Text(
                                      (_user?['fullName'] as String? ?? 'A')[0]
                                          .toUpperCase(),
                                      style: const TextStyle(
                                          color: kWhite,
                                          fontSize: 30,
                                          fontWeight: FontWeight.w900)))),
                          const SizedBox(height: 10),
                          Text(_user?['fullName'] ?? '',
                              style: const TextStyle(
                                  color: kWhite,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800)),
                          const SizedBox(height: 6),
                          buildTag(
                              (_user?['activeRole'] ?? 'worker')
                                  .toString()
                                  .toUpperCase(),
                              kBlue),
                        ])),
                  ])),
                ),
                SliverToBoxAdapter(
                    child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(children: [
                          // Ratings
                          Row(children: [
                            Expanded(
                                child: _ratingCard(
                                    'As Worker',
                                    (_user?['workerRating'] as num?)
                                            ?.toDouble() ??
                                        0,
                                    (_user?['workerRatingCount'] as num?)
                                            ?.toInt() ??
                                        0,
                                    kBlueGrad)),
                            const SizedBox(width: 14),
                            Expanded(
                                child: _ratingCard(
                                    'As Poster',
                                    (_user?['employerRating'] as num?)
                                            ?.toDouble() ??
                                        0,
                                    (_user?['employerRatingCount'] as num?)
                                            ?.toInt() ??
                                        0,
                                    kPurpleGrad)),
                          ]),
                          const SizedBox(height: 20),

                          // Info card
                          _buildInfoCard(),
                          if (_isWorker) ...[
                            const SizedBox(height: 16),
                            _buildSkillsCard()
                          ],

                          // Reviews
                          const SizedBox(height: 24),
                          Align(
                              alignment: Alignment.centerLeft,
                              child: Text('Reviews (${_reviews.length})',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 16,
                                      color: kBlack))),
                          const SizedBox(height: 12),
                          _reviews.isEmpty
                              ? Container(
                                  padding: const EdgeInsets.all(32),
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                      color: kWhite,
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: kShadow),
                                  child: const Text('No reviews yet.',
                                      style: TextStyle(
                                          color: kGrey, fontSize: 13)))
                              : Column(
                                  children: _reviews
                                      .map((r) => _reviewCard(r))
                                      .toList()),
                          const SizedBox(height: 40),
                        ]))),
              ]),
      );

  Widget _ratingCard(String label, double rating, int count, Gradient grad) =>
      Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: kWhite,
              borderRadius: BorderRadius.circular(18),
              boxShadow: kShadow),
          child: Column(children: [
            ShaderMask(
                shaderCallback: (b) => grad.createShader(b),
                child: Text(rating > 0 ? rating.toStringAsFixed(1) : '—',
                    style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: kWhite))),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.star_rounded, size: 13, color: Colors.amber.shade600),
              const SizedBox(width: 3),
              Text(label, style: const TextStyle(color: kGrey, fontSize: 11)),
            ]),
            Text('$count reviews',
                style: const TextStyle(color: kGrey, fontSize: 10)),
          ]));

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
        _editing
            ? Column(children: [
                _editField(
                    _nameCtrl, 'Full Name', Icons.person_outline_rounded),
                const SizedBox(height: 12),
                _editField(_cityCtrl, 'City', Icons.location_city_rounded),
                const SizedBox(height: 12),
                _editField(_areaCtrl, 'Area', Icons.map_outlined),
                const SizedBox(height: 12),
                _editField(_countryCtrl, 'Country', Icons.flag_rounded),
              ])
            : Column(children: [
                _infoRow(Icons.phone_rounded, 'Phone',
                    _user?['phoneNumber'] ?? '—', kBlue),
                Divider(height: 20, color: kDivider),
                _infoRow(Icons.location_city_rounded, 'City',
                    _user?['city'] ?? 'Not set', kPurple),
                Divider(height: 20, color: kDivider),
                _infoRow(Icons.map_outlined, 'Area',
                    _user?['area'] ?? 'Not set', kGreen),
                Divider(height: 20, color: kDivider),
                _infoRow(Icons.flag_rounded, 'Country',
                    _user?['country'] ?? 'Not set', kOrange),
              ]),
      ]));

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
          const SizedBox(height: 14),
          _editing
              ? TextFormField(
                  controller: _skillsCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Skills (comma-separated)',
                      prefixIcon: Icon(Icons.build_circle_outlined)))
              : skills.isEmpty
                  ? const Text('No skills added.',
                      style: TextStyle(color: kGrey, fontSize: 13))
                  : Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: skills
                          .map((s) => Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                    gradient: kBlueGrad,
                                    borderRadius: BorderRadius.circular(20)),
                                child: Text(s.trim(),
                                    style: const TextStyle(
                                        color: kWhite,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700)),
                              ))
                          .toList()),
        ]));
  }

  Widget _infoRow(IconData icon, String label, String value, Color color) =>
      Row(children: [
        Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 17)),
        const SizedBox(width: 12),
        Text(label, style: const TextStyle(color: kGrey, fontSize: 13)),
        const Spacer(),
        Text(value,
            style: const TextStyle(
                fontWeight: FontWeight.w700, fontSize: 13, color: kBlack)),
      ]);

  Widget _editField(TextEditingController ctrl, String label, IconData icon) =>
      TextFormField(
          controller: ctrl,
          decoration:
              InputDecoration(labelText: label, prefixIcon: Icon(icon)));

  Widget _reviewCard(Map<String, dynamic> r) {
    final reviewer = r['reviewer'] as Map<String, dynamic>?;
    final rating = (r['overallRating'] as num?)?.toInt() ?? 0;
    return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: kWhite,
            borderRadius: BorderRadius.circular(16),
            boxShadow: kShadow),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                    gradient: kPurpleGrad, shape: BoxShape.circle),
                child: Center(
                    child: Text(
                        (reviewer?['fullName'] as String? ?? '?')[0]
                            .toUpperCase(),
                        style: const TextStyle(
                            color: kWhite, fontWeight: FontWeight.w900)))),
            const SizedBox(width: 12),
            Expanded(
                child: Text(reviewer?['fullName'] ?? 'User',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, color: kBlack))),
            Row(
                children: List.generate(
                    5,
                    (i) => Icon(
                        i < rating
                            ? Icons.star_rounded
                            : Icons.star_border_rounded,
                        color: i < rating
                            ? Colors.amber.shade500
                            : kGrey.withValues(alpha: 0.3),
                        size: 15))),
          ]),
          if ((r['comment'] as String?)?.isNotEmpty == true) ...[
            const SizedBox(height: 8),
            Text(r['comment'] as String,
                style:
                    const TextStyle(color: kGrey, fontSize: 13, height: 1.4)),
          ],
        ]));
  }
}
