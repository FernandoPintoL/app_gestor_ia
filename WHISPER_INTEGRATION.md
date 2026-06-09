# Integración Whisper - Guía Completa

## 🎯 Objetivo
Convertir voz a texto en tiempo real usando **VAD (Voice Activity Detection)** sin necesidad de internet.

## 🏗️ Arquitectura Implementada

### Flujo Completo
```
┌─────────────────────────────────────────────────────────────┐
│                    🎤 USUARIO HABLA                        │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│ 📱 Record Plugin                                            │
│ - Captura audio desde micrófono (16kHz, WAV, mono)        │
│ - Guarda en /recordings/recording_*.wav                    │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│ 🔍 VAD Timer (Voice Activity Detection)                    │
│ - Detecta pausa de 2 segundos                              │
│ - Gatilla transcripción automáticamente                    │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│ 🎙️ Whisper (whisper_ggml)                                  │
│ - Transcribe audio WAV → texto plano                       │
│ - Offline, ~140MB modelo                                  │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│ 📝 WhisperProvider (Estado)                                │
│ - Muestra transcripción en la app                         │
│ - Botón "Usar" para copiar a prompt                       │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│ 🧠 Qwen (ActionService)                                    │
│ - Procesa texto natural                                    │
│ - Convierte a JSON                                        │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│ ⚙️ Acción Ejecutada                                        │
│ - Crear venta, cliente, etc.                             │
└─────────────────────────────────────────────────────────────┘
```

## 📦 Dependencias

```yaml
whisper_ggml: ^1.7.0   # Motor de transcripción
record: ^5.1.0         # Grabación de audio
```

## 🏃 Implementación en Código

### 1. **WhisperProvider** (`lib/providers/whisper_provider.dart`)

```dart
class WhisperProvider extends ChangeNotifier {
  // Propiedades públicas
  bool _isRecording;      // ¿Se está grabando?
  bool _isTranscribing;   // ¿Se está transcribiendo?
  String? _transcript;    // Resultado de la transcripción
  
  // Métodos principales
  initializeModel(path)   // Cargar modelo Whisper
  startRecording()        // Iniciar grabación 🎤
  stopRecording()         // Detener grabación ⏹️
}
```

### 2. **UI Integration** (`lib/pages/gestor_page.dart`)

```dart
Consumer<WhisperProvider>(
  builder: (context, whisper, _) {
    return Card(
      child: Column(
        children: [
          // Botón Grabar/Detener
          ElevatedButton.icon(
            onPressed: whisper.isRecording 
              ? () => whisper.stopRecording()
              : () => whisper.startRecording(),
            icon: Icon(whisper.isRecording 
              ? Icons.stop_circle 
              : Icons.mic),
            label: Text(whisper.isRecording ? 'Detener' : 'Grabar'),
          ),
          
          // Botón Usar (insertar en prompt)
          if (whisper.transcript != null)
            ElevatedButton.icon(
              onPressed: () {
                _promptController.text = whisper.transcript!;
                whisper.clearTranscript();
              },
              label: Text('Usar'),
            ),
          
          // Mostrar transcripción
          if (whisper.transcript != null)
            Text(whisper.transcript!),
        ],
      ),
    );
  },
)
```

### 3. **VAD (Voice Activity Detection)**

```dart
void _resetSilenceTimer() {
  _silenceTimer?.cancel();
  _silenceTimer = Timer(
    const Duration(seconds: 2),  // 2 segundos de pausa
    () async => await _transcribeAudio(),
  );
}
```

**Cómo funciona:**
- Usuario presiona "Grabar"
- Record captura audio
- Cada 2 segundos sin sonido → Timer llama `_transcribeAudio()`
- Whisper transcribe → Resultado aparece en app

## 🎙️ Configuración de Audio

```dart
RecordConfig(
  encoder: AudioEncoder.wav,      // Formato WAV
  sampleRate: 16000,              // 16kHz (Whisper recomendado)
  numChannels: 1,                 // Mono
  bitRate: 128000,                // 128 kbps
)
```

## 📥 Descarga del Modelo Whisper

### Opción 1: Inglés (Recomendado)
```
https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-base.en.bin
Tamaño: 140 MB
Precisión: Buena
Velocidad: Rápida
```

### Opción 2: Multiidioma (Español + Inglés)
```
https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-base.bin
Tamaño: 140 MB
Precisión: Buena
Velocidad: Normal
Idiomas: Todos (automático)
```

### Instalación
1. Descargar archivo `.bin`
2. Renombrar a: `ggml-whisper.bin`
3. Copiar a dispositivo en carpeta accesible
4. En la app: Usar botón "Explorar" para seleccionar
5. Modelo se carga automáticamente

## 🔄 Flujo Completo de Usuario

```
1. App abre → Lee modelo guardado (si existe)
2. Usuario presiona 🎤 Grabar
3. Permite acceso a micrófono (primera vez)
4. Usuario habla naturalmente
5. Pausa de 2 segundos → Whisper transcribe automáticamente
6. Texto aparece en la app ("El joven compró 2 zapatos")
7. Usuario presiona "Usar"
8. Texto se inserta en el campo prompt
9. Usuario presiona "Procesar"
10. Qwen convierte a JSON
11. Acción se ejecuta (crear venta)
```

## ⚙️ Permisos Necesarios

### Android (`android/app/src/main/AndroidManifest.xml`)
```xml
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
```

Nota: La app solicita permisos en runtime (primera vez)

## 🐛 Troubleshooting

### "Archivo de modelo no encontrado"
- Verificar ruta del archivo
- No usar rutas system, usar `/sdcard/Download/` o similar

### "Error: dlopen failed: library not found"
- Es normal en Android, no afecta funcionamiento
- Ignorar el warning

### "Micrófono no funciona"
- Verificar permisos en Settings → Apps → Permisos
- Activar: Audio Recording (Micrófono)

### "Transcripción lenta"
- Normal en modelos grandes
- Considerar modelo `tiny.en` si es muy lento
- O cortar frases más cortas (pausa más frecuentemente)

## 🚀 Próximas Mejoras

- [ ] Soporte para idiomas específicos (Español)
- [ ] Visualización de onda de audio
- [ ] Historial de transcripciones
- [ ] Ajuste automático de sensibilidad de VAD
- [ ] Streaming en tiempo real (sin esperar pausa)

## 📊 Rendimiento Esperado

| Modelo | Tamaño | Precisión | Velocidad | Idiomas |
|--------|--------|-----------|-----------|---------|
| tiny.en | 75 MB | Buena | Muy rápida | Inglés |
| **base.en** | **140 MB** | **Muy buena** | **Rápida** | **Inglés** |
| small.en | 461 MB | Excelente | Normal | Inglés |
| base | 140 MB | Muy buena | Normal | Todos |

**Recomendado**: `base.en` para balance de precisión y velocidad

---

## 💡 Notas Finales

- **Offline**: No requiere internet
- **Privado**: Los datos no se envían a servidores
- **VAD**: Detección automática de pausa (no manual)
- **Integrado**: Funciona junto con Qwen sin cambios
- **Escalable**: Fácil de extender con nuevas features

