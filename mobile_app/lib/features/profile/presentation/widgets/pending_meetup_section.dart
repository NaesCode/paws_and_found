import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';

class PendingMeetupsSection extends StatelessWidget {
  final List<Map<String, dynamic>> meetups;

  const PendingMeetupsSection({super.key, required this.meetups});

  @override
  Widget build(BuildContext context) {
    if (meetups.isEmpty) return const SizedBox.shrink();

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.handshake_outlined,
                size: 18,
                color: AppColors.primary,
              ),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  'Pending Meetups & Claims',
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
                  color: AppColors.accentOrange.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${meetups.length}',
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: AppColors.accentOrange,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...meetups.map((item) => _PendingMeetupCard(item: item)),
        ],
      ),
    );
  }
}

class _PendingMeetupCard extends StatelessWidget {
  final Map<String, dynamic> item;

  const _PendingMeetupCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final reportId = item['reportId']?.toString() ?? '';
    final petTitle = item['petTitle']?.toString() ?? 'Pet Claim';
    final photoUrl = item['photoUrl']?.toString() ?? '';
    final otherPartyName = item['otherPartyName']?.toString() ?? 'Member';
    final isFinder = item['isFinder'] == true;
    final currentStage = (item['currentStage'] as num?)?.toInt() ?? 1;
    final meetupPlace = item['meetupPlace']?.toString();
    final meetupTime = item['meetupTime']?.toString();
    final meetupAgreed = item['meetupAgreed'] == true;
    final myHandoverConfirmed = item['myHandoverConfirmed'] == true;

    String statusLabel;
    Color statusColor;
    if (currentStage < 3) {
      statusLabel = currentStage == 1
          ? 'STAGE 1 • AGREEMENT'
          : 'STAGE 2 • VERIFICATION';
      statusColor = AppColors.accentOrange;
    } else if (myHandoverConfirmed) {
      statusLabel = 'AWAITING HANDOVER CONFIRM';
      statusColor = AppColors.primary;
    } else if (meetupAgreed) {
      statusLabel = 'MEETUP AGREED';
      statusColor = AppColors.primary;
    } else if (meetupPlace != null && meetupPlace.isNotEmpty) {
      statusLabel = 'SPOT PROPOSED';
      statusColor = AppColors.accentOrange;
    } else {
      statusLabel = 'STAGE 3 • SET MEETUP';
      statusColor = AppColors.accentOrange;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
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
                  width: 54,
                  height: 54,
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

              // Meetup Details
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
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            statusLabel,
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold,
                              color: statusColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      isFinder
                          ? 'Claimant: $otherPartyName'
                          : 'Finder: $otherPartyName',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.text2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          meetupPlace != null && meetupPlace.isNotEmpty
                              ? Icons.location_on_outlined
                              : Icons.schedule_outlined,
                          size: 13.5,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            meetupPlace != null && meetupPlace.isNotEmpty
                                ? '$meetupPlace${meetupTime != null && meetupTime.isNotEmpty ? ' • $meetupTime' : ''}'
                                : 'Tap to complete recovery steps',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                              color: AppColors.darkCharcoal,
                            ),
                          ),
                        ),
                      ],
                    ),
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
      child: const Icon(Icons.pets, color: AppColors.primary, size: 24),
    );
  }
}
