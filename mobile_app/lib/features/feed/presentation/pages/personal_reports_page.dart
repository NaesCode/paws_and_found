import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:paws_and_found/core/constants/app_assets.dart';
import 'package:paws_and_found/features/feed/data/repositories/feed_repository_impl.dart';
import 'package:paws_and_found/features/feed/domain/entities/feed_post.dart';
import 'package:paws_and_found/features/feed/domain/repositories/feed_repository.dart';
import 'package:paws_and_found/features/feed/presentation/widgets/feed_filter_reports_dropdown.dart';
import 'package:paws_and_found/features/feed/presentation/widgets/feed_report_card_item.dart';
import 'package:paws_and_found/features/feed/presentation/widgets/feed_status_banner.dart';
import 'package:paws_and_found/shared/molecules/paw_loading.dart';
import 'package:paws_and_found/shared/organisms/location_pin_picker_sheet.dart';

/// Screen displaying personal animal reports submitted by the logged-in user.
///
/// Features:
/// - Category filtering ("Latest", "Oldest", "Missing", "Found", "Spotted")
/// - Interactive "Pin on Map" option allowing users to reposition/pin missing pets
/// - Direct "View on Map" integration which deep-links to the Community Animal Map
class PersonalReportsPage extends StatefulWidget {
  final bool showBottomNavPlaceholder;

  const PersonalReportsPage({
    super.key,
    this.showBottomNavPlaceholder = true,
  });

  @override 
  State<PersonalReportsPage> createState() => _PersonalReportsState();
}

class _PersonalReportsState extends State<PersonalReportsPage> {
  final FeedRepository _repository = FeedRepositoryImpl();
  late Future<List<FeedPost>> _reportsFuture;

  // for the filter dropdown
  String _selectedFilter = 'latest';
  final List<String> _personalFilters = ['Latest', 'Oldest', 'Missing', 'Found', 'Spotted'];

  @override
  void initState() {
    super.initState();
    _reportsFuture = _repository.getPersonalReports("user_001");
  }

  BannerType _getBannerType(String status) {
    switch (status.toLowerCase()) {
      case 'missing':
        return BannerType.missing;
      case 'spotted':
        return BannerType.spotted;
      case 'found':
        return BannerType.found;
      default:
        return BannerType.missing;
    }
  }

  Future<void> _handlePinOnMap(FeedPost report) async {
    final double initialLat = report.latitude ?? 14.5995;
    final double initialLng = report.longitude ?? 120.9842;

    final picked = await LocationPinPickerSheet.show(
      context: context,
      initialLocation: LatLng(initialLat, initialLng),
      pinStatus: report.status,
      title: 'Pin ${report.petName} on Animal Map',
      subtitle: 'Tap anywhere on the map to reposition this report pin',
    );

    if (picked != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Pin updated for ${report.petName}: ${picked.latitude.toStringAsFixed(4)}° N, ${picked.longitude.toStringAsFixed(4)}° E',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _handleViewOnMap(FeedPost report) {
    final double lat = report.latitude ?? 14.5995;
    final double lng = report.longitude ?? 120.9842;
    context.go('/map?reportId=${report.id}&lat=$lat&lng=$lng');
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
                      });
                    },
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 10), 
            
            Expanded(
              child: FutureBuilder<List<FeedPost>>(
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
                        final isMissing = report.status.toLowerCase() == 'missing';

                        return ReportCardItem(
                          bannerType: _getBannerType(report.status),
                          petName: report.petName,
                          postedBy: report.postedBy,
                          species: report.species,
                          location: report.location,
                          description: report.description,
                          formattedTime: report.formattedTime,
                          imageURL: report.imageUrl.isNotEmpty
                              ? report.imageUrl
                              : AppAssets.petPlaceholder,
                          button1Text: isMissing ? "Pin on Map" : "View on Map",
                          button2Text: isMissing ? "View Map" : "Found",
                          onButton1Pressed: () {
                            if (isMissing) {
                              _handlePinOnMap(report);
                            } else {
                              _handleViewOnMap(report);
                            }
                          },
                          onButton2Pressed: () {
                            if (isMissing) {
                              _handleViewOnMap(report);
                            }
                          },
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
