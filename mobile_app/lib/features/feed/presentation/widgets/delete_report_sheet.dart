import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/atoms/drag_handle.dart';
import '../../../../shared/atoms/paw_button.dart';
import '../../../../shared/atoms/paw_text_field.dart';
import '../../data/models/feed_post_model.dart';
import '../../domain/repositories/feed_repository.dart';

/// Modal bottom sheet allowing report authors to undo/delete their post
/// within the grace period (e.g. false alarms, mistaken posts).
class DeleteReportSheet extends StatefulWidget {
  final FeedPost report;
  final FeedRepository repository;

  const DeleteReportSheet({
    super.key,
    required this.report,
    required this.repository,
  });

  static Future<bool?> show({
    required BuildContext context,
    required FeedPost report,
    required FeedRepository repository,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DeleteReportSheet(
        report: report,
        repository: repository,
      ),
    );
  }

  @override
  State<DeleteReportSheet> createState() => _DeleteReportSheetState();
}

class _DeleteReportSheetState extends State<DeleteReportSheet> {
  final TextEditingController _otherReasonController = TextEditingController();

  final List<String> _reasons = [
    'False alarm (Pet was just hiding / nearby)',
    'Accidental / Mistaken submission',
    'Duplicate post',
    'Other reasons',
  ];

  String _selectedReason = 'False alarm (Pet was just hiding / nearby)';
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _otherReasonController.dispose();
    super.dispose();
  }

  Future<void> _handleDelete() async {
    if (_selectedReason == 'Other reasons' &&
        _otherReasonController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Please provide details for the reason.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final details = _selectedReason == 'Other reasons'
          ? _otherReasonController.text.trim()
          : null;

      await widget.repository.deleteReport(
        widget.report.id,
        reason: _selectedReason,
        details: details,
      );

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to delete report: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isMissing = widget.report.status.toLowerCase() == 'missing';
    final targetName = widget.report.petName != 'Unknown Pet'
        ? widget.report.petName
        : '${widget.report.species} report';

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: bottomInset > 0 ? bottomInset + 16 : 32,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Center(child: DragHandle()),
            const SizedBox(height: 16),

            // Header Icon & Title
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.undo_rounded,
                    color: Colors.red.shade700,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Undo / Delete Report',
                        style: const TextStyle(
                          fontFamily: 'Nunito Sans',
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.darkCharcoal,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isMissing
                            ? 'Will remove the alert from the map and reset pet to safe.'
                            : 'Will remove this sighting post from the community feed.',
                        style: const TextStyle(
                          fontFamily: 'Ek Mukta',
                          fontSize: 12.5,
                          color: AppColors.text3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            const Divider(color: AppColors.text3),
            const SizedBox(height: 12),

            Text(
              'Why do you want to remove the report for $targetName?',
              style: const TextStyle(
                fontFamily: 'Nunito Sans',
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.text1,
              ),
            ),
            const SizedBox(height: 10),

            ..._reasons.map((reason) {
              final isSelected = _selectedReason == reason;
              return InkWell(
                onTap: () {
                  setState(() {
                    _selectedReason = reason;
                    _errorMessage = null;
                  });
                },
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    children: [
                      Radio<String>(
                        value: reason,
                        groupValue: _selectedReason,
                        activeColor: AppColors.contrast2,
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _selectedReason = val;
                              _errorMessage = null;
                            });
                          }
                        },
                      ),
                      Expanded(
                        child: Text(
                          reason,
                          style: TextStyle(
                            fontFamily: 'Nunito Sans',
                            fontSize: 13.5,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected ? AppColors.darkCharcoal : AppColors.text2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),

            if (_selectedReason == 'Other reasons') ...[
              const Text(
                'Reason details*',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.text2),
              ),
              const SizedBox(height: 8),
              PawTextField(
                controller: _otherReasonController,
                hintText: 'Describe the situation...',
                maxLines: 2,
                onChanged: (_) => setState(() => _errorMessage = null),
              ),
            ],

            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, size: 16, color: Colors.red.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: Colors.red.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: AppColors.text3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: _isLoading ? null : () => Navigator.of(context).pop(false),
                    child: const Text(
                      'Keep Post',
                      style: TextStyle(
                        color: AppColors.text2,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: PawButton(
                    text: 'Confirm Undo',
                    onPressed: _handleDelete,
                    color: AppColors.contrast2,
                    textColor: Colors.white,
                    isLoading: _isLoading,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

