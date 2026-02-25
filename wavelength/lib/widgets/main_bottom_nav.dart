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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(
                  Icons.person_rounded,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
                title: Text(
                  'Profil',
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  _goTo(context, MainNavTab.profile);
                },
              ),
              Divider(
                height: 0,
                color: isDarkMode ? Colors.grey[800] : Colors.grey[300],
              ),
              ListTile(
                leading: Icon(
                  Icons.close_rounded,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
                title: Text(
                  'Luk',
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                onTap: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        );
      },
    );
  }

  Color _iconColor(BuildContext context, MainNavTab tab) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    if (tab == activeTab) {
      return const Color(0xFF9B6DD9);
    }
    return isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600;
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return SafeArea(
      top: false,
      child: Container(
        height: 72,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
          border: Border(
            top: BorderSide(
              color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200,
              width: 1,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.08),
              blurRadius: 16,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: Icon(Icons.explore_rounded, color: _iconColor(context, MainNavTab.discover), size: 28),
              onPressed: () => _goTo(context, MainNavTab.discover),
            ),
            GestureDetector(
              onTap: () => _openMenu(context),
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF9B6DD9), Color(0xFF7D5CEB)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF9B6DD9).withOpacity(0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.menu_rounded, color: Colors.white, size: 26),
              ),
            ),
            IconButton(
              icon: Icon(Icons.people_alt_rounded, color: _iconColor(context, MainNavTab.matches), size: 28),
              onPressed: () => _goTo(context, MainNavTab.matches),
            ),
          ],
        ),
      ),
    );
  }
}
