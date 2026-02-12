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
  bool _hasQuiz = false;

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
    _checkForQuiz();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  void _showSnack(String msg, {bool success = true}) =>
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );

  List<String> _getSortedTagIds(List<String> tagIds) {
    final selected = tagIds
        .where((id) => _selectedTagIds.contains(id))
        .toList();
    final notSelected = tagIds
        .where((id) => !_selectedTagIds.contains(id))
        .toList();
    // Sort by tag name, not ID
    selected.sort(
      (a, b) => (_availableTags[a] ?? '').compareTo(_availableTags[b] ?? ''),
    );
    notSelected.sort(
      (a, b) => (_availableTags[a] ?? '').compareTo(_availableTags[b] ?? ''),
    );
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

  // Check if user has a quiz
  Future<void> _checkForQuiz() async {
    try {
      final res = await _authService.getQuiz();
      if (mounted) {
        setState(() => _hasQuiz = res.statusCode == 200);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _hasQuiz = false);
      }
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
            tagDict.map((key, value) => MapEntry(key, value.toString())),
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
            _user = _user!.copyWith(
              description: desc,
              tags: _selectedTagIds.toList(),
            );
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
      final img = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (img == null) return;
      setState(() => _isLoading = true);
      final res = await _authService.uploadAvatar(
        await img.readAsBytes(),
        img.name,
      );
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
                if (!mounted) return;
                Navigator.pop(context);
                _showSnack(
                  res.statusCode == 200
                      ? 'Adgangskode ændret!'
                      : 'Fejl: ${res.statusCode}',
                  success: res.statusCode == 200,
                );
              } catch (e) {
                if (!mounted) return;
                Navigator.pop(context);
                _showSnack('Fejl: $e', success: false);
              }
            },
            child: const Text('Gem'),
          ),
        ],
      ),
    );
  }

  // --- LAV QUIZ ---
  Future<bool?> _showQuizEditor() async {
    return await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _QuizEditorModal(
        authService: _authService,
        shouldLoadExisting: _hasQuiz,
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
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 60, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage!,
                    style: const TextStyle(fontSize: 16, color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadUserProfile,
                    child: const Text('Prøv igen'),
                  ),
                ],
              ),
            )
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
                          Stack(
                            children: [
                              CircleAvatar(
                                radius: 60,
                                backgroundColor: Colors.deepPurple,
                                backgroundImage: _avatarImage != null
                                    ? MemoryImage(_avatarImage!)
                                          as ImageProvider
                                    : null,
                                child: _avatarImage == null
                                    ? Text(
                                        _user!.username.isNotEmpty
                                            ? _user!.username[0].toUpperCase()
                                            : _user!.email.isNotEmpty
                                            ? _user!.email[0].toUpperCase()
                                            : '?',
                                        style: const TextStyle(
                                          fontSize: 48,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      )
                                    : null,
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: CircleAvatar(
                                  backgroundColor: Colors.deepPurple,
                                  radius: 20,
                                  child: IconButton(
                                    icon: const Icon(
                                      Icons.camera_alt,
                                      size: 16,
                                      color: Colors.white,
                                    ),
                                    onPressed: _pickAndUploadAvatar,
                                  ),
                                ),
                              ),
                            ],
                          ),
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
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                          if (_user!.birthday != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                DateFormat(
                                  'dd/MM/yyyy',
                                ).format(_user!.birthday!),
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
                                            fillColor:
                                                Colors.deepPurple.shade50,
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              borderSide: const BorderSide(
                                                color: Colors.deepPurple,
                                              ),
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              borderSide: BorderSide(
                                                color:
                                                    Colors.deepPurple.shade200,
                                                width: 1.5,
                                              ),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              borderSide: const BorderSide(
                                                color: Colors.deepPurple,
                                                width: 2,
                                              ),
                                            ),
                                            contentPadding:
                                                const EdgeInsets.all(16),
                                          ),
                                        )
                                      : Text(
                                          _user!.description?.isNotEmpty == true
                                              ? _user!.description!
                                              : 'Ingen beskrivelse',
                                          style: TextStyle(
                                            fontSize: 16,
                                            color:
                                                _user!
                                                        .description
                                                        ?.isNotEmpty ==
                                                    true
                                                ? Colors.black87
                                                : Colors.grey,
                                          ),
                                        ),
                                ],
                              ),
                            ),
                          ),
                          // --- TAGS ---
                          if (!_isEditing &&
                              (_user!.tags?.isNotEmpty ?? false)) ...[
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
                                        Icon(
                                          Icons.label,
                                          color: Colors.deepPurple,
                                        ),
                                        const SizedBox(width: 8),
                                        const Text(
                                          'Tags',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Wrap(
                                      alignment: WrapAlignment.start,
                                      spacing: 8,
                                      runSpacing: 8,
                                      children:
                                          (_user!.tags!
                                                  .map(
                                                    (id) =>
                                                        _availableTags[id] ??
                                                        id,
                                                  )
                                                  .toList()
                                                ..sort())
                                              .map((tagName) {
                                                return Chip(
                                                  label: Text(tagName),
                                                  backgroundColor: Colors
                                                      .deepPurple
                                                      .shade100,
                                                  labelStyle: const TextStyle(
                                                    color: Colors.deepPurple,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                );
                                              })
                                              .toList(),
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
                                        Icon(
                                          Icons.label,
                                          color: Colors.deepPurple,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'Tags (${_selectedTagIds.length}/10)',
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    if (_tagsLoading)
                                      const Padding(
                                        padding: EdgeInsets.all(16),
                                        child: CircularProgressIndicator(),
                                      )
                                    else if (_availableTags.isEmpty)
                                      const Text(
                                        'Ingen tags tilgængelige',
                                        style: TextStyle(color: Colors.grey),
                                      )
                                    else
                                      ConstrainedBox(
                                        constraints: const BoxConstraints(
                                          maxHeight: 175,
                                        ),
                                        child: ListView(
                                          padding: EdgeInsets.zero,
                                          shrinkWrap: true,
                                          children:
                                              _getSortedTagIds(
                                                _availableTags.keys.toList(),
                                              ).map((tagId) {
                                                final isSelected =
                                                    _selectedTagIds.contains(
                                                      tagId,
                                                    );
                                                final tagName =
                                                    _availableTags[tagId] ??
                                                    tagId;
                                                return CheckboxListTile(
                                                  dense: true,
                                                  title: Text(tagName),
                                                  value: isSelected,
                                                  onChanged: (_) {
                                                    setState(() {
                                                      if (isSelected) {
                                                        _selectedTagIds.remove(
                                                          tagId,
                                                        );
                                                      } else if (_selectedTagIds
                                                              .length <
                                                          10) {
                                                        _selectedTagIds.add(
                                                          tagId,
                                                        );
                                                      }
                                                    });
                                                  },
                                                  activeColor:
                                                      Colors.deepPurple,
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
                    padding: const EdgeInsets.only(
                      left: 34,
                      right: 34,
                      top: 8,
                      bottom: 30,
                    ),
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
                            child: ElevatedButton.icon(
                              icon: Icon(_hasQuiz ? Icons.edit : Icons.quiz),
                              label: Text(
                                _hasQuiz ? 'Rediger Quiz' : 'Lav Quiz',
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.deepPurple,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.all(16),
                              ),
                              onPressed: () async {
                                final result = await _showQuizEditor();
                                if (result == true) {
                                  setState(() => _hasQuiz = true);
                                }
                              },
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
                                side: const BorderSide(
                                  color: Colors.deepPurple,
                                ),
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

// --- QUIZ EDITOR MODAL ---
class _QuizEditorModal extends StatefulWidget {
  final AuthService authService;
  final bool shouldLoadExisting;

  const _QuizEditorModal({
    required this.authService,
    this.shouldLoadExisting = false,
  });

  @override
  State<_QuizEditorModal> createState() => _QuizEditorModalState();
}

class _QuizEditorModalState extends State<_QuizEditorModal> {
  final List<_QuestionData> _questions = [_QuestionData()];
  int _scoreRequired = 1;
  bool _isSubmitting = false;
  bool _isLoading = true;
  bool _hasExistingQuiz = false;

  @override
  void initState() {
    super.initState();
    if (widget.shouldLoadExisting) {
      _loadExistingQuiz();
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadExistingQuiz() async {
    try {
      final res = await widget.authService.getQuiz();

      if (res.statusCode == 200) {
        final quizData = jsonDecode(res.body) as Map<String, dynamic>;
        _questions.clear();

        for (var q in quizData['questions'] as List<dynamic>) {
          final question = _QuestionData();
          question.questionText = q['questionText'] as String;
          question.questionController.text = question.questionText;
          question.correctOptionIndex = q['correctOptionIndex'] as int;

          // Clear default options before adding loaded ones
          question.options.clear();
          for (var controller in question.optionControllers) {
            controller.dispose();
          }
          question.optionControllers.clear();

          for (var opt in q['options'] as List<dynamic>) {
            final optText = opt['text'] as String;
            question.options.add(optText);
            question.optionControllers.add(
              TextEditingController(text: optText),
            );
          }
          _questions.add(question);
        }

        setState(() {
          _hasExistingQuiz = true;
          _scoreRequired = quizData['scoreRequired'] as int;
          _isLoading = false;
        });
      } else {
        setState(() {
          _hasExistingQuiz = false;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _hasExistingQuiz = false;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    for (var question in _questions) {
      question.dispose();
    }
    super.dispose();
  }

  void _addQuestion() {
    if (_questions.length < 10) {
      setState(() {
        _questions.add(_QuestionData());
        // Adjust required score if needed
        if (_scoreRequired > _questions.length) {
          _scoreRequired = _questions.length;
        }
      });
    }
  }

  void _removeQuestion(int index) {
    if (_questions.length > 1) {
      setState(() {
        _questions[index].dispose();
        _questions.removeAt(index);
        // Adjust required score if needed
        if (_scoreRequired > _questions.length) {
          _scoreRequired = _questions.length;
        }
      });
    }
  }

  Future<void> _saveQuiz() async {
    // Validation
    if (_questions.isEmpty) {
      _showSnack('Tilføj mindst ét spørgsmål', success: false);
      return;
    }

    for (var i = 0; i < _questions.length; i++) {
      final q = _questions[i];
      if (q.questionText.trim().isEmpty) {
        _showSnack(
          'Spørgsmål ${i + 1}: Udfyld spørgsmålsteksten',
          success: false,
        );
        return;
      }
      if (q.options.length < 2) {
        _showSnack(
          'Spørgsmål ${i + 1}: Tilføj mindst 2 svarmuligheder',
          success: false,
        );
        return;
      }
      for (var j = 0; j < q.options.length; j++) {
        if (q.options[j].trim().isEmpty) {
          _showSnack(
            'Spørgsmål ${i + 1}: Udfyld alle svarmuligheder',
            success: false,
          );
          return;
        }
      }
      if (q.correctOptionIndex < 0 ||
          q.correctOptionIndex >= q.options.length) {
        _showSnack('Spørgsmål ${i + 1}: Vælg korrekt svar', success: false);
        return;
      }
    }

    // Validate required score
    if (_scoreRequired < 1 || _scoreRequired > _questions.length) {
      _showSnack(
        'Krævet antal rigtige svar skal være mellem 1 og ${_questions.length}',
        success: false,
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final quizData = <String, dynamic>{
        'scoreRequired': _scoreRequired,
        'questions': _questions
            .map(
              (q) => <String, dynamic>{
                'questionText': q.questionText,
                'type': 0,
                'options': q.options
                    .map((opt) => <String, dynamic>{'text': opt})
                    .toList(),
                'correctOptionIndex': q.correctOptionIndex,
                'score': q.score,
              },
            )
            .toList(),
      };

      final res = await widget.authService.editQuiz(quizData);

      if (mounted) {
        if (res.statusCode == 200 || res.statusCode == 204) {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _hasExistingQuiz ? '✅ Quiz opdateret!' : '✅ Quiz oprettet!',
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        } else {
          setState(() => _isSubmitting = false);
          _showSnack('Fejl: ${res.statusCode}', success: false);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        _showSnack('Fejl: $e', success: false);
      }
    }
  }

  void _showSnack(String msg, {bool success = true}) =>
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: success ? Colors.green : Colors.red,
          duration: Duration(seconds: success ? 2 : 5),
          behavior: SnackBarBehavior.floating,
        ),
      );

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.deepPurple,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.quiz, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _hasExistingQuiz ? 'Rediger Quiz' : 'Lav Quiz',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            // Content
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(color: Colors.deepPurple),
                          SizedBox(height: 16),
                          Text('Henter quiz data...'),
                        ],
                      ),
                    )
                  : ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.all(16),
                      children: [
                        // Score Required
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.check_circle_outline,
                                      color: Colors.deepPurple,
                                    ),
                                    const SizedBox(width: 8),
                                    const Expanded(
                                      child: Text(
                                        'Antal Rigtige Svar Krævet',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Brugeren skal have mindst dette antal rigtige svar:',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Center(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.deepPurple.shade50,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.deepPurple.shade200,
                                        width: 2,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(
                                            Icons.remove_circle_outline,
                                          ),
                                          color: _scoreRequired > 1
                                              ? Colors.deepPurple
                                              : Colors.grey,
                                          iconSize: 32,
                                          onPressed: _scoreRequired > 1
                                              ? () => setState(
                                                  () => _scoreRequired--,
                                                )
                                              : null,
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 24,
                                            vertical: 12,
                                          ),
                                          child: Column(
                                            children: [
                                              Text(
                                                '$_scoreRequired',
                                                style: const TextStyle(
                                                  fontSize: 36,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.deepPurple,
                                                ),
                                              ),
                                              Text(
                                                'ud af ${_questions.length}',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.add_circle_outline,
                                          ),
                                          color:
                                              _scoreRequired < _questions.length
                                              ? Colors.deepPurple
                                              : Colors.grey,
                                          iconSize: 32,
                                          onPressed:
                                              _scoreRequired < _questions.length
                                              ? () => setState(
                                                  () => _scoreRequired++,
                                                )
                                              : null,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Questions
                        ...List.generate(_questions.length, (index) {
                          return _QuestionCard(
                            questionNumber: index + 1,
                            questionData: _questions[index],
                            onRemove: _questions.length > 1
                                ? () => _removeQuestion(index)
                                : null,
                            onChanged: () => setState(() {}),
                          );
                        }),
                        // Add Question Button
                        if (_questions.length < 10)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.add),
                              label: Text(
                                'Tilføj Spørgsmål (${_questions.length}/10)',
                              ),
                              onPressed: _addQuestion,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.deepPurple,
                                padding: const EdgeInsets.all(16),
                              ),
                            ),
                          ),
                      ],
                    ),
            ),
            // Save Button
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _saveQuiz,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(16),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          _hasExistingQuiz ? 'Gem Ændringer' : 'Gem Quiz',
                          style: const TextStyle(fontSize: 16),
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

class _QuestionData {
  String questionText = '';
  List<String> options = ['', ''];
  int correctOptionIndex = 0;
  final int score = 1; // Fixed at 1 point per question

  late final TextEditingController questionController;
  late final List<TextEditingController> optionControllers;

  _QuestionData() {
    questionController = TextEditingController(text: questionText);
    optionControllers = options
        .map((opt) => TextEditingController(text: opt))
        .toList();
  }

  void dispose() {
    questionController.dispose();
    for (var controller in optionControllers) {
      controller.dispose();
    }
  }
}

class _QuestionCard extends StatelessWidget {
  final int questionNumber;
  final _QuestionData questionData;
  final VoidCallback? onRemove;
  final VoidCallback onChanged;

  const _QuestionCard({
    required this.questionNumber,
    required this.questionData,
    this.onRemove,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Spørgsmål $questionNumber',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (onRemove != null)
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: onRemove,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            // Question Text
            TextField(
              controller: questionData.questionController,
              decoration: const InputDecoration(
                labelText: 'Spørgsmål',
                border: OutlineInputBorder(),
              ),
              onChanged: (val) {
                questionData.questionText = val;
                onChanged();
              },
            ),
            const SizedBox(height: 12),
            // Options
            const Text(
              'Svarmuligheder:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...List.generate(questionData.options.length, (index) {
              final isSelected = questionData.correctOptionIndex == index;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Radio<int>(
                      value: index,
                      toggleable: false,
                      groupValue: questionData.correctOptionIndex,
                      onChanged: (val) {
                        if (val != null) {
                          questionData.correctOptionIndex = val;
                          onChanged();
                        }
                      },
                    ),
                    Expanded(
                      child: TextField(
                        controller: questionData.optionControllers[index],
                        decoration: InputDecoration(
                          labelText: 'Mulighed ${index + 1}',
                          border: const OutlineInputBorder(),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                        ),
                        onChanged: (val) {
                          questionData.options[index] = val;
                          onChanged();
                        },
                      ),
                    ),
                    if (questionData.options.length > 2)
                      IconButton(
                        icon: const Icon(
                          Icons.remove_circle,
                          color: Colors.red,
                        ),
                        onPressed: () {
                          questionData.options.removeAt(index);
                          questionData.optionControllers[index].dispose();
                          questionData.optionControllers.removeAt(index);
                          if (questionData.correctOptionIndex >=
                              questionData.options.length) {
                            questionData.correctOptionIndex =
                                questionData.options.length - 1;
                          }
                          onChanged();
                        },
                      ),
                  ],
                ),
              );
            }),
            if (questionData.options.length < 5)
              TextButton.icon(
                icon: const Icon(Icons.add),
                label: Text(
                  'Tilføj Mulighed (${questionData.options.length}/5)',
                ),
                onPressed: () {
                  questionData.options.add('');
                  questionData.optionControllers.add(TextEditingController());
                  onChanged();
                },
              ),
          ],
        ),
      ),
    );
  }
}
