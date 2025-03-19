import 'package:flutter/material.dart';

class TabPage extends StatelessWidget {
  final int tab;
  final Widget page;

  const TabPage({super.key, required this.tab, required this.page});

  @override
  Widget build(BuildContext context) {
    return page;
  }
}
