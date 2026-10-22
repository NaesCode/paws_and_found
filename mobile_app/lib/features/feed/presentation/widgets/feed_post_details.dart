import 'package:flutter/material.dart';

class FeedPostDetails extends StatelessWidget {

  final String name;
  final String specie;
  final String description;

  const FeedPostDetails({
    super.key,
    required this.name,
    required this.specie,
    required this.description,
    });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          // TODO: change the way this get the names from the db and other details
          'Name: $name',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Specie: $specie',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Description:', //unchanged
          style: TextStyle(
            fontSize: 11,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          description,
          style: const TextStyle(
            fontSize: 11,
            color: Colors.black87,
            height: 1.3,
          ),
          maxLines: 5,
          // TODO: change nga mu open ug lain nga modal, idk
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}


