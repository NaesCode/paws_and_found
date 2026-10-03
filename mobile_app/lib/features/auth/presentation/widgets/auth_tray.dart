import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/atoms/drag_handle.dart';
import '../../../../shared/atoms/paw_button.dart';
import '../../../../shared/atoms/paw_text_field.dart';
import '../../../../shared/molecules/paw_segmented_control.dart';

class AuthTray extends StatelessWidget {
  final bool isLogin;
  final ValueChanged<bool> onModeChanged;

  const AuthTray({
    super.key,
    required this.isLogin,
    required this.onModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const DragHandle(),
              const SizedBox(height: 24),
              const Text(
                'Paws and Found',
                style: TextStyle(
                  fontFamily: 'Caveat', // Handwriting style font placeholder
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkCharcoal,
                ),
              ),
              const SizedBox(height: 24),
              
              // Segmented Molecule
              PawSegmentedControl(
                isFirstOptionSelected: isLogin,
                firstOptionText: 'Login',
                secondOptionText: 'Register',
                onOptionChanged: onModeChanged,
              ),
              
              const SizedBox(height: 24),
              
              const PawTextField(hintText: 'Username'),
              const SizedBox(height: 16),
              const PawTextField(hintText: 'Password', obscureText: true),
              
              const SizedBox(height: 24),
              
              SizedBox(
                width: 200,
                child: PawButton(
                  text: isLogin ? 'Login' : 'Register',
                  onPressed: () {},
                  color: AppColors.darkCharcoal,
                  textColor: Colors.white,
                ),
              ),
              
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }
}
