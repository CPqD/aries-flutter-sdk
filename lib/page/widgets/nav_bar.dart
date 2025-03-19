import 'dart:io';

import 'package:flutter/material.dart';

import 'nav_item.dart';

class NavBar extends StatelessWidget {
  final int pageIndex;
  final Function(int) onTap;
  final int notificationCount;

  const NavBar({
    super.key,
    required this.pageIndex,
    required this.onTap,
    required this.notificationCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: Platform.isAndroid ? 16 : 0,
      ),
      child: BottomAppBar(
        color: Colors.transparent,
        elevation: 0.0,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Container(
            height: 60,
            color: Theme.of(context).colorScheme.secondary,
            child: Row(
              children: [
                NavItem(
                  icon: Icons.notifications,
                  label: 'Notificações',
                  selected: pageIndex == 0,
                  notificationCount: notificationCount,
                  onTap: () => onTap(0),
                ),
                const SizedBox(
                  width: 80,
                ),
                NavItem(
                  icon: Icons.settings,
                  label: 'Configurações',
                  selected: pageIndex == 1,
                  onTap: () => onTap(1),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
