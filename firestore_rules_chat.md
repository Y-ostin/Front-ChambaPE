# Reglas de Seguridad de Firestore para el Sistema de Chat

## Reglas Completas

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Reglas para usuarios
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Reglas para conversaciones
    match /conversations/{conversationId} {
      // Permitir lectura y escritura solo a participantes de la conversación
      allow read, write: if request.auth != null && 
        (resource.data.clientId == request.auth.uid || 
         resource.data.workerId == request.auth.uid);
      
      // Reglas para mensajes dentro de la conversación
      match /messages/{messageId} {
        allow read, write: if request.auth != null && 
          (get(/databases/$(database)/documents/conversations/$(conversationId)).data.clientId == request.auth.uid ||
           get(/databases/$(database)/documents/conversations/$(conversationId)).data.workerId == request.auth.uid);
      }
      
      // Reglas para estado de escritura
      match /typing/{userId} {
        allow read, write: if request.auth != null && 
          (get(/databases/$(database)/documents/conversations/$(conversationId)).data.clientId == request.auth.uid ||
           get(/databases/$(database)/documents/conversations/$(conversationId)).data.workerId == request.auth.uid);
      }
    }
  }
}
```

## Reglas Simplificadas (Para Desarrollo)

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Permitir todo para usuarios autenticados (solo para desarrollo)
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

## Instrucciones de Configuración

### 1. Acceder a la Consola de Firebase

1. Ve a [Firebase Console](https://console.firebase.google.com/)
2. Selecciona tu proyecto
3. En el menú lateral, ve a "Firestore Database"
4. Haz clic en la pestaña "Rules"

### 2. Aplicar las Reglas

1. Copia las reglas completas (o simplificadas para desarrollo)
2. Pega en el editor de reglas
3. Haz clic en "Publish"

### 3. Verificar la Configuración

```bash
# Instalar Firebase CLI si no lo tienes
npm install -g firebase-tools

# Iniciar sesión
firebase login

# Inicializar proyecto (si no está inicializado)
firebase init firestore

# Desplegar reglas
firebase deploy --only firestore:rules
```

## Estructura de Datos Esperada

### Colección: conversations

```javascript
{
  "conversationId": {
    "clientId": "user_uid",
    "workerId": "worker_uid", 
    "clientName": "Nombre del Cliente",
    "workerName": "Nombre del Trabajador",
    "lastMessage": "Último mensaje enviado",
    "lastMessageTime": "timestamp",
    "unreadCount": 0,
    "isActive": true
  }
}
```

### Subcolección: messages

```javascript
{
  "messageId": {
    "senderId": "user_uid",
    "receiverId": "receiver_uid",
    "message": "Contenido del mensaje",
    "timestamp": "timestamp",
    "isRead": false,
    "imageUrl": "url_imagen_opcional",
    "type": "text" // o "image"
  }
}
```

### Subcolección: typing

```javascript
{
  "userId": {
    "isTyping": true,
    "timestamp": "timestamp"
  }
}
```

## Consideraciones de Seguridad

### ✅ Buenas Prácticas

1. **Autenticación Requerida**: Todas las operaciones requieren autenticación
2. **Validación de Participantes**: Solo los participantes pueden acceder a la conversación
3. **Validación de Datos**: Los datos se validan antes de ser escritos
4. **Reglas Específicas**: Cada subcolección tiene sus propias reglas

### ⚠️ Advertencias

1. **No usar reglas simplificadas en producción**
2. **Validar datos en el cliente y servidor**
3. **Implementar rate limiting para prevenir spam**
4. **Considerar límites de tamaño para mensajes**

### 🔒 Seguridad Adicional

```javascript
// Reglas con validación de datos
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /conversations/{conversationId} {
      allow create: if request.auth != null && 
        request.resource.data.clientId == request.auth.uid &&
        request.resource.data.clientId != request.resource.data.workerId;
      
      allow read, update: if request.auth != null && 
        (resource.data.clientId == request.auth.uid || 
         resource.data.workerId == request.auth.uid);
      
      match /messages/{messageId} {
        allow create: if request.auth != null && 
          request.resource.data.senderId == request.auth.uid &&
          request.resource.data.message.size() <= 1000; // Límite de caracteres
        
        allow read, update: if request.auth != null && 
          (get(/databases/$(database)/documents/conversations/$(conversationId)).data.clientId == request.auth.uid ||
           get(/databases/$(database)/documents/conversations/$(conversationId)).data.workerId == request.auth.uid);
      }
    }
  }
}
```

## Testing de Reglas

### Usar Firebase Emulator

```bash
# Iniciar emulador
firebase emulators:start --only firestore

# Ejecutar tests
firebase emulators:exec --only firestore "npm test"
```

### Ejemplo de Test

```javascript
const firebase = require('firebase/app');
require('firebase/firestore');

describe('Chat Security Rules', () => {
  it('should allow authenticated users to create conversations', async () => {
    // Test implementation
  });
  
  it('should prevent unauthorized access to conversations', async () => {
    // Test implementation
  });
});
```

## Monitoreo y Logs

### Habilitar Logs de Firestore

1. Ve a Firebase Console > Firestore Database
2. Haz clic en "Usage" 
3. Habilita "Detailed usage statistics"

### Consultas Útiles

```sql
-- Ver conversaciones activas
SELECT * FROM conversations WHERE isActive = true

-- Ver mensajes no leídos
SELECT * FROM messages WHERE isRead = false

-- Ver actividad reciente
SELECT * FROM conversations 
ORDER BY lastMessageTime DESC 
LIMIT 10
```

## Resolución de Problemas

### Error: "Missing or insufficient permissions"

1. Verificar que el usuario esté autenticado
2. Comprobar que el usuario sea participante de la conversación
3. Revisar las reglas de seguridad
4. Verificar la estructura de datos

### Error: "Document does not exist"

1. Verificar que la conversación exista
2. Comprobar los IDs de usuario
3. Revisar la creación de documentos

### Error: "Invalid data"

1. Verificar la estructura de datos
2. Comprobar tipos de datos
3. Revisar validaciones en las reglas 