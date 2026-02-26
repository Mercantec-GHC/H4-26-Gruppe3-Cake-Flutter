import 'dart:math';
import 'dart:typed_data';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:wavelength/widgets/main_bottom_nav.dart';
import '../models/matched_user_model.dart';
import '../services/matches_service.dart';

class MatchesPage extends StatefulWidget {
  const MatchesPage({super.key});

  @override
  State<MatchesPage> createState() => _MatchesPageState();
}

class _MatchesPageState extends State<MatchesPage> {
  // State til liste, pagination og token
  final List<MatchedUser> _matches = [];
  final ScrollController _scrollController = ScrollController();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  late final Future<String?> _tokenFuture;

  // Page size is set to 1 during testing; It will be set to 10 for production.
  static const int _pageSize = 10;
  int _currentPage = 1;
  int _totalPages = 1;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tokenFuture = _secureStorage.read(key: 'jwtToken');
    // Hent første side af matches
    _loadInitial();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadInitial() async {
    // Nulstil state og hent side 1
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // MatchesCount returns the number of pages for a given page size.
      final totalPages = await MatchesService.fetchMatchesPageCount(
        pageCount: _pageSize,
      );

      if (!mounted) return;

      if (totalPages <= 0) {
        setState(() {
          _totalPages = 0;
          _matches.clear();
          _isLoading = false;
        });
        return;
      }

      final matches = await MatchesService.fetchMatchedUsers(
        page: 1,
        count: _pageSize,
      );

      if (!mounted) return;

      setState(() {
        _totalPages = totalPages;
        _currentPage = 1;
        _matches
          ..clear()
          ..addAll(matches);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    // Pagination: hent flere matches
    if (_isLoadingMore || _currentPage >= _totalPages) return;

    setState(() {
      _isLoadingMore = true;
    });

    final nextPage = _currentPage + 1;

    try {
      final matches = await MatchesService.fetchMatchedUsers(
        page: nextPage,
        count: _pageSize,
      );

      if (!mounted) return;

      setState(() {
        _currentPage = nextPage;
        _matches.addAll(matches);
        _isLoadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _isLoadingMore = false;
      });
    }
  }


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
              child: _buildBody(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const MainBottomNavBar(activeTab: MainNavTab.matches),
    );
  }

  Widget _buildBody() {
    // Vis loading/fejl/empty/list
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.person_search, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadInitial,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_matches.isEmpty) {
      return const Center(
        child: Text(
          'Ingen matches endnu',
          style: TextStyle(fontSize: 16),
        ),
      );
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        // Load næste side når vi er tæt på bunden
        if (notification is ScrollUpdateNotification ||
            notification is OverscrollNotification) {
          if (notification.metrics.extentAfter < 200) {
            _loadMore();
          }
        }
        return false;
      },
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 16.0),
        itemCount: _matches.length + (_isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= _matches.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16.0),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          return _buildMatchCard(_matches[index]);
        },
      ),
    );
  }

  Widget _buildMatchCard(MatchedUser match) {
    // Kort for en enkelt match
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
            Row(
              children: [
                _buildAvatar(match.id),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    match.fullName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Viser max 3 tags for kompakt kort. 
            if (match.tags.isNotEmpty)
              Wrap(
                spacing: 4.0,
                runSpacing: 4.0,
                children: _selectTags(match)
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
            if (match.matchPercent != null) ...[
              const SizedBox(height: 10),
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
                    '${match.matchPercent}% på bølgelængde',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(String userId) {
    // Web: hent bytes direkte. Mobil: cached image med auth header.
    // Web uses direct byte fetch because cached_network_image headers are limited on web.
    if (kIsWeb) {
      return FutureBuilder<Uint8List?>(
        future: _fetchAvatarBytes(userId: userId),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data != null) {
            return ClipOval(
              child: Image.memory(
                snapshot.data!,
                width: 50,
                height: 50,
                fit: BoxFit.cover,
              ),
            );
          }
          return _buildAvatarPlaceholder();
        },
      );
    }

    return FutureBuilder<String?>(
      future: _tokenFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data == null) {
          return _buildAvatarPlaceholder();
        }

        // CachedNetworkImage håndterer caching og auth headers på mobil. På web er der begrænsninger, så vi bruger Image.memory der i stedet.
        return ClipOval(
          child: CachedNetworkImage(
            imageUrl: MatchesService.getAvatarUrl(userId),
            width: 50,
            height: 50,
            fit: BoxFit.cover,
            httpHeaders: {
              'Authorization': 'Bearer ${snapshot.data}',
            },
            placeholder: (context, url) => _buildAvatarPlaceholder(),
            errorWidget: (context, url, error) => _buildAvatarPlaceholder(),
          ),
        );
      },
    );
  }

  Widget _buildAvatarPlaceholder() {
    // Placeholder avatar når billedet mangler
    return Container(
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
      child: const Icon(Icons.person, size: 24, color: Colors.grey),
    );
  }

  List<String> _selectTags(MatchedUser match) {
    // Viser max 3 tags for kompakt kort
    if (match.tags.length <= 3) {
      return match.tags;
    }

    final random = Random(match.id.hashCode);
    final shuffled = List<String>.from(match.tags)..shuffle(random);
    return shuffled.take(3).toList();
  }

  Future<Uint8List?> _fetchAvatarBytes({required String userId}) async {
    // Hent avatar med token til web
    try {
      final token = await _secureStorage.read(key: 'jwtToken');
      if (token == null) return null;

      final response = await http.get(
        Uri.parse(MatchesService.getAvatarUrl(userId)),
        headers: {
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return response.bodyBytes;
      }
    } catch (_) {
      return null;
    }

    return null;
  }
}
