import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider extends ChangeNotifier {
  static const String _languageKey = 'language_code';

  Locale _locale = const Locale('es', 'ES');

  Locale get locale => _locale;

  String get currentLanguageCode => _locale.languageCode;

  final Map<String, Locale> supportedLocales = {
    'Español': const Locale('es', 'ES'),
    'English': const Locale('en', 'US'),
    'Português': const Locale('pt', 'BR'),
  };

  final Map<String, String> languageNames = {
    'es': 'Español',
    'en': 'English',
    'pt': 'Português',
  };

  LanguageProvider() {
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final languageCode = prefs.getString(_languageKey) ?? 'es';
      _locale = Locale(languageCode);
      notifyListeners();
    } catch (e) {
      // Si hay error, mantener español por defecto
      _locale = const Locale('es', 'ES');
    }
  }

  Future<void> setLanguage(String languageCode) async {
    _locale = Locale(languageCode);
    await _saveLanguage(languageCode);
    notifyListeners();
  }

  Future<void> _saveLanguage(String languageCode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_languageKey, languageCode);
    } catch (e) {
      // Manejar error de guardado
    }
  }

  String getTranslatedText(String key) {
    final translations = _getTranslations();
    return translations[key] ?? key;
  }

  Map<String, String> _getTranslations() {
    switch (_locale.languageCode) {
      case 'en':
        return _englishTranslations;
      case 'pt':
        return _portugueseTranslations;
      default:
        return _spanishTranslations;
    }
  }

  static const Map<String, String> _spanishTranslations = {
    'configuracion': 'Configuración',
    'perfil': 'Perfil',
    'preferencias': 'Preferencias',
    'aplicacion': 'Aplicación',
    'soporte': 'Soporte',
    'cuenta': 'Cuenta',
    'modo_oscuro': 'Modo Oscuro',
    'idioma': 'Idioma',
    'notificaciones': 'Notificaciones',
    'editar_perfil': 'Editar Perfil',
    'cerrar_sesion': 'Cerrar Sesión',
    'acerca_de': 'Acerca de',
    'version': 'Versión',
    'politica_privacidad': 'Política de Privacidad',
    'terminos_servicio': 'Términos de Servicio',
    'contacto': 'Contacto',
    'ayuda': 'Ayuda',
    'eliminar_cuenta': 'Eliminar Cuenta',
    'guardar': 'Guardar',
    'cancelar': 'Cancelar',
    'correo_electronico': 'Correo Electrónico',
    'nombre': 'Nombre',
    'especialidad': 'Especialidad',
    'telefono': 'Teléfono',
    'direccion': 'Dirección',
    'cambios_guardados': 'Cambios guardados exitosamente',
    'error_guardar': 'Error al guardar los cambios',
    'confirmar_eliminacion': '¿Estás seguro de que quieres eliminar tu cuenta?',
    'esta_accion_no_se_puede_desacer': 'Esta acción no se puede deshacer.',
    'eliminar': 'Eliminar',
    'chat': 'Chat',
    'mensajes': 'Mensajes',
    'escribir_mensaje': 'Escribir mensaje...',
    'enviar': 'Enviar',
    'tecnico': 'Técnico',
    'cliente': 'Cliente',
    'disponible': 'Disponible',
    'ocupado': 'Ocupado',
    'calificacion': 'Calificación',
    'experiencia': 'Experiencia',
    'trabajos_completados': 'Trabajos completados',
    'rango_precios': 'Rango de precios',
    'estado': 'Estado',
    'ver_perfil': 'Ver perfil',
    'llamar': 'Llamar',
    'chatear': 'Chatear',
    'contratar': 'Contratar',
    'cerrar': 'Cerrar',
    'contactar': 'Contactar',
    'tecnicos_destacados': 'Técnicos Destacados',
    'ver_todos': 'Ver todos',
    'categorias': 'Categorías',
    'buscar_tecnicos': 'Buscar técnicos...',
    'servicios_recientes': 'Servicios Recientes',
    'solicitar_servicio': 'Solicitar servicio',
    'inicio': 'Inicio',
    'historial': 'Historial',
    'perfil_trabajador': 'Perfil del trabajador',
    'editar_perfil_trabajador': 'Editar perfil',
    'ver_historial_trabajos': 'Ver historial de trabajos',
    'historial_trabajos': 'Historial de trabajos',
    'trabajos': 'Trabajos',
    'rating': 'Rating',
    'manos_expertas': 'ChambaPE',
    'tecnicos_disponibles': 'técnicos disponibles',
    'no_se_encontraron_tecnicos': 'No se encontraron técnicos',
    'intenta_cambiar_filtros': 'Intenta cambiar los filtros o la búsqueda',
    'simulando_llamada': 'Simulando llamada a',
    'chat_simulado_desarrollo': 'Chat simulado en desarrollo',
    'contratar_tecnico': 'Contratar Técnico',
    'deseas_contratar': '¿Deseas contratar a',
    'para_un_trabajo': 'para un trabajo?',
    'solicitud_enviada_exitosamente': 'Solicitud enviada exitosamente',
    'contactando_a': 'Contactando a',
    'funcionalidad_imagenes_proximamente':
        'Funcionalidad de imágenes próximamente disponible',
    'error_seleccionar_imagen': 'Error al seleccionar imagen',
  };

  static const Map<String, String> _englishTranslations = {
    'configuracion': 'Settings',
    'perfil': 'Profile',
    'preferencias': 'Preferences',
    'aplicacion': 'Application',
    'soporte': 'Support',
    'cuenta': 'Account',
    'modo_oscuro': 'Dark Mode',
    'idioma': 'Language',
    'notificaciones': 'Notifications',
    'editar_perfil': 'Edit Profile',
    'cerrar_sesion': 'Sign Out',
    'acerca_de': 'About',
    'version': 'Version',
    'politica_privacidad': 'Privacy Policy',
    'terminos_servicio': 'Terms of Service',
    'contacto': 'Contact',
    'ayuda': 'Help',
    'eliminar_cuenta': 'Delete Account',
    'guardar': 'Save',
    'cancelar': 'Cancel',
    'correo_electronico': 'Email',
    'nombre': 'Name',
    'especialidad': 'Specialty',
    'telefono': 'Phone',
    'direccion': 'Address',
    'cambios_guardados': 'Changes saved successfully',
    'error_guardar': 'Error saving changes',
    'confirmar_eliminacion': 'Are you sure you want to delete your account?',
    'esta_accion_no_se_puede_desacer': 'This action cannot be undone.',
    'eliminar': 'Delete',
    'chat': 'Chat',
    'mensajes': 'Messages',
    'escribir_mensaje': 'Write a message...',
    'enviar': 'Send',
    'tecnico': 'Technician',
    'cliente': 'Client',
    'disponible': 'Available',
    'ocupado': 'Busy',
    'calificacion': 'Rating',
    'experiencia': 'Experience',
    'trabajos_completados': 'Completed jobs',
    'rango_precios': 'Price range',
    'estado': 'Status',
    'ver_perfil': 'View profile',
    'llamar': 'Call',
    'chatear': 'Chat',
    'contratar': 'Hire',
    'cerrar': 'Close',
    'contactar': 'Contact',
    'tecnicos_destacados': 'Featured Technicians',
    'ver_todos': 'View all',
    'categorias': 'Categories',
    'buscar_tecnicos': 'Search technicians...',
    'servicios_recientes': 'Recent Services',
    'solicitar_servicio': 'Request service',
    'inicio': 'Home',
    'historial': 'History',
    'perfil_trabajador': 'Worker Profile',
    'editar_perfil_trabajador': 'Edit profile',
    'ver_historial_trabajos': 'View work history',
    'historial_trabajos': 'Work History',
    'trabajos': 'Jobs',
    'rating': 'Rating',
    'manos_expertas': 'ChambaPE',
    'tecnicos_disponibles': 'technicians available',
    'no_se_encontraron_tecnicos': 'No technicians found',
    'intenta_cambiar_filtros': 'Try changing filters or search',
    'simulando_llamada': 'Simulating call to',
    'chat_simulado_desarrollo': 'Chat simulation in development',
    'contratar_tecnico': 'Hire Technician',
    'deseas_contratar': 'Do you want to hire',
    'para_un_trabajo': 'for a job?',
    'solicitud_enviada_exitosamente': 'Request sent successfully',
    'contactando_a': 'Contacting',
    'funcionalidad_imagenes_proximamente': 'Image functionality coming soon',
    'error_seleccionar_imagen': 'Error selecting image',
  };

  static const Map<String, String> _portugueseTranslations = {
    'configuracion': 'Configurações',
    'perfil': 'Perfil',
    'preferencias': 'Preferências',
    'aplicacion': 'Aplicação',
    'soporte': 'Suporte',
    'cuenta': 'Conta',
    'modo_oscuro': 'Modo Escuro',
    'idioma': 'Idioma',
    'notificaciones': 'Notificações',
    'editar_perfil': 'Editar Perfil',
    'cerrar_sesion': 'Sair',
    'acerca_de': 'Sobre',
    'version': 'Versão',
    'politica_privacidad': 'Política de Privacidade',
    'terminos_servicio': 'Termos de Serviço',
    'contacto': 'Contato',
    'ayuda': 'Ajuda',
    'eliminar_cuenta': 'Excluir Conta',
    'guardar': 'Salvar',
    'cancelar': 'Cancelar',
    'correo_electronico': 'E-mail',
    'nombre': 'Nome',
    'especialidad': 'Especialidade',
    'telefono': 'Telefone',
    'direccion': 'Endereço',
    'cambios_guardados': 'Alterações salvas com sucesso',
    'error_guardar': 'Erro ao salvar alterações',
    'confirmar_eliminacion': 'Tem certeza de que deseja excluir sua conta?',
    'esta_accion_no_se_puede_desacer': 'Esta ação não pode ser desfeita.',
    'eliminar': 'Excluir',
    'chat': 'Chat',
    'mensajes': 'Mensagens',
    'escribir_mensaje': 'Escrever mensagem...',
    'enviar': 'Enviar',
    'tecnico': 'Técnico',
    'cliente': 'Cliente',
    'disponible': 'Disponível',
    'ocupado': 'Ocupado',
    'calificacion': 'Avaliação',
    'experiencia': 'Experiência',
    'trabajos_completados': 'Trabalhos concluídos',
    'rango_precios': 'Faixa de preços',
    'estado': 'Status',
    'ver_perfil': 'Ver perfil',
    'llamar': 'Ligar',
    'chatear': 'Conversar',
    'contratar': 'Contratar',
    'cerrar': 'Fechar',
    'contactar': 'Contatar',
    'tecnicos_destacados': 'Técnicos em Destaque',
    'ver_todos': 'Ver todos',
    'categorias': 'Categorias',
    'buscar_tecnicos': 'Buscar técnicos...',
    'servicios_recientes': 'Serviços Recentes',
    'solicitar_servicio': 'Solicitar serviço',
    'inicio': 'Início',
    'historial': 'Histórico',
    'perfil_trabajador': 'Perfil do Trabalhador',
    'editar_perfil_trabajador': 'Editar perfil',
    'ver_historial_trabajos': 'Ver histórico de trabalhos',
    'historial_trabajos': 'Histórico de Trabalhos',
    'trabajos': 'Trabalhos',
    'rating': 'Avaliação',
    'manos_expertas': 'ChambaPE',
    'tecnicos_disponibles': 'técnicos disponíveis',
    'no_se_encontraron_tecnicos': 'Nenhum técnico encontrado',
    'intenta_cambiar_filtros': 'Tente alterar filtros ou pesquisa',
    'simulando_llamada': 'Simulando chamada para',
    'chat_simulado_desarrollo': 'Simulação de chat em desenvolvimento',
    'contratar_tecnico': 'Contratar Técnico',
    'deseas_contratar': 'Deseja contratar',
    'para_un_trabajo': 'para um trabalho?',
    'solicitud_enviada_exitosamente': 'Solicitação enviada com sucesso',
    'contactando_a': 'Contatando',
    'funcionalidad_imagenes_proximamente': 'Funcionalidade de imagens em breve',
    'error_seleccionar_imagen': 'Erro ao selecionar imagem',
  };
}
