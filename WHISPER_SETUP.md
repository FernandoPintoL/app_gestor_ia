# Configuración Whisper - Voice to Text

## 📥 Descargar Modelo Whisper

Los modelos Whisper GGUF están en **Hugging Face**:

### Opción A: Modelo Recomendado (Mejor balance)
```
https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-base.en.bin
```
- Tamaño: ~140 MB
- Idioma: Inglés
- Velocidad: Rápido
- Precisión: Buena

### Opción B: Más Preciso
```
https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-small.en.bin
```
- Tamaño: ~461 MB
- Idioma: Inglés
- Velocidad: Media
- Precisión: Muy buena

### Opción C: Más Rápido
```
https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-tiny.en.bin
```
- Tamaño: ~75 MB
- Idioma: Inglés
- Velocidad: Muy rápido
- Precisión: Aceptable

### Opción D: Multiidioma
```
https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-base.bin
```
- Soporta múltiples idiomas (español, inglés, etc)
- Tamaño: ~140 MB

---

## 📱 Instalación en Dispositivo

Una vez descargado el modelo:

1. **Renombra el archivo a**: `ggml-whisper.bin`

2. **Copia a tu dispositivo** (igual que con Qwen):
   - Coloca en carpeta accesible (Downloads, Documents, etc)
   - La app lo buscará allí

3. **En la app**:
   - Ve a la sección "🤖 Modelo GGUF"
   - Click "Explorar" → selecciona el archivo `.bin`
   - Click "Cargar"

---

## 🔧 Estructura de Carpetas Recomendada

```
/Downloads
├── ggml-qwen.gguf          (Qwen para NL→JSON)
├── ggml-whisper.bin         (Whisper para Voice→Text)
```

---

## 🎤 Cómo Funciona (Flujo Completo)

```
Usuario presiona "Grabar"
    ↓
Record captura audio (micrófono)
    ↓
Usuario habla y hay pausa de 2 segundos
    ↓
Whisper transcribe automáticamente
    ↓
Texto aparece en la app
    ↓
Usuario presiona "Usar" → se inserta en prompt
    ↓
Usuario presiona "Procesar"
    ↓
Qwen convierte a JSON
    ↓
Acción se ejecuta
```

---

## ⚙️ Configuración (Ya Hecha)

- ✅ `whisper_ggml: ^1.7.0` - Modelo Whisper
- ✅ `record: ^5.1.0` - Grabación de audio
- ✅ `silero_vad: ^0.3.0` - Detección de pausa
- ✅ `WhisperProvider` - Gestión de estado
- ✅ Botón 🎤 en UI

---

## 🚀 Próximos Pasos

1. **Descargar modelo** (recomendado: `ggml-base.en.bin`)
2. **Ejecutar**: `flutter pub get`
3. **Probar la app**: Presionar botón 🎤 y hablar
4. **Usar transcripción**: Click "Usar" para insertar en prompt

---

## 📝 Notas Importantes

- **VAD (Voice Activity Detection)**: Detección automática de pausa
  - Cuando dejas de hablar 2 segundos → Transcribe automáticamente
  - No necesitas presionar botón de parada (pero puedes)

- **Tiempo Real**: La transcripción es casi inmediata después de pausar
  
- **Idioma**: Si usas `ggml-base.en.bin`, solo funciona inglés
  - Para español: usa `ggml-base.bin` (multiidioma)

- **Offline**: Todo funciona sin internet

---

## Troubleshooting

### "Error: dlopen failed: library not found"
- Es normal en Android, no afecta

### "Archivo no encontrado"
- Verifica que el modelo esté en una ruta accesible
- No uses rutas system, usa `/sdcard/Download/` o similar

### "Grabación silenciosa"
- Verifica permisos de micrófono en el dispositivo
- Settings → App Permissions → Micrófono → Activar

