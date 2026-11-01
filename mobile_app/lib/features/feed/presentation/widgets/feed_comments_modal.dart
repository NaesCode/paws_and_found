import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:paws_and_found/core/constants/app_assets.dart';
import 'package:paws_and_found/core/theme/app_colors.dart';
import 'package:paws_and_found/features/feed/data/models/comment_model.dart';
import 'package:paws_and_found/features/feed/data/models/feed_post_model.dart';
import 'package:paws_and_found/features/feed/data/repositories/feed_repository_impl.dart';
import 'package:paws_and_found/features/feed/domain/repositories/feed_repository.dart';
import 'package:paws_and_found/shared/atoms/drag_handle.dart';
import 'package:paws_and_found/features/feed/presentation/widgets/feed_card_comments.dart';
import 'feed_comment_input_bar.dart';

class FeedCommentsModal extends StatefulWidget {
  final String? reportId;
  final String? petName;
  final int initialTab;

  const FeedCommentsModal({
    super.key,
    this.reportId,
    this.petName,
    this.initialTab = 0,
  });

  @override
  State<FeedCommentsModal> createState() => _FeedCommentsModalState();
}

class _FeedCommentsModalState extends State<FeedCommentsModal> {
  final FeedRepository _repository = FeedRepositoryImpl();
  String? _replyingToUser;
  String? _replyingToParentId;
  final FocusNode _commentFocusNode = FocusNode();

  List<FeedComment> _comments = [];
  List<FeedPost> _sightings = [];
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
      ]);

      if (mounted) {
        setState(() {
          _comments = results[0] as List<FeedComment>;
          _sightings = results[1] as List<FeedPost>;
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

  Future<void> _handleCommentSubmit(String text, String? replyTo) async {
    if (widget.reportId == null || text.trim().isEmpty) return;

    try {
      final newComment = await _repository.addComment(
        widget.reportId!,
        text.trim(),
        parentId: _replyingToParentId,
      );

      if (mounted) {
        setState(() {
          _comments.add(newComment);
          _replyingToUser = null;
          _replyingToParentId = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to post comment: $e')),
        );
      }
    }
  }

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
                            title: '💬 Chat (${_comments.length})',
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
                    focusNode: _commentFocusNode,
                    onCancelReply: () {
                      setState(() {
                        _replyingToUser = null;
                        _replyingToParentId = null;
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
              // Header: Spotter info & time
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

              // Photo & Location
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
                        if (sighting.description.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            sighting.description,
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

              // Action button to map
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

  Widget _buildCommentsFeed(ScrollController scrollController) {
    if (_comments.isEmpty) {
      return const Center(
        child: Column(
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
              style: TextStyle(fontSize: 12, color: AppColors.text3),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _comments.length,
      itemBuilder: (context, index) {
        final comment = _comments[index];
        return FeedCardComments(
          commentText: comment.cleanContent,
          username: comment.authorName,
          timeAgo: comment.timeAgo,
          userPhotoUrl: comment.authorPhotoUrl.isNotEmpty ? comment.authorPhotoUrl : null,
          linkedReportId: comment.linkedReportId,
          onReplyTap: () {
            setState(() {
              _replyingToUser = comment.authorName;
              _replyingToParentId = comment.id;
            });
            _commentFocusNode.requestFocus();
          },
        );
      },
    );
  }
}
