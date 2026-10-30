/// Represents a pending or resolved ownership verification gate item.
///
/// In Paws & Found, before an owner is connected with a finder,
/// they must submit proof of ownership within the app.
/// System administrators or automated checks verify these documents.
class OwnershipVerificationItem {
  final String id;
  final String claimantName;
  final String claimantEmail;
  final String finderName;
  final String finderEmail;
  final String petName;
  final String petBreed;
  final String submittedDate;
  final String status; // 'pending', 'verified', 'rejected'
  final List<String> documents;
  final String notes;
  final bool isAutomatedCheckPassed;

  const OwnershipVerificationItem({
    required this.id,
    required this.claimantName,
    required this.claimantEmail,
    required this.finderName,
    required this.finderEmail,
    required this.petName,
    required this.petBreed,
    required this.submittedDate,
    required this.status,
    required this.documents,
    required this.notes,
    this.isAutomatedCheckPassed = false,
  });

  bool get isPending => status.toLowerCase() == 'pending';
  bool get isVerified => status.toLowerCase() == 'verified';
  bool get isRejected => status.toLowerCase() == 'rejected';

  OwnershipVerificationItem copyWith({
    String? claimantName,
    String? claimantEmail,
    String? finderName,
    String? finderEmail,
    String? petName,
    String? petBreed,
    String? submittedDate,
    String? status,
    List<String>? documents,
    String? notes,
    bool? isAutomatedCheckPassed,
  }) {
    return OwnershipVerificationItem(
      id: id,
      claimantName: claimantName ?? this.claimantName,
      claimantEmail: claimantEmail ?? this.claimantEmail,
      finderName: finderName ?? this.finderName,
      finderEmail: finderEmail ?? this.finderEmail,
      petName: petName ?? this.petName,
      petBreed: petBreed ?? this.petBreed,
      submittedDate: submittedDate ?? this.submittedDate,
      status: status ?? this.status,
      documents: documents ?? this.documents,
      notes: notes ?? this.notes,
      isAutomatedCheckPassed:
          isAutomatedCheckPassed ?? this.isAutomatedCheckPassed,
    );
  }
}
