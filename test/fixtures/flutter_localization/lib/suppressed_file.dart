// devaudit-ignore-file: flutter.localization.hardcoded-ui-string
import 'package:flutter/material.dart';

class SuppressedFile extends StatelessWidget {
  const SuppressedFile({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [Text('Entire file is suppressed'), Text('So is this one')],
    );
  }
}
