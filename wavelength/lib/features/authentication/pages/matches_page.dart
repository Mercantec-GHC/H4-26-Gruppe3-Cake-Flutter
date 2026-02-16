import 'package:flutter/material.dart';
import 'package:wavelength/widgets/main_bottom_nav.dart';

class MatchesPage extends StatefulWidget {
  const MatchesPage({super.key});

  @override
  State<MatchesPage> createState() => _MatchesPageState();
}

class _MatchesPageState extends State<MatchesPage> {
  // Hardcoded match data
  final List<Match> matches = [
    Match(
      id: '1',
      name: 'Sarah',
      avatar: '👩‍🦰',
      tags: ['Gaming', 'Natur', 'Musik'],
      compatibility: 96,
    ),
    Match(
      id: '2',
      name: 'Mads',
      avatar: '👨‍🦱',
      tags: ['Musik', '80\'er film', 'Kunst'],
      compatibility: 89,
    ),
    Match(
      id: '3',
      name: 'Sofie',
      avatar: '👩‍🦳',
      tags: ['Fitness', 'Musik', 'BøgerOgLæsning'],
      compatibility: 82,
    ),
    Match(
      id: '4',
      name: 'Nadia',
      avatar: '👩‍🦱',
      tags: ['Musik', '80\'er film', 'Kunst'],
      compatibility: 81,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 16.0, top: 16.0, right: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Matches',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 16.0),
                itemCount: matches.length,
                itemBuilder: (context, index) {
                  return _buildMatchCard(matches[index]);
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const MainBottomNavBar(activeTab: MainNavTab.matches),
    );
  }

  Widget _buildMatchCard(Match match) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            spreadRadius: 0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with avatar and name
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey[300],
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
                        blurRadius: 4,
                        spreadRadius: 0,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      match.avatar,
                      style: const TextStyle(fontSize: 28),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        match.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Tags
            Wrap(
              spacing: 4.0,
              runSpacing: 4.0,
              children: match.tags
                  .map(
                    (tag) => Chip(
                      label: Text(tag),
                      backgroundColor: Colors.white,
                      side: BorderSide(
                        color: Colors.grey[300]!,
                      ),
                      labelStyle: const TextStyle(
                        color: Colors.black87,
                        fontSize: 11,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      visualDensity: const VisualDensity(
                        horizontal: -2,
                        vertical: -3,
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 10),
            // Compatibility badge
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 10.0,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF9B6DD9),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF9B6DD9).withOpacity(0.3),
                      blurRadius: 8,
                      spreadRadius: 0,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Text(
                  '${match.compatibility}% på bølgelængde',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Match {
  final String id;
  final String name;
  final String avatar;
  final List<String> tags;
  final int compatibility;

  Match({
    required this.id,
    required this.name,
    required this.avatar,
    required this.tags,
    required this.compatibility,
  });
}
