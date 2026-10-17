  import 'package:flutter/material.dart';
import 'package:paws_and_found/features/feed/presentation/pages/general_reports_page.dart';
  import 'package:paws_and_found/core/theme/app_colors.dart';
  import 'package:paws_and_found/shared/molecules/paw_segmented_control.dart';
import 'package:paws_and_found/features/feed/presentation/pages/personal_reports_page.dart';

  class FeedPage extends StatefulWidget {
    const FeedPage({super.key});

    @override
    State<FeedPage> createState() => _FeedPageState();
  }

  class _FeedPageState extends State<FeedPage> {
    bool _isGeneralSelected = true;

    @override
    Widget build(BuildContext context) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Paws and Found'),
          backgroundColor: AppColors.primary,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            PawSegmentedControl(
              isFirstOptionSelected: _isGeneralSelected, 
              firstOptionText: 'General Reports', 
              secondOptionText: 'Your Reports', 
              activeColor: AppColors.primary,
              inactiveColor: AppColors.darkCharcoal,
              onOptionChanged: (bool value){
                setState((){
                  _isGeneralSelected = value;
                });
              }
            ),

          const SizedBox(height: 6),
          Expanded(
            child: _isGeneralSelected ? GeneralReports() : PersonalReportsPage(), //i change ni into different pages pagyud
            ),
          ],
        )
        )
      );
    }
  }