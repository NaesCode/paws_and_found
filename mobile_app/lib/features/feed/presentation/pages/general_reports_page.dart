import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:paws_and_found/core/constants/app_assets.dart';
import 'package:paws_and_found/features/feed/presentation/widgets/feed_filter_reports_dropdown.dart';
import 'package:paws_and_found/features/feed/presentation/widgets/feed_report_card_item.dart';
import 'package:paws_and_found/features/feed/presentation/widgets/feed_status_banner.dart';
import 'package:paws_and_found/shared/molecules/paw_loading.dart';
import 'package:paws_and_found/features/feed/data/repositories/feed_repository_impl.dart';
import 'package:paws_and_found/features/feed/data/models/feed_post_model.dart';
import 'package:paws_and_found/features/feed/domain/repositories/feed_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../widgets/claim_confirm_dialog.dart';
import 'package:geolocator/geolocator.dart';

// SHOWS THE GENERAL REPORTS (ALL) EXCEPT THE USER'S POST

class GeneralReportsPage extends StatefulWidget{
  final String? isolatedReportId;
  final VoidCallback? onClearIsolation;

  const GeneralReportsPage({
    super.key,
    this.isolatedReportId,
    this.onClearIsolation,
  });

  @override 
  State<GeneralReportsPage> createState() => _GeneralReportsState();
}

class _GeneralReportsState extends State<GeneralReportsPage> {
  final FeedRepository _repository = FeedRepositoryImpl();
  late Future<List<FeedPost>> _reportsFuture;
  String? _isolatedReportId;

  // for the filter (aron dli na magpasa2 ug indicators)
  String _selectedFilter = 'latest';
  final List<String> _generalFilters = ['Latest', 'Oldest', 'Near Me', 'Missing', 'Found', 'Spotted'];

  String get _currentUserId {
    try {
      return Supabase.instance.client.auth.currentUser?.id ?? '';
    } catch (_) {
      return '';
    }
  }

  @override
  void initState() {
    super.initState();
    _isolatedReportId = widget.isolatedReportId;
    if (_isolatedReportId != null && _isolatedReportId!.isNotEmpty) {
      _loadIsolatedReport(_isolatedReportId!);
    } else {
      _reportsFuture = _repository.getGeneralReports(_currentUserId);
    }
  }

  @override
  void didUpdateWidget(GeneralReportsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isolatedReportId != oldWidget.isolatedReportId) {
      setState(() {
        _isolatedReportId = widget.isolatedReportId;
        if (_isolatedReportId != null && _isolatedReportId!.isNotEmpty) {
          _loadIsolatedReport(_isolatedReportId!);
        } else {
          _fetchGeneralReports(_selectedFilter);
        }
      });
    }
  }

  void _loadIsolatedReport(String reportId) {
    _reportsFuture = _repository.getReportById(reportId).then((post) {
      if (post != null) {
        return [post];
      }
      return <FeedPost>[];
    });
  }

  void _clearIsolation() {
    setState(() {
      _isolatedReportId = null;
      _fetchGeneralReports(_selectedFilter);
    });
    widget.onClearIsolation?.call();
  }

  Future<List<FeedPost>> _loadNearMeReports(String currentUserId) async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled.');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw Exception('Location permission is required to filter reports near you.');
    }

    final position = await Geolocator.getCurrentPosition();

    return _repository.getGeneralReportsNearMe(
      currentUserId,
      lat: position.latitude,
      lng: position.longitude,
      radiusMeters: null, 
    );
  }

  void _fetchGeneralReports(String filterValue) {
    final currentUserId = _currentUserId;
    
    setState(
      () {
      _isolatedReportId = null;
      _selectedFilter = filterValue;
      String dbFilterValue = filterValue;
      if (filterValue.toLowerCase() == 'spotted') {
        dbFilterValue = 'stray';
      }
      
      switch (filterValue.toLowerCase()) {
        case 'missing':
          _reportsFuture = _repository.getGeneralReports(currentUserId, filterStatus: filterValue);
            break;
        case 'found':
          _reportsFuture = _repository.getGeneralReports(currentUserId, filterStatus: filterValue);
          break;
        case 'spotted':
          _reportsFuture = _repository.getGeneralReports(currentUserId, filterStatus: dbFilterValue);
          break;
        case 'oldest':
          _reportsFuture = _repository.getGeneralReports(currentUserId).then((list) {
            list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
            return list;
          });
          break;
        case 'near me':
          _reportsFuture = _loadNearMeReports(currentUserId);
          break;
        case 'latest':
        default:
          _reportsFuture = _repository.getGeneralReports(currentUserId);
          break;
        }
      }
    );
  }

  BannerType _getBannerType(String status){
    switch(status.toLowerCase()){
      case 'missing': return BannerType.missing;
      case 'stray': return BannerType.spotted;
      case 'found': return BannerType.found;
      case 'safe': return BannerType.safe;
      default: return BannerType.missing;
    }
  }

  Widget _buildIsolationBanner() {
    String displayId = _isolatedReportId ?? '';
    if (displayId.contains('-')) {
      displayId = displayId.split('-').first.toUpperCase();
    } else if (displayId.length > 8) {
      displayId = displayId.substring(0, 8).toUpperCase();
    } else {
      displayId = displayId.toUpperCase();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.filter_alt_rounded, size: 20, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Post Filter Active',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.text3,
                  ),
                ),
                Text(
                  'Showing post #$displayId',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: _clearIsolation,
            icon: const Icon(Icons.clear_all_rounded, size: 16),
            label: const Text(
              'Show All',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isIsolated = _isolatedReportId != null && _isolatedReportId!.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(left: 0.0, right: 0.0, top: 14.0, bottom: 0.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isIsolated)
            _buildIsolationBanner()
          else ...[
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
                        _fetchGeneralReports(newValue);
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
            
          Expanded(
            child: FutureBuilder<List<FeedPost>>(
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
                  return RefreshIndicator(
                    color: AppColors.primary,
                    onRefresh: () async {
                      if (isIsolated) {
                        setState(() {
                          _loadIsolatedReport(_isolatedReportId!);
                        });
                      } else {
                        _fetchGeneralReports(_selectedFilter);
                      }
                    },
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        const SizedBox(height: 120),
                        Center(
                          child: Text(
                            isIsolated
                                ? 'Post not found or is no longer available.'
                                : 'No Reports Found',
                            style: const TextStyle(
                              color: AppColors.text3,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () async {
                    if (isIsolated) {
                      setState(() {
                        _loadIsolatedReport(_isolatedReportId!);
                      });
                    } else {
                      _fetchGeneralReports(_selectedFilter);
                    }
                  },
                    child: TweenAnimationBuilder<double>(
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
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: reports.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 15),
                        itemBuilder: (context, index) {
                        final report = reports[index];
                        final statusLower = report.status.toLowerCase();
                        final isSafe = statusLower == 'safe';
                        final isSpotted = statusLower == 'stray';
                        final isMissing = statusLower == 'missing';
                        final isFound = statusLower == 'found';

                        return ReportCardItem(
                        id: report.id,
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
                        userImageUrl: report.userImageUrl,
                        isFlagged: report.isFlagged,
                        petButtonText: isSafe
                        ? "Claimed"
                        : (isMissing || isSpotted) ? "View on Map" : "This is my pet",
                        button1Text: isFound
                            ? "View on Map"
                            : (isSpotted ? "Found" : "Spotted"),
                        button2Text: (isFound || isSpotted) ? null : "Found",
                        onPetButtonPressed: isSafe
                          ? null
                          : () {
                              if (isMissing || isSpotted) {
                                context.push('/map?reportId=${report.id}');
                              } else {
                                showConfirmMyPetDialog(context, report);
                              }
                            },
                        onButton1Pressed: isSafe
                          ? null
                          : () {
                              if (isFound) {
                                context.push('/map?reportId=${report.id}');
                              } else if (isSpotted) {
                                context.push(
                                  '/camera?threadId=${report.id}&petName=${Uri.encodeComponent(report.petName)}&status=found',
                                );
                              } else {
                                context.push(
                                  '/camera?threadId=${report.id}&petName=${Uri.encodeComponent(report.petName)}&status=stray',
                                );
                              }
                            },
                        onButton2Pressed: (isSafe || isFound || isSpotted)
                            ? null
                            : () {
                                context.push(
                                  '/camera?threadId=${report.id}&petName=${Uri.encodeComponent(report.petName)}&status=found',
                                );
                              },
                      );
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
