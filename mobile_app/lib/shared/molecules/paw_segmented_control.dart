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
    this.activeColor = AppColors.contrast1,
    this.inactiveColor = AppColors.darkCharcoal,
    this.height = 50.0,            
    this.borderRadius = 8.0,      
    this.fontSize = 16.0,         
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
    this.isFullWidth = true,       
  });

  @override
  Widget build(BuildContext context) {
    Widget buildSegment({
      required bool isSelected,
      required String text,
      required bool targetValue,
    }) {
      final widgetContent = AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeInOut,
        height: height - 8,
        padding: padding,
        decoration: BoxDecoration(
          color: isSelected ? activeColor : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: activeColor.withValues(alpha: 0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: isSelected ? Colors.white : inactiveColor,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            fontSize: fontSize,
          ),
        ),
      );

      return isFullWidth
          ? Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onOptionChanged(targetValue),
                child: widgetContent,
              ),
            )
          : GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onOptionChanged(targetValue),
              child: widgetContent,
            );
    }

    return Container(
      height: height,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border, width: 1.0),
      ),
      child: Row(
        mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
        children: [
          buildSegment(
            isSelected: isFirstOptionSelected,
            text: firstOptionText,
            targetValue: true,
          ),
          buildSegment(
            isSelected: !isFirstOptionSelected,
            text: secondOptionText,
            targetValue: false,
          ),
        ],
      ),
    );
  }
}
