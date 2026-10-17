import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

enum ReportFilter {
  latest('Latest'),
  oldest('Oldest'),
  proximity('Proximity'); 

  const ReportFilter(this.label);
  final String label;

  static List<DropdownMenuEntry<ReportFilter>> get entries =>
      values.map((filter) => DropdownMenuEntry<ReportFilter>(
        value: filter,
        label: filter.label,
      )).toList();
}

class FilterButtonDropdown extends StatefulWidget {
  const FilterButtonDropdown({super.key});


  @override
  State<FilterButtonDropdown> createState() => _FilterButtonDropdownState();
}

class _FilterButtonDropdownState extends State<FilterButtonDropdown> {
  ReportFilter _selectedFilter = ReportFilter.latest;

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<ReportFilter>(
      initialValue: _selectedFilter,
      onSelected: (ReportFilter filter){
        setState((){
          _selectedFilter = filter;
        });
      },
      child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: Colors.grey[200],
      borderRadius: BorderRadius.circular(20)
      ),
      child: Row(mainAxisSize: MainAxisSize.min,
      children: [
      Text(
        _selectedFilter.label,
        style: const TextStyle(fontSize: 14,
        fontWeight: FontWeight.w500,
        color: Colors.black87,
        ),
      ),
      const SizedBox(width: 8),
      const Icon(CupertinoIcons.paw, size: 20, color: Colors.black87),
      ],
      ),
      ),
      itemBuilder: (BuildContext context){
        return ReportFilter.values.map((ReportFilter filter){
          return PopupMenuItem<ReportFilter>(
            value: filter, 
            child: Text(filter.label),
          );
        }).toList();
      },
    );
  }
}
