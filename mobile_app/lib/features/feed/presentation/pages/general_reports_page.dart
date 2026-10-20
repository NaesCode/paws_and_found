import 'package:flutter/material.dart';
import 'package:paws_and_found/features/feed/presentation/widgets/feed_filter_reports_dropdown.dart';
import 'package:paws_and_found/features/feed/presentation/widgets/feed_report_card_item.dart';
import 'package:paws_and_found/features/feed/presentation/widgets/feed_status_banner.dart';
import 'package:paws_and_found/shared/molecules/paw_loading.dart';

//hardcoded temp data and how to get them (can also be used for fetching real time from supa db)
import "package:paws_and_found/features/feed/data/models/feed_post_model.dart";
import "package:paws_and_found/features/feed/data/repositories/feed_repo_imp.dart";

// SHOWS THE GENERAL REPORTS (ALL) SO FAR THIS ALSO INCLUDES THE USER'S POST (GOTTA CHANGE MAYBE)

class GeneralReportsPage extends StatefulWidget{
  const GeneralReportsPage({super.key});


  @override 
  State<GeneralReportsPage> createState() => _GeneralReportsState();
}

class _GeneralReportsState extends State<GeneralReportsPage> {

  final FeedRepoImp _repository = FeedRepoImp();
  late Future<List<PetPostModel>> _reportsFuture;

  // for the filter (aron dli na magpasa2 ug indicators)
  String _selectedFilter = 'latest';
  final List<String> _generalFilters = ['Latest', 'Oldest', 'Near Me', 'Missing', 'Found', 'Spotted'];

  @override
  void initState() {
    super.initState();
    _reportsFuture = _repository.getGeneralReports();
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
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 0.0, vertical: 10.0),
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
                    filterOptions: _generalFilters,
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
            
            // TODO: change into dynamic data according to filters
            Expanded(
              child: FutureBuilder<List<PetPostModel>>(
                future: _reportsFuture,
                builder: (context, snapshot){
                  if (snapshot.connectionState == ConnectionState.waiting){
                    return const PawLoadingIndicator();
                  }
                  if(snapshot.hasError){
                    return Center(
                      child: Text('Error: ${snapshot.error}'));
                  }
                  final reports = snapshot.data ?? [];
                  if(reports.isEmpty){
                    return const Center(
                      child: Text('No Reports Found'));
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
                    // this is where the cards are shown - called the ReportCardItem (the widget that holds the ui of necessary detail posts while calling other widgets needed for a clean structure)
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
                          imageURL: report.imageUrl.isNotEmpty ? report.imageUrl : 'assets/images/images.jpg', //static usa kay wala pakoy link
                          button1Text: "Spotted",
                          button2Text: "Found",
                          onButton1Pressed: () {}, //TODO: need to put what should be shown
                          onButton2Pressed: () {},
                        );
                      },
                    ),
                  );
                },)
            )
          ],
        ),
      ),
    );
  }
}
