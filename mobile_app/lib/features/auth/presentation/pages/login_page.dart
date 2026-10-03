import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../widgets/auth_tray.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool isLogin = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Map Placeholder (Template background)
          Container(
            color: const Color(0xFFD6D6D6),
            width: double.infinity,
            height: double.infinity,
            child: const Center(
              child: Padding(
                padding: EdgeInsets.only(bottom: 120.0), 
                child: Text(
                  'Paws\nand\nFound',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Caveat',
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkCharcoal,
                    height: 1.2,
                  ),
                ),
              ),
            ),
          ),
          
          // 2. The Draggable Tray (Organism)
          Align(
            alignment: Alignment.bottomCenter,
            child: AuthTray(
              isLogin: isLogin,
              onModeChanged: (value) => setState(() => isLogin = value),
            ),
          ),
        ],
      ),
    );
  }
}
