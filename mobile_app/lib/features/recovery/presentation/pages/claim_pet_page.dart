import 'package:flutter/material.dart';
import 'package:paws_and_found/core/theme/app_colors.dart';
import 'package:paws_and_found/features/feed/data/models/feed_post_model.dart';
import 'package:paws_and_found/features/feed/data/repositories/feed_repository_impl.dart';
import '../widgets/recovery_stepper_header.dart';
import '../widgets/claimant_selector_bar.dart';
import '../widgets/stage1_agreement_widget.dart';
import '../widgets/stage2_verification_widget.dart';
import '../widgets/stage3_meetup_widget.dart';
import '../widgets/popups/handover_confirm_dialog.dart';
import '../../data/repositories/recovery_repository_impl.dart';
import '../../data/models/recovery_claim_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

typedef ActiveClaimProgress = Map<String, dynamic>;

class ClaimPetPage extends StatefulWidget {
  final String reportId;
  final FeedPost? report;

  const ClaimPetPage({
    super.key,
    required this.reportId,
    this.report,
  });

  @override
  State<ClaimPetPage> createState() => _ClaimPetPageState();
}

class _ClaimPetPageState extends State<ClaimPetPage> {
  final ClaimRepository _repository = ClaimRepository();
  int? _viewingStage;
  int _selectedClaimantIndex = 0;
  late Future<FeedPost?> _reportFuture;

  String get _currentUserId => Supabase.instance.client.auth.currentUser?.id ?? '';

  @override
  void initState() {
    super.initState();
    _reportFuture = widget.report != null
        ? Future.value(widget.report)
        : FeedRepositoryImpl().getReportById(widget.reportId);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<FeedPost?>(
      future: _reportFuture,
      builder: (context, reportSnapshot) {
        if (reportSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (reportSnapshot.hasError) {
          return Scaffold(
            body: Center(child: Text('Error loading report: ${reportSnapshot.error}')),
          );
        }

        final report = reportSnapshot.data;
        if (report == null) {
          return const Scaffold(
            body: Center(child: Text('Report not found.')),
          );
        }

        final resolvedFinderId = report.reporterId;
        final isFinderView = _currentUserId.isNotEmpty && _currentUserId == resolvedFinderId;
        final petTitle = report.petName.isNotEmpty
            ? report.petName
            : 'Spotted Pet #${report.id.length >= 4 ? report.id.substring(0, 4) : report.id}';

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Recovery Pipeline', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text(
                  'Case: $petTitle',
                  style: TextStyle(fontSize: 11.5, color: Colors.white.withValues(alpha: 0.85)),
                ),
              ],
            ),
          ),
          body: StreamBuilder<List<PetClaim>>(
            stream: _repository.watchClaimsForReport(report.id),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final allClaims = snapshot.data ?? [];

              PetClaim? activeClaim;
              if (isFinderView) {
                if (allClaims.isNotEmpty) {
                  final safeIndex = _selectedClaimantIndex.clamp(0, allClaims.length - 1);
                  activeClaim = allClaims[safeIndex];
                }
              } else {
                activeClaim = allClaims.where((c) => c.claimerId == _currentUserId).firstOrNull;
              }

              if (isFinderView && activeClaim == null) {
                return const Center(child: Text('No claim requests submitted for this pet yet.'));
              }

              final isCompleted = activeClaim?.isCompleted ?? false;
              final maxUnlockedStage = isCompleted ? 3 : (activeClaim?.currentStage ?? 1);
              final displayedStage = (_viewingStage != null && _viewingStage! <= maxUnlockedStage)
                  ? _viewingStage!
                  : maxUnlockedStage;

              return Column(
                children: [
                  RecoveryStepperHeader(
                    currentStage: displayedStage,
                    isCompleted: isCompleted,
                    onStageTap: (tappedStage) {
                      if (tappedStage <= maxUnlockedStage) {
                        setState(() => _viewingStage = tappedStage);
                      }
                    },
                  ),

                  if (isFinderView && allClaims.length > 1)
                    ClaimantSelectorBar(
                      claimants: allClaims.map((c) => {
                        'id': c.id,
                        'name': c.claimerName,
                        'joined': 'Verified Member',
                        'reportsCount': 0,
                        'verifiedCount': 0,
                        'avatarUrl': '',
                      }).toList(),
                      selectedIndex: _selectedClaimantIndex,
                      onSelect: (idx) => setState(() {
                        _selectedClaimantIndex = idx;
                        _viewingStage = null;
                      }),
                    ),

                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: _buildStageFromClaim(
                        claim: activeClaim,
                        report: report,
                        petTitle: petTitle,
                        isFinderView: isFinderView,
                        displayedStage: displayedStage,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildStageFromClaim({
    required PetClaim? claim,
    required FeedPost report,
    required String petTitle,
    required bool isFinderView,
    required int displayedStage,
  }) {
    final isCompleted = claim != null && claim.isCompleted;

    Widget stageContent;
    switch (displayedStage) {
      case 1:
        final otherUserId = isFinderView ? (claim?.claimerId ?? '') : report.reporterId;

        stageContent = Column(
          children: [
            if (!isCompleted && (claim?.currentStage ?? 1) > 1)
              _buildStageSwitchBanner(
                icon: Icons.check_circle_outline,
                label: 'Agreement accepted — currently on Stage ${claim!.currentStage}.',
                buttonText: 'Back to Stage ${claim.currentStage} →',
                onTap: () => setState(() => _viewingStage = claim.currentStage),
              ),
            FutureBuilder<UserProfileSummary>(
              future: otherUserId.isNotEmpty
                  ? _repository.getUserProfileSummary(otherUserId)
                  : Future.value(<String, dynamic>{}),
              builder: (context, profileSnap) {
                final profile = profileSnap.data ?? <String, dynamic>{};
                final fallbackName = isFinderView
                    ? (claim?.claimerName ?? 'Claimant')
                    : report.username;

                return Stage1AgreementWidget(
                  isFinderView: isFinderView,
                  requestSent: claim?.stage1RequestSent ?? false,
                  isApproved: claim?.stage1Approved ?? false,
                  otherPartyName: profile['name'] ?? fallbackName,
                  otherPartyAvatarUrl: profile['avatarUrl'] ?? (isFinderView ? '' : report.userImageUrl),
                  otherPartyEmail: profile['email'] ?? '',
                  isReadOnly: isCompleted,
                  otherPartyPhone: profile['phone'] ?? '',
                  otherPartyJoined: profile['joinedText'] ?? 'Community Member',
                  otherPartyReports: profile['totalReports'] ?? 0,
                  otherPartyVerified: profile['verifiedReunions'] ?? 0,
                  onSendRequest: () async {
                    if (isCompleted) return;
                    try {
                      if (_currentUserId.isEmpty) {
                        throw Exception('You must be logged in to send a claim.');
                      }

                      await _repository.createClaimRequest(
                        reportId: report.id,
                        finderId: report.reporterId,
                        claimerId: _currentUserId,
                      );

                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Claim request sent!')),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  onApproveRequest: () => _repository.respondToStage1(claim!.id, approve: true),
                  onDeclineRequest: () => _repository.respondToStage1(claim!.id, approve: false),
                );
              },
            ),
          ],
        );
        break;

      case 2:
        stageContent = Column(
          children: [
            if (!isCompleted && claim!.currentStage >= 3)
              _buildStageSwitchBanner(
                icon: Icons.verified_outlined,
                label: 'Verification approved — Stage 3 Retrieval is active.',
                buttonText: 'Go to Retrieval →',
                onTap: () => setState(() => _viewingStage = 3),
              ),
            Stage2VerificationWidget(
              claimId: claim.id,
              isFinderView: isFinderView,
              proofSubmitted: claim.stage2ProofSubmitted,
              isApproved: claim.stage2Approved,
              claimerName: claim.claimerName,
              uniqueFeaturesNote: claim.uniqueFeaturesNote,
              finderFeedback: claim.stage2Feedback,
              uploadedProofLabels: claim.proofImageUrls,
              uploadedDocLabels: claim.docUrls,
              onSubmitVerification: (note, proofs, docs) => _repository.submitStage2Proof(
                claimId: claim.id,
                note: note,
                proofUrls: proofs,
                docUrls: docs,
              ),
              onApproveVerification: () async {
                await _repository.approveStage2(claim.id);
                if (mounted) {
                  setState(() => _viewingStage = 3);
                }
              },
              onRequestMoreInfo: (feedback) => _repository.requestMoreStage2Info(
                claimId: claim.id,
                feedbackMessage: feedback,
              ),
            ),
          ],
        );
        break;

      case 3:
      default:
        final myMeetupAgreed = isFinderView
            ? claim!.meetupConfirmedByFinder
            : claim!.meetupConfirmedByClaimer;
        final isMeetupConfirmed =
            claim.meetupConfirmedByFinder && claim.meetupConfirmedByClaimer;

        stageContent = Column(
          children: [
            if (!isCompleted)
              _buildStageSwitchBanner(
                icon: Icons.fact_check_outlined,
                label: 'Need to re-check submitted photos or vet records?',
                buttonText: '← View Verification',
                onTap: () => setState(() => _viewingStage = 2),
              ),
            Stage3MeetupWidget(
              isFinderView: isFinderView,
              isReadOnly: isCompleted,
              petName: petTitle,
              otherPartyName: isFinderView ? claim.claimerName : report.username,
              selectedPlace: claim.meetupPlace,
              selectedLat: claim.meetupLat,
              selectedLng: claim.meetupLng,
              selectedTime: claim.meetupTime,
              myMeetupAgreed: myMeetupAgreed,
              isMeetupConfirmed: isMeetupConfirmed,
              myHandoverConfirmed: isFinderView
                  ? claim.finderConfirmedHandover
                  : claim.claimerConfirmedHandover,
              otherHandoverConfirmed: isFinderView
                  ? claim.claimerConfirmedHandover
                  : claim.finderConfirmedHandover,
              onProposeMeetup: (place, lat, lng, time) => _repository.proposeMeetup(
                claimId: claim.id,
                placeName: place,
                lat: lat,
                lng: lng,
                time: time,
                isFinder: isFinderView,
              ),
              onConfirmMeetup: () => _repository.confirmMeetup(
                claimId: claim.id,
                isFinder: isFinderView,
              ),
              onConfirmHandoverTap: () async {
                final confirmed = await showHandoverConfirmDialog(
                  context,
                  petName: petTitle,
                  isFinder: isFinderView,
                );
                if (confirmed == true) {
                  await _repository.confirmHandover(claim, isFinder: isFinderView);
                }
              },
            ),
          ],
        );
        break;
    }

    if (!isCompleted) return stageContent;

    return Column(
      children: [
        _buildCompletedBanner(petTitle),
        const SizedBox(height: 16),
        stageContent,
      ],
    );
  }

  Widget _buildStageSwitchBanner({
    required IconData icon,
    required String label,
    required String buttonText,
    required VoidCallback onTap,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.darkCharcoal,
              ),
            ),
          ),
          TextButton(
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: onTap,
            child: Text(
              buttonText,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletedBanner(String petTitle) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.verified_rounded, size: 48, color: AppColors.primary),
          ),
          const SizedBox(height: 16),
          const Text(
            'Reunion Confirmed!',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.darkCharcoal,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Both parties have confirmed the safe handover of $petTitle. This report has been automatically marked as FOUND and closed on the community map. Tap any stage above to review the completed record.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13.5, color: AppColors.text2, height: 1.4),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Back to Community Feed',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Stream<List<ActiveClaimProgress>> watchActiveClaims() {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id ?? '';

    if (userId.isEmpty) {
      return Stream.value([]);
    }

    return supabase
        .from('pet_claims')
        .stream(primaryKey: ['id'])
        .order('updated_at', ascending: false)
        .asyncMap((rows) async {
          final activeRows = rows.where((row) =>
              (row['finder_id'] == userId || row['claimer_id'] == userId) &&
              row['status'] != 'completed' &&
              row['status'] != 'declined');

          final List<ActiveClaimProgress> items = [];
          for (final row in activeRows) {
            final reportId = row['report_id']?.toString() ?? '';
            Map<String, dynamic>? report;

            if (reportId.isNotEmpty) {
              report = await supabase
                  .from('reports')
                  .select('id, animal_name, animal_type, photo_url')
                  .eq('id', reportId)
                  .maybeSingle();
            }

            final rawName = (report?['animal_name'] ?? '').toString().trim();
            final animalType = (report?['animal_type'] ?? 'Pet').toString().trim();
            final petTitle = rawName.isNotEmpty ? rawName : 'Spotted $animalType';

            items.add({
              'claimId': row['id']?.toString() ?? '',
              'reportId': reportId,
              'isFinder': row['finder_id'] == userId,
              'currentStage': row['current_stage'] ?? 1,
              'stage1Approved': row['stage1_approved'] ?? false,
              'stage2ProofSubmitted': row['stage2_proof_submitted'] ?? false,
              'stage2Approved': row['stage2_approved'] ?? false,
              'finderConfirmedHandover': row['finder_confirmed_handover'] ?? false,
              'claimerConfirmedHandover': row['claimer_confirmed_handover'] ?? false,
              'petTitle': petTitle,
              'photoUrl': (report?['photo_url'] ?? '').toString(),
            });
          }
          return items;
        });
  }
}