import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../utils/app_theme.dart';

class ActiveJobScreen extends StatefulWidget {
  const ActiveJobScreen({super.key});

  @override
  State<ActiveJobScreen> createState() => _ActiveJobScreenState();
}

class _ActiveJobScreenState extends State<ActiveJobScreen> {
  final _api = ApiService();
  bool _loading = true;
  bool _completing = false;
  Map<String, dynamic>? _job;
  String _role = 'worker';
  String? _userId;

  @override
  void initState() {
    super.initState();
    _loadActiveJob();
  }

  Future<void> _loadActiveJob() async {
    try {
      if (mounted) setState(() => _loading = true);
      final user = await _api.getMe();
      _role = user['activeRole']?.toString() ??
          await StorageService.getActiveRole();
      _userId = await StorageService.getUserId();

      if (_role == 'worker') {
        _job = await _api.getActiveJob();
      } else {
        final jobs = await _api.getMyJobs();
        final activeJobs = jobs.cast<Map<String, dynamic>>().where((j) {
          final status = (j['status'] as String?)?.toLowerCase();
          return status == 'active' ||
              status == 'accepted' ||
              status == 'in_progress' ||
              j['acceptedSeekerId'] != null;
        }).toList();
        _job = activeJobs.isEmpty ? null : activeJobs.first;
      }
    } catch (e) {
      if (mounted) showSnack(context, e.toString(), err: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  int? get _currentUserId => int.tryParse(_userId ?? '');

  int? get _revieweeId {
    if (_job == null || _currentUserId == null) return null;
    final posterId = _job!['posterId'] as int?;
    final acceptedSeekerId = _job!['acceptedSeekerId'] as int?;
    if (posterId == null || acceptedSeekerId == null) return null;
    return _currentUserId == posterId ? acceptedSeekerId : posterId;
  }

  String get _otherPartyLabel {
    if (_role == 'worker') return 'Poster';
    return 'Worker';
  }

  Future<void> _completeJob() async {
    if (_job == null) return;
    try {
      setState(() => _completing = true);
      await _api.completeJob(_job!['id'] as int);
      if (mounted)
        showSnack(context, 'Job marked complete. Review flow started.',
            ok: true);
      if (_revieweeId != null) {
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/review', arguments: {
            'jobId': _job!['id'],
            'revieweeId': _revieweeId,
            'revieweeName': 'Other Party',
          });
        }
        return;
      }
      if (mounted) Navigator.pushReplacementNamed(context, '/dashboard');
    } catch (e) {
      if (mounted) showSnack(context, e.toString(), err: true);
    } finally {
      if (mounted) setState(() => _completing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        title: const Text('Active Job'),
        leading: const BackButton(color: kWhite),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: kBlue))
          : Padding(
              padding: const EdgeInsets.all(20),
              child: _job == null
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.work_outline,
                              size: 60, color: kGrey),
                          const SizedBox(height: 18),
                          Text(
                            'No active job found.',
                            style: TextStyle(
                                color: kBlack.withValues(alpha: 0.85),
                                fontSize: 18,
                                fontWeight: FontWeight.w700),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Once a bid is accepted, you will see your active job here and can mark it complete to open the review screen.',
                            style: const TextStyle(
                                color: kGrey, fontSize: 13, height: 1.5),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: kWhite,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: kShadow,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_job!['title'] ?? 'Untitled Job',
                                  style: const TextStyle(
                                      color: kBlack,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w900)),
                              const SizedBox(height: 10),
                              Text(_job!['description'] ?? '',
                                  style: const TextStyle(
                                      color: kGrey, fontSize: 13, height: 1.6)),
                              const SizedBox(height: 16),
                              Row(children: [
                                const Icon(Icons.monetization_on_rounded,
                                    color: kBlue, size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  'Rs. ${(_job!['price'] as num?)?.toStringAsFixed(0) ?? '0'}',
                                  style: const TextStyle(
                                      color: kBlack,
                                      fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(width: 16),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: kBlue.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    (_job!['pricingType'] as String?) ==
                                            'hourly'
                                        ? 'Hourly'
                                        : 'Fixed',
                                    style: const TextStyle(
                                        color: kBlue,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700),
                                  ),
                                ),
                              ]),
                              const SizedBox(height: 12),
                              Row(children: [
                                const Icon(Icons.flag_rounded,
                                    color: kPurple, size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  'Urgency: ${(_job!['urgency'] as String?)?.toUpperCase() ?? 'FLEXIBLE'}',
                                  style: const TextStyle(
                                      color: kGrey, fontSize: 12),
                                ),
                              ]),
                              const SizedBox(height: 12),
                              if (_job!['locationAddress'] != null)
                                Row(children: [
                                  const Icon(Icons.location_on_rounded,
                                      color: kGreen, size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _job!['locationAddress'] as String,
                                      style: const TextStyle(
                                          color: kGrey, fontSize: 12),
                                    ),
                                  ),
                                ]),
                              const SizedBox(height: 18),
                              Text('Status: ACTIVE',
                                  style: const TextStyle(
                                      color: kGreen,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700)),
                              const SizedBox(height: 10),
                              Text('Review target: $_otherPartyLabel',
                                  style: const TextStyle(
                                      color: kBlack,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700)),
                              if (_job!['acceptedSeekerId'] != null ||
                                  _job!['posterId'] != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    'Job ID: ${_job!['id']} · Poster: ${_job!['poster'] != null ? _job!['poster']['fullName'] : 'N/A'}',
                                    style: const TextStyle(
                                        color: kGrey, fontSize: 12),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: GradBtn(
                                text:
                                    'CHAT WITH ${_otherPartyLabel.toUpperCase()}',
                                loading: false,
                                onTap: () {
                                  if (_job != null && _revieweeId != null) {
                                    Navigator.pushNamed(context, '/chat',
                                        arguments: {
                                          'jobId': _job!['id'],
                                          'otherUserId': _revieweeId,
                                          'otherName': _otherPartyLabel,
                                        });
                                  }
                                },
                                gradient: kBlueGrad,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: GradBtn(
                                text: 'MARK JOB COMPLETE',
                                loading: _completing,
                                onTap: _completeJob,
                                gradient: kGreenGrad,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
            ),
    );
  }
}
