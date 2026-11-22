import 'package:flutter/material.dart';
import 'package:paws_and_found/core/theme/app_colors.dart';

class ClaimantSelectorBar extends StatelessWidget {
  final List? claimants;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  const ClaimantSelectorBar({
    super.key,
    required this.claimants,
    required this.selectedIndex,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.07),
        border: Border(
          bottom: BorderSide(color: AppColors.primary.withValues(alpha: 0.2)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ACTIVE CLAIMANTS (${claimants?.length ?? 0})',
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 6),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(claimants?.length ?? 0, (index) {
                final item = claimants?[index];
                final isSelected = index == selectedIndex;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    selected: isSelected,
                    selectedColor: AppColors.primary,
                    backgroundColor: Colors.white,
                    label: Text(
                      item?['name'] ?? '',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : AppColors.darkCharcoal,
                      ),
                    ),
                    onSelected: (_) => onSelect(index),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}