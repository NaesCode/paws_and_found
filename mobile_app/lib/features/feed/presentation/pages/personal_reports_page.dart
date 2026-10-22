import 'package:flutter/material.dart';
import 'package:paws_and_found/features/feed/presentation/widgets/feed_filter_reports_dropdown.dart';
import 'package:paws_and_found/features/feed/presentation/widgets/feed_report_card_item.dart';
// import 'package:paws_and_found/core/theme/app_colors.dart';
// import 'package:paws_and_found/features/report/presentation/pages/camera_report_page.dart';
// import 'package:go_router/go_router.dart';
import 'package:paws_and_found/features/feed/presentation/widgets/feed_status_banner.dart';
import 'package:paws_and_found/shared/molecules/paw_loading.dart';

//hardcoded temp data
import "package:paws_and_found/features/feed/data/models/feed_post_model.dart";
import "package:paws_and_found/features/feed/data/repositories/feed_repo_imp.dart";

// SHOWS THE PERSONAL REPORTS MEAN THE USER'S POST ONLY CAN BE SHOWN, AND THERE IS A BUTTON FOR MAKING A NEW REPORT (I-EDIT PA)

class PersonalReportsPage extends StatefulWidget{
  final bool showBottomNavPlaceholder;

  const PersonalReportsPage({
    super.key,
    this.showBottomNavPlaceholder = true,
  });

  @override 
  State<PersonalReportsPage> createState() => _PersonalReportsState();
}

class _PersonalReportsState extends State<PersonalReportsPage> {
  final FeedRepoImp _repository = FeedRepoImp();
  late Future<List<PetPostModel>> _reportsFuture;

  // for the filter dropdown
    String _selectedFilter = 'latest';
  final List<String> _personalFilters = ['Latest', 'Oldest', 'Missing', 'Found', 'Spotted'];

  @override
  void initState(){
    super.initState();
    // TODO: change the user_001 to real user data from db, probably the way how sean did the profile page
    _reportsFuture = _repository.getPersonalReports("user_001");
  }

  BannerType _getBannerType(String status){
    switch(status.toLowerCase()){
      case 'missing': return BannerType.missing;
      case 'spotted': return BannerType.spotted;
      case 'found': return BannerType.found;
      default: return BannerType.missing;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(left: 0.0, right: 0.0, top: 14.0, bottom: 0.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 0.0),
                  child: FilterButtonDropdown(
                    selectedLabel: _selectedFilter,
                    filterOptions: _personalFilters,
                    onFilterChanged: (newValue) {
                      setState(() {
                        _selectedFilter = newValue;
                        // TODO: Re-fetch or filter your general feed data matching newValue
                      });
                    },
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 10), 
            
            Expanded(
              child: FutureBuilder<List<PetPostModel>>(
                future: _reportsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const PawLoadingIndicator();
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  final reports = snapshot.data ?? [];
                  if (reports.isEmpty) {
                    return const Center(child: Text('No Reports Found'));
                  }

                  return TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeOutCubic,
                    builder: (context, opacityValue, child) {
                      return Opacity(
                        opacity: opacityValue,
                        child: child,
                      );
                    },
                    child: ListView.separated(
                      itemCount: reports.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 15),
                      itemBuilder: (context, index) {
                        final report = reports[index];

                        return ReportCardItem(
                          bannerType: _getBannerType(report.status),
                          petName: report.petName,
                          postedBy: report.postedBy,
                          species: report.species,
                          location: report.location,
                          description: report.description,
                          formattedTime: report.formattedTime,
                          imageURL: report.imageUrl.isNotEmpty ? report.imageUrl : 'assets/images/images.jpg',
                          button1Text: "Edit",
                          button2Text: "Found",
                          onButton1Pressed: () {},
                          onButton2Pressed: () {},
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

