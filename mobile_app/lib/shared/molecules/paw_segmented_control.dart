import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class PawSegmentedControl extends StatelessWidget {
  final bool isFirstOptionSelected;
  final String firstOptionText;
  final String secondOptionText;
  final ValueChanged<bool> onOptionChanged;
  final Color activeColor;
  final Color inactiveColor;
  
  //added properties aron usable kaau
  final double height;
  final double borderRadius;
  final double fontSize;
  final EdgeInsetsGeometry padding;
  final bool isFullWidth;

  const PawSegmentedControl({
    super.key,
    required this.isFirstOptionSelected,
    required this.firstOptionText,
    required this.secondOptionText,
    required this.onOptionChanged,
    this.activeColor = AppColors.primary,
    this.inactiveColor = AppColors.darkCharcoal,
    this.height = 50.0,            
    this.borderRadius = 8.0,      
    this.fontSize = 16.0,         
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
    this.isFullWidth = true,       
  });

  @override
  Widget build(BuildContext context) {
    // Inner widget segment template to reduce copy-paste footprint
    Widget buildSegment({required bool isSelected, required String text, required bool targetValue}) {
      final widgetContent = AnimatedContainer(
        duration: const Duration(milliseconds: 200), // Smooth active color fade shifts
        height: height,
        padding: padding,
        decoration: BoxDecoration(
          color: isSelected ? activeColor : inactiveColor,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          style: TextStyle(
            // Auto-toggles contrast coloring dynamically
            color: isSelected ? Colors.white : Colors.white, 
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: fontSize,
          ),
        ),
      );

      return isFullWidth 
          ? Expanded(child: GestureDetector(onTap: () => onOptionChanged(targetValue), child: widgetContent))
          : GestureDetector(onTap: () => onOptionChanged(targetValue), child: widgetContent);
    }

    return Row(
      mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
      children: [
        buildSegment(isSelected: isFirstOptionSelected, text: firstOptionText, targetValue: true),
        const SizedBox(width: 8), // Clean structural visual separation
        buildSegment(isSelected: !isFirstOptionSelected, text: secondOptionText, targetValue: false),
      ],
    );
  }
}
