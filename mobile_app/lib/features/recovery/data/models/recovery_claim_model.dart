class PetClaim {
  final String id;
  final String reportId;
  final String finderId;
  final String claimerId;
  final String claimerName;
  final int currentStage;
  final String status;

  // Stage 1
  final bool stage1RequestSent;
  final bool stage1Approved;

  // Stage 2
  final bool stage2ProofSubmitted;
  final bool stage2Approved;
  final String uniqueFeaturesNote;
  final List<String> proofImageUrls;
  final List<String> docUrls;

  // feedback sa stage 2
  final String? stage2Feedback;

  // Stage 3
  final String? meetupPlace;
  final String? meetupTime;
  final bool meetupConfirmedByFinder;
  final bool meetupConfirmedByClaimer;
  final bool claimerConfirmedHandover;
  final bool finderConfirmedHandover;
  final double? meetupLat;
  final double? meetupLng;

  bool get isCompleted => claimerConfirmedHandover && finderConfirmedHandover;

  PetClaim({
    required this.id,
    required this.reportId,
    required this.finderId,
    required this.claimerId,
    this.claimerName = 'Claimant',
    required this.currentStage,
    required this.status,
    required this.stage1RequestSent,
    required this.stage1Approved,
    required this.stage2ProofSubmitted,
    required this.stage2Approved,
    required this.uniqueFeaturesNote,
    required this.proofImageUrls,
    required this.docUrls,
    this.meetupPlace,
    this.meetupTime,
    required this.meetupConfirmedByFinder,
    required this.meetupConfirmedByClaimer,
    required this.claimerConfirmedHandover,
    required this.finderConfirmedHandover,
    this.stage2Feedback,
    this.meetupLat,
    this.meetupLng,
  });

  factory PetClaim.fromJson(Map<String, dynamic> json) {
    return PetClaim(
      id: json['id'],
      reportId: json['report_id'],
      finderId: json['finder_id'],
      claimerId: json['claimer_id'],
      claimerName: json['profiles']?['username'] ?? 'User',
      currentStage: json['current_stage'] ?? 1,
      status: json['status'] ?? 'pending',
      stage1RequestSent: json['stage1_request_sent'] ?? false,
      stage1Approved: json['stage1_approved'] ?? false,
      stage2ProofSubmitted: json['stage2_proof_submitted'] ?? false,
      stage2Approved: json['stage2_approved'] ?? false,
      uniqueFeaturesNote: json['unique_features_note'] ?? '',
      proofImageUrls: List<String>.from(json['proof_image_urls'] ?? []),
      docUrls: List<String>.from(json['doc_urls'] ?? []),
      meetupPlace: json['meetup_place'],
      meetupTime: json['meetup_time'],
      meetupConfirmedByFinder: json['meetup_confirmed_by_finder'] ?? false,
      meetupConfirmedByClaimer: json['meetup_confirmed_by_claimer'] ?? false,
      claimerConfirmedHandover: json['claimer_confirmed_handover'] ?? false,
      finderConfirmedHandover: json['finder_confirmed_handover'] ?? false,
      stage2Feedback: json['stage2_feedback']?.toString(),
      meetupLat: (json['meetup_lat'] as num?)?.toDouble(),
      meetupLng: (json['meetup_lng'] as num?)?.toDouble(),
    );
  }
}