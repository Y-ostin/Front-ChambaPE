import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../models/chat_message.dart';
import '../providers/language_provider.dart';

class ChatInputWidget extends StatefulWidget {
  final Function(String message) onSendMessage;
  final Function(String imageUrl)? onSendImage;
  final String conversationId;
  final String currentUserId;
  final Function(bool isTyping)? onTypingChanged;

  const ChatInputWidget({
    super.key,
    required this.onSendMessage,
    this.onSendImage,
    required this.conversationId,
    required this.currentUserId,
    this.onTypingChanged,
  });

  @override
  State<ChatInputWidget> createState() => _ChatInputWidgetState();
}

class _ChatInputWidgetState extends State<ChatInputWidget> {
  final TextEditingController _messageController = TextEditingController();
  bool _isComposing = false;
  bool _isAttaching = false;

  @override
  void initState() {
    super.initState();
    _messageController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final isComposing = _messageController.text.isNotEmpty;
    if (isComposing != _isComposing) {
      setState(() {
        _isComposing = isComposing;
      });
      widget.onTypingChanged?.call(isComposing);
    }
  }

  void _handleSubmitted(String text) {
    if (text.trim().isEmpty) return;

    widget.onSendMessage(text.trim());
    _messageController.clear();
    widget.onTypingChanged?.call(false);
  }

  Future<void> _pickImage() async {
    if (_isAttaching) return;

    setState(() {
      _isAttaching = true;
    });

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.path != null) {
          // Aquí podrías implementar la lógica para subir la imagen
          // Por ahora, solo mostramos un mensaje de placeholder
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                Provider.of<LanguageProvider>(
                  context,
                  listen: false,
                ).getTranslatedText('funcionalidad_imagenes_proximamente'),
              ),
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${Provider.of<LanguageProvider>(context, listen: false).getTranslatedText('error_seleccionar_imagen')}: $e',
          ),
        ),
      );
    } finally {
      setState(() {
        _isAttaching = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, -2),
            blurRadius: 4,
            color: Colors.black.withOpacity(0.1),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Botón de adjuntar
            IconButton(
              onPressed: _isAttaching ? null : _pickImage,
              icon:
                  _isAttaching
                      ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : const Icon(Icons.attach_file),
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(width: 8),
            // Campo de texto
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: TextField(
                  controller: _messageController,
                  onSubmitted: _handleSubmitted,
                  decoration: InputDecoration(
                    hintText: languageProvider.getTranslatedText(
                      'escribir_mensaje',
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  maxLines: null,
                  textCapitalization: TextCapitalization.sentences,
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Botón de enviar
            Container(
              decoration: BoxDecoration(
                color:
                    _isComposing
                        ? Theme.of(context).primaryColor
                        : Colors.grey[300],
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed:
                    _isComposing
                        ? () => _handleSubmitted(_messageController.text)
                        : null,
                icon: const Icon(Icons.send),
                color: _isComposing ? Colors.white : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
