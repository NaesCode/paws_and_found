import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';

class ReunionHistorySection extends StatelessWidget {
  final List<dynamic> history;

  const ReunionHistorySection({super.key, required this.history});

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) return const SizedBox.shrink();

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(
                Icons.verified_rounded,
                size: 18,
                color: AppColors.primary,
              ),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  'Reunion History',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkCharcoal,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${history.length}',
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...history.map((item) => _ReunionHistoryCard(item: item)),
        ],
      ),
    );
  }
}

class _ReunionHistoryCard extends StatelessWidget {
  final Map<String, dynamic> item;

  const _ReunionHistoryCard({required this.item});

  String _formatCompletedDate(String? rawIso) {
    if (rawIso == null || rawIso.isEmpty) return '';
    final parsed = DateTime.tryParse(rawIso)?.toLocal();
    if (parsed == null) return '';
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[parsed.month - 1]} ${parsed.day}, ${parsed.year}';
  }

  @override
  Widget build(BuildContext context) {
    final reportId = item['reportId']?.toString() ?? '';
    final petTitle = item['petTitle']?.toString() ?? 'Reunited Pet';
    final photoUrl = item['photoUrl']?.toString() ?? '';
    final otherPartyName = item['otherPartyName']?.toString() ?? 'Member';
    final isFinder = item['isFinder'] == true;
    final meetupPlace = item['meetupPlace']?.toString();
    final completedDate = _formatCompletedDate(item['updatedAt']?.toString());

    final badgeText = isFinder ? 'RETURNED' : 'CLAIMED';
    final subtitleText = isFinder
        ? 'Returned to $otherPartyName'
        : 'Claimed from $otherPartyName';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: reportId.isEmpty
            ? null
            : () => context.push('/claim?reportId=$reportId'),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Pet Thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 50,
                  height: 50,
                  child: photoUrl.isNotEmpty
                      ? Image.network(
                          photoUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => _fallbackAvatar(),
                        )
                      : _fallbackAvatar(),
                ),
              ),
              const SizedBox(width: 12),

              // History Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            petTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.darkCharcoal,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.check_circle,
                                size: 11,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                badgeText,
                                style: const TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitleText,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.text2,
                      ),
                    ),
                    if ((meetupPlace != null && meetupPlace.isNotEmpty) ||
                        completedDate.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        [
                          if (meetupPlace != null && meetupPlace.isNotEmpty)
                            meetupPlace,
                          if (completedDate.isNotEmpty) completedDate,
                        ].join(' • '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.text3,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.chevron_right_rounded, color: AppColors.text3),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fallbackAvatar() {
    return Container(
      color: AppColors.primary.withValues(alpha: 0.12),
      child: const Icon(Icons.pets, color: AppColors.primary, size: 22),
    );
  }
}
