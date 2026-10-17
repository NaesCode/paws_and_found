import 'package:flutter/material.dart';

class FeedPostDetails extends StatelessWidget {
  const FeedPostDetails({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          // TODO: change the way this get the names from the db and other details
          'Name: Banana',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Specie: Tabby Cat',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Description:',
          style: TextStyle(
            fontSize: 11,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 2),
        const Text(
          'The quick brown fox jumps over the lazy dog. The quick brown fox jumps over the lazy dog. The quick brown fox jumps over the lazy dog.',
          style: TextStyle(
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


