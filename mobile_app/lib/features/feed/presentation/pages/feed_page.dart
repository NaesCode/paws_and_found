import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:paws_and_found/features/feed/presentation/pages/general_reports_page.dart';
import 'package:paws_and_found/core/theme/app_colors.dart';
import 'package:paws_and_found/shared/molecules/paw_segmented_control.dart';
import 'package:paws_and_found/features/feed/presentation/pages/personal_reports_page.dart';
import 'package:go_router/go_router.dart';

class FeedPage extends StatefulWidget {
  final Widget? generalReportsView;
  final Widget? personalReportsView;
  const FeedPage({
    super.key,
    this.generalReportsView,
    this.personalReportsView,
    });

  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  bool _isGeneralSelected = true;
  bool _isFabExtended = true;
  bool _isFabVisible = true;

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
        title: const Text('Reports'),
        backgroundColor: AppColors.primary,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.only(left: 12.0, right: 12.0, top: 12.0, bottom: 0.0),
          child: Column(
            children: [
              PawSegmentedControl(
                isFirstOptionSelected: _isGeneralSelected,
                firstOptionText: 'General Reports',
                secondOptionText: 'Your Reports',
                activeColor: AppColors.primary,
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
                      ? (widget.generalReportsView ?? const GeneralReportsPage())
                      : (widget.personalReportsView ?? const PersonalReportsPage()),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: (!_isGeneralSelected && _isFabVisible)
      ? AnimatedScale(
          scale: _isFabVisible ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          child: FloatingActionButton.extended(
            extendedPadding: _isFabExtended 
                ? const EdgeInsets.symmetric(horizontal: 16.0) 
                : const EdgeInsets.all(16.0),
            backgroundColor: AppColors.accentOrange,
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
                        SizedBox(width: 8.0), // Spacing between icon & label
                        Text(
                          'Report Sighting',
                          maxLines: 1,
                          softWrap: false,
                        ),
                      ],
                    )
                  : const SizedBox.shrink(), // Collapses label space entirely
            ),
          ),
        )
      : null,
    );
  }
}