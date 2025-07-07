# 🔐 Nuevo Módulo de Autenticación - ChambaPE

## 📋 Resumen

Se ha creado un nuevo módulo de autenticación que se conecta directamente con el backend NestJS, incluyendo:

- ✅ **Login mejorado** con validación y conexión al backend
- ✅ **Registro completo** con validación de documentos para trabajadores
- ✅ **Provider NestJS** para comunicación con el backend
- ✅ **Widget de subida de documentos** reutilizable
- ✅ **Configuración de API** centralizada
- ✅ **Rutas actualizadas** con navegación mejorada

## 🚀 Características del Nuevo Módulo

### 🔑 Autenticación
- **Login dual**: Firebase Auth + NestJS (mantiene compatibilidad)
- **Registro diferenciado**: Cliente vs Trabajador
- **Validación en tiempo real** de formularios
- **Indicador de conexión** al servidor
- **Manejo de errores** mejorado

### 📄 Registro de Trabajadores
- **Validación de DNI** (8 dígitos)
- **Subida de documentos obligatorios**:
  - DNI frontal y posterior
  - Certificado del Ministerio de Trabajo
  - Antecedentes penales
- **Certificados adicionales** (opcionales)
- **Pantalla de verificación** post-registro

### 🛠️ Componentes Técnicos
- **NestJSProvider**: Comunicación HTTP con el backend
- **DocumentUploadWidget**: Widget reutilizable para archivos
- **ApiConfig**: Configuración centralizada de endpoints
- **Validaciones**: Reglas de negocio implementadas

## 📁 Archivos Creados/Modificados

### Nuevos Archivos
```
lib/screens/auth/
├── login_screen_new.dart          # Nueva pantalla de login
└── register_screen_new.dart       # Nueva pantalla de registro

lib/widgets/
└── document_upload_widget.dart    # Widget para subir documentos

lib/providers/
└── nestjs_provider.dart           # Provider para NestJS

lib/config/
└── api_config.dart                # Configuración de API
```

### Archivos Modificados
```
lib/main.dart                      # Agregado NestJSProvider
lib/routes/app_router.dart         # Rutas actualizadas
pubspec.yaml                       # Nuevas dependencias
```

## 🧪 Cómo Probar

### 1. Preparar el Backend
```bash
# En el directorio del backend
cd nestjs-boilerplate

# Verificar que el backend esté corriendo
npm run start:dev

# Verificar endpoint de salud
curl http://localhost:3000/api/health
```

### 2. Instalar Dependencias
```bash
# En el directorio del frontend
cd proyecto_integrador5to

# Instalar nuevas dependencias
flutter pub get
```

### 3. Configurar Variables de Entorno
```bash
# Verificar que el backend esté en localhost:3000
# Si usas emulador Android, cambiar en api_config.dart:
# static const String baseUrl = 'http://10.0.2.2:3000/api';
```

### 4. Ejecutar la Aplicación
```bash
flutter run
```

## 🎯 Flujos de Prueba

### 🔐 Login
1. Abrir la app → Pantalla de login
2. Verificar indicador de conexión (debe mostrar "Conectado")
3. Ingresar credenciales válidas
4. Debe redirigir según el rol del usuario

### 📝 Registro de Cliente
1. Ir a "Registrarse"
2. Seleccionar "Cliente"
3. Llenar formulario básico
4. Debe crear cuenta y redirigir al dashboard

### 👷 Registro de Trabajador
1. Ir a "Registrarse"
2. Seleccionar "Trabajador"
3. Llenar formulario básico
4. **Subir documentos obligatorios**:
   - DNI frontal (foto)
   - DNI posterior (foto)
   - Certificado PDF
   - Antecedentes penales
5. Agregar certificados adicionales (opcional)
6. Debe crear cuenta y redirigir a verificación

## 🔧 Configuración del Backend

### Endpoints Requeridos
El backend debe tener estos endpoints funcionando:

```typescript
// Autenticación
POST /api/auth/email/login
POST /api/auth/email/register
POST /api/auth/email/confirm
GET /api/auth/me

// Trabajadores
POST /api/workers/register
GET /api/workers/:id
PATCH /api/workers/:id

// Archivos
POST /api/files/upload

// Salud
GET /api/health
```

### Variables de Entorno
```env
# Backend (.env)
DATABASE_URL=postgresql://...
JWT_SECRET=tu_jwt_secret
JWT_EXPIRES_IN=15m
JWT_REFRESH_EXPIRES_IN=7d
```

## 🐛 Solución de Problemas

### Error de Conexión
```
Error: Error de conexión. Verifica tu internet.
```
**Solución**: Verificar que el backend esté corriendo en `localhost:3000`

### Error de CORS
```
Error: CORS policy
```
**Solución**: Verificar configuración CORS en el backend NestJS

### Error de Subida de Archivos
```
Error: Error al subir archivo
```
**Solución**: Verificar permisos de escritura en el directorio de uploads

### Error de Validación
```
Error: Datos inválidos
```
**Solución**: Verificar que los campos cumplan las validaciones del backend

## 📱 Próximos Pasos

### Funcionalidades Pendientes
- [ ] **Recuperación de contraseña**
- [ ] **Login con Google**
- [ ] **Verificación de email**
- [ ] **Notificaciones push**
- [ ] **Geolocalización**
- [ ] **Sistema de pagos**

### Mejoras Técnicas
- [ ] **Caché de datos** con SharedPreferences
- [ ] **Interceptores HTTP** para refresh token
- [ ] **Validación offline** de formularios
- [ ] **Compresión de imágenes** antes de subir
- [ ] **Progress indicators** para uploads

## 🔗 Enlaces Útiles

- [Documentación NestJS](https://docs.nestjs.com/)
- [Flutter HTTP Package](https://pub.dev/packages/http)
- [Image Picker](https://pub.dev/packages/image_picker)
- [Go Router](https://pub.dev/packages/go_router)

## 📞 Soporte

Si encuentras problemas:

1. Verificar logs del backend: `npm run start:dev`
2. Verificar logs de Flutter: `flutter logs`
3. Verificar conexión: `curl http://localhost:3000/api/health`
4. Revisar configuración CORS en el backend

---

**¡El nuevo módulo de autenticación está listo para usar! 🎉** 