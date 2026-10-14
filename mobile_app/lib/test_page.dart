import 'package:flutter/material.dart';
import 'shared/organisms/custom_app_bar.dart';

class TestPage extends StatefulWidget {
  const TestPage({super.key});

  @override
  State<TestPage> createState() => _TestPageState();
}

class _TestPageState extends State<TestPage> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Custom App Bar Test',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text('Currently Active Index: $_currentIndex'),
            const SizedBox(height: 32),
            const Text('Click the icons below to see the active state change!'),
          ],
        ),
      ),
      // Positioned at the bottom:
      bottomNavigationBar: CustomAppBar(
        currentIndex: _currentIndex,
        hasUnreadNotifications: true,
        onTabSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}

