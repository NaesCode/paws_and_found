import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:paws_and_found/core/constants/app_assets.dart';
import 'package:paws_and_found/core/services/profanity_filter_service.dart';
import 'package:paws_and_found/core/theme/app_colors.dart';
import 'package:paws_and_found/features/feed/data/models/comment_model.dart';
import 'package:paws_and_found/features/feed/data/models/feed_post_model.dart';
import 'package:paws_and_found/features/feed/data/repositories/feed_repository_impl.dart';
import 'package:paws_and_found/features/feed/domain/repositories/feed_repository.dart';
import 'package:paws_and_found/shared/atoms/drag_handle.dart';
import 'package:paws_and_found/features/feed/presentation/widgets/feed_card_comments.dart';
import 'feed_comment_input_bar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum CommentSortFilter { all, newest, oldest }

class FeedCommentsModal extends StatefulWidget {
  final String? reportId;
  final String? petName;
  final int initialTab;
  final String? reporterName;
  final String? contactInfo;

  const FeedCommentsModal({
    super.key,
    this.reportId,
    this.petName,
    this.initialTab = 0,
    this.reporterName,
    this.contactInfo,
  });

  @override
  State<FeedCommentsModal> createState() => _FeedCommentsModalState();
}

class _FeedCommentsModalState extends State<FeedCommentsModal> {
  final FeedRepository _repository = FeedRepositoryImpl();
  CommentSortFilter _selectedFilter = CommentSortFilter.all;
  String? _replyingToUser;
  String? _replyingToParentId;
  final FocusNode _commentFocusNode = FocusNode();
  FeedComment? _editingComment;
  final Set<String> _expandedCommentIds = {};
  static const int _initialVisibleReplies = 2;

  List<FeedComment> _comments = [];
  List<FeedPost> _sightings = [];
  FeedPost? _reportPost;
  bool _isLoading = false;
  String? _errorMessage;
  late int _selectedTab;

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.initialTab;
    _loadData();
  }

  Future<void> _loadData() async {
    if (widget.reportId == null) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        _repository.getComments(widget.reportId!),
        _repository.getLinkedSightings(widget.reportId!),
        _repository.getReportById(widget.reportId!),
      ]);

      if (mounted) {
        setState(() {
          _comments = results[0] as List<FeedComment>;
          _sightings = results[1] as List<FeedPost>;
          _reportPost = results[2] as FeedPost?;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  List<FeedComment> get _generalComments => _comments.where((c) {
        final isSightingLink = c.linkedReportId != null && c.linkedReportId!.isNotEmpty;
        final isAutoSightingText = c.cleanContent.startsWith('🐾 Sighting reported');
        return !isSightingLink && !isAutoSightingText;
      }).toList();

  @override
  void dispose() {
    _commentFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final headerTitle = widget.petName != null && widget.petName!.isNotEmpty
        ? 'Pet Case File: ${widget.petName}'
        : 'Community Pet File';

    return DraggableScrollableSheet(
      initialChildSize: 0.78,
      minChildSize: 0.45,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Padding(
          padding: EdgeInsets.only(bottom: bottomInset),
          child: Container(
            decoration: const BoxDecoration(
              color: AppColors.background1,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                const DragHandle(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                  child: Row(
                    children: [
                      const Icon(Icons.shield_outlined, size: 18, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          headerTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15.0,
                            fontWeight: FontWeight.bold,
                            color: AppColors.darkCharcoal,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh, size: 18, color: AppColors.text3),
                        onPressed: _loadData,
                        tooltip: 'Refresh data',
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                ),

                // Contact / Case Lead Banner
                _buildContactBanner(),

                // Dual-Tab Switcher: Sightings Dashboard vs. Community Chat
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: AppColors.background2,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildTabButton(
                            title: '🐾 Sightings Log (${_sightings.length})',
                            isSelected: _selectedTab == 0,
                            onTap: () => setState(() => _selectedTab = 0),
                          ),
                        ),
                        Expanded(
                          child: _buildTabButton(
                            title: '💬 Chat (${_generalComments.length})',
                            isSelected: _selectedTab == 1,
                            onTap: () => setState(() => _selectedTab = 1),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Divider(color: AppColors.text1, height: 1),

                // Body content based on selected tab
                Expanded(
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(color: AppColors.primary),
                        )
                      : _errorMessage != null
                          ? Center(
                              child: Text(
                                'Error: $_errorMessage',
                                style: const TextStyle(color: Colors.red),
                              ),
                            )
                          : _selectedTab == 0
                              ? _buildSightingsDashboard(scrollController)
                              : _buildCommentsFeed(scrollController),
                ),

                // Only render comment input bar on Chat tab
                if (_selectedTab == 1)
                  FeedCommentInputBar(
                    replyingToUser: _replyingToUser,
                    editingCommentId: _editingComment?.id,
                    editingInitialText: _editingComment?.cleanContent,
                    focusNode: _commentFocusNode,
                    onCancelReply: () {
                      setState(() {
                        _replyingToUser = null;
                        _replyingToParentId = null;
                        _editingComment = null;
                      });
                    },
                    onCommentSubmitted: (text, replyToUser) => _handleCommentSubmit(text, replyToUser),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildContactBanner() {
    final ownerName = widget.reporterName ?? _reportPost?.postedBy ?? 'Pet Owner';

    String? phone = widget.contactInfo;
    if ((phone == null || phone.isEmpty) && _reportPost != null && _reportPost!.description.isNotEmpty) {
      final phoneRegex = RegExp(r'(\+?63\s?|0)9\d{2}[\s\-]?\d{3}[\s\-]?\d{4}|\b\d{3}[\s\-]?\d{4}\b');
      final match = phoneRegex.firstMatch(_reportPost!.description);
      if (match != null) {
        phone = match.group(0);
      }
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.25), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 17,
            backgroundColor: AppColors.primary.withValues(alpha: 0.12),
            child: const Icon(Icons.person_pin_circle_rounded, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Case Lead: $ownerName',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: AppColors.darkCharcoal,
                  ),
                ),
                const SizedBox(height: 2),
                if (phone != null && phone.isNotEmpty) ...[
                  Row(
                    children: [
                      const Icon(Icons.phone_rounded, size: 12, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text(
                        phone,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  const Text(
                    'Message the owner directly in the discussion below.',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: AppColors.text3,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (phone != null && phone.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.copy_rounded, size: 18, color: AppColors.primary),
              tooltip: 'Copy Phone Number',
              visualDensity: VisualDensity.compact,
              onPressed: () {
                Clipboard.setData(ClipboardData(text: phone!));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Phone number copied to clipboard!'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            )
          else
            TextButton.icon(
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
              icon: const Icon(Icons.chat_bubble_outline_rounded, size: 14, color: AppColors.primary),
              label: const Text('Chat', style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600)),
              onPressed: () {
                if (_selectedTab != 1) {
                  setState(() => _selectedTab = 1);
                }
                _commentFocusNode.requestFocus();
              },
            ),
        ],
      ),
    );
  }

  Widget _buildTabButton({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: Text(
          title,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            color: isSelected ? AppColors.darkCharcoal : AppColors.text3,
          ),
        ),
      ),
    );
  }

  Widget _buildSightingsDashboard(ScrollController scrollController) {
    if (_sightings.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.pets, size: 36, color: AppColors.primary),
              ),
              const SizedBox(height: 12),
              const Text(
                'No Sightings Reported Yet',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkCharcoal,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'When community members snap photos of this animal, they will appear here as a chronological timeline with GPS map locations.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12.5,
                  color: AppColors.text3,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: _sightings.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final sighting = _sightings[index];
        final hasPic = sighting.imageUrl.isNotEmpty &&
            (sighting.imageUrl.startsWith('http://') || sighting.imageUrl.startsWith('https://'));

        final matchRegex = RegExp(r'\[AI Match:\s*(\d+)%?\]', caseSensitive: false);
        final match = matchRegex.firstMatch(sighting.description);
        final matchConfidence = match?.group(1);
        final cleanDesc = sighting.description.replaceAll(matchRegex, '').trim();

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.text1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: AppColors.background2,
                    backgroundImage: sighting.userImageUrl.isNotEmpty
                        ? NetworkImage(sighting.userImageUrl)
                        : null,
                    child: sighting.userImageUrl.isEmpty
                        ? const Icon(Icons.person, size: 16, color: AppColors.text3)
                        : null,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Spotted by ${sighting.postedBy}',
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.darkCharcoal,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (matchConfidence != null)
                    Container(
                      margin: const EdgeInsets.only(right: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: int.tryParse(matchConfidence) != null && int.parse(matchConfidence) >= 85
                            ? const Color(0xFFE8F5E9)
                            : const Color(0xFFFFF3E0),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: int.tryParse(matchConfidence) != null && int.parse(matchConfidence) >= 85
                              ? const Color(0xFF81C784)
                              : const Color(0xFFFFB74D),
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.auto_awesome,
                            size: 10,
                            color: int.tryParse(matchConfidence) != null && int.parse(matchConfidence) >= 85
                                ? const Color(0xFF2E7D32)
                                : const Color(0xFFE65100),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '$matchConfidence% Match',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: int.tryParse(matchConfidence) != null && int.parse(matchConfidence) >= 85
                                  ? const Color(0xFF2E7D32)
                                  : const Color(0xFFE65100),
                            ),
                          ),
                        ],
                      ),
                    ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.accentOrange.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      sighting.formattedTime,
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        color: AppColors.accentOrange,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      width: 68,
                      height: 68,
                      child: hasPic
                          ? Image.network(
                              sighting.imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Image.asset(
                                AppAssets.petPlaceholder,
                                fit: BoxFit.cover,
                              ),
                            )
                          : Image.asset(AppAssets.petPlaceholder, fit: BoxFit.cover),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.location_on, size: 14, color: AppColors.primary),
                            const SizedBox(width: 3),
                            Expanded(
                              child: Text(
                                sighting.location.isNotEmpty ? sighting.location : 'Reported Location',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.darkCharcoal,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        if (cleanDesc.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            cleanDesc,
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: AppColors.text2,
                              height: 1.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary, width: 1.2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  icon: const Icon(Icons.map_rounded, size: 16),
                  label: const Text(
                    'View Sighting on Map →',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                    context.go('/map?reportId=${sighting.id}');
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _handleCommentSubmit(String text, String? replyTo) async {
    if (widget.reportId == null || text.trim().isEmpty) return;

    // Bad words / profanity validation across English, Filipino, and Bisaya
    final badWords = ProfanityFilterService.findProfanities(text);
    if (badWords.isNotEmpty) {
      final result = await ProfanityFilterService.instance.recordInfraction(badWords);
      if (mounted) {
        _showProfanityBlockedDialog(badWords, result);
      }
      return; // Stop submission
    }

    try {
      if (_editingComment != null) {
        final updated = await _repository.updateComment(_editingComment!.id, text.trim());
        if (mounted) {
          setState(() {
            final index = _comments.indexWhere((c) => c.id == updated.id);
            if (index != -1) _comments[index] = updated;
            _editingComment = null;
          });
        }
        return;
      }

      final newComment = await _repository.addComment(
        widget.reportId!,
        text.trim(),
        parentId: _replyingToParentId,
      );

      if (mounted) {
        setState(() {
          _comments.add(newComment);
          if (_replyingToParentId != null) {
            _expandedCommentIds.add(_replyingToParentId!);
          }
          _replyingToUser = null;
          _replyingToParentId = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Action failed: $e')),
        );
      }
    }
  }

  void _showProfanityBlockedDialog(
    List<String> badWords,
    ProfanityInfractionResult result,
  ) {
    showDialog<void>(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(
                result.isSuspended ? Icons.block_rounded : Icons.warning_amber_rounded,
                color: result.isSuspended ? AppColors.error : AppColors.accentOrange,
                size: 26,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  result.isSuspended
                      ? 'Account Suspended'
                      : result.isWarned
                          ? 'Community Warning'
                          : 'Prohibited Language',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Your comment was not posted because it contains prohibited language in our community guidelines.',
                style: TextStyle(fontSize: 13.5, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  'Detected: "${badWords.join(', ')}"',
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.error,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                result.message,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: result.isSuspended ? AppColors.error : AppColors.textPrimary,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: const Text('Understood', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _confirmAndDeleteComment(FeedComment comment) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Comment?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _repository.deleteComment(comment.id);
      if (mounted) {
        setState(() {
          _comments.removeWhere((c) => c.id == comment.id || c.parentId == comment.id);
          if (_editingComment?.id == comment.id) _editingComment = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete comment: $e')),
        );
      }
    }
  }

  Widget _buildCommentsFeed(ScrollController scrollController) {
    final generalComments = _generalComments;

    if (generalComments.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.chat_bubble_outline_rounded, size: 40, color: AppColors.text3),
              SizedBox(height: 8),
              Text(
                'No community messages yet.',
                style: TextStyle(color: AppColors.text3, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 4),
              Text(
                'Leave an encouraging message or search update below!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: AppColors.text3),
              ),
            ],
          ),
        ),
      );
    }

    final currentUserId = Supabase.instance.client.auth.currentUser?.id;

    final topLevel = generalComments
        .where((c) => c.parentId == null || c.parentId!.isEmpty)
        .toList();
    final Map<String, List<FeedComment>> repliesMap = {};
    for (final c in generalComments) {
      if (c.parentId != null && c.parentId!.isNotEmpty) {
        repliesMap.putIfAbsent(c.parentId!, () => []).add(c);
      }
    }

    switch (_selectedFilter) {
      case CommentSortFilter.newest:
        topLevel.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case CommentSortFilter.oldest:
      case CommentSortFilter.all:
        topLevel.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
    }

    // Build mixed list of comments + retractable "See more / Hide" rows
    final List<_CommentListRow> displayRows = [];
    for (final parent in topLevel) {
      displayRows.add(_CommentListRow.comment(parent, isReply: false));

      final replies = repliesMap[parent.id] ?? [];
      if (replies.isNotEmpty) {
        final isExpanded = _expandedCommentIds.contains(parent.id);
        final visibleReplies = (!isExpanded && replies.length > _initialVisibleReplies)
            ? replies.take(_initialVisibleReplies).toList()
            : replies;

        for (final reply in visibleReplies) {
          displayRows.add(_CommentListRow.comment(reply, isReply: true));
        }

        if (replies.length > _initialVisibleReplies) {
          final hiddenCount = replies.length - visibleReplies.length;
          displayRows.add(
            _CommentListRow.toggle(
              parentId: parent.id,
              hiddenCount: hiddenCount,
              isExpanded: isExpanded,
            ),
          );
        }
      }
    }

    return Column(
      children: [
        // Compact filter bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 2),
          child: Row(
            children: [
              Text(
                '${topLevel.length} ${topLevel.length == 1 ? 'thread' : 'threads'}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.text3,
                ),
              ),
              const Spacer(),
              PopupMenuButton<CommentSortFilter>(
                initialValue: _selectedFilter,
                onSelected: (filter) => setState(() => _selectedFilter = filter),
                itemBuilder: (context) => const [
                  PopupMenuItem(value: CommentSortFilter.all, child: Text('All')),
                  PopupMenuItem(value: CommentSortFilter.newest, child: Text('Newest')),
                  PopupMenuItem(value: CommentSortFilter.oldest, child: Text('Oldest')),
                ],
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.background2,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.sort_rounded, size: 14, color: AppColors.text2),
                      const SizedBox(width: 4),
                      Text(
                        _filterLabel(_selectedFilter),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.text2,
                        ),
                      ),
                      const Icon(Icons.arrow_drop_down, size: 16, color: AppColors.text2),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            controller: scrollController,
            padding: const EdgeInsets.symmetric(vertical: 4),
            itemCount: displayRows.length,
            itemBuilder: (context, index) {
              final row = displayRows[index];

              if (row.isToggle) {
                return Padding(
                  padding: const EdgeInsets.only(left: 48.0, top: 2.0, bottom: 10.0),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        if (row.isExpanded) {
                          _expandedCommentIds.remove(row.parentId!);
                        } else {
                          _expandedCommentIds.add(row.parentId!);
                        }
                      });
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 20,
                          height: 1.5,
                          color: AppColors.text3.withValues(alpha: 0.4),
                          margin: const EdgeInsets.only(right: 8.0),
                        ),
                        Text(
                          row.isExpanded
                              ? 'Hide replies'
                              : 'See ${row.hiddenCount} more ${row.hiddenCount == 1 ? 'reply' : 'replies'}',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 12.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          row.isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                          size: 16,
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                  ),
                );
              }

              final comment = row.comment!;
              return FeedCardComments(
                commentText: comment.cleanContent,
                username: comment.authorName,
                timeAgo: comment.timeAgo,
                userPhotoUrl: comment.authorPhotoUrl.isNotEmpty ? comment.authorPhotoUrl : null,
                isReply: row.isReply,
                isCurrentUser: currentUserId != null && comment.userId == currentUserId,
                onReplyTap: () {
                  setState(() {
                    _editingComment = null;
                    _replyingToUser = comment.authorName;
                    _replyingToParentId = row.isReply ? comment.parentId : comment.id;
                  });
                  _commentFocusNode.requestFocus();
                },
                onEditTap: () {
                  setState(() {
                    _replyingToUser = null;
                    _replyingToParentId = null;
                    _editingComment = comment;
                  });
                  _commentFocusNode.requestFocus();
                },
                onDeleteTap: () => _confirmAndDeleteComment(comment),
              );
            },
          ),
        ),
      ],
    );
  }

  String _filterLabel(CommentSortFilter filter) {
    switch (filter) {
      case CommentSortFilter.all:
        return 'All';
      case CommentSortFilter.newest:
        return 'Newest';
      case CommentSortFilter.oldest:
        return 'Oldest';
    }
  }
}

class _CommentListRow {
  final FeedComment? comment;
  final bool isReply;
  final bool isToggle;
  final String? parentId;
  final int hiddenCount;
  final bool isExpanded;

  const _CommentListRow._({
    this.comment,
    this.isReply = false,
    this.isToggle = false,
    this.parentId,
    this.hiddenCount = 0,
    this.isExpanded = false,
  });

  factory _CommentListRow.comment(FeedComment comment, {required bool isReply}) {
    return _CommentListRow._(comment: comment, isReply: isReply);
  }

  factory _CommentListRow.toggle({
    required String parentId,
    required int hiddenCount,
    required bool isExpanded,
  }) {
    return _CommentListRow._(
      isToggle: true,
      parentId: parentId,
      hiddenCount: hiddenCount,
      isExpanded: isExpanded,
    );
  }
}