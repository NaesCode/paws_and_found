// import '../../../../core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:paws_and_found/shared/molecules/filter_reports_dropdown.dart';
import 'package:paws_and_found/shared/molecules/report_card_item.dart';


class PersonalReportsPage extends StatefulWidget{
  const PersonalReportsPage({super.key});

  @override 
  State<PersonalReportsPage> createState() => _PersonalReportsState();
}

class _PersonalReportsState extends State<PersonalReportsPage> {
  final int itemCount = 3;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 0.0, vertical: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 0.0),
                  child: FilterButtonDropdown(),
                ),
              ],
            ),
            
            const SizedBox(height: 20), 
            
            // TODO: change into dynamic data
            Expanded(
              child: ListView.separated(
                itemCount: itemCount,
                separatorBuilder: (context, index) => const SizedBox(height: 20),
                itemBuilder: (context, index){
                  return const ReportCardItem();
                } 
              )
            )
          ],
        ),
      ),
    );
  }
}
