import 'package:flutter/material.dart';
import 'package:paws_and_found/core/theme/app_colors.dart';
import 'popups/user_profile_preview.dart';

class Stage1AgreementWidget extends StatefulWidget {
  final bool isFinderView;
  final bool isReadOnly;
  final bool requestSent;
  final bool isApproved;
  final bool isDeclined;
  final bool wasPreviouslyDeclined;
  final String otherPartyName;
  final String otherPartyAvatarUrl;
  final String otherPartyEmail;
  final String otherPartyPhone;
  final String otherPartyJoined;
  final int otherPartyReports;
  final int otherPartyVerified;
  final VoidCallback onSendRequest;
  final VoidCallback onApproveRequest;
  final VoidCallback onDeclineRequest;

  const Stage1AgreementWidget({
    super.key,
    required this.isFinderView,
    this.isReadOnly = false,
    required this.requestSent,
    required this.isApproved,
    this.isDeclined = false,
    this.wasPreviouslyDeclined = false,
    required this.otherPartyName,
    this.otherPartyAvatarUrl = '',
    this.otherPartyEmail = '',
    this.otherPartyPhone = '',
    required this.otherPartyJoined,
    required this.otherPartyReports,
    required this.otherPartyVerified,
    required this.onSendRequest,
    required this.onApproveRequest,
    required this.onDeclineRequest,
  });

  @override
  State<Stage1AgreementWidget> createState() => _Stage1AgreementWidgetState();
}

class _Stage1AgreementWidgetState extends State<Stage1AgreementWidget> {
  late bool _agreeOwnership;
  late bool _agreeTruthfulProof;
  late bool _agreePublicMeetup;

  bool get _isLocked => widget.isApproved || widget.isReadOnly;
  bool get _allAgreed =>
      _agreeOwnership && _agreeTruthfulProof && _agreePublicMeetup;

  @override
  void initState() {
    super.initState();
    _agreeOwnership = _isLocked;
    _agreeTruthfulProof = _isLocked;
    _agreePublicMeetup = _isLocked;
  }

  @override
  void didUpdateWidget(covariant Stage1AgreementWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_isLocked && !oldWidget.isApproved && !oldWidget.isReadOnly) {
      _agreeOwnership = true;
      _agreeTruthfulProof = true;
      _agreePublicMeetup = true;
    }
    // Reset checkboxes if a previously sent request was declined and reopened
    if (!widget.requestSent && oldWidget.requestSent && !_isLocked) {
      _agreeOwnership = false;
      _agreeTruthfulProof = false;
      _agreePublicMeetup = false;
    }
  }

  void _openProfilePopup() {
    showUserProfilePreviewDialog(
      context,
      name: widget.otherPartyName,
      avatarUrl: widget.otherPartyAvatarUrl,
      email: widget.otherPartyEmail,
      phone: widget.otherPartyPhone,
      roleLabel: widget.isFinderView ? 'Claimant' : 'Post Finder',
      joinedText: widget.otherPartyJoined,
      totalReports: widget.otherPartyReports,
      verifiedReunions: widget.otherPartyVerified,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Status Banner (Hide 48h lock warning once approved or completed)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: (_isLocked ? AppColors.primary : AppColors.accentOrange)
                .withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: (_isLocked ? AppColors.primary : AppColors.accentOrange)
                  .withValues(alpha: 0.4),
            ),
          ),
          child: Row(
            children: [
              Icon(
                _isLocked ? Icons.check_circle_outline : Icons.timer_outlined,
                size: 18,
                color: _isLocked ? AppColors.primary : AppColors.accentOrange,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _isLocked
                      ? 'Initial claim agreement has been accepted and locked.'
                      : 'Stage 2 & 3 remain locked until the Finder approves this initial claim request (48h response window).',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.darkCharcoal,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Other Party Profile Card with Pop-up Trigger
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                backgroundImage: widget.otherPartyAvatarUrl.isNotEmpty
                    ? NetworkImage(widget.otherPartyAvatarUrl)
                    : null,
                child: widget.otherPartyAvatarUrl.isEmpty
                    ? const Icon(Icons.person_rounded, color: AppColors.primary)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.isFinderView ? 'Claimant' : 'Spotted By',
                      style: const TextStyle(fontSize: 11, color: AppColors.text3),
                    ),
                    Text(
                      widget.otherPartyName,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkCharcoal,
                      ),
                    ),
                  ],
                ),
              ),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                ),
                icon: const Icon(Icons.badge_outlined, size: 16),
                label: const Text('View Profile', style: TextStyle(fontSize: 12)),
                onPressed: _openProfilePopup,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Role-Specific Action Card
        if (widget.isFinderView) _buildFinderCard() else _buildClaimerCard(),
      ],
    );
  }

  Widget _buildClaimerCard() {
    if (widget.requestSent && !widget.isApproved && !widget.isReadOnly) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.accentOrange.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.send_rounded,
                size: 32,
                color: AppColors.accentOrange,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Claim Request Sent',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.darkCharcoal,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Waiting for the finder to accept your request. Once accepted, Stage 2 (Ownership Verification) will unlock automatically.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.5,
                color: AppColors.text2,
                height: 1.4,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.wasPreviouslyDeclined) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withValues(alpha: 0.25)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.red),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Your previous claim request was declined. You may review the terms and submit a new request below.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.darkCharcoal,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const Text(
            'Claimant Responsibility Agreement',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.darkCharcoal,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _isLocked
                ? 'You accepted all responsibility terms for this recovery claim:'
                : 'Please review and accept all terms before initiating a recovery claim:',
            style: const TextStyle(fontSize: 12, color: AppColors.text3),
          ),
          const SizedBox(height: 12),
          CheckboxListTile(
            value: _agreeOwnership,
            activeColor: AppColors.primary,
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            title: const Text(
              'I confirm I am the rightful owner (or authorized family member) of this pet.',
              style: TextStyle(fontSize: 12.5, color: AppColors.text2),
            ),
            onChanged: _isLocked
                ? null
                : (v) => setState(() => _agreeOwnership = v ?? false),
          ),
          CheckboxListTile(
            value: _agreeTruthfulProof,
            activeColor: AppColors.primary,
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            title: const Text(
              'I agree to submit clear photos and identifying details in Stage 2.',
              style: TextStyle(fontSize: 12.5, color: AppColors.text2),
            ),
            onChanged: _isLocked
                ? null
                : (v) => setState(() => _agreeTruthfulProof = v ?? false),
          ),
          CheckboxListTile(
            value: _agreePublicMeetup,
            activeColor: AppColors.primary,
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            title: const Text(
              'I agree to conduct any pet handover in a safe, public open location.',
              style: TextStyle(fontSize: 12.5, color: AppColors.text2),
            ),
            onChanged: _isLocked
                ? null
                : (v) => setState(() => _agreePublicMeetup = v ?? false),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                disabledBackgroundColor: AppColors.background2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: (!_isLocked && _allAgreed) ? widget.onSendRequest : null,
              child: Text(
                _isLocked ? 'Agreement Accepted ✓' : 'Send Claim Request',
                style: TextStyle(
                  color: (!_isLocked && _allAgreed)
                      ? Colors.white
                      : AppColors.text3,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinderCard() {
    if (widget.isDeclined) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.cancel_outlined,
                size: 28,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Request declined successfully',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15.5,
                fontWeight: FontWeight.bold,
                color: AppColors.darkCharcoal,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${widget.otherPartyName}\'s claim request has been closed and this report is open again for other potential owners.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12.5,
                color: AppColors.text2,
                height: 1.4,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Incoming Ownership Claim Request',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.darkCharcoal,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${widget.otherPartyName} has accepted the responsibility terms and wants to verify ownership of this animal.',
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.text2,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _isLocked ? AppColors.text3 : Colors.red,
                    side: BorderSide(
                      color: _isLocked ? AppColors.border : Colors.red,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _isLocked ? null : widget.onDeclineRequest,
                  child: const Text(
                    'Decline',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    disabledBackgroundColor: AppColors.background2,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _isLocked ? null : widget.onApproveRequest,
                  child: Text(
                    _isLocked ? 'Accepted ✓' : 'Accept & Unlock Verification',
                    style: TextStyle(
                      color: _isLocked ? AppColors.text3 : Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}