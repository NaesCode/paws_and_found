import 'package:flutter/material.dart';
import '../../../../core/theme/wireframe_colors.dart';
import '../../data/datasources/admin_static_data.dart';
import '../../data/models/admin_post_item.dart';
import '../../data/models/admin_user_item.dart';
import '../../data/repositories/admin_repository_impl.dart';
import '../../domain/repositories/admin_repository.dart';
import '../widgets/admin_bar_chart.dart';
import '../widgets/admin_bottom_nav_bar.dart';
import '../widgets/admin_header.dart';
import '../widgets/admin_pie_chart.dart';

/// Screen — ADMIN · ANALYTICS & INSIGHTS
///
/// Provides executive and administrative visual analytics:
/// - User Management: Total users, New Users this week vs this month,
///   registration trend bar chart, and account status breakdowns.
/// - Post Management: Interactive Donut / Pie Chart visualizing post
///   statuses (Missing, Stray, Found) and content moderation health.
class AdminAnalyticsPage extends StatefulWidget {
  final ValueChanged<int>? onTabChanged;
  final VoidCallback? onLogout;
  final int selectedTabIndex;
  final AdminRepository? repository;
  final bool showBottomNav;

  const AdminAnalyticsPage({
    super.key,
    this.onTabChanged,
    this.onLogout,
    this.selectedTabIndex = 2,
    this.repository,
    this.showBottomNav = true,
  });

  @override
  State<AdminAnalyticsPage> createState() => _AdminAnalyticsPageState();
}

class _AdminAnalyticsPageState extends State<AdminAnalyticsPage> {
  late final AdminRepository _adminRepository;

  bool _isLoading = true;
  String? _errorMessage;
  List<AdminUserItem> _users = [];
  List<AdminPostItem> _posts = [];

  // User timeframe toggle: 'weekly', 'monthly', 'yearly'
  String _userTimeframe = 'weekly';

  // Post timeframe toggle: 'daily', 'weekly', 'monthly'
  String _postTimeframe = 'weekly';

  // Section filter toggle: 'users', 'posts'
  String _activeSectionFilter = 'users';

  // History scanning offsets for users: 0 = current, -1 = 1 period ago, -2 = 2 periods ago, etc.
  int _userWeekOffset = 0;
  int _userMonthOffset = 0;
  int _userYearOffset = 0;
  final ScrollController _periodScrollController = ScrollController();

  // History scanning offsets for posts: 0 = current, -1 = 1 period ago, etc.
  int _postWeekOffset = 0;
  int _postMonthOffset = 0;
  int _postYearOffset = 0;
  final ScrollController _postPeriodScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _adminRepository = widget.repository ?? AdminRepositoryImpl();
    _loadAnalytics();
  }

  @override
  void dispose() {
    _periodScrollController.dispose();
    _postPeriodScrollController.dispose();
    super.dispose();
  }

  Future<void> _loadAnalytics() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        _adminRepository.fetchUsers(),
        _adminRepository.fetchPosts(),
      ]);

      if (!mounted) return;
      setState(() {
        _users = results[0] as List<AdminUserItem>;
        _posts = results[1] as List<AdminPostItem>;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
        // Fallback fixtures for testing or offline environment
        if (_users.isEmpty) {
          _users = AdminStaticData.users;
        }
        if (_posts.isEmpty) {
          _posts = AdminStaticData.posts;
        }
      });
    }
  }

  // ---------------------------------------------------------------------------
  // Metric Calculations
  // ---------------------------------------------------------------------------

  bool get _hasRealTimestamps => _users.any((u) => u.createdAt != null);
  bool get _hasPostTimestamps => _posts.any((p) => p.createdAt != null);

  int _countUsersInWeek(DateTime monday) {
    final start = DateTime(monday.year, monday.month, monday.day);
    final end = start.add(const Duration(days: 7));
    return _users.where((u) {
      if (u.createdAt == null) return false;
      return !u.createdAt!.isBefore(start) && u.createdAt!.isBefore(end);
    }).length;
  }

  int _countUsersInMonth(DateTime monthStart) {
    final monthEnd = (monthStart.month < 12)
        ? DateTime(monthStart.year, monthStart.month + 1, 1)
        : DateTime(monthStart.year + 1, 1, 1);
    return _users.where((u) {
      if (u.createdAt == null) return false;
      return !u.createdAt!.isBefore(monthStart) && u.createdAt!.isBefore(monthEnd);
    }).length;
  }

  int _countUsersInYear(int year) {
    final start = DateTime(year, 1, 1);
    final end = DateTime(year + 1, 1, 1);
    return _users.where((u) {
      if (u.createdAt == null) return false;
      return !u.createdAt!.isBefore(start) && u.createdAt!.isBefore(end);
    }).length;
  }

  int _countPostsInWeek(DateTime monday) {
    final start = DateTime(monday.year, monday.month, monday.day);
    final end = start.add(const Duration(days: 7));
    return _posts.where((p) {
      if (p.createdAt == null) return false;
      return !p.createdAt!.isBefore(start) && p.createdAt!.isBefore(end);
    }).length;
  }

  int _countPostsInMonth(DateTime monthStart) {
    final monthEnd = (monthStart.month < 12)
        ? DateTime(monthStart.year, monthStart.month + 1, 1)
        : DateTime(monthStart.year + 1, 1, 1);
    return _posts.where((p) {
      if (p.createdAt == null) return false;
      return !p.createdAt!.isBefore(monthStart) && p.createdAt!.isBefore(monthEnd);
    }).length;
  }

  int _countPostsInYear(int year) {
    final start = DateTime(year, 1, 1);
    final end = DateTime(year + 1, 1, 1);
    return _posts.where((p) {
      if (p.createdAt == null) return false;
      return !p.createdAt!.isBefore(start) && p.createdAt!.isBefore(end);
    }).length;
  }

  List<AdminUserItem> get _newUsersInSelectedTimeframe {
    final now = DateTime.now();
    DateTime startCutoff;
    DateTime endCutoff;

    if (_userTimeframe == 'yearly' || _userTimeframe == 'year') {
      final targetYear = now.year + _userYearOffset;
      startCutoff = DateTime(targetYear, 1, 1);
      endCutoff = DateTime(targetYear + 1, 1, 1);
    } else if (_userTimeframe == 'monthly' || _userTimeframe == 'month') {
      final totalMonths = (now.year * 12 + (now.month - 1)) + _userMonthOffset;
      final targetYear = totalMonths ~/ 12;
      final targetMonth = (totalMonths % 12) + 1;
      startCutoff = DateTime(targetYear, targetMonth, 1);
      endCutoff = (targetMonth < 12)
          ? DateTime(targetYear, targetMonth + 1, 1)
          : DateTime(targetYear + 1, 1, 1);
    } else {
      // Weekly
      final currentMonday = DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: now.weekday - 1));
      final targetMonday = currentMonday.add(Duration(days: _userWeekOffset * 7));
      startCutoff = targetMonday;
      endCutoff = targetMonday.add(const Duration(days: 7));
    }

    final filtered = _users.where((u) {
      if (u.createdAt == null) return false;
      return !u.createdAt!.isBefore(startCutoff) &&
          u.createdAt!.isBefore(endCutoff);
    }).toList();

    // If data items lack exact createdAt timestamps in static mock fixtures,
    // provide a representative subset so visualizations display realistically.
    // If real timestamps exist, strictly respect the real data (do not fabricate counts).
    if (!_hasRealTimestamps && filtered.isEmpty && _users.isNotEmpty) {
      int sampleCount;
      if (_userTimeframe == 'yearly' || _userTimeframe == 'year') {
        sampleCount = _userYearOffset < 0
            ? (_users.length >= 3 ? _users.length - 1 : 1)
            : _users.length;
      } else if (_userTimeframe == 'monthly' || _userTimeframe == 'month') {
        sampleCount = _userMonthOffset < 0
            ? (_users.length >= 2 ? 2 : 1)
            : (_users.length >= 3 ? 3 : _users.length);
      } else {
        sampleCount = _userWeekOffset < 0 ? 1 : (_users.length >= 2 ? 2 : 1);
      }
      return _users.take(sampleCount).toList();
    }
    return filtered;
  }

  List<BarChartGroup> _generateUserRegistrationBars() {
    final now = DateTime.now();

    if (_userTimeframe == 'weekly' || _userTimeframe == 'week') {
      const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      final currentWeekday = now.weekday; // 1 = Mon, 7 = Sun
      final currentMonday = DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: now.weekday - 1));
      final targetMonday = currentMonday.add(Duration(days: _userWeekOffset * 7));

      return List.generate(7, (i) {
        final dayIndex = (i + 1); // 1 to 7
        final dayStart = targetMonday.add(Duration(days: i));
        final dayEnd = dayStart.add(const Duration(days: 1));

        final isToday = (_userWeekOffset == 0) && dayIndex == currentWeekday;
        final isFutureDay = (_userWeekOffset == 0) && dayIndex > currentWeekday;

        // Count users registered on this weekday
        int count = 0;
        for (final u in _users) {
          if (u.createdAt != null &&
              !u.createdAt!.isBefore(dayStart) &&
              u.createdAt!.isBefore(dayEnd)) {
            count++;
          }
        }

        // Fallback ONLY for static mock data when NO timestamps exist in the dataset
        if (!_hasRealTimestamps && count == 0 && _users.isNotEmpty) {
          if (isToday) {
            count = 2;
          } else if (_userWeekOffset < 0) {
            count = (i == 1 || i == 4) ? 1 : 0;
          } else if (!isFutureDay && (i == 1 || i == 3)) {
            count = 1;
          } else {
            count = 0;
          }
        }

        return BarChartGroup(
          label: weekdays[i],
          value: count,
          isHighlight: isToday,
        );
      });
    } else if (_userTimeframe == 'monthly' || _userTimeframe == 'month') {
      // Month view: Weeks 1 to 4 of target month
      final totalMonths = (now.year * 12 + (now.month - 1)) + _userMonthOffset;
      final targetYear = totalMonths ~/ 12;
      final targetMonth = (totalMonths % 12) + 1;

      final currentWeekOfMonth = ((now.day - 1) ~/ 7) + 1;
      final targetMonthStart = DateTime(targetYear, targetMonth, 1);
      final targetMonthEnd = (targetMonth < 12)
          ? DateTime(targetYear, targetMonth + 1, 1)
          : DateTime(targetYear + 1, 1, 1);

      // Bucket real user registrations by week of target month
      final weekCounts = [0, 0, 0, 0];
      for (final u in _users) {
        if (u.createdAt != null &&
            !u.createdAt!.isBefore(targetMonthStart) &&
            u.createdAt!.isBefore(targetMonthEnd)) {
          final weekIndex = ((u.createdAt!.day - 1) ~/ 7).clamp(0, 3);
          weekCounts[weekIndex]++;
        }
      }

      final totalInPeriod = _newUsersInSelectedTimeframe.length;

      return List.generate(4, (i) {
        final weekNum = i + 1;
        final isCurrentWeek =
            (_userMonthOffset == 0) && weekNum == currentWeekOfMonth.clamp(1, 4);
        final isFutureWeek = (_userMonthOffset == 0) && weekNum > currentWeekOfMonth;

        int value = 0;
        if (_hasRealTimestamps) {
          value = weekCounts[i];
        } else {
          if (isCurrentWeek) {
            value = totalInPeriod > 0 ? totalInPeriod : 2;
          } else if (_userMonthOffset < 0) {
            value = (i == 0 || i == 2) ? 1 : (i == 1 ? 2 : 0);
          } else if (!isFutureWeek) {
            value = 1;
          } else {
            value = 0;
          }
        }

        return BarChartGroup(
          label: 'Wk $weekNum',
          value: value,
          isHighlight: isCurrentWeek,
        );
      });
    } else {
      // Yearly view: 12 months (Jan through Dec) of target year
      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec'
      ];
      final targetYear = now.year + _userYearOffset;
      final targetYearStart = DateTime(targetYear, 1, 1);
      final nextYearStart = DateTime(targetYear + 1, 1, 1);

      final monthCounts = List.filled(12, 0);
      for (final u in _users) {
        if (u.createdAt != null &&
            !u.createdAt!.isBefore(targetYearStart) &&
            u.createdAt!.isBefore(nextYearStart) &&
            u.createdAt!.month >= 1 &&
            u.createdAt!.month <= 12) {
          monthCounts[u.createdAt!.month - 1]++;
        }
      }

      return List.generate(12, (i) {
        final monthNum = i + 1;
        final isCurrentMonth = (_userYearOffset == 0) && monthNum == now.month;
        final isFutureMonth = (_userYearOffset == 0) && monthNum > now.month;

        int value = 0;
        if (_hasRealTimestamps) {
          value = monthCounts[i];
        } else {
          if (isCurrentMonth) {
            value = 3;
          } else if (_userYearOffset < 0) {
            value = (i % 3 == 0) ? 2 : 1;
          } else if (!isFutureMonth) {
            value = (i % 2 == 0) ? 2 : 1;
          } else {
            value = 0;
          }
        }

        return BarChartGroup(
          label: months[i],
          value: value,
          isHighlight: isCurrentMonth,
        );
      });
    }
  }

  List<AdminPostItem> get _postsInSelectedTimeframe {
    final now = DateTime.now();
    DateTime startCutoff;
    DateTime endCutoff;

    if (_postTimeframe == 'yearly' || _postTimeframe == 'year') {
      final targetYear = now.year + _postYearOffset;
      startCutoff = DateTime(targetYear, 1, 1);
      endCutoff = DateTime(targetYear + 1, 1, 1);
    } else if (_postTimeframe == 'monthly' || _postTimeframe == 'month') {
      final totalMonths = (now.year * 12 + (now.month - 1)) + _postMonthOffset;
      final targetYear = totalMonths ~/ 12;
      final targetMonth = (totalMonths % 12) + 1;
      startCutoff = DateTime(targetYear, targetMonth, 1);
      endCutoff = (targetMonth < 12)
          ? DateTime(targetYear, targetMonth + 1, 1)
          : DateTime(targetYear + 1, 1, 1);
    } else {
      // Weekly (or default)
      final currentMonday = DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: now.weekday - 1));
      final targetMonday = currentMonday.add(Duration(days: _postWeekOffset * 7));
      startCutoff = targetMonday;
      endCutoff = targetMonday.add(const Duration(days: 7));
    }

    final filtered = _posts.where((p) {
      if (p.createdAt == null) return false;
      return !p.createdAt!.isBefore(startCutoff) &&
          p.createdAt!.isBefore(endCutoff);
    }).toList();

    // Fallback if data items lack createdAt timestamps in mock fixtures
    if (!_hasPostTimestamps && filtered.isEmpty && _posts.isNotEmpty) {
      int sampleCount;
      if (_postTimeframe == 'yearly' || _postTimeframe == 'year') {
        sampleCount = _postYearOffset < 0
            ? (_posts.length >= 3 ? _posts.length - 1 : 1)
            : _posts.length;
      } else if (_postTimeframe == 'monthly' || _postTimeframe == 'month') {
        sampleCount = _postMonthOffset < 0
            ? (_posts.length >= 2 ? 2 : 1)
            : (_posts.length >= 3 ? 3 : _posts.length);
      } else {
        sampleCount = _postWeekOffset < 0 ? 1 : (_posts.length >= 2 ? 2 : 1);
      }
      return _posts.take(sampleCount).toList();
    }
    return filtered;
  }

  List<PieChartSegment> _generatePostStatusSegments() {
    final activePosts = _postsInSelectedTimeframe;
    final missingCount =
        activePosts.where((p) => p.isMissing).length.toDouble();
    final strayCount = activePosts.where((p) => p.isStray).length.toDouble();
    final foundCount = activePosts.where((p) => p.isFound).length.toDouble();

    final total = missingCount + strayCount + foundCount;
    final fallbackMissing = total == 0 ? 1.0 : missingCount;
    final fallbackStray = total == 0 ? 1.0 : strayCount;
    final fallbackFound = total == 0 ? 1.0 : foundCount;

    return [
      PieChartSegment(
        label: 'Missing Pets',
        value: total == 0 ? fallbackMissing : missingCount,
        color: const Color(0xFFEF4444), // Coral Red
        icon: Icons.search_rounded,
      ),
      PieChartSegment(
        label: 'Stray Sightings',
        value: total == 0 ? fallbackStray : strayCount,
        color: const Color(0xFFF59E0B), // Warning Amber
        icon: Icons.pets_rounded,
      ),
      PieChartSegment(
        label: 'Found / Reunited',
        value: total == 0 ? fallbackFound : foundCount,
        color: const Color(0xFF10B981), // Emerald Green
        icon: Icons.check_circle_rounded,
      ),
    ];
  }

  // ---------------------------------------------------------------------------
  // Build Method
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WireframeColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Admin Header
            AdminHeader(
              title: 'Analytics & Insights',
              selectedTabIndex: widget.selectedTabIndex,
              onTabChanged: widget.onTabChanged,
              onLogout: widget.onLogout,
            ),

            // Main Content Area
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            color: WireframeColors.primaryDark,
                            strokeWidth: 2.8,
                          ),
                          SizedBox(height: 14),
                          Text(
                            'Loading platform analytics...',
                            style: TextStyle(
                              fontSize: 13.0,
                              fontWeight: FontWeight.w600,
                              color: WireframeColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadAnalytics,
                      color: WireframeColors.primaryDark,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // 1. Filter Chips (All Insights, Users, Posts)
                            _buildFilterSelector(),
                            const SizedBox(height: 16),

                            if (_errorMessage != null) ...[
                              Container(
                                padding: const EdgeInsets.all(10.0),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEF2F2),
                                  borderRadius: BorderRadius.circular(8.0),
                                  border: Border.all(color: const Color(0xFFFCA5A5)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.info_outline, size: 16, color: Color(0xFFB91C1C)),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Notice: display reflects cached analytics fixtures ($_errorMessage)',
                                        style: const TextStyle(fontSize: 11.5, color: Color(0xFFB91C1C)),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 14),
                            ],

                            // 2. High-Level KPI Summary Cards
                            _buildKpiSummaryRow(),
                            const SizedBox(height: 20),

                            // 3. User Management Analytics Section
                            if (_activeSectionFilter == 'users') ...[
                              _buildUserAnalyticsCard(),
                              const SizedBox(height: 20),
                            ],

                            // 4. Post Management Analytics Section (Pie Chart)
                            if (_activeSectionFilter == 'posts') ...[
                              _buildPostAnalyticsCard(),
                              const SizedBox(height: 20),
                            ],
                          ],
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: widget.showBottomNav
          ? AdminBottomNavBar(
              currentIndex: widget.selectedTabIndex,
              onTabSelected: widget.onTabChanged ?? (_) {},
            )
          : null,
    );
  }

  // ---------------------------------------------------------------------------
  // Widget Components
  // ---------------------------------------------------------------------------

  Widget _buildFilterSelector() {
    return Row(
      children: [
        _buildFilterTab('users', 'Users', Icons.people_alt_rounded),
        const SizedBox(width: 10),
        _buildFilterTab('posts', 'Posts', Icons.article_rounded),
      ],
    );
  }

  Widget _buildFilterTab(String key, String label, IconData icon) {
    final isSelected = _activeSectionFilter == key;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _activeSectionFilter = key),
        borderRadius: BorderRadius.circular(10.0),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9.0),
          decoration: BoxDecoration(
            color: isSelected
                ? WireframeColors.primaryDark
                : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(10.0),
            border: Border.all(
              color: isSelected
                  ? WireframeColors.primaryDark
                  : WireframeColors.border,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 15,
                color: isSelected ? Colors.white : WireframeColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.white : WireframeColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKpiSummaryRow() {
    final totalUsers = _users.length;
    final activeUsers = _users.where((u) => u.isActive).length;
    final totalPosts = _posts.length;
    final flaggedPosts =
        _posts.where((p) => p.isFlagged || p.isModerationFlagged).length;

    return Row(
      children: [
        Expanded(
          child: _buildKpiCard(
            title: 'TOTAL USERS',
            value: totalUsers.toString(),
            subtitle: '$activeUsers active now',
            icon: Icons.people_alt_rounded,
            accentColor: WireframeColors.primaryDark,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildKpiCard(
            title: 'TOTAL POSTS',
            value: totalPosts.toString(),
            subtitle: flaggedPosts > 0
                ? '$flaggedPosts flagged'
                : 'All in good standing',
            icon: Icons.article_rounded,
            accentColor: flaggedPosts > 0
                ? const Color(0xFFD97706)
                : const Color(0xFF0D9488),
          ),
        ),
      ],
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: WireframeColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: WireframeColors.textMuted,
                  letterSpacing: 0.5,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6.0),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Icon(icon, size: 16, color: accentColor),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 22.0,
              fontWeight: FontWeight.w800,
              color: accentColor,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              color: WireframeColors.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // User Management Analytics Card
  // ---------------------------------------------------------------------------

  Widget _buildUserAnalyticsCard() {
    final newUsersCount = _newUsersInSelectedTimeframe.length;
    final totalUsers = _users.length;
    final activeCount = _users.where((u) => u.isActive).length;
    final warningCount = _users.where((u) => u.isWarning).length;
    final suspendedCount = _users.where((u) => u.isSuspended).length;

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.0),
        border: Border.all(color: WireframeColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Title with Icon
          Row(
            children: const [
              Icon(Icons.people_alt_rounded,
                  size: 20, color: WireframeColors.primaryDark),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'User Growth & Velocity',
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                    color: WireframeColors.primaryDark,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Visualization of registered members and new signups',
            style: TextStyle(
              fontSize: 12.0,
              color: WireframeColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),

          // Timeframe Toggle Row: Weekly, Monthly, Yearly (Responsive full-width segmented control)
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(9.0),
              border: Border.all(color: WireframeColors.border),
            ),
            padding: const EdgeInsets.all(3.0),
            child: Row(
              children: [
                Expanded(child: _buildTimeframePill('weekly', 'Weekly')),
                Expanded(child: _buildTimeframePill('monthly', 'Monthly')),
                Expanded(child: _buildTimeframePill('yearly', 'Yearly')),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // History Scan Scrollbar: Allows admin to scan any week, month, or year
          _buildHistoryScanScrollbar(),
          const SizedBox(height: 12),

          // Growth Highlight Metric Box
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
            decoration: BoxDecoration(
              color: WireframeColors.primaryDark.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(10.0),
              border: Border.all(
                color: WireframeColors.primaryDark.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: WireframeColors.primaryDark,
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: const Icon(
                    Icons.trending_up_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        newUsersCount > 0
                            ? '+$newUsersCount New User${newUsersCount == 1 ? '' : 's'}'
                            : '0 New Users',
                        style: const TextStyle(
                          fontSize: 16.0,
                          fontWeight: FontWeight.w800,
                          color: WireframeColors.primaryDark,
                        ),
                      ),
                      Text(
                        _getUserTimeframeGrowthSubtitle(totalUsers),
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: WireframeColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Registration Velocity Bar Chart
          const Text(
            'REGISTRATION ACTIVITY',
            style: TextStyle(
              fontSize: 11.0,
              fontWeight: FontWeight.w700,
              color: WireframeColors.textMuted,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 10),
          AdminBarChart(
            groups: _generateUserRegistrationBars(),
            height: 130,
            unitLabel: 'users',
          ),
          const SizedBox(height: 20),

          // User Account Status Breakdown
          const Text(
            'ACCOUNT STATUS DISTRIBUTION',
            style: TextStyle(
              fontSize: 11.0,
              fontWeight: FontWeight.w700,
              color: WireframeColors.textMuted,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 10),
          _buildStatusProgressRow('Active Accounts', activeCount, totalUsers,
              WireframeColors.primaryDark),
          const SizedBox(height: 8),
          _buildStatusProgressRow('Accounts with Warnings', warningCount,
              totalUsers, const Color(0xFFF59E0B)),
          const SizedBox(height: 8),
          _buildStatusProgressRow('Suspended Accounts', suspendedCount,
              totalUsers, const Color(0xFFEF4444)),
        ],
      ),
    );
  }

  Widget _buildTimeframePill(String key, String label) {
    final isSelected = _userTimeframe == key ||
        (_userTimeframe == 'week' && key == 'weekly') ||
        (_userTimeframe == 'month' && key == 'monthly') ||
        (_userTimeframe == 'year' && key == 'yearly');
    return InkWell(
      key: ValueKey('btn_user_timeframe_$key'),
      onTap: () => setState(() => _userTimeframe = key),
      borderRadius: BorderRadius.circular(6.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(6.0),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected
                ? WireframeColors.primaryDark
                : WireframeColors.textMuted,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _buildHistoryScanScrollbar() {
    final now = DateTime.now();
    const shortMonths = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];

    final List<Widget> items = [];

    if (_userTimeframe == 'weekly' || _userTimeframe == 'week') {
      final currentMonday = DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: now.weekday - 1));

      // Display 8 weeks of history: from current week (0) descending to past (-7)
      for (int offset = 0; offset >= -7; offset--) {
        final monday = currentMonday.add(Duration(days: offset * 7));
        final sunday = monday.add(const Duration(days: 6));
        final isSelected = _userWeekOffset == offset;

        int count = _countUsersInWeek(monday);
        bool hasData;
        if (_hasRealTimestamps) {
          hasData = count > 0;
        } else {
          // Static fixture fallback: current week (0), last week (-1), and 2 weeks ago (-2) have mock data
          if (offset >= -2) {
            hasData = true;
            count = offset == 0 ? 2 : 1;
          } else {
            hasData = false;
            count = 0;
          }
        }

        String label;
        if (offset == 0) {
          label = 'This Week';
        } else if (offset == -1) {
          label = 'Last Week';
        } else {
          final weekNum = ((monday.day - 1) ~/ 7) + 1;
          label = 'Wk $weekNum ${shortMonths[monday.month - 1]}';
        }

        final dateRange =
            '${shortMonths[monday.month - 1]} ${monday.day} – ${shortMonths[sunday.month - 1]} ${sunday.day}';

        items.add(
          _buildHistoryItemCard(
            key: ValueKey('history_week_$offset'),
            label: label,
            dateRange: dateRange,
            isSelected: isSelected,
            hasData: hasData,
            count: count,
            onTap: () {
              setState(() {
                _userWeekOffset = offset;
              });
            },
          ),
        );
      }
    } else if (_userTimeframe == 'monthly' || _userTimeframe == 'month') {
      // Display 6 months of history: from current month (0) descending to past (-5)
      for (int offset = 0; offset >= -5; offset--) {
        final totalMonths = (now.year * 12 + (now.month - 1)) + offset;
        final targetYear = totalMonths ~/ 12;
        final targetMonth = (totalMonths % 12) + 1;
        final monthStart = DateTime(targetYear, targetMonth, 1);
        final isSelected = _userMonthOffset == offset;

        int count = _countUsersInMonth(monthStart);
        bool hasData;
        if (_hasRealTimestamps) {
          hasData = count > 0;
        } else {
          if (offset >= -1) {
            hasData = true;
            count = offset == 0 ? 3 : 2;
          } else {
            hasData = false;
            count = 0;
          }
        }

        String label;
        if (offset == 0) {
          label = 'This Month';
        } else if (offset == -1) {
          label = 'Last Month';
        } else {
          label = '${shortMonths[targetMonth - 1]} $targetYear';
        }

        final dateRange = '${shortMonths[targetMonth - 1]} $targetYear';

        items.add(
          _buildHistoryItemCard(
            key: ValueKey('history_month_$offset'),
            label: label,
            dateRange: dateRange,
            isSelected: isSelected,
            hasData: hasData,
            count: count,
            onTap: () {
              setState(() {
                _userMonthOffset = offset;
              });
            },
          ),
        );
      }
    } else {
      // Yearly: 4 years of history: from current year (0) descending to past (-3)
      for (int offset = 0; offset >= -3; offset--) {
        final year = now.year + offset;
        final isSelected = _userYearOffset == offset;

        int count = _countUsersInYear(year);
        bool hasData;
        if (_hasRealTimestamps) {
          hasData = count > 0;
        } else {
          if (offset >= -1) {
            hasData = true;
            count = offset == 0
                ? _users.length
                : (_users.length >= 2 ? _users.length - 1 : 1);
          } else {
            hasData = false;
            count = 0;
          }
        }

        String label;
        if (offset == 0) {
          label = 'This Year';
        } else if (offset == -1) {
          label = 'Last Year';
        } else {
          label = 'Year $year';
        }

        final dateRange = 'Jan – Dec $year';

        items.add(
          _buildHistoryItemCard(
            key: ValueKey('history_year_$offset'),
            label: label,
            dateRange: dateRange,
            isSelected: isSelected,
            hasData: hasData,
            count: count,
            onTap: () {
              setState(() {
                _userYearOffset = offset;
              });
            },
          ),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text(
              'SCAN TIMEFRAME HISTORY',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: WireframeColors.textMuted,
                letterSpacing: 0.5,
              ),
            ),
            Text(
              'Gray = No Data Available',
              style: TextStyle(
                fontSize: 10.0,
                color: WireframeColors.textMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Scrollbar(
          controller: _periodScrollController,
          thumbVisibility: true,
          trackVisibility: true,
          child: SingleChildScrollView(
            controller: _periodScrollController,
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              children: items,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryItemCard({
    required Key key,
    required String label,
    required String dateRange,
    required bool isSelected,
    required bool hasData,
    required int count,
    required VoidCallback? onTap,
    String unitSingular = 'user',
    String unitPlural = 'users',
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0, bottom: 4.0),
      child: Tooltip(
        message: hasData
            ? '$label: $count $unitPlural'
            : '$label: No data recorded',
        child: InkWell(
          key: key,
          onTap: hasData ? onTap : null, // unclickable when no data!
          borderRadius: BorderRadius.circular(8.0),
          child: Container(
            constraints: const BoxConstraints(minWidth: 104),
            padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 7.0),
            decoration: BoxDecoration(
              color: !hasData
                  ? const Color(0xFFF1F5F9) // Grayed out
                  : (isSelected ? WireframeColors.primaryDark : Colors.white),
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(
                color: !hasData
                    ? const Color(0xFFCBD5E1) // Gray border
                    : (isSelected
                        ? WireframeColors.primaryDark
                        : WireframeColors.border),
                width: isSelected ? 1.6 : 1.0,
              ),
              boxShadow: isSelected && hasData
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ]
                  : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      !hasData
                          ? Icons.block_rounded
                          : (isSelected
                              ? Icons.check_circle_rounded
                              : Icons.calendar_today_rounded),
                      size: 11,
                      color: !hasData
                          ? const Color(0xFF94A3B8)
                          : (isSelected ? Colors.white : WireframeColors.primaryDark),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 11.0,
                        fontWeight:
                            isSelected ? FontWeight.w800 : FontWeight.w600,
                        color: !hasData
                            ? const Color(0xFF94A3B8) // Gray text
                            : (isSelected
                                ? Colors.white
                                : WireframeColors.textPrimary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  dateRange,
                  style: TextStyle(
                    fontSize: 10.0,
                    color: !hasData
                        ? const Color(0xFFA0AEC0)
                        : (isSelected
                            ? Colors.white.withValues(alpha: 0.85)
                            : WireframeColors.textSecondary),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 5.0, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: !hasData
                        ? const Color(0xFFE2E8F0)
                        : (isSelected
                            ? Colors.white.withValues(alpha: 0.2)
                            : WireframeColors.primaryDark
                                .withValues(alpha: 0.08)),
                    borderRadius: BorderRadius.circular(4.0),
                  ),
                  child: Text(
                    !hasData
                        ? 'No data'
                        : (count == 1 ? '1 $unitSingular' : '$count $unitPlural'),
                    style: TextStyle(
                      fontSize: 9.0,
                      fontWeight: FontWeight.w700,
                      color: !hasData
                          ? const Color(0xFF94A3B8)
                          : (isSelected
                              ? Colors.white
                              : WireframeColors.primaryDark),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getUserTimeframeGrowthSubtitle(int totalUsers) {
    if (_userTimeframe == 'yearly' || _userTimeframe == 'year') {
      final targetYear = DateTime.now().year + _userYearOffset;
      if (_userYearOffset == 0) {
        return 'Registered this calendar year ($targetYear) out of $totalUsers total';
      } else if (_userYearOffset == -1) {
        return 'Registered in previous calendar year ($targetYear) out of $totalUsers total';
      } else {
        return 'Registered in calendar year ($targetYear) out of $totalUsers total';
      }
    } else if (_userTimeframe == 'monthly' || _userTimeframe == 'month') {
      if (_userMonthOffset == 0) {
        return 'Registered this calendar month out of $totalUsers total';
      } else if (_userMonthOffset == -1) {
        return 'Registered in previous calendar month out of $totalUsers total';
      } else {
        const monthNames = [
          'January',
          'February',
          'March',
          'April',
          'May',
          'June',
          'July',
          'August',
          'September',
          'October',
          'November',
          'December'
        ];
        final now = DateTime.now();
        final totalMonths = (now.year * 12 + (now.month - 1)) + _userMonthOffset;
        final targetYear = totalMonths ~/ 12;
        final targetMonth = (totalMonths % 12) + 1;
        return 'Registered in ${monthNames[targetMonth - 1]} $targetYear out of $totalUsers total';
      }
    } else {
      if (_userWeekOffset == 0) {
        return 'Registered in current week out of $totalUsers total';
      } else if (_userWeekOffset == -1) {
        return 'Registered in previous week out of $totalUsers total';
      } else {
        final now = DateTime.now();
        final currentMonday = DateTime(now.year, now.month, now.day)
            .subtract(Duration(days: now.weekday - 1));
        final targetMonday =
            currentMonday.add(Duration(days: _userWeekOffset * 7));
        final targetSunday = targetMonday.add(const Duration(days: 6));
        const shortMonths = [
          'Jan',
          'Feb',
          'Mar',
          'Apr',
          'May',
          'Jun',
          'Jul',
          'Aug',
          'Sep',
          'Oct',
          'Nov',
          'Dec'
        ];
        return 'Registered during week of ${shortMonths[targetMonday.month - 1]} ${targetMonday.day}–${targetSunday.day} out of $totalUsers total';
      }
    }
  }

  Widget _buildPostHistoryScanScrollbar() {
    final now = DateTime.now();
    const shortMonths = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];

    final List<Widget> items = [];

    if (_postTimeframe == 'weekly' || _postTimeframe == 'week') {
      final currentMonday = DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: now.weekday - 1));

      // Display 8 weeks of history: from current week (0) descending to past (-7)
      for (int offset = 0; offset >= -7; offset--) {
        final monday = currentMonday.add(Duration(days: offset * 7));
        final sunday = monday.add(const Duration(days: 6));
        final isSelected = _postWeekOffset == offset;

        int count = _countPostsInWeek(monday);
        bool hasData;
        if (_hasPostTimestamps) {
          hasData = count > 0;
        } else {
          if (offset >= -2) {
            hasData = true;
            count = offset == 0 ? 2 : 1;
          } else {
            hasData = false;
            count = 0;
          }
        }

        String label;
        if (offset == 0) {
          label = 'This Week';
        } else if (offset == -1) {
          label = 'Last Week';
        } else {
          final weekNum = ((monday.day - 1) ~/ 7) + 1;
          label = 'Wk $weekNum ${shortMonths[monday.month - 1]}';
        }

        final dateRange =
            '${shortMonths[monday.month - 1]} ${monday.day} – ${shortMonths[sunday.month - 1]} ${sunday.day}';

        items.add(
          _buildHistoryItemCard(
            key: ValueKey('history_post_week_$offset'),
            label: label,
            dateRange: dateRange,
            isSelected: isSelected,
            hasData: hasData,
            count: count,
            unitSingular: 'post',
            unitPlural: 'posts',
            onTap: () {
              setState(() {
                _postWeekOffset = offset;
              });
            },
          ),
        );
      }
    } else if (_postTimeframe == 'monthly' || _postTimeframe == 'month') {
      // Display 6 months of history: from current month (0) descending to past (-5)
      for (int offset = 0; offset >= -5; offset--) {
        final totalMonths = (now.year * 12 + (now.month - 1)) + offset;
        final targetYear = totalMonths ~/ 12;
        final targetMonth = (totalMonths % 12) + 1;
        final monthStart = DateTime(targetYear, targetMonth, 1);
        final isSelected = _postMonthOffset == offset;

        int count = _countPostsInMonth(monthStart);
        bool hasData;
        if (_hasPostTimestamps) {
          hasData = count > 0;
        } else {
          if (offset >= -1) {
            hasData = true;
            count = offset == 0 ? 3 : 2;
          } else {
            hasData = false;
            count = 0;
          }
        }

        String label;
        if (offset == 0) {
          label = 'This Month';
        } else if (offset == -1) {
          label = 'Last Month';
        } else {
          label = '${shortMonths[targetMonth - 1]} $targetYear';
        }

        final dateRange = '${shortMonths[targetMonth - 1]} $targetYear';

        items.add(
          _buildHistoryItemCard(
            key: ValueKey('history_post_month_$offset'),
            label: label,
            dateRange: dateRange,
            isSelected: isSelected,
            hasData: hasData,
            count: count,
            unitSingular: 'post',
            unitPlural: 'posts',
            onTap: () {
              setState(() {
                _postMonthOffset = offset;
              });
            },
          ),
        );
      }
    } else {
      // Yearly: 4 years of history: from current year (0) descending to past (-3)
      for (int offset = 0; offset >= -3; offset--) {
        final year = now.year + offset;
        final isSelected = _postYearOffset == offset;

        int count = _countPostsInYear(year);
        bool hasData;
        if (_hasPostTimestamps) {
          hasData = count > 0;
        } else {
          if (offset >= -1) {
            hasData = true;
            count = offset == 0
                ? _posts.length
                : (_posts.length >= 2 ? _posts.length - 1 : 1);
          } else {
            hasData = false;
            count = 0;
          }
        }

        String label;
        if (offset == 0) {
          label = 'This Year';
        } else if (offset == -1) {
          label = 'Last Year';
        } else {
          label = 'Year $year';
        }

        final dateRange = 'Jan – Dec $year';

        items.add(
          _buildHistoryItemCard(
            key: ValueKey('history_post_year_$offset'),
            label: label,
            dateRange: dateRange,
            isSelected: isSelected,
            hasData: hasData,
            count: count,
            unitSingular: 'post',
            unitPlural: 'posts',
            onTap: () {
              setState(() {
                _postYearOffset = offset;
              });
            },
          ),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text(
              'SCAN TIMEFRAME HISTORY',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: WireframeColors.textMuted,
                letterSpacing: 0.5,
              ),
            ),
            Text(
              'Gray = No Data Available',
              style: TextStyle(
                fontSize: 10.0,
                color: WireframeColors.textMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Scrollbar(
          controller: _postPeriodScrollController,
          thumbVisibility: true,
          trackVisibility: true,
          child: SingleChildScrollView(
            controller: _postPeriodScrollController,
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              children: items,
            ),
          ),
        ),
      ],
    );
  }

  String _getPostTimeframeSubtitle(int totalPosts) {
    if (_postTimeframe == 'yearly' || _postTimeframe == 'year') {
      final targetYear = DateTime.now().year + _postYearOffset;
      if (_postYearOffset == 0) {
        return 'Recorded this calendar year ($targetYear) out of $totalPosts total posts';
      } else if (_postYearOffset == -1) {
        return 'Recorded in previous calendar year ($targetYear) out of $totalPosts total posts';
      } else {
        return 'Recorded in calendar year ($targetYear) out of $totalPosts total posts';
      }
    } else if (_postTimeframe == 'monthly' || _postTimeframe == 'month') {
      if (_postMonthOffset == 0) {
        return 'Recorded this calendar month out of $totalPosts total posts';
      } else if (_postMonthOffset == -1) {
        return 'Recorded in previous calendar month out of $totalPosts total posts';
      } else {
        const monthNames = [
          'January',
          'February',
          'March',
          'April',
          'May',
          'June',
          'July',
          'August',
          'September',
          'October',
          'November',
          'December'
        ];
        final now = DateTime.now();
        final totalMonths = (now.year * 12 + (now.month - 1)) + _postMonthOffset;
        final targetYear = totalMonths ~/ 12;
        final targetMonth = (totalMonths % 12) + 1;
        return 'Recorded in ${monthNames[targetMonth - 1]} $targetYear out of $totalPosts total posts';
      }
    } else {
      if (_postWeekOffset == 0) {
        return 'Recorded in current week out of $totalPosts total posts';
      } else if (_postWeekOffset == -1) {
        return 'Recorded in previous week out of $totalPosts total posts';
      } else {
        final now = DateTime.now();
        final currentMonday = DateTime(now.year, now.month, now.day)
            .subtract(Duration(days: now.weekday - 1));
        final targetMonday =
            currentMonday.add(Duration(days: _postWeekOffset * 7));
        final targetSunday = targetMonday.add(const Duration(days: 6));
        const shortMonths = [
          'Jan',
          'Feb',
          'Mar',
          'Apr',
          'May',
          'Jun',
          'Jul',
          'Aug',
          'Sep',
          'Oct',
          'Nov',
          'Dec'
        ];
        return 'Recorded during week of ${shortMonths[targetMonday.month - 1]} ${targetMonday.day}–${targetSunday.day} out of $totalPosts total posts';
      }
    }
  }

  Widget _buildStatusProgressRow(
      String label, int count, int total, Color color) {
    final ratio = total > 0 ? (count / total).clamp(0.0, 1.0) : 0.0;
    final percentage = (ratio * 100).toStringAsFixed(0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12.0,
                fontWeight: FontWeight.w600,
                color: WireframeColors.textPrimary,
              ),
            ),
            Text(
              '$count ($percentage%)',
              style: TextStyle(
                fontSize: 12.0,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4.0),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 6,
            backgroundColor: const Color(0xFFE2E8F0),
            color: color,
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Post Management Analytics Card (Pie / Donut Chart)
  // ---------------------------------------------------------------------------

  Widget _buildPostAnalyticsCard() {
    final activePosts = _postsInSelectedTimeframe;
    final totalInPeriod = activePosts.length;
    final missingCount = activePosts.where((p) => p.isMissing).length;
    final strayCount = activePosts.where((p) => p.isStray).length;
    final foundCount = activePosts.where((p) => p.isFound).length;

    final flaggedCount =
        _posts.where((p) => p.isFlagged || p.isModerationFlagged).length;
    final approvedCount = _posts.where((p) => p.isModerationApproved).length;

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.0),
        border: Border.all(color: WireframeColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: const [
              Icon(Icons.article_rounded,
                  size: 20, color: WireframeColors.primaryDark),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Post Status Breakdown',
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                    color: WireframeColors.primaryDark,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Timeline and category breakdown of animal sightings',
            style: TextStyle(
              fontSize: 12.0,
              color: WireframeColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),

          // Timeline Segmented Selector: Weekly, Monthly, Yearly
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(9.0),
              border: Border.all(color: WireframeColors.border),
            ),
            padding: const EdgeInsets.all(3.0),
            child: Row(
              children: [
                Expanded(child: _buildPostTimeframePill('weekly', 'Weekly')),
                Expanded(child: _buildPostTimeframePill('monthly', 'Monthly')),
                Expanded(child: _buildPostTimeframePill('yearly', 'Yearly')),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // History Scan Scrollbar for Posts
          _buildPostHistoryScanScrollbar(),
          const SizedBox(height: 12),

          // Post Number Analytics Metric Box
          Container(
            padding: const EdgeInsets.all(14.0),
            decoration: BoxDecoration(
              color: WireframeColors.primaryDark.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12.0),
              border: Border.all(
                color: WireframeColors.primaryDark.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: WireframeColors.primaryDark,
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: const Icon(
                        Icons.insights_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            totalInPeriod > 0
                                ? '+$totalInPeriod Sighting Post${totalInPeriod == 1 ? '' : 's'}'
                                : '0 Sighting Posts',
                            style: const TextStyle(
                              fontSize: 16.0,
                              fontWeight: FontWeight.w800,
                              color: WireframeColors.primaryDark,
                            ),
                          ),
                          Text(
                            _getPostTimeframeSubtitle(_posts.length),
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: WireframeColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildPostCountChip(
                        'Missing', missingCount, const Color(0xFFEF4444)),
                    const SizedBox(width: 6),
                    _buildPostCountChip(
                        'Stray', strayCount, const Color(0xFFF59E0B)),
                    const SizedBox(width: 6),
                    _buildPostCountChip(
                        'Found', foundCount, const Color(0xFF10B981)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Donut / Pie Chart Component
          Center(
            child: AdminPieChart(
              segments: _generatePostStatusSegments(),
              size: 190,
              strokeWidth: 28,
              centerLabel: totalInPeriod.toString(),
              centerSublabel: '${_postTimeframe.toUpperCase()} POSTS',
            ),
          ),
          const SizedBox(height: 20),

          // Category Breakdown with Progress Bars
          const Text(
            'STATUS BREAKDOWN DETAILS',
            style: TextStyle(
              fontSize: 11.0,
              fontWeight: FontWeight.w700,
              color: WireframeColors.textMuted,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 10),
          _buildStatusProgressRow(
            'Missing Pets',
            missingCount,
            totalInPeriod,
            const Color(0xFFEF4444),
          ),
          const SizedBox(height: 8),
          _buildStatusProgressRow(
            'Stray Sightings',
            strayCount,
            totalInPeriod,
            const Color(0xFFF59E0B),
          ),
          const SizedBox(height: 8),
          _buildStatusProgressRow(
            'Found / Reunited',
            foundCount,
            totalInPeriod,
            const Color(0xFF10B981),
          ),
          const SizedBox(height: 20),

          // Moderation Health Banner
          Container(
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: flaggedCount > 0
                  ? const Color(0xFFFFFBEB)
                  : const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(10.0),
              border: Border.all(
                color: flaggedCount > 0
                    ? const Color(0xFFFDE68A)
                    : const Color(0xFFBBF7D0),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  flaggedCount > 0
                      ? Icons.flag_rounded
                      : Icons.verified_user_rounded,
                  size: 18,
                  color: flaggedCount > 0
                      ? const Color(0xFFB45309)
                      : const Color(0xFF15803D),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    flaggedCount > 0
                        ? '$flaggedCount post${flaggedCount == 1 ? '' : 's'} currently flagged for administrative review.'
                        : 'All $approvedCount active posts meet community moderation standards.',
                    style: TextStyle(
                      fontSize: 12.0,
                      fontWeight: FontWeight.w600,
                      color: flaggedCount > 0
                          ? const Color(0xFF92400E)
                          : const Color(0xFF166534),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostTimeframePill(String key, String label) {
    final isSelected = _postTimeframe == key ||
        (_postTimeframe == 'week' && key == 'weekly') ||
        (_postTimeframe == 'month' && key == 'monthly') ||
        (_postTimeframe == 'year' && key == 'yearly');
    return InkWell(
      key: ValueKey('btn_post_status_$key'),
      onTap: () {
        setState(() {
          _postTimeframe = key;
        });
      },
      borderRadius: BorderRadius.circular(6.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(6.0),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected
                ? WireframeColors.primaryDark
                : WireframeColors.textMuted,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _buildPostCountChip(String label, int count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 4.0),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(7.0),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 14.0,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              label,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
