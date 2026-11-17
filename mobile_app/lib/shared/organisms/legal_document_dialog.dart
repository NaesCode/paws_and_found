import 'package:flutter/material.dart';
import '../../core/constants/app_legal_constants.dart';
import '../../core/theme/app_colors.dart';

/// Modal dialog organism displaying application legal documents (Privacy Policy & Terms of Service).
///
/// Adheres strictly to Atomic Design (lib/shared/organisms/).
/// Reusable dumb component rendered with clean typography and clause cards.
class LegalDocumentDialog extends StatelessWidget {
  final String title;
  final String lastUpdated;
  final String intro;
  final List<Map<String, dynamic>> sections;

  const LegalDocumentDialog({
    super.key,
    required this.title,
    required this.lastUpdated,
    required this.intro,
    required this.sections,
  });

  /// Static helper to display the Privacy Policy popup based directly on PRIVACY_POLICY.md.
  static Future<void> showPrivacyPolicy(BuildContext context) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) => const LegalDocumentDialog(
        title: AppLegalConstants.privacyPolicyTitle,
        lastUpdated: AppLegalConstants.lastUpdated,
        intro: AppLegalConstants.privacyPolicyIntro,
        sections: AppLegalConstants.privacyPolicySections,
      ),
    );
  }

  /// Static helper to display the Terms of Service popup based directly on TERMS_OF_SERVICE.md.
  static Future<void> showTermsOfService(BuildContext context) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) => const LegalDocumentDialog(
        title: AppLegalConstants.termsOfServiceTitle,
        lastUpdated: AppLegalConstants.lastUpdated,
        intro: AppLegalConstants.termsOfServiceIntro,
        sections: AppLegalConstants.termsOfServiceSections,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final maxHeight = mediaQuery.size.height * 0.82;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: maxHeight,
          maxWidth: 480,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Bar
            Container(
              padding: const EdgeInsets.fromLTRB(20, 18, 12, 14),
              decoration: const BoxDecoration(
                color: AppColors.primary,
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.description_outlined,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Last Updated: $lastUpdated',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Scrollable Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Intro Paragraph
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceMuted,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Text(
                        intro,
                        style: const TextStyle(
                          fontSize: 13.5,
                          height: 1.45,
                          color: AppColors.darkCharcoal,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Document Sections
                    ...sections.map((section) {
                      final sectionTitle = section['title'] as String;
                      final items = (section['items'] as List<dynamic>?) ?? [];

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              sectionTitle,
                              style: const TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            ...items.map((item) {
                              final text = item.toString();
                              final parts = text.split(': ');
                              final hasPrefix = parts.length > 1;

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 6, left: 4),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Padding(
                                      padding: EdgeInsets.only(top: 6, right: 8),
                                      child: Icon(
                                        Icons.circle,
                                        size: 6,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    Expanded(
                                      child: hasPrefix
                                          ? RichText(
                                              text: TextSpan(
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  height: 1.4,
                                                  color: AppColors.textPrimary,
                                                ),
                                                children: [
                                                  TextSpan(
                                                    text: '${parts[0]}: ',
                                                    style: const TextStyle(
                                                      fontWeight: FontWeight.w600,
                                                      color: AppColors.darkCharcoal,
                                                    ),
                                                  ),
                                                  TextSpan(
                                                    text: parts.sublist(1).join(': '),
                                                  ),
                                                ],
                                              ),
                                            )
                                          : Text(
                                              text,
                                              style: const TextStyle(
                                                fontSize: 13,
                                                height: 1.4,
                                                color: AppColors.textPrimary,
                                              ),
                                            ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),

            // Bottom Action Footer
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: const BoxDecoration(
                color: AppColors.surfaceMuted,
                border: Border(
                  top: BorderSide(color: AppColors.border),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text(
                      'I Understand',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
