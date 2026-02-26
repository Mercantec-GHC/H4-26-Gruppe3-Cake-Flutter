class ChatRoom {
  final String id;
  final String name;
  final List<String> participants;

  ChatRoom({
    required this.id,
    required this.name,
    required this.participants
  });

  factory ChatRoom.fromJson(Map<String, dynamic> json) {
    return ChatRoom(
      id: json['id'] as String,
      name: json['name'] as String,
      participants: List<String>.from(json['participants'] as List),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'participants': participants
  };
}

class ChatSender {
  final String id;
  final String firstName;
  final String lastName;

  ChatSender({
    required this.id,
    required this.firstName,
    required this.lastName
  });

  factory ChatSender.fromJson(Map<String, dynamic> json) {
    return ChatSender(
      id: json['id'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String
    );
  }

  String get fullName => '$firstName $lastName';
}

class ChatMessage {
  final int id;
  final DateTime createdAt;
  final ChatSender sender;
  final String messageContent;

  ChatMessage({
    required this.id,
    required this.createdAt,
    required this.sender,
    required this.messageContent
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as int,
      createdAt: DateTime.parse(json['createdAt'] as String),
      sender: ChatSender.fromJson(json['sender'] as Map<String, dynamic>),
      messageContent: json['messageContent'] as String
    );
  }
}

class ChatMessagesResponse {
  final List<ChatMessage> messageObjects;
  final String? nextCursor;
  final bool hasMore;

  ChatMessagesResponse({
    required this.messageObjects,
    required this.nextCursor,
    required this.hasMore
  });

  factory ChatMessagesResponse.fromJson(Map<String, dynamic> json) {
    return ChatMessagesResponse(
      messageObjects: (json['messageObjects'] as List)
          .map((m) => ChatMessage.fromJson(m as Map<String, dynamic>))
          .toList(),
      nextCursor: json['nextCursor'] as String?,
      hasMore: json['hasMore'] as bool,
    );
  }
}