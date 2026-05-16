import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';
import '../models/job_model.dart';
import '../utils/app_theme.dart';

class JobFeedScreen extends StatefulWidget {
  const JobFeedScreen({super.key});
  @override
  State<JobFeedScreen> createState() => _JobFeedScreenState();
}

class _JobFeedScreenState extends State<JobFeedScreen> {
  final _api = ApiService();
  List<JobModel> _jobs = [];
  bool _loading = true;
  int _idx = 0; // current card index

  @override
  void initState() {
    super.initState();
    _load();
    _listenSocket();
  }

  void _listenSocket() {
    SocketService().on('new_job_card', (d) {
      try {
        final job = JobModel.fromJson(d);
        if (mounted) setState(() => _jobs.insert(0, job));
      } catch (_) {}
    });
  }

  @override
  void dispose() {
    SocketService().off('new_job_card');
    super.dispose();
  }

  Future<void> _load() async {
    try {
      setState(() => _loading = true);
      final raw = await _api.getJobFeed();
      if (mounted) {
        setState(() {
          _jobs = raw.map((j) => JobModel.fromJson(j)).toList();
          _idx = 0;
        });
      }
    } catch (e) {
      if (mounted) showSnack(context, e.toString(), err: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _reject() async {
    if (_idx >= _jobs.length) return;
    final job = _jobs[_idx];
    try {
      await _api.rejectJob(job.id);
    } catch (_) {}
    setState(() => _idx++);
  }

  Color _getJobCardColor(int index) {
    return kJobCardColors[index % kJobCardColors.length];
  }

  void _showBidSheet(JobModel job) {
    final priceCtrl = TextEditingController(text: job.price.toStringAsFixed(0));
    final msgCtrl = TextEditingController();
    bool submitting = false;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
          builder: (ctx, setBS) => Container(
                margin: const EdgeInsets.all(16),
                padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                    left: 20,
                    right: 20,
                    top: 20),
                decoration: BoxDecoration(
                    color: kWhite, borderRadius: BorderRadius.circular(24)),
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Handle
                      Center(
                          child: Container(
                              width: 40,
                              height: 4,
                              decoration: BoxDecoration(
                                  color: kDivider,
                                  borderRadius: BorderRadius.circular(2)))),
                      const SizedBox(height: 16),
                      Text('Counter Offer',
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: kBlack)),
                      const SizedBox(height: 4),
                      Text(
                          'Original: Rs. ${job.price.toStringAsFixed(0)} ${job.pricingType == "hourly" ? "/ hr" : "fixed"}',
                          style: const TextStyle(color: kGrey, fontSize: 13)),
                      const SizedBox(height: 16),
                      TextFormField(
                          controller: priceCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                              labelText: 'Your Price (Rs.)',
                              prefixIcon: Icon(Icons.money_rounded))),
                      const SizedBox(height: 12),
                      TextFormField(
                          controller: msgCtrl,
                          maxLines: 2,
                          decoration: const InputDecoration(
                              labelText: 'Message (optional)',
                              prefixIcon: Icon(Icons.message_outlined))),
                      const SizedBox(height: 20),
                      GradBtn(
                        text: submitting ? 'Sending…' : 'SEND BID',
                        loading: submitting,
                        gradient: kBlueGrad,
                        foreColor: kWhite,
                        onTap: () async {
                          final price = double.tryParse(priceCtrl.text);
                          if (price == null || price <= 0) {
                            showSnack(context, 'Enter valid price', err: true);
                            return;
                          }
                          setBS(() => submitting = true);
                          try {
                            await _api.placeBid(job.id, price,
                                message: msgCtrl.text.trim().isEmpty
                                    ? null
                                    : msgCtrl.text.trim());
                            if (mounted) {
                              Navigator.pop(ctx);
                            }
                            if (mounted && context.mounted) {
                              showSnack(
                                  context, 'Bid sent! Waiting for poster.',
                                  ok: true);
                              setState(() => _idx++);
                            }
                          } catch (e) {
                            if (mounted) {
                              showSnack(context, e.toString(), err: true);
                            }
                          } finally {
                            setBS(() => submitting = false);
                          }
                        },
                      ),
                    ]),
              )),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: kBg,
        appBar: AppBar(
          title: const Text('Job Cards'),
          leading: const BackButton(color: kWhite),
          actions: [
            IconButton(
                icon: const Icon(Icons.refresh_rounded, color: kWhite),
                onPressed: _load)
          ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator(color: kBlue))
            : _idx >= _jobs.length
                ? _emptyState()
                : Column(children: [
                    Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        child: Row(children: [
                          Text('${_jobs.length - _idx} jobs for you',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700, color: kGrey)),
                          const Spacer(),
                          Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                  color: kBlue.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(20)),
                              child: Text('Swipe right to bid',
                                  style: TextStyle(
                                      color: kBlue,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700))),
                        ])),
                    Expanded(child: _cardStack()),
                    _actionButtons(),
                  ]),
      );

  Widget _cardStack() {
    final visible = <Widget>[];
    for (int i = (_idx + 2).clamp(0, _jobs.length - 1); i >= _idx; i--) {
      final offset = i - _idx;
      final color = _getJobCardColor(i);
      visible.add(Positioned(
        top: offset * 8.0,
        left: offset * 6.0,
        right: offset * 6.0,
        child: _jobCard(_jobs[i], color, isTop: i == _idx),
      ));
    }
    return Stack(alignment: Alignment.center, children: visible);
  }

  Widget _jobCard(JobModel job, Color color, {required bool isTop}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: MediaQuery.of(context).size.height * 0.48,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: color.withValues(alpha: 0.35),
              blurRadius: 24,
              offset: const Offset(0, 10))
        ],
      ),
      child: Padding(
          padding: const EdgeInsets.all(24),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Header row
            Row(children: [
              Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20)),
                  child: Text(job.urgency.toUpperCase(),
                      style: const TextStyle(
                          color: kWhite,
                          fontSize: 10,
                          fontWeight: FontWeight.w800))),
              const Spacer(),
              if (job.skillRequired != null)
                Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20)),
                    child: Text(job.skillRequired!,
                        style: const TextStyle(
                            color: kWhite,
                            fontSize: 10,
                            fontWeight: FontWeight.w800))),
            ]),
            const SizedBox(height: 16),
            Text(job.title,
                style: const TextStyle(
                    color: kWhite,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    height: 1.2)),
            const SizedBox(height: 10),
            Text(job.description,
                style: TextStyle(
                    color: kWhite.withValues(alpha: 0.85),
                    fontSize: 13,
                    height: 1.6),
                maxLines: 3,
                overflow: TextOverflow.ellipsis),
            const Spacer(),
            Divider(color: kWhite.withValues(alpha: 0.25)),
            const SizedBox(height: 8),
            // Price
            Row(children: [
              const Icon(Icons.monetization_on_rounded,
                  color: kWhite, size: 20),
              const SizedBox(width: 8),
              Text(
                  'Rs. ${job.price.toStringAsFixed(0)}${job.pricingType == "hourly" ? " / hr" : " fixed"}',
                  style: const TextStyle(
                      color: kWhite,
                      fontWeight: FontWeight.w900,
                      fontSize: 18)),
            ]),
            const SizedBox(height: 6),
            // Location
            Row(children: [
              Icon(
                  job.isRemote ? Icons.wifi_rounded : Icons.location_on_rounded,
                  color: kWhite.withValues(alpha: 0.8),
                  size: 15),
              const SizedBox(width: 6),
              Expanded(
                  child: Text(
                      job.isRemote
                          ? 'Remote / No travel required'
                          : (job.locationAddress ?? 'On-site'),
                      style: TextStyle(
                          color: kWhite.withValues(alpha: 0.8), fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis)),
            ]),
            if (job.estimatedHours != null) ...[
              const SizedBox(height: 4),
              Row(children: [
                Icon(Icons.timer_outlined,
                    color: kWhite.withValues(alpha: 0.8), size: 15),
                const SizedBox(width: 6),
                Text('~${job.estimatedHours} hours',
                    style: TextStyle(
                        color: kWhite.withValues(alpha: 0.8), fontSize: 12)),
              ]),
            ],
          ])),
    );
  }

  Widget _actionButtons() => SafeArea(
      child: Padding(
          padding: const EdgeInsets.fromLTRB(40, 8, 40, 16),
          child:
              Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            _actionBtn(Icons.close_rounded, kRed, 'Skip', _reject),
            _actionBtn(Icons.check_rounded, kGreen, 'Bid',
                () => _showBidSheet(_jobs[_idx]),
                large: true),
          ])));

  Widget _actionBtn(
      IconData icon, Color color, String label, VoidCallback onTap,
      {bool large = false}) {
    final size = large ? 70.0 : 56.0;
    return GestureDetector(
        onTap: onTap,
        child: Column(children: [
          Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: kWhite,
                  boxShadow: [
                    BoxShadow(
                        color: color.withValues(alpha: 0.25),
                        blurRadius: 16,
                        offset: const Offset(0, 4))
                  ]),
              child: Icon(icon, color: color, size: large ? 34 : 26)),
          const SizedBox(height: 6),
          Text(label,
              style: TextStyle(
                  color: color, fontSize: 12, fontWeight: FontWeight.w700)),
        ]));
  }

  Widget _emptyState() => Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: kBg,
                border: Border.all(color: kDivider, width: 2)),
            child: const Icon(Icons.style_rounded, size: 44, color: kGrey)),
        const SizedBox(height: 20),
        const Text('No More Jobs',
            style: TextStyle(
                fontWeight: FontWeight.w900, fontSize: 20, color: kBlack)),
        const SizedBox(height: 8),
        const Text('Check back soon for new opportunities.',
            textAlign: TextAlign.center,
            style: TextStyle(color: kGrey, fontSize: 13)),
        const SizedBox(height: 24),
        GestureDetector(
            onTap: _load,
            child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                    gradient: kBlueGrad,
                    borderRadius: BorderRadius.circular(12)),
                child: const Text('Refresh',
                    style: TextStyle(
                        color: kWhite, fontWeight: FontWeight.w800)))),
      ]));
}
