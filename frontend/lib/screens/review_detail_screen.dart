import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

class ReviewDetailScreen extends StatelessWidget {
  final Map<String, dynamic> review;

  const ReviewDetailScreen({super.key, required this.review});

  @override
  Widget build(BuildContext context) {
    final reviewer = review['reviewer'] as Map<String, dynamic>?;
    final reviewerName = (reviewer?['fullName'] ?? 'User').toString();
    final role = (review['revieweeRole'] ?? '').toString().toUpperCase();

    final overall = (review['overallRating'] as num?)?.toInt() ?? 0;
    final quality = (review['workQualityRating'] as num?)?.toInt() ?? 0;
    final behavior = (review['behaviorRating'] as num?)?.toInt() ?? 0;
    final smoothness = (review['smoothnessRating'] as num?)?.toInt() ?? 0;

    final comment = (review['comment'] ?? '').toString().trim();
    final date = (review['createdAt'] ?? '').toString().split('T').first;

    final urls = <String>{};
    final dynamic listUrls = review['imageUrls'];
    if (listUrls is List) {
      for (final u in listUrls) {
        final value = u.toString().trim();
        if (value.isNotEmpty) urls.add(value);
      }
    }
    final before = (review['beforeImageUrl'] ?? '').toString().trim();
    final after = (review['afterImageUrl'] ?? '').toString().trim();
    if (before.isNotEmpty) urls.add(before);
    if (after.isNotEmpty) urls.add(after);
    final images = urls.toList();

    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kBlack,
        title: const Text('Review Detail',
            style: TextStyle(color: kWhite, fontWeight: FontWeight.w800)),
        leading: const BackButton(color: kWhite),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: kWhite,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: kPrimaryLime.withValues(alpha: 0.4)),
              boxShadow: kShadow,
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    color: kPrimaryLime,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      reviewerName.isNotEmpty
                          ? reviewerName[0].toUpperCase()
                          : 'U',
                      style: const TextStyle(
                          color: kBlack,
                          fontSize: 18,
                          fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(reviewerName,
                          style: const TextStyle(
                              color: kBlack,
                              fontSize: 15,
                              fontWeight: FontWeight.w800)),
                      const SizedBox(height: 4),
                      Text('Role: $role',
                          style: const TextStyle(color: kGrey, fontSize: 12)),
                      Text(date,
                          style: const TextStyle(color: kGrey, fontSize: 12)),
                    ],
                  ),
                ),
                buildTag('RATING ${overall > 0 ? overall : '—'}', kPrimaryLime),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _metricCard('Overall', overall),
          const SizedBox(height: 10),
          _metricCard('Work Quality', quality),
          const SizedBox(height: 10),
          _metricCard('Behavior & Communication', behavior),
          const SizedBox(height: 10),
          _metricCard('Smoothness of Process', smoothness),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: kWhite,
              borderRadius: BorderRadius.circular(16),
              boxShadow: kShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Comment',
                    style: TextStyle(
                        color: kBlack,
                        fontSize: 14,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Text(
                  comment.isEmpty ? 'No comment provided.' : comment,
                  style:
                      const TextStyle(color: kGrey, fontSize: 13, height: 1.45),
                ),
              ],
            ),
          ),
          if (images.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: kWhite,
                borderRadius: BorderRadius.circular(16),
                boxShadow: kShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Images',
                      style: TextStyle(
                          color: kBlack,
                          fontSize: 14,
                          fontWeight: FontWeight.w800)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: images
                        .map((url) => ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.network(
                                url,
                                width: 98,
                                height: 98,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  width: 98,
                                  height: 98,
                                  color: kDivider,
                                  child: const Icon(Icons.broken_image_rounded,
                                      color: kGrey),
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _metricCard(String label, int value) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: kWhite,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: kPrimaryLime.withValues(alpha: 0.35)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(label,
                  style: const TextStyle(
                      color: kBlack,
                      fontSize: 13,
                      fontWeight: FontWeight.w700)),
            ),
            Row(
              children: List.generate(
                5,
                (i) => Icon(
                  i < value ? Icons.star_rounded : Icons.star_border_rounded,
                  size: 16,
                  color: i < value ? kBlack : kGrey.withValues(alpha: 0.35),
                ),
              ),
            ),
          ],
        ),
      );
}
