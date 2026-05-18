import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';
import '../utils/app_theme.dart';

class BidModel {
  final int id;
  final int jobId;
  final int seekerId;
  final double offeredPrice;
  final String? message;
  final String status;
  final Map<String, dynamic>? seeker;
  final bool isCounterOffer;
  final double? previousPrice;

  BidModel({
    required this.id,
    required this.jobId,
    required this.seekerId,
    required this.offeredPrice,
    this.message,
    required this.status,
    this.seeker,
    this.isCounterOffer = false,
    this.previousPrice,
  });

  factory BidModel.fromJson(Map<String, dynamic> json) {
    return BidModel(
      id: json['id'],
      jobId: json['jobId'],
      seekerId: json['seekerId'],
      offeredPrice: (json['offeredPrice'] as num).toDouble(),
      message: json['message'],
      status: json['status'],
      seeker: json['seeker'],
      isCounterOffer: json['isCounterOffer'] ?? false,
      previousPrice: json['previousPrice'] != null
          ? (json['previousPrice'] as num).toDouble()
          : null,
    );
  }
}

class BidsScreen extends StatefulWidget {
  final int jobId;
  const BidsScreen({super.key, required this.jobId});

  @override
  State<BidsScreen> createState() => _BidsScreenState();
}

class _BidsScreenState extends State<BidsScreen> {
  final _api = ApiService();
  List<BidModel> _bids = [];
  Map<String, dynamic>? _job;
  bool _loading = true;
  int? _accepting;

  static const Color _yellow = Color(0xFFF9F77E);

  @override
  void initState() {
    super.initState();
    _load();
    SocketService().on('new_bid', _handleNewBidEvent);
    SocketService().on('bid_updated', _handleBidUpdatedEvent);
  }

  @override
  void dispose() {
    SocketService().off('new_bid');
    SocketService().off('bid_updated');
    super.dispose();
  }

  void _handleNewBidEvent(Map<String, dynamic> data) {
    final eventJobId = data['jobId'];
    if (eventJobId == widget.jobId && mounted) {
      showSnack(context, 'New bid received! Refreshing...', ok: true);
      _load();
    }
  }

  void _handleBidUpdatedEvent(Map<String, dynamic> data) {
    final eventJobId = data['jobId'];
    if (eventJobId == widget.jobId && mounted) {
      showSnack(context, 'Counter offer received. Check updated price.',
          ok: true);
      _load();
    }
  }

  Future<void> _load() async {
    try {
      setState(() => _loading = true);
      final results = await Future.wait([
        _api.getJob(widget.jobId),
        _api.getBidsForJob(widget.jobId),
      ]);
      if (mounted) {
        setState(() {
          _job = results[0] as Map<String, dynamic>;
          _bids =
              (results[1] as List).map((b) => BidModel.fromJson(b)).toList();
        });
      }
    } catch (e) {
      if (mounted) {
        showSnack(context, e.toString(), err: true);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _accept(BidModel bid) async {
    setState(() => _accepting = bid.id);
    try {
      await _api.acceptBid(widget.jobId, bid.id);
      if (mounted) {
        showSnack(context, 'Bid accepted! Job is now ACTIVE ✓', ok: true);
        Navigator.pushReplacementNamed(context, '/active-job');
      }
    } catch (e) {
      if (mounted) showSnack(context, e.toString(), err: true);
    } finally {
      if (mounted) setState(() => _accepting = null);
    }
  }

  void _viewProfile(BidModel bid) {
    final seeker = bid.seeker ?? {};
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: _yellow,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: kBlack, width: 1.3),
          boxShadow: kShadow,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: kBlack,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: kBlack,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      ((seeker['fullName'] as String?) ?? ' ')[0].toUpperCase(),
                      style: const TextStyle(
                        color: kWhite,
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        seeker['fullName'] ?? 'Unknown',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: kBlack,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.star_rounded,
                            size: 15,
                            color: Colors.amber.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${(seeker['workerRating'] ?? 0).toStringAsFixed(1)} (${seeker['workerRatingCount'] ?? 0} reviews)',
                            style: const TextStyle(color: kBlack, fontSize: 12),
                          ),
                        ],
                      ),
                      if (seeker['city'] != null)
                        Text(
                          '📍 ${seeker['city']}',
                          style: const TextStyle(color: kBlack, fontSize: 12),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            if ((seeker['skills'] as String?)?.isNotEmpty == true) ...[
              const SizedBox(height: 16),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Skills',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: kBlack,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: (seeker['skills'] as String)
                      .split(',')
                      .map((s) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: kBlack,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              s.trim(),
                              style: const TextStyle(
                                color: _yellow,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ))
                      .toList(),
                ),
              ),
            ],
            const SizedBox(height: 20),
            GradBtn(
              text:
                  'ACCEPT THIS BID — Rs. ${bid.offeredPrice.toStringAsFixed(0)}',
              gradient: kValidationGrad,
              onTap: () {
                Navigator.pop(context);
                _accept(bid);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: kBg,
        appBar: AppBar(
          title: Text('Bids (${_bids.length})'),
          leading: const BackButton(color: kWhite),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: kWhite),
              onPressed: _load,
            ),
          ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator(color: kBlack))
            : Column(
                children: [
                  if (_job != null) _jobHeader(),
                  Expanded(
                    child: _bids.isEmpty ? _emptyState() : _bidsList(),
                  ),
                ],
              ),
      );

  Widget _jobHeader() => Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _yellow,
          borderRadius: BorderRadius.circular(18),
          boxShadow: kShadow,
          border: Border.all(color: kBlack, width: 1.3),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: kBlack,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.work_rounded, color: _yellow),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _job!['title'] ?? '',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: kBlack,
                    ),
                  ),
                  Text(
                    'Rs. ${(_job!['price'] as num?)?.toStringAsFixed(0) ?? '0'} · ${_job!['pricingType'] ?? 'fixed'}',
                    style: const TextStyle(color: kBlack, fontSize: 12),
                  ),
                ],
              ),
            ),
            buildTag(
              (_job!['status'] ?? 'open').toString().toUpperCase(),
              kBlack,
            ),
          ],
        ),
      );

  Widget _bidsList() => RefreshIndicator(
        onRefresh: _load,
        color: kBlack,
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: _bids.length,
          itemBuilder: (_, i) => _bidCard(_bids[i]),
        ),
      );

  Widget _bidCard(BidModel bid) {
    final seeker = bid.seeker ?? {};
    final name = (seeker['fullName'] as String?) ?? 'Worker';
    final rating = (seeker['workerRating'] as num?)?.toDouble() ?? 0;
    final initial = name[0].toUpperCase();
    final isCounterOffer = bid.isCounterOffer ||
        (bid.previousPrice != null && bid.previousPrice != bid.offeredPrice);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _yellow,
        borderRadius: BorderRadius.circular(18),
        boxShadow: kShadow,
        border: Border.all(color: kBlack, width: 1.3),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: kBlack,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      initial,
                      style: const TextStyle(
                        color: _yellow,
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                              color: kBlack,
                            ),
                          ),
                          if (isCounterOffer) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: kBlack,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'COUNTER',
                                style: TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w800,
                                  color: _yellow,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      Row(
                        children: [
                          Icon(
                            Icons.star_rounded,
                            size: 13,
                            color: kBlack,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            rating.toStringAsFixed(1),
                            style: const TextStyle(color: kBlack, fontSize: 11),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (bid.previousPrice != null &&
                        bid.previousPrice != bid.offeredPrice)
                      Text(
                        'Rs. ${bid.previousPrice!.toStringAsFixed(0)}',
                        style: const TextStyle(
                          decoration: TextDecoration.lineThrough,
                          color: kBlack,
                          fontSize: 11,
                        ),
                      ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: kBlack,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Rs. ${bid.offeredPrice.toStringAsFixed(0)}',
                        style: const TextStyle(
                          color: _yellow,
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (bid.message?.isNotEmpty == true)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: kWhite,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: kBlack.withValues(alpha: 0.55)),
                ),
                child: Text(
                  '"${bid.message}"',
                  style: const TextStyle(
                    color: kBlack,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Row(
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.person_search_rounded, size: 16),
                  label: const Text('View Profile'),
                  onPressed: () => _viewProfile(bid),
                  style: TextButton.styleFrom(foregroundColor: kBlack),
                ),
                const Spacer(),
                SizedBox(
                  height: 36,
                  child: ElevatedButton(
                    onPressed: _accepting == bid.id ? null : () => _accept(bid),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kBlack,
                      minimumSize: Size.zero,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: _accepting == bid.id
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              color: _yellow,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            isCounterOffer ? 'Accept New Price' : 'Accept',
                            style: const TextStyle(
                                fontWeight: FontWeight.w800, color: _yellow),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.inbox_outlined, size: 64, color: kBlack),
            const SizedBox(height: 16),
            const Text(
              'No Bids Yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: kBlack,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Workers will see your job card soon.',
              style: TextStyle(color: kBlack, fontSize: 13),
            ),
          ],
        ),
      );
}
