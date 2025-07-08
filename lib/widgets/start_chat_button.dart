import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../providers/chat_provider.dart';

class StartChatButton extends StatefulWidget {
  final String workerId;
  final String workerName;
  final String? serviceType;

  const StartChatButton({
    super.key,
    required this.workerId,
    required this.workerName,
    this.serviceType,
  });

  @override
  State<StartChatButton> createState() => _StartChatButtonState();
}

class _StartChatButtonState extends State<StartChatButton> {
  bool _isLoading = false;

  Future<void> _startConversation() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      final currentUser = authProvider.currentUser;

      if (currentUser == null) {
        throw Exception('Usuario no autenticado');
      }

      // Crear o obtener conversación existente
      final conversationId = await chatProvider.createConversation(
        clientId: currentUser.uid,
        workerId: widget.workerId,
        clientName:
            currentUser.email
                .split('@')
                .first, // Usar email como nombre temporal
        workerName: widget.workerName,
      );

      // Navegar al chat
      if (mounted) {
        context.go(
          '/chatDetail',
          extra: {
            'conversationId': conversationId,
            'otherUserName': widget.workerName,
            'otherUserId': widget.workerId,
          },
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al iniciar conversación: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: _isLoading ? null : _startConversation,
      style: ElevatedButton.styleFrom(
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child:
          _isLoading
              ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
              : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.chat_bubble_outline, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    widget.serviceType != null
                        ? 'Solicitar ${widget.serviceType}'
                        : 'Iniciar chat',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
    );
  }
}
