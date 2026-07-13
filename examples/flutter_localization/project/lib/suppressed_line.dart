import 'package:flutter/material.dart';

class SuppressedLine extends StatelessWidget {
  const SuppressedLine({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('Not suppressed'),
        Text(
          'Suppressed same line',
        ), // devaudit-ignore: flutter.localization.hardcoded-ui-string
        // devaudit-ignore: flutter.localization.hardcoded-ui-string
        Text('Suppressed leading comment'),
      ],
    );
  }
}
