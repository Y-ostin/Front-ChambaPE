# 🔧 Solución para Errores de Permisos en Firestore

## Problema Identificado

Los errores que estás viendo son de **permisos denegados** en Firestore:

```
PERMISSION_DENIED: Missing or insufficient permissions
```

Esto significa que las reglas de seguridad de Firestore no permiten las operaciones que estamos intentando realizar.

## ✅ Solución Inmediata

### Paso 1: Actualizar Reglas de Firestore

1. Ve a [Firebase Console](https://console.firebase.google.com/)
2. Selecciona tu proyecto
3. Ve a **Firestore Database** → **Rules**
4. **Reemplaza completamente** las reglas actuales con estas:

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

5. Haz clic en **"Publish"**

### Paso 2: Verificar que los Datos de Ejemplo Usen el UID Correcto

Ya actualicé el archivo `lib/utils/sample_data.dart` para usar el UID real que aparece en tus logs: `mMTEUEm5UsOv5q6Zn1CuJNNdGns1`

### Paso 3: Poblar Datos de Ejemplo

1. Reinicia la aplicación
2. Inicia sesión con tu cuenta
3. Ve a **Configuración** → **"Poblar datos de ejemplo"**
4. Toca el botón para agregar los datos

### Paso 4: Probar la Funcionalidad

1. Ve al perfil del trabajador
2. Intenta cambiar la disponibilidad (el switch)
3. Verifica que no aparezcan más errores de permisos

## 🔍 Verificación

Después de aplicar estos pasos, deberías ver en los logs:

```
✅ Datos de ejemplo agregados exitosamente
✅ No más errores de PERMISSION_DENIED
✅ El switch de disponibilidad funciona correctamente
```

## 📋 Reglas de Producción (Para el Futuro)

Cuando estés listo para producción, usa estas reglas más seguras:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Usuarios
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Trabajadores
    match /workers/{workerId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == workerId;
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
    
    // Conversaciones
    match /conversations/{conversationId} {
      allow read, write: if request.auth != null && 
        (resource.data.clientId == request.auth.uid || 
         resource.data.workerId == request.auth.uid);
      
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

## 🚨 Si el Problema Persiste

1. **Verifica que estés autenticado**:
   ```dart
   print('Usuario autenticado: ${FirebaseAuth.instance.currentUser?.uid}');
   ```

2. **Verifica las reglas en Firebase Console**:
   - Asegúrate de que las reglas se hayan publicado correctamente
   - Puede tomar unos minutos para que los cambios se propaguen

3. **Reinicia la aplicación completamente**:
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

4. **Verifica la conexión a Firebase**:
   - Asegúrate de que `google-services.json` esté actualizado
   - Verifica que el proyecto de Firebase sea el correcto

## 📱 Comandos Útiles

```bash
# Ver logs en tiempo real
flutter logs

# Limpiar cache
flutter clean
flutter pub get

# Verificar configuración de Firebase
flutterfire configure
```

## ✅ Resultado Esperado

Después de aplicar la solución:

- ✅ El nombre del trabajador se muestra correctamente
- ✅ El switch de disponibilidad funciona sin errores
- ✅ Los trabajos recientes se cargan dinámicamente
- ✅ Las reseñas se muestran correctamente
- ✅ No hay más errores de `PERMISSION_DENIED` en los logs 