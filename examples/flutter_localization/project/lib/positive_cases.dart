import 'package:flutter/material.dart';

class PositiveCases extends StatelessWidget {
  const PositiveCases({super.key, required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Settings')),
      body: Column(
        children: [
          Text('Hello'),
          Text("Save"),
          Text('Hello $name'),
          Text.rich(TextSpan(text: 'Followers')),
          TextField(decoration: InputDecoration(hintText: 'Search')),
          Tooltip(message: 'Refresh', child: Icon(Icons.refresh)),
          Semantics(label: 'Profile image', child: Icon(Icons.person)),
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          IconButton(
            tooltip: 'Delete',
            onPressed: () {},
            icon: Icon(Icons.delete),
          ),
        ],
      ),
    );
  }
}
