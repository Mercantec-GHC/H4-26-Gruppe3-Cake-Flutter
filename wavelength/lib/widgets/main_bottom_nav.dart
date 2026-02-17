import 'package:flutter/material.dart';
import 'package:wavelength/features/authentication/pages/discover_page.dart';
import 'package:wavelength/features/authentication/pages/matches_page.dart';
import 'package:wavelength/features/authentication/pages/profile_page.dart';

enum MainNavTab {
  discover,
  matches,
  profile,
}

class MainBottomNavBar extends StatelessWidget {
  const MainBottomNavBar({super.key, required this.activeTab});

  final MainNavTab activeTab;

  void _goTo(BuildContext context, MainNavTab tab) {
    if (tab == activeTab) {
      return;
    }

    Widget page;
    switch (tab) {
      case MainNavTab.discover:
        page = const DiscoverPage();
        break;
      case MainNavTab.matches:
        page = const MatchesPage();
        break;
      case MainNavTab.profile:
        page = const ProfilePage();
        break;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => page),
    );
  }

  void _openMenu(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.person_rounded),
                title: const Text('Profil'),
                onTap: () {
                  Navigator.of(context).pop();
                  _goTo(context, MainNavTab.profile);
                },
              ),
              const Divider(height: 0),
              ListTile(
                leading: const Icon(Icons.close_rounded),
                title: const Text('Luk'),
                onTap: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        );
      },
    );
  }

  Color _iconColor(BuildContext context, MainNavTab tab) {
    if (tab == activeTab) {
      return const Color(0xFF7D5CEB);
    }
    return Colors.grey.shade500;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        height: 72,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: Icon(Icons.explore_rounded, color: _iconColor(context, MainNavTab.discover)),
              onPressed: () => _goTo(context, MainNavTab.discover),
            ),
            GestureDetector(
              onTap: () => _openMenu(context),
              child: Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: const Color(0xFF9B6DD9),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF9B6DD9).withOpacity(0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.menu_rounded, color: Colors.white),
              ),
            ),
            IconButton(
              icon: Icon(Icons.people_alt_rounded, color: _iconColor(context, MainNavTab.matches)),
              onPressed: () => _goTo(context, MainNavTab.matches),
            ),
          ],
        ),
      ),
    );
  }
}
