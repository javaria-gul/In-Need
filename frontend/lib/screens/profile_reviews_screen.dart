import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import 'review_detail_screen.dart';

class ProfileReviewsScreen extends StatelessWidget {
  final String role;
  final List<Map<String, dynamic>> reviews;

  const ProfileReviewsScreen({
    super.key,
    required this.role,
    required this.reviews,
  });

  @override
  Widget build(BuildContext context) {
    final roleTitle = role == 'worker' ? 'Worker Reviews' : 'Employer Reviews';

    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kBlack,
        title: Text(roleTitle,
            style: const TextStyle(color: kWhite, fontWeight: FontWeight.w800)),
        leading: const BackButton(color: kWhite),
      ),
      body: reviews.isEmpty
          ? Center(
              child: Container(
                margin: const EdgeInsets.all(20),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: kWhite,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: kShadow,
                ),
                child: const Text('No reviews available for this role.',
                    style: TextStyle(color: kGrey, fontSize: 14)),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: reviews.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, index) {
                final review = reviews[index];
                final reviewer = review['reviewer'] as Map<String, dynamic>?;
                final reviewerName =
                    (reviewer?['fullName'] ?? 'User').toString();
                final rating =
                    (review['overallRating'] as num?)?.toDouble() ?? 0;
                final comment = (review['comment'] ?? '').toString().trim();
                final date =
                    (review['createdAt'] ?? '').toString().split('T').first;

                return GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ReviewDetailScreen(review: review),
                    ),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: kWhite,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: kPrimaryLime.withValues(alpha: 0.38)),
                      boxShadow: kShadow,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
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
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                reviewerName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    color: kBlack,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: List.generate(
                                  5,
                                  (i) => Icon(
                                    i < rating.round()
                                        ? Icons.star_rounded
                                        : Icons.star_border_rounded,
                                    size: 14,
                                    color: i < rating.round()
                                        ? kBlack
                                        : kGrey.withValues(alpha: 0.35),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                comment.isEmpty ? 'No comment' : comment,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    color: kGrey, fontSize: 12, height: 1.35),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              rating > 0 ? rating.toStringAsFixed(1) : '—',
                              style: const TextStyle(
                                  color: kBlack,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 14),
                            ),
                            const SizedBox(height: 4),
                            Text(date,
                                style: const TextStyle(
                                    color: kGrey, fontSize: 10)),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
