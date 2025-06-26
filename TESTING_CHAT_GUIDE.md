# Guía de Pruebas del Sistema de Chat

## Configuración Inicial

### 1. Crear Cuentas de Prueba

**Cuenta Cliente:**
- Email: `cliente@test.com`
- Contraseña: `123456`
- Rol: `cliente`

**Cuenta Trabajador:**
- Email: `trabajador@test.com`
- Contraseña: `123456`
- Rol: `trabajador`

### 2. Configurar Firebase

1. Ve a [Firebase Console](https://console.firebase.google.com/)
2. Selecciona tu proyecto
3. Ve a **Authentication** → **Users**
4. Verifica que las cuentas estén creadas
5. Ve a **Firestore Database** → **Data**
6. Verifica que exista la colección `users`

## Métodos de Prueba

### Método 1: Dos Dispositivos Físicos

**Dispositivo 1 (Cliente):**
```bash
# Ejecutar en modo release para mejor rendimiento
flutter run --release
```

**Dispositivo 2 (Trabajador):**
```bash
# Ejecutar en modo release
flutter run --release
```

### Método 2: Dispositivo + Emulador

**Emulador (Cliente):**
```bash
# Listar emuladores disponibles
flutter emulators

# Iniciar emulador
flutter emulators --launch <emulator_id>

# Ejecutar app
flutter run
```

**Dispositivo Físico (Trabajador):**
```bash
# Conectar dispositivo y ejecutar
flutter run
```

### Método 3: Dos Emuladores

**Emulador 1 (Cliente):**
```bash
flutter emulators --launch Pixel_4_API_30
flutter run -d emulator-5554
```

**Emulador 2 (Trabajador):**
```bash
flutter emulators --launch Pixel_5_API_30
flutter run -d emulator-5556
```

## Pasos de Prueba

### Paso 1: Autenticación
1. **Dispositivo Cliente:**
   - Abre la app
   - Inicia sesión con `cliente@test.com`
   - Verifica que vaya a la pantalla de cliente

2. **Dispositivo Trabajador:**
   - Abre la app
   - Inicia sesión con `trabajador@test.com`
   - Verifica que vaya a la pantalla de trabajador

### Paso 2: Crear Conversación
1. **Desde el Cliente:**
   - Ve a la pantalla de servicios
   - Busca un trabajador
   - Toca el botón "Iniciar chat" o "Solicitar servicio"
   - Debería crear una conversación y abrir el chat

### Paso 3: Verificar Conversación
1. **En el Cliente:**
   - Ve a "Mis chats" (`/chats`)
   - Debería aparecer la conversación con el trabajador

2. **En el Trabajador:**
   - Ve a "Chats con clientes" (`/workerChats`)
   - Debería aparecer la conversación con el cliente

### Paso 4: Enviar Mensajes
1. **Desde el Cliente:**
   - Escribe un mensaje: "Hola, necesito ayuda con electricidad"
   - Toca enviar
   - Verifica que aparezca en el chat

2. **Desde el Trabajador:**
   - Abre la conversación
   - Debería ver el mensaje del cliente
   - Responde: "Hola, ¿en qué puedo ayudarte?"
   - Verifica que aparezca

### Paso 5: Probar Funcionalidades
1. **Indicador de Escritura:**
   - Empieza a escribir en un dispositivo
   - En el otro debería aparecer "Escribiendo..."

2. **Mensajes No Leídos:**
   - Envía un mensaje desde un dispositivo
   - En el otro, ve a la lista de chats
   - Debería mostrar un indicador de mensaje no leído

3. **Tiempo Real:**
   - Envía mensajes rápidamente
   - Verifica que aparezcan sin recargar

## Verificación en Firebase

### 1. Verificar Datos en Firestore

**Colección `conversations`:**
```javascript
// Debería existir un documento con:
{
  "clientId": "cliente_uid",
  "workerId": "trabajador_uid",
  "clientName": "cliente@test.com",
  "workerName": "trabajador@test.com",
  "lastMessage": "Hola, ¿en qué puedo ayudarte?",
  "lastMessageTime": "timestamp",
  "unreadCount": 0,
  "isActive": true
}
```

**Subcolección `messages`:**
```javascript
// Deberían existir mensajes como:
{
  "senderId": "cliente_uid",
  "receiverId": "trabajador_uid",
  "message": "Hola, necesito ayuda con electricidad",
  "timestamp": "timestamp",
  "isRead": true,
  "type": "text"
}
```

### 2. Verificar Logs

**En Firebase Console:**
1. Ve a **Firestore Database** → **Usage**
2. Verifica que haya actividad
3. Revisa los logs de errores

## Problemas Comunes y Soluciones

### Error: "Missing or insufficient permissions"
- **Causa:** Reglas de Firestore incorrectas
- **Solución:** Verificar que las reglas estén aplicadas correctamente

### Error: "Document does not exist"
- **Causa:** Conversación no creada correctamente
- **Solución:** Verificar que el `ChatProvider` esté funcionando

### Mensajes no aparecen en tiempo real
- **Causa:** Problema con los listeners de Firestore
- **Solución:** Verificar conexión a internet y configuración de Firebase

### App se cuelga al enviar mensaje
- **Causa:** Error en el provider o modelo
- **Solución:** Revisar logs de Flutter y Firebase

## Comandos Útiles para Debugging

```bash
# Ver logs de Flutter
flutter logs

# Ejecutar con logs detallados
flutter run --verbose

# Limpiar cache
flutter clean
flutter pub get

# Verificar configuración de Firebase
flutterfire configure
```

## Verificación Final

### ✅ Checklist de Funcionalidades

- [ ] Autenticación funciona en ambos dispositivos
- [ ] Se crea conversación al iniciar chat
- [ ] Los mensajes se envían correctamente
- [ ] Los mensajes aparecen en tiempo real
- [ ] Indicador de escritura funciona
- [ ] Mensajes no leídos se muestran
- [ ] Lista de conversaciones se actualiza
- [ ] No hay errores en la consola
- [ ] Datos se guardan en Firestore

### 🎯 Resultado Esperado

Si todo funciona correctamente, deberías poder:
1. Iniciar una conversación desde el cliente
2. Ver la conversación en ambos dispositivos
3. Enviar y recibir mensajes en tiempo real
4. Ver indicadores de escritura y mensajes no leídos
5. Navegar entre pantallas sin problemas

¡El sistema de chat estará completamente funcional! 