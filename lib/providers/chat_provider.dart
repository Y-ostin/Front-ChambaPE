import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat_message.dart';

class ChatProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<ChatConversation> _conversations = [];
  List<ChatMessage> _messages = [];
  bool _isLoading = false;
  String? _currentConversationId;
  Map<String, bool> _typingStatus = {};
  StreamSubscription<QuerySnapshot>? _messagesSubscription;
  StreamSubscription<QuerySnapshot>? _conversationsSubscription;

  List<ChatConversation> get conversations => _conversations;
  List<ChatMessage> get messages => _messages;
  bool get isLoading => _isLoading;
  String? get currentConversationId => _currentConversationId;
  Map<String, bool> get typingStatus => _typingStatus;

  // Obtener conversaciones para un usuario específico
  Future<void> loadConversations(String userId, String userRole) async {
    _isLoading = true;
    notifyListeners();

    try {
      Query query;
      if (userRole == 'trabajador') {
        query = _firestore
            .collection('conversations')
            .where('workerId', isEqualTo: userId)
            .orderBy('lastMessageTime', descending: true);
      } else {
        query = _firestore
            .collection('conversations')
            .where('clientId', isEqualTo: userId)
            .orderBy('lastMessageTime', descending: true);
      }

      _conversationsSubscription?.cancel();
      _conversationsSubscription = query.snapshots().listen((snapshot) {
        _conversations =
            snapshot.docs
                .map((doc) => ChatConversation.fromFirestore(doc))
                .toList();
        notifyListeners();
      });
    } catch (e) {
      print('Error loading conversations: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Cargar mensajes de una conversación específica
  Future<void> loadMessages(String conversationId, String currentUserId) async {
    _currentConversationId = conversationId;
    _messages = [];
    notifyListeners();

    try {
      _messagesSubscription?.cancel();
      _messagesSubscription = _firestore
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .orderBy('timestamp', descending: false)
          .snapshots()
          .listen((snapshot) {
            _messages =
                snapshot.docs
                    .map((doc) => ChatMessage.fromFirestore(doc))
                    .toList();

            // Marcar mensajes como leídos automáticamente
            _markMessagesAsRead(conversationId, currentUserId);

            notifyListeners();
          });
    } catch (e) {
      print('Error loading messages: $e');
    }
  }

  // Enviar mensaje
  Future<void> sendMessage({
    required String conversationId,
    required String senderId,
    required String receiverId,
    required String message,
    MessageType type = MessageType.text,
    String? imageUrl,
  }) async {
    try {
      final chatMessage = ChatMessage(
        id: '', // Se generará automáticamente
        senderId: senderId,
        receiverId: receiverId,
        message: message,
        timestamp: DateTime.now(),
        isRead: false,
        imageUrl: imageUrl,
        type: type,
      );

      // Agregar mensaje a la subcolección
      await _firestore
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .add(chatMessage.toFirestore());

      // Actualizar la conversación con el último mensaje
      await _firestore.collection('conversations').doc(conversationId).update({
        'lastMessage': message,
        'lastMessageTime': Timestamp.now(),
        'unreadCount': FieldValue.increment(1),
      });
    } catch (e) {
      print('Error sending message: $e');
      rethrow;
    }
  }

  // Crear nueva conversación
  Future<String> createConversation({
    required String clientId,
    required String workerId,
    required String clientName,
    required String workerName,
  }) async {
    try {
      // Verificar si ya existe una conversación
      final existingConversation =
          await _firestore
              .collection('conversations')
              .where('clientId', isEqualTo: clientId)
              .where('workerId', isEqualTo: workerId)
              .get();

      if (existingConversation.docs.isNotEmpty) {
        return existingConversation.docs.first.id;
      }

      // Crear nueva conversación
      final conversation = ChatConversation(
        id: '',
        clientId: clientId,
        workerId: workerId,
        clientName: clientName,
        workerName: workerName,
        lastMessageTime: DateTime.now(),
        lastMessage: '',
        unreadCount: 0,
        isActive: true,
      );

      final docRef = await _firestore
          .collection('conversations')
          .add(conversation.toFirestore());

      return docRef.id;
    } catch (e) {
      print('Error creating conversation: $e');
      rethrow;
    }
  }

  // Marcar mensajes como leídos
  Future<void> _markMessagesAsRead(
    String conversationId,
    String currentUserId,
  ) async {
    try {
      final unreadMessages =
          _messages
              .where((msg) => msg.receiverId == currentUserId && !msg.isRead)
              .toList();

      if (unreadMessages.isNotEmpty) {
        final batch = _firestore.batch();

        for (final message in unreadMessages) {
          final messageRef = _firestore
              .collection('conversations')
              .doc(conversationId)
              .collection('messages')
              .doc(message.id);

          batch.update(messageRef, {'isRead': true});
        }

        // Actualizar contador de mensajes no leídos
        final conversationRef = _firestore
            .collection('conversations')
            .doc(conversationId);
        batch.update(conversationRef, {
          'unreadCount': FieldValue.increment(-unreadMessages.length),
        });

        await batch.commit();
      }
    } catch (e) {
      print('Error marking messages as read: $e');
    }
  }

  // Actualizar estado de escritura
  Future<void> updateTypingStatus(
    String conversationId,
    String userId,
    bool isTyping,
  ) async {
    try {
      await _firestore
          .collection('conversations')
          .doc(conversationId)
          .collection('typing')
          .doc(userId)
          .set({'isTyping': isTyping, 'timestamp': Timestamp.now()});
    } catch (e) {
      print('Error updating typing status: $e');
    }
  }

  // Escuchar estado de escritura
  void listenToTypingStatus(String conversationId) {
    _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('typing')
        .snapshots()
        .listen((snapshot) {
          final now = DateTime.now();
          _typingStatus.clear();

          for (final doc in snapshot.docs) {
            final data = doc.data();
            final timestamp = (data['timestamp'] as Timestamp).toDate();

            // Solo considerar como escribiendo si fue en los últimos 5 segundos
            if (now.difference(timestamp).inSeconds < 5) {
              _typingStatus[doc.id] = data['isTyping'] ?? false;
            }
          }

          notifyListeners();
        });
  }

  // Limpiar estado de escritura
  Future<void> clearTypingStatus(String conversationId, String userId) async {
    try {
      await _firestore
          .collection('conversations')
          .doc(conversationId)
          .collection('typing')
          .doc(userId)
          .delete();
    } catch (e) {
      print('Error clearing typing status: $e');
    }
  }

  // Obtener conversación por ID
  ChatConversation? getConversationById(String conversationId) {
    try {
      return _conversations.firstWhere((conv) => conv.id == conversationId);
    } catch (e) {
      return null;
    }
  }

  // Limpiar recursos
  void dispose() {
    _messagesSubscription?.cancel();
    _conversationsSubscription?.cancel();
    super.dispose();
  }

  // Limpiar estado actual
  void clearCurrentChat() {
    _currentConversationId = null;
    _messages = [];
    _typingStatus.clear();
    _messagesSubscription?.cancel();
    notifyListeners();
  }
}
