# Reglas de Firestore con Permisos de Eliminación

## Problema
Las reglas actuales no permiten eliminar documentos, lo que causa el error:
```
PERMISSION_DENIED: Missing or insufficient permissions
```

## Solución: Reglas Actualizadas

### Reglas para Desarrollo (Permitir Todo)
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Permitir todo para usuarios autenticados (SOLO PARA DESARROLLO)
    match /{document=**} {
      allow read, write, delete: if request.auth != null;
    }
  }
}
```

### Reglas Intermedias (Más Seguras)
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Usuarios - Permitir eliminación propia
    match /users/{userId} {
      allow read, write, delete: if request.auth != null && request.auth.uid == userId;
    }
    
    // Trabajadores - Permitir eliminación propia
    match /workers/{workerId} {
      allow read: if request.auth != null;
      allow write, delete: if request.auth != null && request.auth.uid == workerId;
    }
    
    // Trabajos
    match /jobs/{jobId} {
      allow read, write: if request.auth != null;
    }
    
    // Reseñas
    match /reviews/{reviewId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null;
    }
    
    // Conversaciones - Permitir eliminación para participantes
    match /conversations/{conversationId} {
      allow read, write, delete: if request.auth != null && 
        (resource.data.clientId == request.auth.uid || 
         resource.data.workerId == request.auth.uid);
      
      // Subcolecciones (mensajes, typing)
      match /{subcollection}/{document} {
        allow read, write, delete: if request.auth != null && 
          (get(/databases/$(database)/documents/conversations/$(conversationId)).data.clientId == request.auth.uid ||
           get(/databases/$(database)/documents/conversations/$(conversationId)).data.workerId == request.auth.uid);
      }
    }
    
    // Denegar todo lo demás
    match /{document=**} {
      allow read, write, delete: if false;
    }
  }
}
```

## Instrucciones de Aplicación

### Paso 1: Ir a Firebase Console
1. Ve a [Firebase Console](https://console.firebase.google.com/)
2. Selecciona tu proyecto `manosexpertas-daf73`
3. Ve a **Firestore Database** → **Rules**

### Paso 2: Aplicar las Reglas
1. **Reemplaza completamente** las reglas actuales con las reglas de desarrollo:
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Permitir todo para usuarios autenticados (SOLO PARA DESARROLLO)
    match /{document=**} {
      allow read, write, delete: if request.auth != null;
    }
  }
}
```

2. Haz clic en **"Publish"**

### Paso 3: Verificar
1. Espera 1-2 minutos para que los cambios se propaguen
2. Prueba eliminar una cuenta
3. Verifica que no aparezcan más errores de permisos

## Nota Importante
- Las reglas de desarrollo permiten **todo** para usuarios autenticados
- Para producción, usa las reglas intermedias que son más seguras
- La palabra clave `delete` es la que faltaba en las reglas anteriores

## Verificación de Funcionamiento
Después de aplicar las reglas, deberías ver:
- ✅ No más errores de `PERMISSION_DENIED`
- ✅ Eliminación de cuentas funciona correctamente
- ✅ Todos los datos se eliminan de Firestore
- ✅ Navegación automática al login después de eliminar 