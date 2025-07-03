import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';

class DeleteAccountDialog extends StatefulWidget {
  final String title;
  final String message;
  final List<String> itemsToDelete;

  const DeleteAccountDialog({
    super.key,
    required this.title,
    required this.message,
    required this.itemsToDelete,
  });

  @override
  State<DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<DeleteAccountDialog> {
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(Icons.warning_rounded, color: colorScheme.error, size: 24),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              widget.title,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.message, style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 12),
          Text(
            'Esta acción eliminará permanentemente:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurface.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 8),
          ...widget.itemsToDelete.map(
            (item) => Padding(
              padding: const EdgeInsets.only(left: 8, bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '• ',
                    style: TextStyle(fontSize: 13, color: colorScheme.error),
                  ),
                  Expanded(
                    child: Text(
                      item,
                      style: TextStyle(fontSize: 13, color: colorScheme.error),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Esta acción no se puede deshacer.',
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.error,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Para confirmar, ingresa tu contraseña:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurface.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              hintText: 'Contraseña',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility : Icons.visibility_off,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _deleteAccount,
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.error,
            foregroundColor: colorScheme.onError,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child:
              _isLoading
                  ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                  : const Text('Eliminar'),
        ),
      ],
    );
  }

  Future<void> _deleteAccount() async {
    if (_passwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor ingresa tu contraseña'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = context.read<AuthProvider>();

      // Eliminar cuenta con reautenticación
      await authProvider.deleteAccountWithReauth(
        _passwordController.text.trim(),
      );

      // Cerrar el diálogo
      if (mounted) {
        Navigator.pop(context);
      }

      // Mostrar mensaje de éxito y navegar al login
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cuenta eliminada exitosamente'),
            backgroundColor: Colors.green[600],
          ),
        );
        context.go('/');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      String errorMessage = 'Error al eliminar cuenta';

      if (e.toString().contains('wrong-password')) {
        errorMessage = 'Contraseña incorrecta';
      } else if (e.toString().contains('user-mismatch')) {
        errorMessage = 'Error de autenticación';
      } else if (e.toString().contains('requires-recent-login')) {
        errorMessage = 'Sesión expirada, inicia sesión nuevamente';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red[600],
          ),
        );
      }
    }
  }
}
