import 'package:flutter/material.dart';
import 'package:paws_and_found/core/theme/app_colors.dart';
import 'package:paws_and_found/shared/atoms/drag_handle.dart';
import 'package:paws_and_found/features/feed/presentation/widgets/feed_card_comments.dart';
import 'feed_comment_input_bar.dart';
import "./feed_comment_input_bar.dart";

class FeedCommentsModal extends StatefulWidget {
  const FeedCommentsModal({super.key});

  @override
  State<FeedCommentsModal> createState() => _FeedCommentsModalState();
}

class _FeedCommentsModalState extends State<FeedCommentsModal> {
  String? _replyingToUser;
  final FocusNode _commentFocusNode = FocusNode();

  @override
  void dispose() {
    _commentFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

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
                DragHandle(),
                const Divider(
                  color: AppColors.text1,
                  height: 16,
                ),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    itemCount: 5,
                    itemBuilder: (context, index) {
                      const mockUsername = "banana";
                      return FeedCardComments(
                        username: mockUsername,
                        timeAgo: "2 days ago",
                        commentText: "I've seen him with leash on, wandering the streets of mumbai",
                        onReplyTap: () {
                          setState(() {
                            _replyingToUser = mockUsername;
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
                    });
                  },
                  onCommentSubmitted: (text, replyTo) {
                    if (replyTo != null) {
                      print('Replying to $replyTo: $text');
                    } else {
                      print('New comment: $text');
                    }
                    setState(() {
                      _replyingToUser = null;
                    });
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
