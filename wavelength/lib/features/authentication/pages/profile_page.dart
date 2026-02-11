import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import 'login_page.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _authService = AuthService();
  final _secureStorage = FlutterSecureStorage();
  final _imagePicker = ImagePicker();

  // --- State variables ---
  UserModel? _user;
  bool _isLoading = true;
  bool _isEditing = false;
  String? _errorMessage;
  Uint8List? _avatarImage;

  // Editing 
  final _descriptionController = TextEditingController();

  // --- Tags ---
  Map<String, String> _availableTags = {}; // id -> name
  Set<String> _selectedTagIds = {}; // Store tag IDs instead of names
  bool _tagsLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  void _showSnack(String msg, {bool success = true}) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg),
        backgroundColor: success ? Colors.green : Colors.red,
      ));

  List<String> _getSortedTagIds(List<String> tagIds) {
    final selected = tagIds.where((id) => _selectedTagIds.contains(id)).toList();
    final notSelected = tagIds.where((id) => !_selectedTagIds.contains(id)).toList();
    // Sort by tag name, not ID
    selected.sort((a, b) => (_availableTags[a] ?? '').compareTo(_availableTags[b] ?? ''));
    notSelected.sort((a, b) => (_availableTags[a] ?? '').compareTo(_availableTags[b] ?? ''));
    return [...selected, ...notSelected];
  }

  Future<void> _loadUserProfile() async {
    setState(() => _isLoading = true);
    try {
      final res = await _authService.me();
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        final avatar = await _authService.getAvatarImage();
        setState(() {
          _user = UserModel.fromJson(json);
          _avatarImage = avatar;
          _descriptionController.text = _user?.description ?? '';
          _selectedTagIds = Set<String>.from(_user?.tags ?? []);
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Kunne ikke hente profil: ${res.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Fejl: $e';
        _isLoading = false;
      });
    }
  }

  // Loading available tags from API
  Future<void> _loadAvailableTags() async {
    setState(() => _tagsLoading = true);
    try {
      final res = await _authService.getAllTags();
      if (res.statusCode == 200) {
        final tagDict = jsonDecode(res.body) as Map<String, dynamic>;
        setState(() {
          _availableTags = Map<String, String>.from(
            tagDict.map((key, value) => MapEntry(key, value.toString()))
          );
          _tagsLoading = false;
        });
      } else {
        setState(() => _tagsLoading = false);
        _showSnack('Fejl: ${res.statusCode}', success: false);
      }
    } catch (e) {
      setState(() => _tagsLoading = false);
      _showSnack('Fejl: $e', success: false);
    }
  }

  // Saving profile data to API
  Future<void> _saveProfile() async {
    if (_user == null) return;
    setState(() => _isLoading = true);
    try {
      final desc = _descriptionController.text.trim();
      final res = await _authService.updateDescription(desc);
      if (res.statusCode == 200) {
        // Send tag IDs directly to API
        final tagRes = await _authService.setUserTags(_selectedTagIds.toList());
        if (tagRes.statusCode == 200 || tagRes.statusCode == 204) {
          setState(() {
            _user = _user!.copyWith(description: desc, tags: _selectedTagIds.toList());
            _isEditing = false;
            _isLoading = false;
          });
          _showSnack('Profil gemt!');
        } else {
          setState(() => _isLoading = false);
          _showSnack('Fejl ved gem af tags', success: false);
        }
      } else {
        setState(() => _isLoading = false);
        _showSnack('Fejl ved gem', success: false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnack('Fejl: $e', success: false);
    }
  }

  // --- AVATAR UPLOAD ---
  Future<void> _pickAndUploadAvatar() async {
    try {
      final img = await _imagePicker.pickImage(source: ImageSource.gallery, maxWidth: 1024, maxHeight: 1024, imageQuality: 85);
      if (img == null) return;
      setState(() => _isLoading = true);
      final res = await _authService.uploadAvatar(await img.readAsBytes(), img.name);
      if (res.statusCode == 200 || res.statusCode == 204) {
        final avatar = await _authService.getAvatarImage();
        setState(() {
          _avatarImage = avatar;
          _isLoading = false;
        });
        _showSnack('Billede uploadet!');
      } else {
        setState(() => _isLoading = false);
        _showSnack('Upload fejl', success: false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnack('Fejl: $e', success: false);
    }
  }

  // --- LOG UD ---
  Future<void> _logout() async {
    try {
      final token = await _secureStorage.read(key: 'jwtToken');
      if (token != null) await _authService.logout(token);
      await _secureStorage.deleteAll();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (route) => false,
      );
    } catch (e) {
      _showSnack('Fejl ved logout: $e', success: false);
    }
  }

  // --- SKIFT ADGANGSKODE ---
  void _showChangePasswordDialog() {
    final old = TextEditingController();
    final newPwd = TextEditingController();
    final confirm = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Skift Adgangskode'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: old,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Nuværende',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: newPwd,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Ny',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: confirm,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Bekræft ny',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuller'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (newPwd.text != confirm.text) {
                _showSnack('Adgangskoder matcher ikke', success: false);
                return;
              }
              if (old.text.isEmpty || newPwd.text.isEmpty) {
                _showSnack('Udfyld alle felter', success: false);
                return;
              }
              try {
                final res = await _authService.updatePassword(
                  currentPassword: old.text,
                  newPassword: newPwd.text,
                  confirmNewPassword: confirm.text,
                );
                if (mounted) {
                  Navigator.pop(context);
                  _showSnack(
                    res.statusCode == 200
                        ? 'Adgangskode ændret!'
                        : 'Fejl: ${res.statusCode}',
                    success: res.statusCode == 200,
                  );
                }
              } catch (e) {
                if (mounted) {
                  Navigator.pop(context);
                  _showSnack('Fejl: $e', success: false);
                }
              }
            },
            child: const Text('Gem'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // --- HEADER ---
        title: const Text('Min Profil'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          if (!_isEditing && !_isLoading && _user != null)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                _loadAvailableTags();
                setState(() => _isEditing = true);
              },
            ),
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                setState(() {
                  _isEditing = false;
                  _descriptionController.text = _user?.description ?? '';
                  _selectedTagIds = Set<String>.from(_user?.tags ?? []);
                });
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.error_outline, size: 60, color: Colors.red), const SizedBox(height: 16), Text(_errorMessage!, style: const TextStyle(fontSize: 16, color: Colors.red), textAlign: TextAlign.center), const SizedBox(height: 16), ElevatedButton(onPressed: _loadUserProfile, child: const Text('Prøv igen'))]))
          : _user == null
          ? const Center(child: Text('Ingen brugerdata'))
          : RefreshIndicator(
              onRefresh: _loadUserProfile,
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                    const SizedBox(height: 20),
                    Stack(children: [CircleAvatar(radius: 60, backgroundColor: Colors.deepPurple, backgroundImage: _avatarImage != null ? MemoryImage(_avatarImage!) as ImageProvider : null, child: _avatarImage == null ? Text(_user!.username.isNotEmpty ? _user!.username[0].toUpperCase() : _user!.email.isNotEmpty ? _user!.email[0].toUpperCase() : '?', style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white)) : null), Positioned(bottom: 0, right: 0, child: CircleAvatar(backgroundColor: Colors.deepPurple, radius: 20, child: IconButton(icon: const Icon(Icons.camera_alt, size: 16, color: Colors.white), onPressed: _pickAndUploadAvatar)))])  ,
                    const SizedBox(height: 24),
                    Text(
                      '${_user!.firstName ?? ''} ${_user!.lastName ?? ''}'
                              .trim()
                              .isNotEmpty
                          ? '${_user!.firstName ?? ''} ${_user!.lastName ?? ''}'
                                .trim()
                          : _user!.username.isNotEmpty
                          ? _user!.username
                          : _user!.email,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _user!.email,
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                    if (_user!.birthday != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          DateFormat('dd/MM/yyyy').format(_user!.birthday!),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    const SizedBox(height: 32),
                    Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.description,
                                  color: Colors.deepPurple,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Beskrivelse',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _isEditing
                                ? TextField(
                                    controller: _descriptionController,
                                    maxLines: 4,
                                    decoration: InputDecoration(
                                      hintText: 'Fortæl om dig selv...',
                                      filled: true,
                                      fillColor: Colors.deepPurple.shade50,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(
                                          color: Colors.deepPurple,
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: Colors.deepPurple.shade200,
                                          width: 1.5,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(
                                          color: Colors.deepPurple,
                                          width: 2,
                                        ),
                                      ),
                                      contentPadding: const EdgeInsets.all(16),
                                    ),
                                  )
                                : Text(
                                    _user!.description?.isNotEmpty == true
                                        ? _user!.description!
                                        : 'Ingen beskrivelse',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color:
                                          _user!.description?.isNotEmpty == true
                                          ? Colors.black87
                                          : Colors.grey,
                                    ),
                                  ),
                          ],
                        ),
                      ),
                    ),
                    // --- TAGS ---
                    if (!_isEditing && (_user!.tags?.isNotEmpty ?? false)) ...[
                      const SizedBox(height: 20),
                      Card(
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.label, color: Colors.deepPurple),
                                  const SizedBox(width: 8),
                                  const Text('Tags', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                alignment: WrapAlignment.start,
                                spacing: 8,
                                runSpacing: 8,
                                children: (_user!.tags!.map((id) => _availableTags[id] ?? id).toList()..sort()).map((tagName) {
                                  return Chip(
                                    label: Text(tagName),
                                    backgroundColor: Colors.deepPurple.shade100,
                                    labelStyle: const TextStyle(color: Colors.deepPurple, fontWeight: FontWeight.w600),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    // Tags i edit mode
                    if (_isEditing) ...[
                      const SizedBox(height: 20),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.label, color: Colors.deepPurple),
                                  const SizedBox(width: 8),
                                  Expanded(child: Text('Tags (${_selectedTagIds.length}/10)', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                                ],
                              ),
                              const SizedBox(height: 12),
                              if (_tagsLoading)
                                const Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator())
                              else if (_availableTags.isEmpty)
                                const Text('Ingen tags tilgængelige', style: TextStyle(color: Colors.grey))
                              else
                                ConstrainedBox(
                                  constraints: const BoxConstraints(maxHeight: 175),
                                  child: ListView(
                                    padding: EdgeInsets.zero,
                                    shrinkWrap: true,
                                    children: _getSortedTagIds(_availableTags.keys.toList()).map((tagId) {
                                      final isSelected = _selectedTagIds.contains(tagId);
                                      final tagName = _availableTags[tagId] ?? tagId;
                                      return CheckboxListTile(
                                        dense: true,
                                        title: Text(tagName),
                                        value: isSelected,
                                        onChanged: (_) {
                                          setState(() {
                                            if (isSelected) {
                                              _selectedTagIds.remove(tagId);
                                            } else if (_selectedTagIds.length < 10) {
                                              _selectedTagIds.add(tagId);
                                            }
                                          });
                                        },
                                        activeColor: Colors.deepPurple,
                                        checkColor: Colors.white,
                                      );
                                    }).toList(),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 34, right: 34, top: 8, bottom: 30),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_isEditing)
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.save),
                              label: const Text('Gem Ændringer'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.deepPurple,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.all(16),
                              ),
                              onPressed: _saveProfile,
                            ),
                          ),
                        if (!_isEditing) ...[
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.lock),
                              label: const Text('Skift Adgangskode'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.deepPurple,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.all(16),
                              ),
                              onPressed: _showChangePasswordDialog,
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.logout),
                              label: const Text('Log Ud'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.deepPurple,
                                padding: const EdgeInsets.all(16),
                                side: const BorderSide(color: Colors.deepPurple),
                              ),
                              onPressed: _logout,
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.delete_forever),
                              label: const Text('Slet Konto'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                                padding: const EdgeInsets.all(16),
                                side: const BorderSide(color: Colors.red),
                              ),
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Funktionen er endnu ikke implementeret',
                                    ),
                                    backgroundColor: Colors.orange,
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
