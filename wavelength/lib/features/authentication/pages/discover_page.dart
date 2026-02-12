import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/discover_model.dart';
import '../services/discover_service.dart';

class DiscoverPage extends StatefulWidget {
  const DiscoverPage({Key? key}) : super(key: key);

  @override
  State<DiscoverPage> createState() => _DiscoverPageState();
}

class _DiscoverPageState extends State<DiscoverPage> {
  late Future<DiscoverUser> _discoverUserFuture;

  @override
  void initState() {
    super.initState();
    const testUserId = '4bf35003af77409da3b779d116b073f6';
    _discoverUserFuture = DiscoverService.fetchDiscoverUser(userId: testUserId);
    
    // _discoverUserFuture = DiscoverService.fetchDiscoverUser();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      body: SafeArea(
        child: FutureBuilder<DiscoverUser>(
          future: _discoverUserFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.person_search, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text(
                        snapshot.error.toString().contains('404')
                            ? 'No users available to discover right now'
                            : 'Error: ${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _discoverUserFuture =
                                DiscoverService.fetchDiscoverUser();
                          });
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              );
            }

            final user = snapshot.data!;

            return Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                      child: Column(
                        children: [
                          const SizedBox(height: 4),
                          // Profile Header
                          _buildProfileHeader(user),
                          const SizedBox(height: 4),
                          // Image Grid
                          _buildImageGrid(user),
                          const SizedBox(height: 4),
                          // Category Tags
                          _buildCategoryTags(user),
                          const SizedBox(height: 6),
                        ],
                      ),
                    ),
                  ),
                ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6.0),
                    child: _buildActionButtons(),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildProfileHeader(DiscoverUser user) {
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
            Text(
              '${user.firstName}, 23',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const Spacer(),
        Container(
          width: 32,
          height: 32,
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

  Widget _buildImageGrid(DiscoverUser user) {
    print('Interests count: ${user.interests.length}');
    print('Interest IDs: ${user.interests}');
    
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 6,
        mainAxisSpacing: 6,
        childAspectRatio: 1.0,
      ),
      itemCount: user.interests.length,
      itemBuilder: (context, index) {
        final interestId = user.interests[index];
        final imageUrl = DiscoverService.getInterestImageUrl(interestId, miniature: true);
        
        print('Loading image: $imageUrl'); // Debug

        return FutureBuilder<String?>(
          future: _secureStorage.read(key: 'jwtToken'),
          builder: (context, tokenSnapshot) {
            if (!tokenSnapshot.hasData) {
              return Container(
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.image,
                  color: Colors.grey[600],
                  size: 22,
                ),
              );
            }

            return ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                httpHeaders: {
                  'Authorization': 'Bearer ${tokenSnapshot.data}',
                },
                placeholder: (context, url) {
                  return Container(
                    color: Colors.grey[300],
                    child: const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  );
                },
                errorWidget: (context, url, error) {
                  print('Image error for $imageUrl: $error'); // Debug
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.broken_image,
                          color: Colors.grey[600],
                          size: 22,
                        ),
                        Text(
                          'ID: $interestId',
                          style: TextStyle(fontSize: 10, color: Colors.grey[700]),
                        ),
                      ],
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  final _secureStorage = const FlutterSecureStorage();

  Widget _buildCategoryTags(DiscoverUser user) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: user.tags
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
}

