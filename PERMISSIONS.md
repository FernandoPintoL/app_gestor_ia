# Permisos Necesarios para Whisper

## 📱 Permisos Requeridos

### Android

**Archivo**: `android/app/src/main/AndroidManifest.xml`

```xml
<!-- Grabación de audio desde micrófono -->
<uses-permission android:name="android.permission.RECORD_AUDIO" />

<!-- Lectura/escritura de almacenamiento (para guardar grabaciones) -->
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
```

**✅ Ya agregados en el proyecto**

### iOS

**Archivo**: `ios/Runner/Info.plist`

```xml
<key>NSMicrophoneUsageDescription</key>
<string>La app necesita acceso al micrófono para grabar tu voz y transcribirla con Whisper</string>

<key>NSLocationWhenInUseUsageDescription</key>
<string>Opcional: mensaje si necesitas ubicación</string>
```

---

## 🔑 Cómo Funcionan los Permisos

### Android 6.0+ (Nivel 23+)

Android tiene dos tipos de permisos:

#### 1. **Declaración en Manifest** (Compile-time)
```xml
<uses-permission android:name="android.permission.RECORD_AUDIO" />
```
- Se declara en `AndroidManifest.xml`
- Necesario para que la app pueda acceder al micrófono
- Sin esto, la app NO funciona

#### 2. **Solicitud en Runtime** (Runtime)
```dart
// En WhisperProvider
if (await _recorder.hasPermission()) {
  // Usuario ya concedió permiso
} else {
  // Usuario debe conceder permiso (popup)
}
```

**Cuando el usuario presiona 🎤 Grabar:**
1. App verifica si tiene permiso
2. Si NO lo tiene → Android muestra popup
3. Usuario toca "Permitir" o "Denegar"
4. Si permite → Se guarda el permiso
5. Si deniega → Muestra error

---

## 🎯 Flujo Completo de Permisos

```
Usuario abre la app
    ↓
Usuario presiona 🎤 Grabar
    ↓
WhisperProvider llama: _recorder.hasPermission()
    ↓
¿Permiso ya concedido?
    ├─ Sí → Inicia grabación inmediatamente
    └─ No → Android muestra popup
            Usuario toca "Permitir"
            Inicia grabación
```

---

## 📋 Permisos Usados en Este Proyecto

| Permiso | Por qué | Obligatorio |
|---------|---------|-------------|
| `RECORD_AUDIO` | Acceder al micrófono | ✅ Sí |
| `WRITE_EXTERNAL_STORAGE` | Guardar archivos de audio | ✅ Sí |
| `READ_EXTERNAL_STORAGE` | Leer archivos de audio | ✅ Sí |

---

## ✅ Cómo Verificar que Funciona

### En la App:
1. Abre la app
2. Presiona 🎤 Grabar
3. **Primera vez**: Deberías ver un popup
4. Toca "Permitir"
5. Si ves "🎤 Grabando..." → ¡Funciona!

### En Settings del Dispositivo:
```
Configuración → Apps → Gestor IA → Permisos
├── Micrófono ✅ Permitido
├── Almacenamiento ✅ Permitido
└── Otros...
```

---

## 🚨 Problemas Comunes

### "Grabación no funciona"
1. Verifica que hayas tocado "Permitir" en el popup
2. Ve a Settings → Apps → Gestor IA → Permisos
3. Activa: Micrófono

### "¿Dónde se guardan las grabaciones?"
- Ruta: `/sdcard/Android/data/com.fpl.topicos.gestor_ia/recordings/`
- O: `Documents/recordings/`
- Automáticamente gestionado por la app

### "Popup no aparece"
- Normalmente aparece solo la primera vez
- Para resetear: Ve a Settings → Apps → Gestor IA → Permisos → Denegar
- Luego presiona Grabar de nuevo

---

## 🔒 Privacidad

✅ **Todos los datos son locales**
- No se envía nada a internet
- Grabaciones se guardan en el dispositivo
- Whisper corre offline
- Qwen corre offline

---

## 📝 Código Relacionado

**En `WhisperProvider.dart`:**
```dart
Future<void> startRecording() async {
  final hasPermission = await _recorder.hasPermission();
  
  if (hasPermission) {
    // Ya tiene permiso → Grabar
    await _recorder.start(...);
  } else {
    // Sin permiso → Mostrar error
    _error = 'Permiso de micrófono denegado';
  }
}
```

---

## ✨ Resumen

1. **Permisos declarados** en `AndroidManifest.xml` ✅
2. **Runtime permissions** solicitadas automáticamente ✅
3. **iOS** requiere actualizar `Info.plist` (opcional para testing)
4. **Usuario ve popup** la primera vez que usa Grabar
5. **Todo offline** y privado ✅

¡Listo para usar! 🚀

