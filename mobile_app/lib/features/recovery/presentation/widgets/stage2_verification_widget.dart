import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_cached_pdfview/flutter_cached_pdfview.dart';
import 'package:paws_and_found/core/theme/app_colors.dart';
import 'package:paws_and_found/core/services/profanity_filter_service.dart';
import 'package:paws_and_found/core/services/user_restriction_service.dart';
import 'package:paws_and_found/shared/molecules/community_warning_dialog.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/repositories/recovery_repository_impl.dart';

class Stage2VerificationWidget extends StatefulWidget {
  final String claimId;
  final bool isFinderView;
  final bool proofSubmitted;
  final bool isApproved;
  final String claimerName;
  final String uniqueFeaturesNote;
  final List<String> uploadedProofLabels;
  final List<String> uploadedDocLabels;
  final Future<void> Function(String note, List<String> proofs, List<String> docs) onSubmitVerification;
  final VoidCallback onApproveVerification;
  final Future<void> Function(String feedback) onRequestMoreInfo;
  final String? finderFeedback;

  const Stage2VerificationWidget({
    super.key,
    required this.claimId,
    required this.isFinderView,
    required this.proofSubmitted,
    required this.isApproved,
    required this.claimerName,
    required this.uniqueFeaturesNote,
    required this.uploadedProofLabels,
    required this.uploadedDocLabels,
    required this.onSubmitVerification,
    required this.onApproveVerification,
    required this.onRequestMoreInfo,
    this.finderFeedback,
  });

  @override
  State<Stage2VerificationWidget> createState() => _Stage2VerificationWidgetState();
}

class _Stage2VerificationWidgetState extends State<Stage2VerificationWidget> {
  final TextEditingController _featuresController = TextEditingController();
  final ClaimRepository _repository = ClaimRepository();
  final ImagePicker _imagePicker = ImagePicker();

  final List<String> _draftProofUrls = [];
  final List<String> _draftDocUrls = [];
  bool _isUploadingPhoto = false;
  bool _isUploadingDoc = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _featuresController.text = widget.uniqueFeaturesNote;
    _draftProofUrls.addAll(widget.uploadedProofLabels);
    _draftDocUrls.addAll(widget.uploadedDocLabels);
  }

  @override
  void dispose() {
    _featuresController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadPhoto() async {
    try {
      final XFile? picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        imageQuality: 85,
      );
      if (picked == null) return;

      setState(() => _isUploadingPhoto = true);

      final Uint8List bytes = await picked.readAsBytes();
      final url = await _repository.uploadClaimProofFile(
        claimId: widget.claimId,
        bytes: bytes,
        fileName: picked.name,
        folder: 'photos',
      );

      if (mounted) {
        setState(() {
          _draftProofUrls.add(url);
          _isUploadingPhoto = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploadingPhoto = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Photo upload failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _pickAndUploadDocument() async {
    try {
      final files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      );
      if (files.isEmpty) return;

      final file = files.first;
      final Uint8List bytes = file.path != null
          ? await File(file.path!).readAsBytes()
          : await file.xFile.readAsBytes();

      const maxDocBytes = 2 * 1024 * 1024;
      if (bytes.length > maxDocBytes) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('File too large. Please upload a PDF or image under 2 MB.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      setState(() => _isUploadingDoc = true);

      final url = await _repository.uploadClaimProofFile(
        claimId: widget.claimId,
        bytes: bytes,
        fileName: file.name,
        folder: 'docs',
      );

      if (mounted) {
        setState(() {
          _draftDocUrls.add(url);
          _isUploadingDoc = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploadingDoc = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Document upload failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  String _fileNameFromUrl(String url) {
    final clean = url.split('?').first;
    final raw = clean.split('/').last;
    final underscoreIdx = raw.indexOf('_');
    if (underscoreIdx > 0 && underscoreIdx < 16) {
      return raw.substring(underscoreIdx + 1);
    }
    return raw;
  }

  bool _isPdfUrl(String url) {
    return url.toLowerCase().split('?').first.endsWith('.pdf');
  }

  /// Swipeable full-screen image viewer (supports scrolling left/right across photos)
  void _showImageGallery(List<String> urls, int initialIndex) {
    final pageController = PageController(initialPage: initialIndex);
    int currentIndex = initialIndex;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Dialog(
          backgroundColor: Colors.black,
          insetPadding: const EdgeInsets.all(12),
          child: Stack(
            children: [
              PageView.builder(
                controller: pageController,
                itemCount: urls.length,
                onPageChanged: (idx) => setDialogState(() => currentIndex = idx),
                itemBuilder: (_, idx) => InteractiveViewer(
                  child: Center(
                    child: Image.network(
                      urls[idx],
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => const Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'Failed to load image.',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (urls.length > 1)
                Positioned(
                  top: 14,
                  left: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${currentIndex + 1} / ${urls.length}',
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 28),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  void _showDocumentViewer(String url) {
  if (!_isPdfUrl(url)) {
    _showImageGallery([url], 0);
    return;
  }

  showDialog(
    context: context,
    builder: (ctx) => Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.all(12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: const BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Row(
              children: [
                const Icon(Icons.picture_as_pdf_outlined, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _fileNameFromUrl(url),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 22),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(14)),
              child: const PDF().cachedFromUrl(
                url,
                placeholder: (progress) => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(color: AppColors.primary),
                      const SizedBox(height: 10),
                      Text(
                        'Loading PDF... ${progress.toInt()}%',
                        style: const TextStyle(fontSize: 12.5, color: AppColors.text2),
                      ),
                    ],
                  ),
                ),
                errorWidget: (error) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Could not load PDF: $error',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

  Future<void> _showAskMoreInfoDialog() async {
    final controller = TextEditingController();
    final feedback = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text(
          'Request More Proof',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tell the claimant what specific photo or identifying detail you need to confirm ownership:',
              style: TextStyle(fontSize: 12.5, color: AppColors.text2),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 3,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'e.g., Please upload a clearer photo showing the mark on the left ear...',
                hintStyle: const TextStyle(fontSize: 12, color: AppColors.text3),
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.text3)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentOrange,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              final text = controller.text.trim();
              if (text.isNotEmpty) {
                final badWords = ProfanityFilterService.findProfanities(text);
                if (badWords.isNotEmpty) {
                  final targetUid = Supabase.instance.client.auth.currentUser?.id ?? 'current_user';
                  final violation = await const UserRestrictionService().recordViolation(
                    userId: targetUid,
                    prohibitedWord: badWords.first,
                  );
                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                  }
                  if (mounted) {
                    await CommunityWarningDialog.show(
                      context: context,
                      detectedWord: badWords.first,
                      violationCount: violation.count,
                      isSuspended: violation.isSuspended,
                    );
                  }
                  return;
                }
                Navigator.pop(ctx, text);
              }
            },
            child: const Text('Send Request', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (feedback != null && feedback.isNotEmpty) {
      await widget.onRequestMoreInfo(feedback);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Requested additional verification info from claimant.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.isFinderView ? _buildFinderReview() : _buildClaimerForm();
  }

  Widget _buildClaimerForm() {
    if (widget.proofSubmitted && !widget.isApproved) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: const Column(
          children: [
            Icon(Icons.hourglass_top_rounded, size: 42, color: AppColors.accentOrange),
            SizedBox(height: 12),
            Text(
              'Verification Submitted',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.darkCharcoal),
            ),
            SizedBox(height: 6),
            Text(
              'The finder is comparing your photos and unique details with the spotted pet. Stage 3 will unlock once confirmed.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.5, color: AppColors.text2, height: 1.4),
            ),
          ],
        ),
      );
    }

    final bool isLocked = widget.isApproved;
    final bool canSubmit = !isLocked &&
        _draftProofUrls.isNotEmpty &&
        _featuresController.text.trim().isNotEmpty &&
        !_isUploadingPhoto &&
        !_isUploadingDoc &&
        !_isSubmitting;

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
          if (!isLocked &&
              widget.finderFeedback != null &&
              widget.finderFeedback!.trim().isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: AppColors.accentOrange.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.accentOrange.withValues(alpha: 0.45)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.help_outline_rounded, size: 18, color: AppColors.accentOrange),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Finder Requested More Info:',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.darkCharcoal,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.finderFeedback!,
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: AppColors.darkCharcoal,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          Text(
            isLocked ? 'Approved Verification Details' : 'Verify Pet Ownership',
            style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.bold, color: AppColors.darkCharcoal),
          ),
          const SizedBox(height: 4),
          Text(
            isLocked
                ? 'Your ownership proofs have been verified and locked.'
                : 'Help the finder visually confirm this is your pet.',
            style: const TextStyle(fontSize: 12, color: AppColors.text3),
          ),
          const SizedBox(height: 16),

          // 1. Photos Together with Pet (Tappable to open gallery; delete hidden when locked)
          const Text(
            '1. Photo Together with Your Pet (Required)',
            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppColors.darkCharcoal),
          ),
          const SizedBox(height: 8),
          if (_draftProofUrls.isNotEmpty) ...[
            SizedBox(
              height: 92,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _draftProofUrls.length,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final url = _draftProofUrls[index];
                  return GestureDetector(
                    onTap: () => _showImageGallery(_draftProofUrls, index),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: SizedBox(
                        width: 92,
                        height: 92,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.network(
                              url,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => Container(
                                color: AppColors.background,
                                child: const Icon(Icons.image_outlined, color: AppColors.text3),
                              ),
                            ),
                            if (!isLocked)
                              Positioned(
                                top: 6,
                                right: 6,
                                child: GestureDetector(
                                  onTap: () => setState(() => _draftProofUrls.removeAt(index)),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: Colors.black54,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.close, size: 13, color: Colors.white),
                                  ),
                                ),
                              )
                            else
                              Positioned(
                                bottom: 6,
                                right: 6,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.black54,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Icon(Icons.zoom_in, size: 13, color: Colors.white),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            if (!isLocked) const SizedBox(height: 10),
          ],
          if (!isLocked)
            OutlinedButton.icon(
              icon: _isUploadingPhoto
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.add_a_photo_outlined, size: 16),
              label: Text(
                _isUploadingPhoto ? 'Uploading...' : 'Add Photo',
                style: const TextStyle(fontSize: 12),
              ),
              onPressed: _isUploadingPhoto ? null : _pickAndUploadPhoto,
            ),
          const SizedBox(height: 16),

          // 2. Hidden / Unique Features (Read-only when locked)
          const Text(
            '2. Unique Marks, Collar, or Behavior (Required)',
            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppColors.darkCharcoal),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _featuresController,
            readOnly: isLocked,
            maxLines: 3,
            onChanged: isLocked ? null : (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'e.g., Small notch on left ear, red nylon collar, responds to "Jack"...',
              hintStyle: const TextStyle(fontSize: 12, color: AppColors.text3),
              filled: true,
              fillColor: AppColors.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 3. Supporting Legal / Vet Records (Tappable to view PDF/image; delete/add hidden when locked)
          const Text(
            '3. Vet Card / Registration ID (Optional - Dispute Record)',
            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppColors.darkCharcoal),
          ),
          const SizedBox(height: 6),
          if (isLocked && _draftDocUrls.isEmpty)
            const Text(
              'No supporting documents attached.',
              style: TextStyle(fontSize: 12, color: AppColors.text3),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ..._draftDocUrls.map(
                  (url) => isLocked
                      ? ActionChip(
                          avatar: Icon(
                            _isPdfUrl(url) ? Icons.picture_as_pdf_outlined : Icons.image_outlined,
                            size: 15,
                            color: AppColors.primary,
                          ),
                          label: Text(_fileNameFromUrl(url), style: const TextStyle(fontSize: 11.5)),
                          onPressed: () => _showDocumentViewer(url),
                        )
                      : InputChip(
                          avatar: Icon(
                            _isPdfUrl(url) ? Icons.picture_as_pdf_outlined : Icons.image_outlined,
                            size: 15,
                            color: AppColors.primary,
                          ),
                          label: Text(_fileNameFromUrl(url), style: const TextStyle(fontSize: 11.5)),
                          onPressed: () => _showDocumentViewer(url),
                          deleteIcon: const Icon(Icons.close, size: 14),
                          onDeleted: () => setState(() => _draftDocUrls.remove(url)),
                        ),
                ),
                if (!isLocked)
                  OutlinedButton.icon(
                    icon: _isUploadingDoc
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.upload_file_outlined, size: 16),
                    label: Text(
                      _isUploadingDoc ? 'Uploading...' : 'Attach Document',
                      style: const TextStyle(fontSize: 12),
                    ),
                    onPressed: _isUploadingDoc ? null : _pickAndUploadDocument,
                  ),
              ],
            ),

          if (!isLocked) ...[
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  disabledBackgroundColor: AppColors.background2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: canSubmit
                    ? () async {
                        final note = _featuresController.text.trim();
                        final badWords = ProfanityFilterService.findProfanities(note);
                        if (badWords.isNotEmpty) {
                          final targetUid = Supabase.instance.client.auth.currentUser?.id ?? 'current_user';
                          final violation = await const UserRestrictionService().recordViolation(
                            userId: targetUid,
                            prohibitedWord: badWords.first,
                          );
                          if (mounted) {
                            await CommunityWarningDialog.show(
                              context: context,
                              detectedWord: badWords.first,
                              violationCount: violation.count,
                              isSuspended: violation.isSuspended,
                            );
                          }
                          return;
                        }

                        setState(() => _isSubmitting = true);
                        try {
                          await widget.onSubmitVerification(
                            note,
                            List.from(_draftProofUrls),
                            List.from(_draftDocUrls),
                          );
                        } finally {
                          if (mounted) setState(() => _isSubmitting = false);
                        }
                      }
                    : null,
                child: Text(
                  _isSubmitting ? 'Submitting...' : 'Submit Verification',
                  style: TextStyle(
                    color: canSubmit ? Colors.white : AppColors.text3,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildFinderReview() {
    if (!widget.proofSubmitted) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            const Icon(Icons.photo_library_outlined, size: 40, color: AppColors.text3),
            const SizedBox(height: 10),
            Text(
              'Waiting for ${widget.claimerName} to upload verification proofs...',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.text2),
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
          Text(
            widget.isApproved ? 'Verified Ownership Proofs' : 'Visual Match Check',
            style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.bold, color: AppColors.darkCharcoal),
          ),
          const SizedBox(height: 4),
          Text(
            widget.isApproved
                ? 'You approved these proofs. Both parties can now proceed to Stage 3 Retrieval.'
                : 'Compare the claimant\'s photos and identifying details below with the animal you spotted.',
            style: const TextStyle(fontSize: 12, color: AppColors.text3, height: 1.35),
          ),
          const SizedBox(height: 16),

          // 1. Photos Together with Pet (Horizontal Scrollable Row + Full-Screen Zoom)
          const Text(
            '1. Photos Together with Pet',
            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppColors.darkCharcoal),
          ),
          const SizedBox(height: 8),
          if (widget.uploadedProofLabels.isEmpty)
            const Text(
              'No photos uploaded.',
              style: TextStyle(fontSize: 12, color: AppColors.text3),
            )
          else
            SizedBox(
              height: 110,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: widget.uploadedProofLabels.length,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final url = widget.uploadedProofLabels[index];
                  return GestureDetector(
                    onTap: () => _showImageGallery(widget.uploadedProofLabels, index),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: SizedBox(
                        width: 110,
                        height: 110,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.network(
                              url,
                              fit: BoxFit.cover,
                              loadingBuilder: (context, child, progress) {
                                if (progress == null) return child;
                                return Container(
                                  color: AppColors.background,
                                  child: const Center(
                                    child: SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    ),
                                  ),
                                );
                              },
                              errorBuilder: (_, _, _) => Container(
                                color: AppColors.background,
                                child: const Icon(Icons.broken_image_outlined, color: AppColors.text3),
                              ),
                            ),
                            Positioned(
                              bottom: 6,
                              right: 6,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Icon(Icons.zoom_in, size: 14, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 16),

          // 2. Unique Marks, Collar, or Behavior
          const Text(
            '2. Unique Marks, Collar, or Behavior',
            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppColors.darkCharcoal),
          ),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              widget.uniqueFeaturesNote.isNotEmpty
                  ? widget.uniqueFeaturesNote
                  : 'No details provided.',
              style: const TextStyle(fontSize: 13, color: AppColors.darkCharcoal, height: 1.4),
            ),
          ),
          const SizedBox(height: 16),

          // 3. Vet Card / Registration ID (In-App PDF / Image Viewer)
          const Text(
            '3. Vet Card / Registration ID (Optional)',
            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppColors.darkCharcoal),
          ),
          const SizedBox(height: 6),
          if (widget.uploadedDocLabels.isEmpty)
            const Text(
              'No supporting documents attached.',
              style: TextStyle(fontSize: 12, color: AppColors.text3),
            )
          else
            Column(
              children: widget.uploadedDocLabels.map((url) {
                final isPdf = _isPdfUrl(url);
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => _showDocumentViewer(url),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      child: Row(
                        children: [
                          Icon(
                            isPdf ? Icons.picture_as_pdf_outlined : Icons.image_outlined,
                            size: 20,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _fileNameFromUrl(url),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w500,
                                color: AppColors.darkCharcoal,
                              ),
                            ),
                          ),
                          const Text(
                            'Open',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

          if (!widget.isApproved) ...[
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.accentOrange,
                      side: const BorderSide(color: AppColors.accentOrange),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _showAskMoreInfoDialog,
                    child: const Text('Ask More Info', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: widget.onApproveVerification,
                    child: const Text(
                      'Looks Like a Match →',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
