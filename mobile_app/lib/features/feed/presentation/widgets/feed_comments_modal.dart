import 'package:flutter/material.dart';
import 'package:paws_and_found/core/theme/app_colors.dart';
import 'package:paws_and_found/features/feed/data/models/comment_model.dart';
import 'package:paws_and_found/features/feed/data/repositories/feed_repository_impl.dart';
import 'package:paws_and_found/features/feed/domain/repositories/feed_repository.dart';
import 'package:paws_and_found/shared/atoms/drag_handle.dart';
import 'package:paws_and_found/features/feed/presentation/widgets/feed_card_comments.dart';
import 'feed_comment_input_bar.dart';

class FeedCommentsModal extends StatefulWidget {
  final String? reportId;
  final String? petName;

  const FeedCommentsModal({
    super.key,
    this.reportId,
    this.petName,
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
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  Future<void> _loadComments() async {
    if (widget.reportId == null) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final list = await _repository.getComments(widget.reportId!);
      if (mounted) {
        setState(() {
          _comments = list;
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
        ? 'Discussion Thread: ${widget.petName}'
        : 'Community Discussion Thread';

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
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
                      const Icon(Icons.forum_outlined, size: 18, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          headerTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14.0,
                            fontWeight: FontWeight.bold,
                            color: AppColors.darkCharcoal,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh, size: 18, color: AppColors.text3),
                        onPressed: _loadComments,
                        tooltip: 'Refresh comments',
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                ),
                const Divider(
                  color: AppColors.text1,
                  height: 1,
                ),
                Expanded(
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(color: AppColors.primary),
                        )
                      : _errorMessage != null
                          ? Center(
                              child: Text(
                                'Error loading comments: $_errorMessage',
                                style: const TextStyle(color: Colors.red),
                              ),
                            )
                          : _comments.isEmpty
                              ? const Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.chat_bubble_outline_rounded,
                                          size: 40, color: AppColors.text3),
                                      SizedBox(height: 8),
                                      Text(
                                        'No sightings or comments yet.',
                                        style: TextStyle(
                                            color: AppColors.text3,
                                            fontWeight: FontWeight.w600),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        'Be the first to report an update or sighting!',
                                        style: TextStyle(
                                            color: AppColors.text3, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                )
                              : ListView.builder(
                                  controller: scrollController,
                                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                                  itemCount: _comments.length,
                                  itemBuilder: (context, index) {
                                    final comment = _comments[index];
                                    return FeedCardComments(
                                      username: comment.authorName,
                                      timeAgo: comment.timeAgo,
                                      commentText: comment.cleanContent,
                                      userPhotoUrl: comment.authorPhotoUrl,
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
                                ),
                ),
                FeedCommentInputBar(
                  replyingToUser: _replyingToUser,
                  focusNode: _commentFocusNode,
                  onCancelReply: () {
                    setState(() {
                      _replyingToUser = null;
                      _replyingToParentId = null;
                    });
                  },
                  onCommentSubmitted: (text, replyTo) {
                    _handleCommentSubmit(text, replyTo);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
