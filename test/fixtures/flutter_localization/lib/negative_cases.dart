import 'package:flutter/material.dart';

const routeName = '/profile';

class NegativeCases extends StatelessWidget {
  const NegativeCases({super.key, required this.map});

  final Map<String, String> map;

  @override
  Widget build(BuildContext context) {
    debugPrint('Saved');
    print('Saved');

    return Column(
      children: [
        Text(context.l10n.save),
        Text(S.of(context).save),
        Text(AppLocalizations.of(context)!.save),
        Text('common.save'.tr()),
        Text(map['title']),
        Image.asset('assets/images/logo.png'),
        Text(Uri.parse('https://example.com').toString()),
        Text('42'),
        Text('---'),
        Text(''),
        Text('   '),
      ],
    );
  }
}
