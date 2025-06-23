import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class ChatDetailScreen extends StatefulWidget {
  final String nombre;

  const ChatDetailScreen({super.key, required this.nombre});

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<String> mensajes = [
    'Hola, ¿en qué puedo ayudarte?',
    'Necesito instalar un enchufe',
    'Perfecto, ¿cuándo te viene bien?',
    'Mañana por la tarde estaría bien',
  ];
  final ScrollController _scrollController = ScrollController();

  void enviarMensaje() {
    final texto = _controller.text.trim();
    if (texto.isNotEmpty) {
      setState(() {
        mensajes.add(texto);
        _controller.clear();
      });

      // Scroll hacia abajo automáticamente
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
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
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
            // Navigate based on user role
            if (isWorker) {
              context.go('/workerChats');
            } else {
              context.go('/chats');
            }
          },
        ),
        title: Row(
          children: [
            const CircleAvatar(
              radius: 18,
              backgroundColor: Colors.black,
              child: Icon(Icons.person_outline, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                widget.nombre,
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.black),
            onPressed: () {
              // Aquí puedes agregar opciones adicionales
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                itemCount: mensajes.length,
                itemBuilder: (_, index) {
                  final mensaje = mensajes[index];
                  final isUser = index.isOdd;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Align(
                      alignment:
                          isUser ? Alignment.centerRight : Alignment.centerLeft,
                      child: AnimatedOpacity(
                        opacity: 1.0,
                        duration: const Duration(milliseconds: 300),
                        child: Container(
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.75,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: isUser ? Colors.black : Colors.grey[100],
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            mensaje,
                            style: TextStyle(
                              fontSize: 15,
                              color: isUser ? Colors.white : Colors.black87,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: Colors.grey[200]!, width: 0.5),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: TextField(
                          controller: _controller,
                          textInputAction: TextInputAction.send,
                          maxLines: null,
                          decoration: const InputDecoration(
                            hintText: 'Escribe un mensaje...',
                            hintStyle: TextStyle(color: Colors.grey),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            border: InputBorder.none,
                          ),
                          onSubmitted: (_) => enviarMensaje(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: enviarMensaje,
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: const BoxDecoration(
                          color: Colors.black,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.send_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
