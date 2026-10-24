import 'package:flutter/material.dart';
import 'package:paws_and_found/core/theme/app_colors.dart';
import 'reply_indicator_bar.dart';

class FeedCommentInputBar extends StatefulWidget {
  final String? replyingToUser;
  final FocusNode focusNode;
  final VoidCallback onCancelReply;
  final Function(String text, String? replyToUser) onCommentSubmitted;

  const FeedCommentInputBar({
    super.key,
    required this.replyingToUser,
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
    return Container(
      padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 10.0, bottom: 24.0),
      decoration: BoxDecoration(
        color: AppColors.background1,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, -2),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.replyingToUser != null)
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
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                  style: const TextStyle(color: AppColors.text2, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: widget.replyingToUser != null ? 'Add a reply...' : 'Add a comment...',
                    hintStyle: const TextStyle(color: AppColors.text3, fontSize: 14),
                    filled: true,
                    fillColor: Colors.grey.withOpacity(0.1),
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
                icon: const Icon(Icons.send_rounded, color: AppColors.primary),
                onPressed: _handleSubmit,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
