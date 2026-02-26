import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/chat_model.dart';
import '../services/auth_service.dart';
import '../services/chat_service.dart';

class ChatPage extends StatefulWidget {
  final String participantId;
  final String? chatRoomId;
  final String otherUserName;

  const ChatPage({
    super.key,
    required this.participantId,
    this.chatRoomId,
    required this.otherUserName,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  late Timer _refreshTimer;
  static final _authService = AuthService();

  List<ChatMessage> _messages = [];
  String? _nextCursor;
  bool _hasMore = true;
  bool _isLoadingMessages = true;
  bool _isLoadingMore = false;
  bool _isSendingMessage = false;
  String? _errorMessage;
  String? _currentUserId;
  String? _actualChatRoomId;
  int _lastLoadMoreMs = 0;

  @override
  void initState() {
    super.initState();
    _loadCurrentUserId();
    _initializeChat();
    _scrollController.addListener(_onScroll);
    // Auto-refresh messages every 1 second
    _refreshTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_actualChatRoomId != null && !_isSendingMessage) {
        _loadMessagesQuietly();
      }
    });
  }

  // Initialize chat by getting room from list
  Future<void> _initializeChat() async {
    try {
      final chatRoom = await ChatService.getChatRoomForUser(widget.otherUserName);
      
      if (!mounted) return;
      
      setState(() {
        _actualChatRoomId = chatRoom.id;
      });
      
      // Remove notifications for this chat room
      await ChatService.removeNotifications(chatRoom.id);
      
      await _loadMessages();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _isLoadingMessages = false;
      });
    }
  }

  @override
  void dispose() {
    _refreshTimer.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // Get current user ID from token
  Future<void> _loadCurrentUserId() async {
    try {
      final token = await _authService.getValidJwtToken();
      if (token != null) {
        final parts = token.split('.');
        if (parts.length == 3) {
          final payload = parts[1];
          final normalized = base64Url.normalize(payload);
          final decoded = utf8.decode(base64Url.decode(normalized));
          final json = jsonDecode(decoded);
          if (mounted) {
            setState(() {
              _currentUserId = json['sub'] as String?;
            });
          }
          //print('DEBUG loaded current user ID: $_currentUserId');
        }
      }
    } catch (e) {
      //print('Error loading current user ID: $e');
    }
  }

  // Load initial messages
  Future<void> _loadMessages() async {
    if (_actualChatRoomId == null) return;
    
    setState(() {
      _isLoadingMessages = true;
      _errorMessage = null;
    });

    try {
      final response = await ChatService.getMessages(_actualChatRoomId!, null);

      if (!mounted) return;

      setState(() {
        _messages = response.messageObjects.reversed.toList();
        _nextCursor = response.nextCursor;
        _hasMore = response.hasMore;
        _isLoadingMessages = false;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _isLoadingMessages = false;
      });
    }
  }

  // Load messages silently (without showing loading indicator)
  Future<void> _loadMessagesQuietly() async {
    if (_actualChatRoomId == null) return;

    try {
      final response = await ChatService.getMessages(_actualChatRoomId!, null);

      if (!mounted) return;

      final latestPage = response.messageObjects.reversed.toList();
      final hasLoadedOlder = _messages.length > latestPage.length;

      // Only update if messages changed
      if (latestPage.length != _messages.length) {
        final existingIds = _messages.map((m) => m.id).toSet();
        final newMessages = latestPage.where((m) => !existingIds.contains(m.id));

        setState(() {
          _messages = [
            ..._messages,
            ...newMessages,
          ];
          if (!hasLoadedOlder) {
            _nextCursor = response.nextCursor;
            _hasMore = response.hasMore;
          }
          _errorMessage = null;
        });
      }
    } catch (e) {
      // Silently fail for auto-refresh
      //print('Error auto-loading messages: $e');
    }
  }

  // Load more messages when scrolling up
  void _onScroll() {
    if (!_scrollController.hasClients) {
      return;
    }

    if (!_hasMore || _isLoadingMore || _nextCursor == null) {
      return;
    }

    final nowMs = DateTime.now().millisecondsSinceEpoch;
    if (nowMs - _lastLoadMoreMs < 400) {
      return;
    }

    final position = _scrollController.position;
    if (position.pixels <= position.minScrollExtent + 200) {
      _lastLoadMoreMs = nowMs;
      _loadMoreMessages();
    }
  }

  // Load additional messages
  Future<void> _loadMoreMessages() async {
    if (_isLoadingMore || !_hasMore || _nextCursor == null) return;

    final previousMaxExtent = _scrollController.hasClients
        ? _scrollController.position.maxScrollExtent
        : null;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final response = await ChatService.getMessages(_actualChatRoomId!, _nextCursor);

      if (!mounted) return;

      setState(() {
        _messages = [
          ...response.messageObjects.reversed.toList(),
          ..._messages
        ];
        _nextCursor = response.nextCursor;
        _hasMore = response.hasMore;
        _isLoadingMore = false;
      });

      if (_scrollController.hasClients && previousMaxExtent != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!_scrollController.hasClients) return;
          final newMax = _scrollController.position.maxScrollExtent;
          final delta = newMax - previousMaxExtent;
          if (delta > 0) {
            _scrollController.jumpTo(
              _scrollController.position.pixels + delta,
            );
          }
        });
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoadingMore = false;
        _errorMessage = e.toString();
      });
    }
  }

  // Send a new message
  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();

    if(content.isEmpty) return;

    _messageController.clear();

    setState(() {
      _isSendingMessage = true;
    });

    try {
      await ChatService.sendMessage(_actualChatRoomId!, content);

      if (!mounted) return;

      setState(() {
        _isSendingMessage = false;
      });

      // Reload messages to show the newly sent message
      _loadMessages();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSendingMessage = false;
        _errorMessage = e.toString();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fejl ved afsendelse: $e')),
      );
    }
  }

  /// Delete a message
  Future<void> _deleteMessage(int messageId) async {
    try {
      await ChatService.deleteMessage(messageId);

      if (!mounted) return;

      setState(() {
        _messages.removeWhere((m) => m.id == messageId);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Besked slettet')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fejl ved sletning: $e')),
      );
    }
  }

  // Scroll to bottom of message list
  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? const Color(0xFF121212) : const Color(0xFFF5F5F5);
    final textColor = isDarkMode ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          widget.otherUserName,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.purple,
        elevation: 0,
        centerTitle: false,
      ),
      body: Column(
        children: [
          Expanded(
            child: _buildMessageList(isDarkMode, textColor),
          ),
          _buildMessageInput(isDarkMode),
        ]
      ),
    );
  }

  // Build message list
  Widget _buildMessageList(bool isDarkMode, Color textColor) {
    if (_isLoadingMessages) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red[isDarkMode ? 600 : 400]),
              const SizedBox(height: 16),
              Text(
                'Fejl ved indlæsning af beskeder',
                style: TextStyle(fontSize: 16, color: textColor),
              ),
              const SizedBox(height: 10),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadMessages,
                child: const Text('Prøv igen'),
              ),
            ],
          ),
        ),
      );
    }

    if (_messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Ingen beskeder endnu',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Send en besked for at starte samtalen',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }
  

    return ListView.builder(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      itemCount: _messages.length + (_isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= _messages.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        return _buildMessageBubble(_messages[index], isDarkMode, textColor);
      },
    );
  }

  // Build individual message bubble
  Widget _buildMessageBubble(ChatMessage message, bool isDarkMode, Color textColor) {
    final isCurrentUserMessage = message.sender.id == _currentUserId;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Align(
        alignment: isCurrentUserMessage ? Alignment.centerRight : Alignment.centerLeft,
        child: GestureDetector(
          onLongPress: isCurrentUserMessage
            ? () => _showDeleteDialog(message.id)
            : null,
          child: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isCurrentUserMessage
                ? Colors.purple
                : (isDarkMode ? const Color(0xFF2A2A2A) : Colors.grey[300]),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18),
                topRight: const Radius.circular(18),
                bottomLeft: Radius.circular(isCurrentUserMessage ? 18 : 4),
                bottomRight: Radius.circular(isCurrentUserMessage ? 4 : 18),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message.messageContent,
                  style: TextStyle(
                    color: isCurrentUserMessage ? Colors.white : textColor,
                    fontSize: 15,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _formatTime(message.createdAt),
                  style: TextStyle(
                    fontSize: 11,
                    color: isCurrentUserMessage
                      ? Colors.white.withOpacity(0.7)
                      : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Build message input field
  Widget _buildMessageInput(bool isDarkMode) {
    final inputColor = isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
    final borderColor = isDarkMode ? const Color(0xFF3A3A3A) : Colors.grey[300];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: inputColor,
        border: Border(
          top: BorderSide(
            color: borderColor!,
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: isDarkMode ? const Color(0xFF2A2A2A) : Colors.grey[100],
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Focus(
                  focusNode: _focusNode,
                  onKeyEvent: (node, event) {
                    // Handle Enter for sending, Shift+Enter for new line
                    if (event is KeyDownEvent) {
                      final isShiftPressed = HardwareKeyboard.instance.isShiftPressed;
                      final isEnterPressed = event.logicalKey == LogicalKeyboardKey.enter;
                      
                      // If Enter without Shift, send message
                      if (isEnterPressed && !isShiftPressed) {
                        _sendMessage();
                        return KeyEventResult.handled;
                      }
                      // If Shift+Enter, allow new line (default behavior)
                      if (isEnterPressed && isShiftPressed) {
                        return KeyEventResult.ignored;
                      }
                    }
                    return KeyEventResult.ignored;
                  },
                  child: TextField(
                    controller: _messageController,
                    enabled: !_isSendingMessage,
                    maxLines: null,
                    textCapitalization: TextCapitalization.sentences,
                    style: TextStyle(
                      fontSize: 15,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Skriv en besked...',
                      hintStyle: TextStyle(
                        color: isDarkMode ? Colors.grey[600] : Colors.grey[500],
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 12,
                      ),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.purple,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.purple.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                icon: _isSendingMessage
                  ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                  : const Icon(Icons.send_rounded, color: Colors.white, size: 22),
                onPressed: _isSendingMessage ? null : _sendMessage,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Show delete confirmation dialog
  void _showDeleteDialog(int messageId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Slet besked?'),
        content: const Text('Er du sikker på, du vil slette denne besked?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuller'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteMessage(messageId);
            },
            child: const Text('Slet', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // Format time display
  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (messageDate == today) {
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else {
      return '${dateTime.day}/${dateTime.month}';
    }
  }
}