import 'package:flutter/material.dart';
import '../models/chat_model.dart';
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

  List<ChatMessage> _messages = [];
  String? _nextCursor;
  bool _hasMore = true;
  bool _isLoadingMessages = true;
  bool _isLoadingMore = false;
  bool _isSendingMessage = false;
  String? _errorMessage;
  String? _currentUserId;
  String? _actualChatRoomId;

  @override
  void initState() {
    super.initState();
    _loadCurrentUserId();
    _initializeChat();
    _scrollController.addListener(_onScroll);
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
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // Get current user ID from token
  Future<void> _loadCurrentUserId() async {
    // Implementation for getting current user ID if needed
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

      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _isLoadingMessages = false;
      });
    }
  }

  // Load more messages when scrolling up
  void _onScroll() {
    if (_scrollController.position.pixels <= 
      _scrollController.position.maxScrollExtent - 200) {
        if (_hasMore && !_isLoadingMore && _nextCursor != null) {
          _loadMoreMessages();
        }
      }
  }

  // Load additional messages
  Future<void> _loadMoreMessages() async {
    if (_isLoadingMore || !_hasMore || _nextCursor == null) return;

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
    final backgroundColor = isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(widget.otherUserName),
        backgroundColor: Colors.purple,
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
        child: Text(
          'Ingen beskeder endnu',
          style: TextStyle(fontSize: 16, color: textColor),
        ),
      );
    }
  

  return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
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
      child: Column(
        crossAxisAlignment: isCurrentUserMessage ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(
            message.sender.fullName,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[isDarkMode ? 400 : 600],
            ),
          ),
          const SizedBox(height: 4),
          GestureDetector(
            onLongPress: isCurrentUserMessage
              ? () => _showDeleteDialog(message.id)
              : null,
            child: Container(
              margin: EdgeInsets.only(
                right: isCurrentUserMessage ? 0 : 50,
                left: isCurrentUserMessage ? 50 : 0,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isCurrentUserMessage
                  ? Colors.purple
                  : (isDarkMode ? const Color(0xFF2C2C2C) : Colors.grey[200]),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.messageContent,
                    style: TextStyle(
                      color: isCurrentUserMessage ? Colors.white : textColor,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(message.createdAt),
                    style: TextStyle(
                      fontSize: 11,
                      color: isCurrentUserMessage
                        ? Colors.white70
                        : Colors.grey[isDarkMode ? 500 : 400],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Build message input field
  Widget _buildMessageInput(bool isDarkMode) {
    final inputColor = isDarkMode ? const Color(0xFF2C2C2C) : Colors.grey[100];
    final hintColor = isDarkMode ? Colors.grey[600] : Colors.grey[400];

    return Container(
      padding: const EdgeInsets.all(12.0),
      color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              enabled: !_isSendingMessage,
              maxLines: null,
              decoration: InputDecoration(
                hintText: 'Skriv en besked...',
                hintStyle: TextStyle(color: hintColor),
                filled: true,
                fillColor: inputColor,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          FloatingActionButton(
            mini: true,
            backgroundColor: Colors.purple,
            onPressed: _isSendingMessage ? null : _sendMessage,
            child: _isSendingMessage
              ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
              : const Icon(Icons.send, color: Colors.white),
          ),
        ],
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