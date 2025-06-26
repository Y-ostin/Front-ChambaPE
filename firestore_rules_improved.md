# Reglas de Firestore Mejoradas para Manos Expertas

## Problemas en las Reglas Originales

1. **Falta validación para creación de conversaciones**
2. **No hay reglas para la colección `users`**
3. **Falta validación de datos**
4. **Las reglas de mensajes no manejan bien la creación inicial**

## Reglas Mejoradas y Completas

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
      // Crear conversación: solo clientes pueden crear, no pueden crear con sí mismos
      allow create: if request.auth != null && 
        request.resource.data.clientId == request.auth.uid &&
        request.resource.data.clientId != request.resource.data.workerId &&
        request.resource.data.clientName is string &&
        request.resource.data.workerName is string;
      
      // Leer y actualizar: solo participantes de la conversación
      allow read, update: if request.auth != null && 
        (resource.data.clientId == request.auth.uid || 
         resource.data.workerId == request.auth.uid);
      
      // Eliminar: solo participantes pueden eliminar
      allow delete: if request.auth != null && 
        (resource.data.clientId == request.auth.uid || 
         resource.data.workerId == request.auth.uid);
      
      // Reglas para mensajes dentro de la conversación
      match /messages/{messageId} {
        // Crear mensaje: solo participantes, con validaciones
        allow create: if request.auth != null && 
          request.resource.data.senderId == request.auth.uid &&
          (get(/databases/$(database)/documents/conversations/$(conversationId)).data.clientId == request.auth.uid ||
           get(/databases/$(database)/documents/conversations/$(conversationId)).data.workerId == request.auth.uid) &&
          request.resource.data.message is string &&
          request.resource.data.message.size() <= 1000 &&
          request.resource.data.timestamp is timestamp;
        
        // Leer mensajes: solo participantes
        allow read: if request.auth != null && 
          (get(/databases/$(database)/documents/conversations/$(conversationId)).data.clientId == request.auth.uid ||
           get(/databases/$(database)/documents/conversations/$(conversationId)).data.workerId == request.auth.uid);
        
        // Actualizar mensajes: solo el remitente puede marcar como leído
        allow update: if request.auth != null && 
          resource.data.senderId != request.auth.uid && // Solo el receptor puede actualizar
          (get(/databases/$(database)/documents/conversations/$(conversationId)).data.clientId == request.auth.uid ||
           get(/databases/$(database)/documents/conversations/$(conversationId)).data.workerId == request.auth.uid) &&
          request.resource.data.diff(resource.data).affectedKeys().hasOnly(['isRead']);
        
        // Eliminar mensajes: solo el remitente
        allow delete: if request.auth != null && 
          resource.data.senderId == request.auth.uid;
      }
      
      // Reglas para estado de escritura
      match /typing/{userId} {
        // Crear/actualizar estado de escritura: solo el usuario mismo
        allow create, update: if request.auth != null && 
          userId == request.auth.uid &&
          (get(/databases/$(database)/documents/conversations/$(conversationId)).data.clientId == request.auth.uid ||
           get(/databases/$(database)/documents/conversations/$(conversationId)).data.workerId == request.auth.uid) &&
          request.resource.data.isTyping is bool &&
          request.resource.data.timestamp is timestamp;
        
        // Leer estado de escritura: solo participantes
        allow read: if request.auth != null && 
          (get(/databases/$(database)/documents/conversations/$(conversationId)).data.clientId == request.auth.uid ||
           get(/databases/$(database)/documents/conversations/$(conversationId)).data.workerId == request.auth.uid);
        
        // Eliminar estado de escritura: solo el usuario mismo
        allow delete: if request.auth != null && 
          userId == request.auth.uid;
      }
    }
    
    // Denegar acceso a todas las demás colecciones
    match /{document=**} {
      allow read, write: if false;
    }
  }
}
```

## Reglas Simplificadas para Desarrollo

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Permitir todo para usuarios autenticados (SOLO PARA DESARROLLO)
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

## Reglas Intermedias (Más Seguras que Desarrollo)

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Usuarios
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Conversaciones y todo su contenido
    match /conversations/{conversationId} {
      allow read, write: if request.auth != null && 
        (resource.data.clientId == request.auth.uid || 
         resource.data.workerId == request.auth.uid);
      
      // Permitir acceso a subcolecciones
      match /{subcollection}/{document} {
        allow read, write: if request.auth != null && 
          (get(/databases/$(database)/documents/conversations/$(conversationId)).data.clientId == request.auth.uid ||
           get(/databases/$(database)/documents/conversations/$(conversationId)).data.workerId == request.auth.uid);
      }
    }
    
    // Denegar todo lo demás
    match /{document=**} {
      allow read, write: if false;
    }
  }
}
```

## Explicación de las Mejoras

### 1. **Validación de Creación de Conversaciones**
```javascript
allow create: if request.auth != null && 
  request.resource.data.clientId == request.auth.uid &&
  request.resource.data.clientId != request.resource.data.workerId;
```
- Solo clientes pueden crear conversaciones
- No pueden crear conversaciones consigo mismos
- Valida que los campos requeridos existan

### 2. **Validación de Mensajes**
```javascript
request.resource.data.message.size() <= 1000
```
- Limita el tamaño de los mensajes
- Previene spam y ataques

### 3. **Control de Actualizaciones**
```javascript
request.resource.data.diff(resource.data).affectedKeys().hasOnly(['isRead'])
```
- Solo permite actualizar el campo `isRead`
- Previene modificaciones no autorizadas

### 4. **Seguridad de Estado de Escritura**
```javascript
userId == request.auth.uid
```
- Solo el usuario puede actualizar su propio estado
- Previene suplantación de identidad

## Recomendación para tu Proyecto

**Para desarrollo/pruebas:** Usa las reglas simplificadas
**Para producción:** Usa las reglas completas

### Pasos para Aplicar:

1. Ve a [Firebase Console](https://console.firebase.google.com/)
2. Selecciona tu proyecto
3. Firestore Database → Rules
4. Copia y pega las reglas que prefieras
5. Haz clic en "Publish"

### Verificación:

```bash
# Si tienes Firebase CLI
firebase deploy --only firestore:rules
```

## Estructura de Datos Esperada

```javascript
// /users/{userId}
{
  "name": "string",
  "email": "string", 
  "role": "cliente" | "trabajador",
  "uid": "string"
}

// /conversations/{conversationId}
{
  "clientId": "string",
  "workerId": "string",
  "clientName": "string",
  "workerName": "string", 
  "lastMessage": "string",
  "lastMessageTime": "timestamp",
  "unreadCount": "number",
  "isActive": "boolean"
}

// /conversations/{conversationId}/messages/{messageId}
{
  "senderId": "string",
  "receiverId": "string",
  "message": "string",
  "timestamp": "timestamp",
  "isRead": "boolean",
  "imageUrl": "string?",
  "type": "text" | "image"
}

// /conversations/{conversationId}/typing/{userId}
{
  "isTyping": "boolean",
  "timestamp": "timestamp"
}
``` 