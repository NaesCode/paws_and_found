import 'package:flutter/material.dart';

class ClaimPetPage extends StatefulWidget {

  final String reportId;
  final String petName;

  const ClaimPetPage({
    super.key, 
    required this.reportId, 
    required this.petName
    }
  );

  @override
  State<ClaimPetPage> createState() => _ClaimPetPageState();
}

class _ClaimPetPageState extends State<ClaimPetPage> {
  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}