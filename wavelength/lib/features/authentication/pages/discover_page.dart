import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:typed_data';
import 'package:wavelength/widgets/main_bottom_nav.dart';
import '../models/discover_model.dart';
import '../models/quiz_model.dart';
import '../models/quiz_result_model.dart';
import '../services/discover_service.dart';
import '../services/quiz_service.dart';
import '../widgets/quiz_dialog.dart';

class DiscoverPage extends StatefulWidget {
  const DiscoverPage({super.key});

  @override
  State<DiscoverPage> createState() => _DiscoverPageState();
}

class _DiscoverPageState extends State<DiscoverPage> {
  List<DiscoverUser> _profiles = [];
  bool _isLoading = true;
  String? _error;
  double _dragDistance = 0;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _loadInitialProfiles();
  }

  Future<void> _loadInitialProfiles() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Load 3 profiles
      final futures = List.generate(3, (_) => DiscoverService.fetchDiscoverUser());
      final profiles = await Future.wait(futures);
      
      setState(() {
        _profiles = profiles;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadNextProfile() async {
    try {
      final newProfile = await DiscoverService.fetchDiscoverUser();
      setState(() {
        _profiles.add(newProfile);
      });
    } catch (e) {
      print('Error loading next profile: $e');
    }
  }

  void _onSwipe(bool isLike) async {
    if (_profiles.isEmpty) return;

    final currentProfile = _profiles.first;

    if (isLike) {
      // Show quiz dialog on top of discover page
      await _showQuizForUser(currentProfile.id);
    } else {
      // If rejecting (X button), dismiss the user in database
      DiscoverService.dismissUser(currentProfile.id);
      
      setState(() {
        _profiles.removeAt(0);
        _dragDistance = 0;
        _isDragging = false;
      });

      // Load a new profile to maintain 3 profiles.
      _loadNextProfile();
    }
  }

  Future<void> _showQuizForUser(String userId) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: CircularProgressIndicator(color: Colors.purple),
      ),
    );

    try {
      final questions = await QuizService.fetchUserQuiz(userId);
      
      // Close loading dialog
      if (mounted) Navigator.pop(context);

      // Show quiz dialog
      if (mounted && questions.isNotEmpty) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => QuizDialog(
            questions: questions,
            userId: userId,
            onComplete: (result) {
              // Quiz completed with result
              Navigator.pop(context);
              _showQuizResult(result);
            },
          ),
        );
      } else {
        _showErrorDialog('Ingen quiz spørgsmål tilgængelige');
      }
    } catch (e) {
      // Close loading dialog
      if (mounted) Navigator.pop(context);
      
      // Show error dialog
      String errorMessage = 'Kunne ikke indlæse quiz';
      if (e.toString().contains('404')) {
        errorMessage = 'Denne brugers quiz er ikke opsat endnu';
      } else if (e.toString().contains('401')) {
        errorMessage = 'Du skal være logget ind for at se quizzen';
      }
      
      _showErrorDialog(errorMessage);
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Fejl'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showQuizResult(dynamic result) {
    final matchPercent = result.matchPercent ?? 0;
    final passed = result.passed ?? false;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(passed ? 'Du bestod! 🎉' : 'Du bestod ikke'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$matchPercent%',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: passed ? Colors.green : Colors.red,
              ),
            ),
            SizedBox(height: 10),
            Text(
              passed
                  ? 'Du matcher godt med denne bruger!'
                  : 'I matcher ikke helt, prøv en anden bruger',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Continue the discover flow - remove current profile and load next one
              setState(() {
                if (_profiles.isNotEmpty) {
                  _profiles.removeAt(0);
                  _dragDistance = 0;
                  _isDragging = false;
                }
              });
              _loadNextProfile();
            },
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: _buildBody(),
      ),
      bottomNavigationBar: const MainBottomNavBar(activeTab: MainNavTab.discover),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.person_search,
                size: 64,
                color: Colors.grey,
              ),
              const SizedBox(height: 16),
              Text(
                _error!.contains('404')
                    ? 'No users available to discover right now'
                    : 'Error: $_error',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadInitialProfiles,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_profiles.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.check_circle_outline,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            const Text(
              'No more profiles to show',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadInitialProfiles,
              child: const Text('Reload'),
            ),
          ],
        ),
      );
    }

    final user = _profiles.first;

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
            padding: const EdgeInsets.symmetric(
              horizontal: 12.0,
              vertical: 15.0,
            ),
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
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const Spacer(),
      ],
    );
  }

  Widget _buildImageGrid(DiscoverUser user) {
    if (user.pictures.isEmpty) {
      return Center(child: Text('No images available'));
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
    final imageUrl = DiscoverService.getInterestImageUrl(
      imageId,
      miniature: true,
    );
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
            child: Image.memory(imageSnapshot.data!, fit: BoxFit.cover),
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
              httpHeaders: {'Authorization': 'Bearer ${tokenSnapshot.data}'},
              placeholder: (context, url) => _buildLoadingPlaceholder(),
              errorWidget: (context, url, error) =>
                  _buildErrorWidget(imageId, error),
            ),
          );
        },
      );
    }
  }

  Future<Uint8List?> _fetchImageBytes({
    int? imageId,
    String? userId,
    bool isAvatar = false,
  }) async {
    try {
      final token = await _secureStorage.read(key: 'jwtToken');
      if (token == null) return null;

      late String imageUrl;
      if (isAvatar && userId != null) {
        imageUrl = DiscoverService.getAvatarUrl(userId);
      } else if (imageId != null) {
        imageUrl = DiscoverService.getInterestImageUrl(
          imageId,
          miniature: true,
        );
      } else {
        return null;
      }

      final response = await http
          .get(Uri.parse(imageUrl), headers: {'Authorization': 'Bearer $token'})
          .timeout(const Duration(seconds: 10));

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
      child: Icon(Icons.image, color: Colors.grey[600], size: 22),
    );
  }

  Widget _buildLoadingPlaceholder() {
    return Container(
      color: Colors.grey[300],
      child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
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
          Icon(Icons.broken_image, color: Colors.grey[600], size: 22),
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
              backgroundColor: Theme.of(context).chipTheme.backgroundColor ?? Colors.grey[800],
              side: BorderSide(color: Theme.of(context).dividerColor),
              labelStyle: TextStyle(
                color: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.white,
                fontSize: 12,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 6),
              visualDensity: const VisualDensity(horizontal: -1, vertical: -2),
            ),
          )
          .toList(),
    );
  }

  Widget _buildActionButton({
    required bool isLike,
    required List<Color> gradientColors,
    required Color shadowColor,
    required Widget child,
  }) {
    return GestureDetector(
      onTap: () => _onSwipe(isLike),
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradientColors,
          ),
          boxShadow: [
            BoxShadow(
              color: shadowColor.withOpacity(0.3),
              blurRadius: 8,
              spreadRadius: 0,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Center(child: child),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
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
          _buildActionButton(
            isLike: false,
            gradientColors: [const Color(0xFFFFE5F0), const Color(0xFFFFCCE0)],
            shadowColor: const Color(0xFFFF69B4),
            child: const Text(
              '✕',
              style: TextStyle(
                fontSize: 26,
                color: Color(0xFFFF1493),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 32),
          _buildActionButton(
            isLike: true,
            gradientColors: [const Color(0xFFEDE7F6), const Color(0xFFD1C4E9)],
            shadowColor: const Color(0xFF9575CD),
            child: const Icon(Icons.extension, color: Color(0xFF7E57C2), size: 28),
          ),
        ],
      ),
    );
  }
}
