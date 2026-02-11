import 'package:flutter/material.dart';

class DiscoverPage extends StatefulWidget {
  const DiscoverPage({Key? key}) : super(key: key);

  @override
  State<DiscoverPage> createState() => _DiscoverPageState();
}

class _DiscoverPageState extends State<DiscoverPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Column(
              children: [
                const SizedBox(height: 4),
                // Profile Header
                _buildProfileHeader(),
                const SizedBox(height: 4),
                // Image Grid
                _buildImageGrid(),
                const SizedBox(height: 4),
                // Category Tags
                _buildCategoryTags(),
                const SizedBox(height: 6),
                // Action Buttons
                _buildActionButtons(),
                const SizedBox(height: 4),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Row(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: Colors.grey[300],
          child: const Icon(Icons.person, size: 20, color: Colors.grey),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Emma, 23',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const Spacer(),
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF87CEEB), Color(0xFFFFB6D9)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.image, color: Colors.white, size: 16),
        ),
      ],
    );
  }

  Widget _buildImageGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 6,
        mainAxisSpacing: 6,
        childAspectRatio: 1.0,
      ),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            _getIconForIndex(index),
            color: Colors.grey[600],
            size: 22,
          ),
        );
      },
    );
  }

  IconData _getIconForIndex(int index) {
    switch (index) {
      case 0:
        return Icons.music_note;
      case 1:
        return Icons.people;
      case 2:
        return Icons.album;
      case 3:
        return Icons.theater_comedy;
      case 4:
        return Icons.palette;
      case 5:
        return Icons.landscape;
      default:
        return Icons.image;
    }
  }

  Widget _buildCategoryTags() {
    final tags = ['Musik', '80er film', 'Kunst', 'Natur'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: tags
            .map(
              (tag) => Padding(
                padding: const EdgeInsets.only(right: 6.0),
                child: Chip(
                  label: Text(tag),
                  backgroundColor: Colors.white,
                  side: BorderSide(color: Colors.grey[300]!),
                  labelStyle: const TextStyle(color: Colors.black87, fontSize: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  visualDensity: const VisualDensity(horizontal: -1, vertical: -2),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildTagQuizButton() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8DC),
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Center(
        child: Text(
          'Tag Quiz',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFFB8860B),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            blurRadius: 12,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Reject Button
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFFFFE5F0),
                  const Color(0xFFFFCCE0),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF69B4).withOpacity(0.3),
                  blurRadius: 8,
                  spreadRadius: 0,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Center(
              child: Text(
                '✕',
                style: TextStyle(
                  fontSize: 26,
                  color: Color(0xFFFF1493),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 32),
          // Like Button
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFFEDE7F6),
                  const Color(0xFFD1C4E9),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF9575CD).withOpacity(0.3),
                  blurRadius: 8,
                  spreadRadius: 0,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Center(
              child: Icon(
                Icons.extension,
                color: Color(0xFF7E57C2),
                size: 28,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessagingIcons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildMessagingIcon(Icons.chat_bubble_outline, Colors.blue),
        const SizedBox(width: 20),
        _buildMessagingIcon(Icons.favorite_outline, Colors.purple),
        const SizedBox(width: 20),
        _buildMessagingIcon(Icons.chat_bubble_outline, Colors.blue),
      ],
    );
  }

  Widget _buildMessagingIcon(IconData icon, Color color) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Icon(
          icon,
          color: color,
          size: 20,
        ),
      ),
    );
  }
}
