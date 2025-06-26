import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../models/chat_message.dart';
import '../../widgets/chat_message_widget.dart';
import '../../widgets/chat_input_widget.dart';
import 'dart:async';

class ChatDetailScreen extends StatefulWidget {
  final String conversationId;
  final String otherUserName;
  final String otherUserId;

  const ChatDetailScreen({
    super.key,
    required this.conversationId,
    required this.otherUserName,
    required this.otherUserId,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final ScrollController _scrollController = ScrollController();
  Timer? _typingTimer;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _listenToTypingStatus();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _typingTimer?.cancel();
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    chatProvider.clearTypingStatus(widget.conversationId, _getCurrentUserId());
    super.dispose();
  }

  String _getCurrentUserId() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    return authProvider.currentUser?.uid ?? '';
  }

  void _loadMessages() {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    chatProvider.loadMessages(widget.conversationId, _getCurrentUserId());
  }

  void _listenToTypingStatus() {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    chatProvider.listenToTypingStatus(widget.conversationId);
  }

  void _sendMessage(String message) async {
    if (message.trim().isEmpty) return;

    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.currentUser;

    if (currentUser == null) return;

    try {
      await chatProvider.sendMessage(
        conversationId: widget.conversationId,
        senderId: currentUser.uid,
        receiverId: widget.otherUserId,
        message: message.trim(),
      );

      // Scroll hacia abajo automáticamente
      _scrollToBottom();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al enviar mensaje: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _onTypingChanged(bool isTyping) {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);

    // Cancelar timer anterior si existe
    _typingTimer?.cancel();

    // Actualizar estado de escritura
    chatProvider.updateTypingStatus(
      widget.conversationId,
      _getCurrentUserId(),
      isTyping,
    );

    // Si está escribiendo, programar limpieza del estado
    if (isTyping) {
      _typingTimer = Timer(const Duration(seconds: 3), () {
        chatProvider.updateTypingStatus(
          widget.conversationId,
          _getCurrentUserId(),
          false,
        );
      });
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isWorker = authProvider.currentUser?.role == 'trabajador';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () {
            if (isWorker) {
              context.go('/workerChats');
            } else {
              context.go('/chats');
            }
          },
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.grey[300],
              child: Text(
                widget.otherUserName.substring(0, 1).toUpperCase(),
                style: const TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.otherUserName,
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w600,
                      fontSize: 18,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Consumer<ChatProvider>(
                    builder: (context, chatProvider, child) {
                      final typingStatus = chatProvider.typingStatus;
                      final isOtherUserTyping =
                          typingStatus[widget.otherUserId] == true;

                      return Text(
                        isOtherUserTyping ? 'Escribiendo...' : 'En línea',
                        style: TextStyle(
                          color:
                              isOtherUserTyping
                                  ? Colors.blue
                                  : Colors.grey[600],
                          fontSize: 12,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.black),
            onPressed: () {
              // Opciones adicionales del chat
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Consumer<ChatProvider>(
                builder: (context, chatProvider, child) {
                  final messages = chatProvider.messages;

                  if (chatProvider.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (messages.isEmpty) {
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
                            'No hay mensajes aún',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '¡Inicia la conversación!',
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
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      final isOwnMessage =
                          message.senderId == _getCurrentUserId();

                      return ChatMessageWidget(
                        message: message,
                        isOwnMessage: isOwnMessage,
                        currentUserId: _getCurrentUserId(),
                      );
                    },
                  );
                },
              ),
            ),
            ChatInputWidget(
              onSendMessage: _sendMessage,
              conversationId: widget.conversationId,
              currentUserId: _getCurrentUserId(),
              onTypingChanged: _onTypingChanged,
            ),
          ],
        ),
      ),
    );
  }
}
