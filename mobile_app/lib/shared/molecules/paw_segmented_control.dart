import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class PawSegmentedControl extends StatelessWidget {
  final bool isFirstOptionSelected;
  final String firstOptionText;
  final String secondOptionText;
  final ValueChanged<bool> onOptionChanged;
  final Color activeColor;
  final Color inactiveColor;

  const PawSegmentedControl({
    super.key,
    required this.isFirstOptionSelected,
    required this.firstOptionText,
    required this.secondOptionText,
    required this.onOptionChanged,
    this.activeColor = AppColors.darkCharcoal,
    this.inactiveColor = const Color(0xFFE0E0E0),
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => onOptionChanged(true),
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: isFirstOptionSelected ? activeColor : inactiveColor,
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Text(
                firstOptionText,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: isFirstOptionSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: GestureDetector(
            onTap: () => onOptionChanged(false),
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: !isFirstOptionSelected ? activeColor : inactiveColor,
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Text(
                secondOptionText,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: !isFirstOptionSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
