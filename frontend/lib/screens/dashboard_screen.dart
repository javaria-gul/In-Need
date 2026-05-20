import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../services/socket_service.dart';
import '../services/notification_service.dart';
import '../utils/app_theme.dart';
import 'active_job_screen.dart';
import 'profile_screen.dart';
import 'poster_home_screen.dart';
import 'seeker_home_screen.dart';
import 'notifications_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  final _api = ApiService();
  final _notifs = NotificationService();
  int _tab = 0;
  bool _loading = true;
  Map<String, dynamic>? _user;

  String get _role => _user?['activeRole']?.toString() ?? 'worker';
  bool get _isPoster => _role == 'employer';

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final cached = await StorageService.getCachedUser();
      if (cached != null && mounted) setState(() => _user = cached);
    } catch (_) {}
    await _load();
    try {
      await SocketService().connect();
      _setupSockets();
    } catch (e) {
      debugPrint('Socket: $e');
    }
  }

  void _setupSockets() {
    SocketService().on('bid_accepted', (d) {
      if (!mounted) return;
      _notifs.addNotification(
          title: 'Bid Accepted',
          body: 'Your bid was accepted.',
          type: 'bid',
          data: d);
      showSnack(context, 'Your bid was accepted.', ok: true);
    });

    SocketService().on('new_bid', (d) {
      if (!mounted) return;
      final name = d['seekerName'] ?? 'Someone';
      _notifs.addNotification(
          title: 'New Bid',
          body: '$name placed a bid on your job',
          type: 'bid',
          data: d);
    });

    SocketService().on('bid_updated', (data) {
      if (!mounted) return;
      final name = data['seekerName'] ?? 'Someone';
      _notifs.addNotification(
          title: 'Counter Offer',
          body: '$name sent a counter offer',
          type: 'offer',
          data: data);
      _showCounterOfferDialog(data);
    });

    SocketService().on('job_relisted', (d) {
      if (!mounted) return;
      _notifs.addNotification(
          title: 'Job Re-listed',
          body: 'A job was re-listed. You can bid again!',
          type: 'job',
          data: d);
    });

    SocketService().on('job_completed', (d) {
      if (!mounted) return;
      final jobId = d['jobId'] as int?;
      final revieweeId = d['revieweeId'] as int?;
      if (jobId != null && revieweeId != null) {
        _notifs.addNotification(
            title: 'Job Completed',
            body: 'Please leave a review.',
            type: 'review',
            data: d);
        Navigator.pushNamed(context, '/review', arguments: {
          'jobId': jobId,
          'revieweeId': revieweeId,
          'revieweeName': 'Other Party',
        });
      }
    });

    SocketService().on('counter_bid_accepted', (d) {
      if (!mounted) return;
      _notifs.addNotification(
          title: 'Counter Offer Accepted',
          body: 'Your counter offer was accepted! Job is now active.',
          type: 'offer',
          data: d);
      showSnack(context, 'Counter offer accepted.', ok: true);
      _load();
    });

    SocketService().on('counter_bid_rejected', (d) {
      if (!mounted) return;
      _notifs.addNotification(
          title: 'Counter Offer Rejected',
          body: 'Your counter offer was rejected.',
          type: 'offer',
          data: d);
      showSnack(context, 'Counter offer rejected.', err: true);
    });

    SocketService().on('message_received', (d) {
      if (!mounted) return;
      final senderId = d['senderId'] as int?;
      final message = d['message'] as String? ?? 'You received a message';

      _notifs.addNotification(
          title: 'New Message',
          body:
              message.length > 50 ? '${message.substring(0, 50)}...' : message,
          type: 'chat',
          data: {
            ...d,
            'otherUserId': senderId,
            'otherName': d['senderName'] ?? 'User',
          });
    });

    SocketService().on('job_status_updated', (d) {
      if (!mounted) return;
      _notifs.addNotification(
          title: 'Job Status Updated',
          body: 'Job progress has been updated',
          type: 'status',
          data: d);
    });
  }

  void _showCounterOfferDialog(Map<String, dynamic> data) {
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(children: [
          Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: kPrimaryLime.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.swap_horiz_rounded, color: kBlack)),
          const SizedBox(width: 12),
          const Text('Counter Offer!',
              style: TextStyle(fontWeight: FontWeight.w900)),
        ]),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('$seekerName sent a counter-offer for "$jobTitle"'),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: kPrimaryLime.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: kPrimaryLime.withValues(alpha: 0.5))),
            child: Column(children: [
              Text('Previous: Rs. $previousPrice',
                  style: const TextStyle(
                      decoration: TextDecoration.lineThrough, color: kGrey)),
              const SizedBox(height: 8),
              Text('New Offer: Rs. $newPrice',
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: kBlack)),
            ]),
          ),
          if (data['message'] != null) ...[
            const SizedBox(height: 12),
            Text('Message: "${data['message']}"',
                style: TextStyle(
                    fontStyle: FontStyle.italic, color: Colors.grey.shade600)),
          ],
        ]),
        actions: [
          TextButton(
              onPressed: () async {
                Navigator.pop(ctx);
                try {
                  await _api.rejectCounterBid(jobId, bidId);
                  if (mounted) showSnack(context, 'Counter offer rejected');
                } catch (e) {
                  if (mounted) showSnack(context, e.toString(), err: true);
                }
              },
              child: const Text('Reject', style: TextStyle(color: kRed))),
          ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                try {
                  await _api.acceptCounterBid(jobId, bidId);
                  if (mounted) {
                    showSnack(context, 'Accepted. Tracking started.', ok: true);
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const ActiveJobScreen()));
                  }
                } catch (e) {
                  if (mounted) showSnack(context, e.toString(), err: true);
                }
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: kBlack, foregroundColor: kWhite),
              child: const Text('Accept',
                  style: TextStyle(fontWeight: FontWeight.w800))),
        ],
      ),
    );
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

  @override
  Widget build(BuildContext context) {
    if (_loading && _user == null) {
      return const Scaffold(
          backgroundColor: kBg,
          body: Center(child: CircularProgressIndicator(color: kBlack)));
    }
    return AnimatedBuilder(
      animation: _notifs,
      builder: (context, _) => Scaffold(
        backgroundColor: kBg,
        body: IndexedStack(
          index: _tab,
          children: [
            _isPoster
                ? PosterHomeScreen(user: _user, onRefresh: _load)
                : SeekerHomeScreen(user: _user, onRefresh: _load),
            const ActiveJobScreen(),
            NotificationsScreen(notifs: _notifs),
            const ProfileScreen(),
          ],
        ),
        bottomNavigationBar: _buildNavBar(),
      ),
    );
  }

  Widget _buildNavBar() {
    if (_isPoster) {
      return Stack(clipBehavior: Clip.none, children: [
        Container(
          margin: const EdgeInsets.only(bottom: 16, left: 24, right: 24),
          decoration: BoxDecoration(
            color: kBlack,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 20,
                  offset: const Offset(0, -4))
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.only(
                    top: 10, left: 16, right: 16, bottom: 8),
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _navItem(0, Icons.home_rounded, 'Home'),
                      _navItem(1, Icons.shopping_bag_rounded, 'Active'),
                      const SizedBox(width: 52),
                      _navBadge(
                          2, Icons.notifications_rounded, _notifs.unreadCount),
                      _navItem(3, Icons.person_rounded, 'Profile'),
                    ]),
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 36,
          left: 0,
          right: 0,
          child: Center(
            child: GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/post-job'),
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFFF9F77E),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                        color: const Color(0xFFF9F77E).withValues(alpha: 0.5),
                        blurRadius: 20,
                        offset: const Offset(0, 6))
                  ],
                ),
                child: const Icon(Icons.add_rounded, color: kBlack, size: 30),
              ),
            ),
          ),
        ),
      ]);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16, left: 24, right: 24),
      decoration: BoxDecoration(
        color: kBlack,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 20,
              offset: const Offset(0, -4))
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: SafeArea(
          top: false,
          child: Padding(
            padding:
                const EdgeInsets.only(top: 10, left: 20, right: 20, bottom: 8),
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _navItem(0, Icons.home_rounded, 'Home'),
                  _navItem(1, Icons.shopping_bag_rounded, 'Active'),
                  _navBadge(
                      2, Icons.notifications_rounded, _notifs.unreadCount),
                  _navItem(3, Icons.person_rounded, 'Profile'),
                ]),
          ),
        ),
      ),
    );
  }

  Widget _navItem(int idx, IconData icon, String label) {
    final active = _tab == idx;
    return GestureDetector(
      onTap: () => setState(() => _tab = idx),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon,
              color: active ? const Color(0xFFF9F77E) : Colors.white54,
              size: 26),
          if (active)
            Container(
              margin: const EdgeInsets.only(top: 4),
              width: 4,
              height: 4,
              decoration: const BoxDecoration(
                  color: Color(0xFFF9F77E), shape: BoxShape.circle),
            ),
        ]),
      ),
    );
  }

  Widget _navBadge(int idx, IconData icon, int count) {
    final active = _tab == idx;
    return GestureDetector(
      onTap: () => setState(() => _tab = idx),
      child: Stack(clipBehavior: Clip.none, children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon,
                color: active ? const Color(0xFFF9F77E) : Colors.white54,
                size: 26),
            if (active)
              Container(
                margin: const EdgeInsets.only(top: 4),
                width: 4,
                height: 4,
                decoration: const BoxDecoration(
                    color: Color(0xFFF9F77E), shape: BoxShape.circle),
              ),
          ]),
        ),
        if (count > 0)
          Positioned(
            top: 0,
            right: 4,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: const BoxDecoration(
                  color: Color(0xFFF9F77E), shape: BoxShape.circle),
              constraints: const BoxConstraints(minWidth: 17, minHeight: 17),
              child: Text(count > 99 ? '99+' : '$count',
                  style: const TextStyle(
                      color: kBlack, fontSize: 9, fontWeight: FontWeight.w900),
                  textAlign: TextAlign.center),
            ),
          ),
      ]),
    );
  }
}
