import 'package:flutter/material.dart';
import 'package:paws_and_found/core/theme/app_colors.dart';
import 'reply_indicator_bar.dart';

class FeedCommentInputBar extends StatefulWidget {
  final String? replyingToUser;
  final String? editingCommentId;
  final String? editingInitialText;
  final FocusNode focusNode;
  final VoidCallback onCancelReply;
  final Function(String text, String? replyToUser) onCommentSubmitted;

  const FeedCommentInputBar({
    super.key,
    required this.replyingToUser,
    this.editingCommentId,
    this.editingInitialText,
    required this.focusNode,
    required this.onCancelReply,
    required this.onCommentSubmitted,
  });

  @override
  State<FeedCommentInputBar> createState() => _FeedCommentInputBarState();
}

class _FeedCommentInputBarState extends State<FeedCommentInputBar> {
  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.editingInitialText != null) {
      _setTextAndCursor(widget.editingInitialText!);
    }
  }

  void _setTextAndCursor(String text) {
    _commentController.text = text;
    _commentController.selection = TextSelection.fromPosition(
      TextPosition(offset: text.length),
    );
  }

  @override
  void didUpdateWidget(covariant FeedCommentInputBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.editingCommentId != oldWidget.editingCommentId ||
        widget.editingInitialText != oldWidget.editingInitialText) {
      if (widget.editingInitialText != null) {
        _setTextAndCursor(widget.editingInitialText!);
      } else {
        _commentController.clear();
      }
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    widget.onCommentSubmitted(text, widget.replyingToUser);
    _commentController.clear();
    widget.focusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.editingInitialText != null;

    return Container(
      padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 10.0, bottom: 24.0),
      decoration: BoxDecoration(
        color: AppColors.background1,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, -2),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isEditing)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
              margin: const EdgeInsets.only(bottom: 8.0),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Row(
                children: [
                  const Icon(Icons.edit_outlined, size: 14, color: AppColors.primary),
                  const SizedBox(width: 6.0),
                  const Expanded(
                    child: Text(
                      'Editing comment',
                      style: TextStyle(
                        color: AppColors.text2,
                        fontSize: 12.0,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: widget.onCancelReply,
                    child: const Icon(Icons.close, size: 16, color: AppColors.text3),
                  ),
                ],
              ),
            )
          else if (widget.replyingToUser != null)
            ReplyIndicatorBar(
              username: widget.replyingToUser!,
              onClose: widget.onCancelReply,
            ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _commentController,
                  focusNode: widget.focusNode,
                  minLines: 1,
                  maxLines: 5,
                  keyboardType: TextInputType.multiline,
                  style: const TextStyle(color: AppColors.text2, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: isEditing
                        ? 'Edit your comment...'
                        : (widget.replyingToUser != null ? 'Add a reply...' : 'Add a comment...'),
                    hintStyle: const TextStyle(color: AppColors.text3, fontSize: 14),
                    filled: true,
                    fillColor: Colors.grey.withValues(alpha: 0.1),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24.0),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8.0),
              IconButton(
                icon: Icon(
                  isEditing ? Icons.check_circle_rounded : Icons.send_rounded,
                  color: AppColors.primary,
                ),
                onPressed: _handleSubmit,
              ),
            ],
          ),
        ],
      ),
    );
  }
}