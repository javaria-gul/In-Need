import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../utils/app_theme.dart';

class ReviewScreen extends StatefulWidget {
  final int jobId;
  final int revieweeId;
  final String revieweeName;
  const ReviewScreen({
    super.key,
    required this.jobId,
    required this.revieweeId,
    required this.revieweeName,
  });
  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  final _api = ApiService();
  final _commentCtrl = TextEditingController();
  bool _loading = false;

  int _overall = 0;
  int _quality = 0;
  int _behavior = 0;
  int _smoothness = 0;

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_overall == 0) {
      showSnack(context, 'Please give an overall rating', err: true);
      return;
    }
    setState(() => _loading = true);
    try {
      await _api.submitReview({
        'jobId': widget.jobId,
        'overallRating': _overall,
        if (_quality > 0) 'workQualityRating': _quality,
        if (_behavior > 0) 'behaviorRating': _behavior,
        if (_smoothness > 0) 'smoothnessRating': _smoothness,
        if (_commentCtrl.text.trim().isNotEmpty)
          'comment': _commentCtrl.text.trim(),
      });
      if (mounted) {
        showSnack(context, 'Review submitted! Thank you.', ok: true);
        Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (_) => false);
      }
    } catch (e) {
      if (mounted) showSnack(context, e.toString(), err: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
        canPop: false,
        child: Scaffold(
          backgroundColor: kBg,
          appBar: AppBar(
            automaticallyImplyLeading: false,
            title: const Text('Submit Review'),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: buildTag('MANDATORY', kRed),
              )
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(children: [
              // Info banner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: kBlue.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: kBlue.withValues(alpha: 0.2)),
                ),
                child: Row(children: [
                  const Icon(Icons.info_outline_rounded,
                      color: kBlue, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Job complete! You must review ${widget.revieweeName} before continuing.',
                      style: const TextStyle(
                          color: kBlue, fontSize: 13, height: 1.4),
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 28),

              // Reviewee card
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: kWhite,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: kShadow,
                ),
                child: Row(children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                        gradient: kBlueGrad, shape: BoxShape.circle),
                    child: Center(
                      child: Text(
                        widget.revieweeName[0].toUpperCase(),
                        style: const TextStyle(
                            color: kWhite,
                            fontSize: 22,
                            fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Reviewing',
                          style: TextStyle(
                              color: kGrey,
                              fontSize: 11,
                              fontWeight: FontWeight.w600)),
                      Text(widget.revieweeName,
                          style: const TextStyle(
                              color: kBlack,
                              fontSize: 16,
                              fontWeight: FontWeight.w800)),
                    ],
                  ),
                ]),
              ),
              const SizedBox(height: 24),

              // Rating sections
              _ratingSection('⭐ Overall Rating *', _overall,
                  (v) => setState(() => _overall = v),
                  size: 44, required: true),
              const SizedBox(height: 20),
              _ratingSection('🔨 Work Quality', _quality,
                  (v) => setState(() => _quality = v)),
              const SizedBox(height: 20),
              _ratingSection('🤝 Behavior & Communication', _behavior,
                  (v) => setState(() => _behavior = v)),
              const SizedBox(height: 20),
              _ratingSection('✅ Smoothness of Process', _smoothness,
                  (v) => setState(() => _smoothness = v)),
              const SizedBox(height: 24),

              // Comment box
              TextFormField(
                controller: _commentCtrl,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Comment (optional)',
                  alignLabelWithHint: true,
                  prefixIcon: Icon(Icons.comment_outlined),
                ),
              ),
              const SizedBox(height: 24),

              // Blockchain badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: Colors.green.withValues(alpha: 0.3)),
                ),
                child: const Row(children: [
                  Icon(Icons.verified_outlined, color: Colors.green, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This review will be secured by Blockchain — it cannot be changed once submitted.',
                      style: TextStyle(
                          color: Colors.green, fontSize: 12, height: 1.4),
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 24),

              GradBtn(
                text: 'SUBMIT REVIEW',
                loading: _loading,
                onTap: _submit,
                gradient: const LinearGradient(colors: [kGreen, kTealGreen]),
              ),
              const SizedBox(height: 16),
              const Text('You cannot skip this step.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: kGrey, fontSize: 11)),
              const SizedBox(height: 30),
            ]),
          ),
        ),
      );

  Widget _ratingSection(
    String label,
    int current,
    ValueChanged<int> onTap, {
    double size = 36,
    bool required = false,
  }) =>
      Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: kWhite,
          borderRadius: BorderRadius.circular(16),
          boxShadow: kShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                    fontWeight: FontWeight.w800, fontSize: 14, color: kBlack)),
            const SizedBox(height: 12),
            Row(
              children: List.generate(
                5,
                (i) => GestureDetector(
                  onTap: () => onTap(i + 1),
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Icon(
                      i < current
                          ? Icons.star_rounded
                          : Icons.star_border_rounded,
                      color: i < current
                          ? Colors.amber.shade500
                          : kGrey.withValues(alpha: 0.3),
                      size: size,
                    ),
                  ),
                ),
              ),
            ),
            if (current > 0) ...[
              const SizedBox(height: 8),
              Text(
                [
                  '',
                  'Very Poor',
                  'Poor',
                  'Average',
                  'Good',
                  'Excellent'
                ][current],
                style: TextStyle(
                    color: Colors.amber.shade700,
                    fontSize: 12,
                    fontWeight: FontWeight.w700),
              ),
            ],
          ],
        ),
      );
}
