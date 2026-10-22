import 'package:flutter/material.dart';
import 'package:paws_and_found/features/feed/presentation/pages/general_reports_page.dart';
import 'package:paws_and_found/core/theme/app_colors.dart';
import 'package:paws_and_found/shared/molecules/paw_segmented_control.dart';
import 'package:paws_and_found/features/feed/presentation/pages/personal_reports_page.dart';
import 'package:go_router/go_router.dart';

//
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
        title: const Text('Reports'),
        backgroundColor: AppColors.primary,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      // 💡 FIX: Wrap the body in a SafeArea and set bottom to false!
      body: SafeArea(
        bottom: false, // Prevents nested double system padding at the bottom edge
        child: Padding(
          padding: const EdgeInsets.only(left: 12.0, right: 12.0, top: 12.0, bottom: 0.0), // Reduced bottom padding
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
              const SizedBox(height: 4),
              Expanded(
                child: _isGeneralSelected ? 
                const GeneralReportsPage() : const PersonalReportsPage(),
              ),
            ],
          ),
        ),
      ),
      //report sighting button
      floatingActionButton: !_isGeneralSelected 
          ? FloatingActionButton.extended(
              backgroundColor: AppColors.accentOrange,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_a_photo_rounded),
              label: const Text('Report Sighting'),
              onPressed: () {
                context.push('/camera');
              },
            )
          : null,
    );
  }
}
