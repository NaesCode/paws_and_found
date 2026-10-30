import 'package:flutter/material.dart';
import '../../../../core/theme/wireframe_colors.dart';
import 'admin_posts_page.dart';
import 'admin_users_page.dart';

/// Unified Admin Shell allowing developers and administrators to seamlessly
/// toggle between SDD Screen 09 (Users) and Screen 10 (Posts) via the top header dropdown.
class AdminPage extends StatefulWidget {
  final int initialTabIndex; // 0 for Users, 1 for Posts
  final VoidCallback? onLogout;

  const AdminPage({
    super.key,
    this.initialTabIndex = 0,
    this.onLogout,
  });

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  late int _selectedTab;
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.initialTabIndex;
    _pageController = PageController(initialPage: widget.initialTabIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onTabChanged(int index) {
    if (_selectedTab != index) {
      setState(() {
        _selectedTab = index;
      });
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _onPageChanged(int index) {
    if (_selectedTab != index) {
      setState(() {
        _selectedTab = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WireframeColors.surface,
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        physics: const ClampingScrollPhysics(),
        children: [
          AdminUsersPage(
            selectedTabIndex: _selectedTab,
            onTabChanged: _onTabChanged,
            onLogout: widget.onLogout,
          ),
          AdminPostsPage(
            selectedTabIndex: _selectedTab,
            onTabChanged: _onTabChanged,
            onLogout: widget.onLogout,
          ),
        ],
      ),
    );
  }
}
