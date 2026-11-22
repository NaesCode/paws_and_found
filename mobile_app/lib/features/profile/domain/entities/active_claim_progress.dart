class ActiveClaimProgress {
  final String claimId;
  final String reportId;
  final bool isFinder;
  final int currentStage;
  final bool stage1Approved;
  final bool stage2ProofSubmitted;
  final bool stage2Approved;
  final bool finderConfirmedHandover;
  final bool claimerConfirmedHandover;
  final String petTitle;
  final String photoUrl;

  const ActiveClaimProgress({
    required this.claimId,
    required this.reportId,
    required this.isFinder,
    required this.currentStage,
    required this.stage1Approved,
    required this.stage2ProofSubmitted,
    required this.stage2Approved,
    required this.finderConfirmedHandover,
    required this.claimerConfirmedHandover,
    required this.petTitle,
    required this.photoUrl,
  });
}