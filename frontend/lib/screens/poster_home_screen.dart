import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../utils/app_theme.dart';
import 'bids_screen.dart';

class PosterHomeScreen extends StatefulWidget {
  final Map<String, dynamic>? user;
  final VoidCallback onRefresh;

  const PosterHomeScreen(
      {super.key, required this.user, required this.onRefresh});

  @override
  State<PosterHomeScreen> createState() => _PosterHomeScreenState();
}

class _PosterHomeScreenState extends State<PosterHomeScreen> {
  final _api = ApiService();
  List<dynamic> _livePosts = [];
  bool _loadingPosts = true;
  int _liveCount = 0, _offersCount = 0, _totalCount = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() => _loadingPosts = true);
      final jobs = await _api.getMyJobs();
      final now = DateTime.now();
      final live = jobs.cast<Map<String, dynamic>>().where((j) {
        final exp = j['expiresAt'] != null
            ? DateTime.tryParse(j['expiresAt'].toString())
            : null;
        final status = j['status']?.toString().toLowerCase() ?? '';
        return status != 'expired' &&
            status != 'completed' &&
            (exp == null || exp.isAfter(now));
      }).toList();

      int offers = 0;
      for (final job in live) {
        final bids = job['bids'] as List<dynamic>? ?? [];
        offers += bids.length;
      }

      if (mounted) {
        setState(() {
          _livePosts = live;
          _liveCount = live.length;
          _offersCount = offers;
          _totalCount = jobs.length;
        });
      }
    } catch (e) {
      if (mounted) showSnack(context, e.toString(), err: true);
    } finally {
      if (mounted) setState(() => _loadingPosts = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    final fullName = user?['fullName'] as String? ?? '';
    final initial = fullName.isNotEmpty ? fullName[0].toUpperCase() : 'A';
    final area = user?['area'] as String? ?? '';
    final city = user?['city'] as String? ?? '';
    final location = area.isNotEmpty && city.isNotEmpty ? '$area, $city' : city;

    return RefreshIndicator(
      onRefresh: () async {
        await _loadData();
        widget.onRefresh();
      },
      color: kBlack,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // Top header
          SliverAppBar(
            pinned: true,
            backgroundColor: kWhite,
            elevation: 0,
            automaticallyImplyLeading: false,
            expandedHeight: 110,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: kWhite,
                padding: const EdgeInsets.fromLTRB(18, 38, 18, 10),
                child: Center(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: kWhite,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: kShadow,
                      border: Border.all(
                          color: kPrimaryLime.withValues(alpha: 0.35)),
                    ),
                    child: Row(children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Hi, $fullName',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: kBlack,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900),
                            ),
                            const SizedBox(height: 6),
                            Row(children: [
                              const Icon(Icons.location_on_rounded,
                                  color: kGrey, size: 14),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  location.isNotEmpty
                                      ? location
                                      : 'Location not set',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      color: kGrey, fontSize: 13),
                                ),
                              ),
                            ]),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9F77E),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text('Employer',
                            style: TextStyle(
                                color: kBlack,
                                fontWeight: FontWeight.w800,
                                fontSize: 12)),
                      ),
                    ]),
                  ),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(children: [
                // Stats boxes
                Row(children: [
                  _statBox('Live', _liveCount.toString(), Icons.circle, kGreen,
                      'Active posts'),
                  const SizedBox(width: 12),
                  _statBox('Offers', _offersCount.toString(),
                      Icons.swap_horiz_rounded, kOrange, 'Counter offers'),
                  const SizedBox(width: 12),
                  _statBox('Total', _totalCount.toString(), Icons.work_rounded,
                      kPurple, 'All posts'),
                ]),
                const SizedBox(height: 28),
                // Live posts section
                Row(children: [
                  const Text('Your Live Posts',
                      style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: kBlack)),
                  const Spacer(),
                  if (_liveCount > 0)
                    Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                            color: const Color(0xFFF9F77E),
                            borderRadius: BorderRadius.circular(20)),
                        child: Text('$_liveCount active',
                            style: const TextStyle(
                                color: kBlack,
                                fontSize: 11,
                                fontWeight: FontWeight.w700))),
                ]),
                const SizedBox(height: 14),
                if (_loadingPosts)
                  const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: CircularProgressIndicator(color: kBlack))
                else if (_livePosts.isEmpty)
                  _emptyState()
                else
                  ..._livePosts
                      .map((job) => _postCard(job as Map<String, dynamic>))
                      .toList(),
                const SizedBox(height: 40),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statBox(
      String label, String val, IconData icon, Color color, String sub) {
    return Expanded(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF9F77E),
          borderRadius: BorderRadius.circular(18),
          boxShadow: kShadow,
          border: Border.all(color: kBlack, width: 1.6),
        ),
        child: Column(children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
                color: const Color(0xFFF9F77E),
                borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: kBlack, size: 22),
          ),
          const SizedBox(height: 8),
          Text(val,
              style: const TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w900, color: kBlack)),
          Text(label,
              style: const TextStyle(
                  color: kBlack, fontSize: 10, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }

  Widget _postCard(Map<String, dynamic> job) {
    final title = job['title'] as String? ?? 'Untitled';
    final description = (job['description'] as String?) ??
        (job['details'] as String?) ??
        (job['summary'] as String?) ??
        'No description provided for this post.';
    final price = (job['price'] as num?)?.toDouble() ?? 0;
    final bids = (job['bids'] as List<dynamic>?) ?? [];
    final exp = job['expiresAt'] != null
        ? DateTime.tryParse(job['expiresAt'].toString())
        : null;
    final remaining = exp != null ? exp.difference(DateTime.now()) : null;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => BidsScreen(jobId: job['id'] as int)),
      ).then((_) => _loadData()),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: kBlack,
          borderRadius: BorderRadius.circular(20),
          boxShadow: kShadow,
          border: Border.all(color: const Color(0xFFF9F77E), width: 1.3),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
              child: Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: kWhite)),
            ),
            if (bids.isNotEmpty)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                    color: const Color(0xFFF9F77E),
                    borderRadius: BorderRadius.circular(20)),
                child: Row(children: [
                  const Icon(Icons.notifications_rounded,
                      color: kBlack, size: 13),
                  const SizedBox(width: 4),
                  Text('${bids.length} offers',
                      style: const TextStyle(
                          color: kBlack,
                          fontSize: 11,
                          fontWeight: FontWeight.w700)),
                ]),
              ),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            const Icon(Icons.monetization_on_rounded,
                color: Color(0xFFF9F77E), size: 14),
            const SizedBox(width: 4),
            Text('Rs. ${price.toStringAsFixed(0)}',
                style: const TextStyle(color: kWhite, fontSize: 12)),
            const Spacer(),
            if (remaining != null && remaining.isNegative == false)
              Text(
                _formatRemaining(remaining),
                style: TextStyle(
                    color: const Color(0xFFF9F77E),
                    fontSize: 11,
                    fontWeight: FontWeight.w600),
              ),
          ]),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: kBlack.withValues(alpha: 0.32),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: const Color(0xFFF9F77E).withValues(alpha: 0.6)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Description',
                    style: TextStyle(
                        color: Color(0xFFF9F77E),
                        fontSize: 11,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                Text(
                  description,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: kWhite,
                    fontSize: 12,
                    height: 1.35,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                  color: const Color(0xFFF9F77E),
                  borderRadius: BorderRadius.circular(8)),
              child: const Text('LIVE',
                  style: TextStyle(
                      color: kBlack,
                      fontSize: 10,
                      fontWeight: FontWeight.w800)),
            ),
            const Spacer(),
            const Text('Tap to see offers →',
                style: TextStyle(
                    color: Color(0xFFF9F77E),
                    fontSize: 11,
                    fontWeight: FontWeight.w600)),
          ]),
        ]),
      ),
    );
  }

  String _formatRemaining(Duration d) {
    if (d.inHours >= 1) return '${d.inHours}h left';
    return '${d.inMinutes}m left';
  }

  Widget _emptyState() => Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
                color: kBg,
                shape: BoxShape.circle,
                border: Border.all(color: kDivider, width: 2)),
            child: const Icon(Icons.work_off_rounded, size: 38, color: kGrey),
          ),
          const SizedBox(height: 16),
          const Text('No Live Posts',
              style: TextStyle(
                  fontWeight: FontWeight.w800, fontSize: 18, color: kBlack)),
          const SizedBox(height: 8),
          const Text('Post a job to start hiring workers.',
              style: TextStyle(color: kGrey, fontSize: 13)),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/post-job'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                  color: const Color(0xFFF9F77E),
                  borderRadius: BorderRadius.circular(12)),
              child: const Text('Post a Job',
                  style: TextStyle(color: kBlack, fontWeight: FontWeight.w800)),
            ),
          ),
        ]),
      );
}
