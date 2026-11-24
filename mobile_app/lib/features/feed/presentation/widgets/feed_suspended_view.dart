import 'package:flutter/material.dart';
import '../../../../shared/organisms/account_suspended_view.dart';

/// Full-page restriction widget displayed when a suspended user navigates to the Feeds page.
///
/// Backwards-compatible wrapper around [AccountSuspendedView].
class FeedSuspendedView extends StatelessWidget {
  final VoidCallback? onRefreshStatus;
  final VoidCallback? onSignOut;
  final VoidCallback? onContactAdmin;
  final String adminEmail;
  final String? customMessage;

  const FeedSuspendedView({
    super.key,
    this.onRefreshStatus,
    this.onSignOut,
    this.onContactAdmin,
    this.adminEmail = 'pawsandfound26@gmail.com',
    this.customMessage,
  });

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
      key: const Key('feed_suspended_view'),
      child: AccountSuspendedView(
        onRefreshStatus: onRefreshStatus,
        onSignOut: onSignOut,
        onContactAdmin: onContactAdmin,
        adminEmail: adminEmail,
        customMessage: customMessage,
      ),
    );
  }
}
