import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class FilterButtonDropdown extends StatelessWidget {
  final String selectedLabel;
  final List<String> filterOptions;
  final ValueChanged<String> onFilterChanged;

  const FilterButtonDropdown({
    super.key,
    required this.selectedLabel,
    required this.filterOptions,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      initialValue: selectedLabel,
      onSelected: onFilterChanged,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              selectedLabel,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(CupertinoIcons.paw, size: 20, color: Colors.black87),
          ],
        ),
      ),
      itemBuilder: (BuildContext context) {
        return filterOptions.map((String option) {
          return PopupMenuItem<String>(
            value: option,
            child: Text(option),
          );
        }).toList();
      },
    );
  }
}
