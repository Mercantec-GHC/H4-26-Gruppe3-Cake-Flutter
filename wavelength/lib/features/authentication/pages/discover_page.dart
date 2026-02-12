import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:typed_data';
import '../models/discover_model.dart';
import '../services/discover_service.dart';

class DiscoverPage extends StatefulWidget {
  const DiscoverPage({super.key});

  @override
  State<DiscoverPage> createState() => _DiscoverPageState();
}

class _DiscoverPageState extends State<DiscoverPage> {
  late Future<DiscoverUser> _discoverUserFuture;

  @override
  void initState() {
    super.initState();
    _discoverUserFuture = DiscoverService.fetchDiscoverUser();
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
                          const SizedBox(height: 16),
                          // Profile Header
                          _buildProfileHeader(user),
                          const SizedBox(height: 12),
                          // Image Grid
                          _buildImageGrid(user),
                        ],
                      ),
                    ),
                  ),
                ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 15.0),
                    child: _buildCategoryTags(user),
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
        FutureBuilder<Uint8List?>(
          future: _fetchImageBytes(userId: user.id, isAvatar: true),
          builder: (context, snapshot) {
            if (snapshot.hasData && snapshot.data != null) {
              return ClipOval(
                child: Image.memory(
                  snapshot.data!,
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                ),
              );
            }
            return CircleAvatar(
              radius: 24,
              backgroundColor: Colors.grey[300],
              child: const Icon(Icons.person, size: 20, color: Colors.grey),
            );
          },
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${user.firstName}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const Spacer(),
      ],
    );
  }

  Widget _buildImageGrid(DiscoverUser user) {
    if (user.pictures.isEmpty) {
      return Center(
        child: Text('No images available'),
      );
    }
    
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 6,
        mainAxisSpacing: 6,
        childAspectRatio: 1.0,
      ),
      itemCount: user.pictures.length,
      itemBuilder: (context, index) {
        final imageId = user.pictures[index];
        return _buildImageWidget(imageId);
      },
    );
  }

  Widget _buildImageWidget(int imageId) {
    final imageUrl = DiscoverService.getInterestImageUrl(imageId, miniature: true);
    if (kIsWeb) {
      // Web platform - use a different approach
      return FutureBuilder<Uint8List?>(
        future: _fetchImageBytes(imageId: imageId),
        builder: (context, imageSnapshot) {
          if (imageSnapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingPlaceholder();
          }

          if (imageSnapshot.hasError || imageSnapshot.data == null) {
            return _buildErrorWidget(imageId, imageSnapshot.error);
          }

          return ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.memory(
              imageSnapshot.data!,
              fit: BoxFit.cover,
            ),
          );
        },
      );
    } else {
      // Native platforms (Windows, iOS, Android) - use cached network image with headers
      return FutureBuilder<String?>(
        future: _secureStorage.read(key: 'jwtToken'),
        builder: (context, tokenSnapshot) {
          if (!tokenSnapshot.hasData) {
            return _buildPlaceholder();
          }

          return ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.cover,
              httpHeaders: {
                'Authorization': 'Bearer ${tokenSnapshot.data}',
              },
              placeholder: (context, url) => _buildLoadingPlaceholder(),
              errorWidget: (context, url, error) => _buildErrorWidget(imageId, error),
            ),
          );
        },
      );
    }
  }

  Future<Uint8List?> _fetchImageBytes({int? imageId, String? userId, bool isAvatar = false}) async {
    try {
      final token = await _secureStorage.read(key: 'jwtToken');
      if (token == null) return null;

      late String imageUrl;
      if (isAvatar && userId != null) {
        imageUrl = DiscoverService.getAvatarUrl(userId);
      } else if (imageId != null) {
        imageUrl = DiscoverService.getInterestImageUrl(imageId, miniature: true);
      } else {
        return null;
      }

      final response = await http.get(
        Uri.parse(imageUrl),
        headers: {
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else {
        print('Error fetching image bytes: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  Widget _buildPlaceholder() {
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

  Widget _buildLoadingPlaceholder() {
    return Container(
      color: Colors.grey[300],
      child: const Center(
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }

  Widget _buildErrorWidget(int imageId, dynamic error) {
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
            'ID: $imageId',
            style: TextStyle(fontSize: 10, color: Colors.grey[700]),
          ),
        ],
      ),
    );
  }

  final _secureStorage = const FlutterSecureStorage();

  Widget _buildCategoryTags(DiscoverUser user) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 6.0,
      runSpacing: 6.0,
      children: user.tags
          .map(
            (tag) => Chip(
              label: Text(tag),
              backgroundColor: Colors.white,
              side: BorderSide(color: Colors.grey[300]!),
              labelStyle: const TextStyle(color: Colors.black87, fontSize: 12),
              padding: const EdgeInsets.symmetric(horizontal: 6),
              visualDensity: const VisualDensity(horizontal: -1, vertical: -2),
            ),
          )
          .toList(),
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

