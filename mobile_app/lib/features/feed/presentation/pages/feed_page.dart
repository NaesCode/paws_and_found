import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:go_router/go_router.dart';
import 'package:paws_and_found/core/services/user_restriction_service.dart';
import 'package:paws_and_found/core/theme/app_colors.dart';
import 'package:paws_and_found/features/feed/presentation/pages/general_reports_page.dart';
import 'package:paws_and_found/features/feed/presentation/pages/personal_reports_page.dart';
import 'package:paws_and_found/features/feed/presentation/widgets/feed_suspended_view.dart';
import 'package:paws_and_found/shared/atoms/app_logo.dart';
import 'package:paws_and_found/shared/molecules/app_overflow_menu.dart';
import 'package:paws_and_found/shared/molecules/paw_segmented_control.dart';

class FeedPage extends StatefulWidget {
  final Widget? generalReportsView;
  final Widget? personalReportsView;
  final UserRestrictionService? restrictionService;
  final String? isolatedReportId;
  final VoidCallback? onClearIsolation;

  const FeedPage({
    super.key,
    this.generalReportsView,
    this.personalReportsView,
    this.restrictionService,
    this.isolatedReportId,
    this.onClearIsolation,
  });

  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  late final UserRestrictionService _restrictionService;
  bool _isGeneralSelected = true;
  bool _isFabExtended = true;
  bool _isFabVisible = true;
  bool _isUserSuspended = false;
  String? _isolatedReportId;

  @override
  void initState() {
    super.initState();
    _restrictionService = widget.restrictionService ?? const UserRestrictionService();
    _checkSuspensionStatus();
    
    _isolatedReportId = widget.isolatedReportId;
    if (_isolatedReportId != null && _isolatedReportId!.isNotEmpty) {
      _isGeneralSelected = true;
    }
  }

  @override
  void didUpdateWidget(FeedPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isolatedReportId != oldWidget.isolatedReportId) {
      setState(() {
        _isolatedReportId = widget.isolatedReportId;
        if (_isolatedReportId != null && _isolatedReportId!.isNotEmpty) {
          _isGeneralSelected = true;
        }
      });
    }
  }

  void _clearIsolation() {
    setState(() {
      _isolatedReportId = null;
    });
    widget.onClearIsolation?.call();
  }

  Future<void> _checkSuspensionStatus() async {
    final suspended = await _restrictionService.isUserSuspended();
    if (mounted) {
      setState(() {
        _isUserSuspended = suspended;
      });
    }
  }

  bool _onScrollNotification(ScrollNotification notification) {
    if (notification is UserScrollNotification) {
      if (notification.direction == ScrollDirection.reverse) {
        // Scrolling down: collapse smoothly to icon
        if (_isFabExtended) {
          setState(() {
            _isFabExtended = false;
          });
        }
      } else if (notification.direction == ScrollDirection.forward) {
        // Scrolling up: expand smoothly back to text
        if (!_isFabExtended || !_isFabVisible) {
          setState(() {
            _isFabExtended = true;
            _isFabVisible = true;
          });
        }
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppLogo(size: 32),
            SizedBox(width: 10),
            Text('Reports'),
          ],
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: const [
          AppOverflowMenu(),
        ],
      ),
      body: _isUserSuspended
          ? FeedSuspendedView(
              onRefreshStatus: _checkSuspensionStatus,
            )
          : SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.only(left: 12.0, right: 12.0, top: 12.0, bottom: 0.0),
                child: Column(
                  children: [
                    PawSegmentedControl(
                      isFirstOptionSelected: _isGeneralSelected,
                      firstOptionText: 'General Reports',
                      secondOptionText: 'Your Reports',
                      activeColor: AppColors.contrast1,
                      inactiveColor: AppColors.darkCharcoal,
                      onOptionChanged: (bool value) {
                        setState(() {
                          _isGeneralSelected = value;
                        });
                      },
                    ),
                    const SizedBox(height: 4),
                    Expanded(
                      child: NotificationListener<ScrollNotification>(
                        onNotification: _onScrollNotification,
                        child: _isGeneralSelected
                            ? (widget.generalReportsView ?? GeneralReportsPage(
                              isolatedReportId: _isolatedReportId,
                              onClearIsolation: _clearIsolation,
                            ))
                            : (widget.personalReportsView ?? const PersonalReportsPage()),
                      ),
                    ),
                  ],
                ),
              ),
            ),
      floatingActionButton: (!_isUserSuspended && !_isGeneralSelected && _isFabVisible)
          ? AnimatedScale(
              scale: _isFabVisible ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              child: FloatingActionButton.extended(
                extendedPadding: _isFabExtended
                    ? const EdgeInsets.symmetric(horizontal: 16.0)
                    : const EdgeInsets.all(16.0),
                backgroundColor: AppColors.darkSlate,
                foregroundColor: Colors.white,
                onPressed: () => context.push('/camera'),
                icon: const Icon(Icons.add_a_photo_rounded),
                label: AnimatedSize(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  child: _isFabExtended
                      ? const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(width: 8.0),
                            Text(
                              'Report Sighting',
                              maxLines: 1,
                              softWrap: false,
                            ),
                          ],
                        )
                      : const SizedBox.shrink(),
                ),
              ),
            )
          : null,
    );
  }
}
