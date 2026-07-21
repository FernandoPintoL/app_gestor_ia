# Whisper: Cómo Funciona la Red Neuronal de Audio a Texto

## 📖 Tabla de Contenidos
1. [Información General](#información-general)
2. [Quién lo Creó](#quién-lo-creó)
3. [Arquitectura de Red Neuronal](#arquitectura-de-red-neuronal)
4. [Proceso Audio → Texto (Paso a Paso)](#proceso-audio--texto-paso-a-paso)
5. [Componentes Técnicos](#componentes-técnicos)
6. [Modelos Disponibles](#modelos-disponibles)
7. [Capacidades y Limitaciones](#capacidades-y-limitaciones)
8. [Cómo se Usa en Tu App](#cómo-se-usa-en-tu-app)

---

## Información General

**Nombre:** Whisper (Robust Speech Recognition via Large-Scale Weak Supervision)

**Tipo:** Modelo de Reconocimiento Automático de Voz (ASR - Automatic Speech Recognition)

**Año de Lanzamiento:** Septiembre 2022

**Versión Actual:** v2/v3

**Licencia:** MIT (Open Source)

**Código Fuente:** https://github.com/openai/whisper

**Datos de Entrenamiento:**
- 680,000 horas de audio multilingüe
- Descargado de internet (YouTube principalmente)
- Contiene ruido natural, acentos diversos, múltiples idiomas
- Datos sin limpiar intencionalmente (weak supervision)

---

## Quién lo Creó

**Organización:** OpenAI (Artificial Intelligence Research Laboratory)

**Equipo de Investigadores:**
- Alec Radford (Lead)
- Jong Wook Kim
- Tao Xu
- Greg Brockman
- Christine McLeavey
- Sam Altman (CEO de OpenAI)

**Motivación de OpenAI:**
- Crear un modelo robusto que funcione con audio del mundo real
- No solo audio limpio de laboratorio
- Soportar múltiples idiomas
- Resistencia al ruido y acentos variados

**Publicación:**
- Paper original: "Robust Speech Recognition via Large-Scale Weak Supervision"
- URL: https://arxiv.org/abs/2212.04356

---

## Arquitectura de Red Neuronal

### Tipo de Arquitectura: Encoder-Decoder (Secuencia a Secuencia)

```
┌─────────────────────────────────────────────────────┐
│               ARQUITECTURA WHISPER                  │
└─────────────────────────────────────────────────────┘

ENTRADA (Audio)
    │
    ▼
┌─────────────────────────┐
│  PREPROCESSING          │
│  • Mel-Spectrogram      │
│  • Normalización        │
│  • Padding              │
└────────────┬────────────┘
             │
             ▼
┌─────────────────────────────────────────────────┐
│          ENCODER (Transformador)                │
│  ┌────────────────────────────────────────────┐ │
│  │ • Capas de Atención Múltiple               │ │
│  │ • Feed-Forward Networks (FFN)              │ │
│  │ • Normalización de Capas                   │ │
│  │ • Positional Encoding (posición de tiempo) │ │
│  │                                            │ │
│  │ FUNCIÓN: Analizar y comprender el audio    │ │
│  │ SALIDA: Representación vectorial del audio │ │
│  └────────────────────────────────────────────┘ │
└─────────────┬──────────────────────────────────┘
              │
              ▼
    ┌─────────────────────┐
    │  REPRESENTACIÓN     │
    │  LATENTE (Context)  │
    │  del Audio Procesado│
    └──────────┬──────────┘
               │
               ▼
┌─────────────────────────────────────────────────┐
│          DECODER (Transformador)                │
│  ┌────────────────────────────────────────────┐ │
│  │ • Atención Cruzada (atiende al Encoder)    │ │
│  │ • Atención Automática (atiende su output)  │ │
│  │ • Feed-Forward Networks                    │ │
│  │ • Embedding de Tokens (palabras)           │ │
│  │                                            │ │
│  │ FUNCIÓN: Generar texto palabra por palabra │ │
│  │ SALIDA: Token (palabra) más probable       │ │
│  └────────────────────────────────────────────┘ │
└─────────────┬──────────────────────────────────┘
              │
              ▼
    ┌─────────────────────────┐
    │   PROBABILIDADES        │
    │   para cada palabra     │
    │   del vocabulario       │
    └──────────┬──────────────┘
               │
               ▼
        ┌──────────────┐
        │  SELECCIÓN   │
        │  palabra más │
        │  probable    │
        └──────┬───────┘
               │
               ▼
           SALIDA (Texto)
```

### Componentes Clave:

#### 1. **Transformador (Transformer)**
- Arquitectura basada en "Attention is All You Need" (2017)
- No usa RNN (Recurrent Neural Networks)
- Procesa todo el audio simultáneamente (no secuencial)
- Más paralelizable, más rápido

#### 2. **Attention (Atención)**
```
¿Cómo decide qué parte del audio es importante?

Cuando ve la palabra "café", la red decide:
- ¿Cuál parte del audio afecta esta palabra?
- ¿Debería atender al inicio, medio o final?
- ¿Hay contexto anterior importante?

Ejemplo:
Audio: "Quiero un café" 
       ↑     ↑  ↑
       |     |  └─ "café" → atiende aquí
       |     └───── "un" → atiende aquí
       └─────────── contexto
```

#### 3. **Encoder-Decoder Pattern**
```
ENCODER (Codificador):
  - Input: Audio
  - Output: Representación comprimida del audio
  - Analogía: Leer y entender un libro

DECODER (Decodificador):
  - Input: Lo que el Encoder entendió + palabras anteriores
  - Output: Siguiente palabra probable
  - Analogía: Escribir la historia basado en tu entendimiento
```

---

## Proceso Audio → Texto (Paso a Paso)

### Paso 1: Audio Crudo (WAV/MP3)

```
Audio Original: "Hola, quiero un café"
├── Formato: .wav, .mp3, .m4a, .ogg, .flac
├── Muestreo: 16 kHz (típico en Whisper)
├── Duración: Variable (segundos a minutos)
└── Contenido: Onda de sonido
```

### Paso 2: Extracción de Características (Mel-Spectrogram)

```
¿POR QUÉ?
────────
Las redes neuronales NO entienden ondas de sonido directamente.
Necesitan convertir el audio en información visual/numérica.

¿QUÉ ES MEL-SPECTROGRAM?
────────────────────────
Es una imagen que representa:
- Frecuencias (eje Y): Qué tonos hay (agudo, grave)
- Tiempo (eje X): Cuándo ocurren (inicio, medio, fin)
- Intensidad (color): Qué tan fuerte

EJEMPLO VISUAL:
```
Tiempo →
│
│  ┌─────────────────────────────┐
│  │ ████░░░░░░░░░░░░░░░░░░░░░░ │ Agudo (5000 Hz)
│  │ ██████░░░░░████░░░░░░░░░░░░ │
│  │ ████████░░████████░░░░░░░░░ │ Medio
│  │ ██████████████████████░░░░░ │
│  │ ████████████████████████░░░░ │ Grave (500 Hz)
│  └─────────────────────────────┘
│   "H"   "o"    "l"    "a"
└────────────────────────────────

█ = Sonido fuerte (blanco)
░ = Sonido débil (gris)
```

**Proceso técnico:**
```
1. Dividir audio en ventanas pequeñas (25ms cada una)
2. Aplicar FFT (Fast Fourier Transform) a cada ventana
   └─ Convierte dominio temporal → dominio frecuencial
3. Aplicar filtros Mel (escala perceptual humana)
   └─ Nuestros oídos son más sensibles a ciertas frecuencias
4. Aplicar logaritmo (porque el oído percibe volumen logarítmicamente)
5. Resultado: Matriz de números (imagen)
```

**Entrada al Encoder:**
```
Forma: [Tiempo_Steps, Frecuencias]
Ejemplo: [1500 timesteps, 128 frecuencias] = imagen 1500x128
Valores: 0 a 1 (intensidad normalizada)
```

### Paso 3: Encoder (Codificador)

```
OBJETIVO:
─────────
Analizar la "imagen" de audio y crear una representación
comprimida que capture lo "importante".

PROCESO:
────────

Entrada: Mel-Spectrogram (1500x128)
    │
    ▼
┌─────────────────────────────────┐
│ Capas de Transformador Encoder  │ (típicamente 12 capas)
│ ┌──────────────────────────────┐│
│ │ Layer 1                      ││
│ │ • Multi-head Attention       ││  ← "¿Qué partes se relacionan?"
│ │ • Feed-Forward Network       ││  ← "¿Cómo transformar esto?"
│ │ • Layer Normalization        ││  ← "Estabilizar valores"
│ └──────────────────────────────┘│
│ ┌──────────────────────────────┐│
│ │ Layer 2                      ││  ← Repite 12 veces
│ │ • Multi-head Attention       ││
│ │ • Feed-Forward Network       ││
│ │ • Layer Normalization        ││
│ └──────────────────────────────┘│
│ ... (10 capas más)             │
└──────────────────┬──────────────┘
                   │
                   ▼
Salida: Vector de contexto comprimido
├── Tamaño: [Tiempo_Steps, 768 dimensiones]
│   (768 es el "tamaño de representación" del modelo Base)
│
└── Contiene: Información esencial del audio
    ├─ Qué se dijo
    ├─ Cuándo se dijo
    ├─ Contexto del sonido
    └─ Patrones detectados

ANALOGÍA:
─────────
Es como un maestro de escuela que:
1. Lee un libro (Mel-Spectrogram)
2. Lo analiza profundamente
3. Extrae las ideas clave
4. Crea un resumen comprensible (vector de contexto)
```

**¿Qué es Multi-Head Attention?**
```
Imagina que tienes 8 amigos escuchando el audio.
Cada uno enfatiza en cosas diferentes:

Amigo 1: "Atiende al tono"
Amigo 2: "Atiende a la velocidad"
Amigo 3: "Atiende al volumen"
Amigo 4: "Atiende a la respiración"
Amigo 5: "Atiende al silencio"
Amigo 6: "Atiende a los consonantes"
Amigo 7: "Atiende a los vocales"
Amigo 8: "Atiende a los acentos"

Luego combinan sus observaciones
→ Comprensión más completa del audio

En Whisper: 12 heads (12 "amigos"), a veces más
```

### Paso 4: Decoder (Decodificador)

```
OBJETIVO:
─────────
Usando la representación del audio (del Encoder),
generar texto palabra por palabra.

PROCESO:
────────

Entrada: 
├─ Vector del Encoder (contexto del audio)
├─ Palabras generadas anteriormente
└─ Tokens especiales (inicio, fin, lenguaje)

    │
    ▼
┌──────────────────────────────────┐
│ Capas de Transformador Decoder   │ (típicamente 12 capas)
│ ┌─────────────────────────────┐ │
│ │ Layer 1                     │ │
│ │ • Self-Attention            │ │ ← Atiende a palabras anteriores
│ │ • Cross-Attention           │ │ ← Atiende al audio (Encoder)
│ │ • Feed-Forward Network      │ │
│ │ • Layer Normalization       │ │
│ └─────────────────────────────┘ │
│ ... (12 capas totales)         │
└──────────────┬──────────────────┘
               │
               ▼
    ┌──────────────────────────┐
    │ Linear Layer + Softmax   │
    │ ┌──────────────────────┐ │
    │ │ Proyectar a vocab    │ │
    │ │ (50k palabras aprox) │ │
    │ └──────────────────────┘ │
    │ ┌──────────────────────┐ │
    │ │ Calcular             │ │
    │ │ probabilidades       │ │
    │ │ (Softmax)            │ │
    │ └──────────────────────┘ │
    └──────────┬───────────────┘
               │
               ▼
    ┌──────────────────────────────┐
    │ Distribución de              │
    │ Probabilidades               │
    │                              │
    │ "hola": 0.001               │
    │ "quiero": 0.750  ← Máximo   │
    │ "café": 0.200                │
    │ "agua": 0.049                │
    │ ...                          │
    └──────────┬───────────────────┘
               │
               ▼
        ┌─────────────────┐
        │ SELECCIONAR     │
        │ palabra con     │
        │ máxima prob.    │
        │                 │
        │ → "quiero"      │
        └────────┬────────┘
                 │
                 ▼
        AGREGAR A RESULTADO

REPETIR hasta que:
• Se genere token [END] (fin)
• Se alcance máximo de tokens
```

**Ejemplo de Generación Iterativa:**

```
Iteración 1:
  Entrada Decoder: [<START>, Audio_Context]
  Salida: "Hola"
  Estado: "Hola"

Iteración 2:
  Entrada Decoder: [<START>, "Hola", Audio_Context]
  Salida: ","
  Estado: "Hola ,"

Iteración 3:
  Entrada Decoder: [<START>, "Hola", ",", Audio_Context]
  Salida: "quiero"
  Estado: "Hola, quiero"

Iteración 4:
  Entrada Decoder: [<START>, "Hola", ",", "quiero", Audio_Context]
  Salida: "un"
  Estado: "Hola, quiero un"

Iteración 5:
  Entrada Decoder: [...previas..., "un", Audio_Context]
  Salida: "café"
  Estado: "Hola, quiero un café"

Iteración 6:
  Entrada Decoder: [...previas..., "café", Audio_Context]
  Salida: "<END>"
  Estado: "Hola, quiero un café" ✓ LISTO
```

### Paso 5: Salida (Texto Final)

```
RESULTADO FINAL:
────────────────
"Hola, quiero un café"

METADATOS ADICIONALES:
─────────────────────
├─ Idioma detectado: Español
├─ Confianza: 0.95 (95%)
├─ Duración: 3.2 segundos
└─ Modelo usado: Base
```

---

## Componentes Técnicos

### Tokens (Tokenización)

```
¿QUÉ ES UN TOKEN?
─────────────────
Una unidad discreta que representa una palabra o subpalabra.

Whisper usa vocabulario de ~50,000 tokens

EJEMPLO:
Texto: "Hello, world!"

Tokenización:
├─ "Hello" → Token 1
├─ "," → Token 2
├─ "world" → Token 3
└─ "!" → Token 4

TOKENS ESPECIALES:
├─ <|startoftranscript|> → Inicio
├─ <|endoftext|> → Fin
├─ <|es|> → Español
├─ <|en|> → English
└─ <|transcribe|> → Modo transcripción
```

### Embedding (Representación Vectorial)

```
Cada palabra se convierte en un vector de números:

"hola" → [0.2, -0.5, 0.8, 0.1, -0.3, ...]
         │    │    │    │    │
         └─ 768 dimensiones (en modelo Base)

Propiedades:
• Palabras similares → vectores similares
• "rey" - "hombre" + "mujer" ≈ "reina" (matemáticamente)
```

### Layer Normalization

```
Normaliza los valores para mantenerlos estables.

Antes:  [1000, 500, 200, 5000]
                ↓ (inestable)
Después: [0.2, 0.1, 0.04, 0.8]
                ↓ (estable)

Importancia: Sin esto, números explotan a infinito
```

### Positional Encoding

```
¿PROBLEMA?
──────────
El Transformador NO tiene idea del orden temporal.
Todo se procesa en paralelo.

SOLUCIÓN:
─────────
Agregar información de posición:

Token 1 (inicio): suma +[1.0, 0, 1.0, 0, ...]
Token 2: suma +[0.8, 0.6, 0.8, 0.6, ...]
Token 3: suma +[0.6, 1.0, 0.6, 1.0, ...]
Token 4: suma +[0.4, 1.0, 0.4, 1.0, ...]

Usa funciones seno/coseno (sinusoidales)
Así el modelo sabe "Token 1 vino primero"
```

---

## Modelos Disponibles

### Comparativa Técnica

```
┌──────────┬──────────┬────────────┬──────────────┬─────────────┐
│ Modelo   │ Tamaño   │ Parámetros │ Tiempo (30s) │ Precisión   │
├──────────┼──────────┼────────────┼──────────────┼─────────────┤
│ Tiny     │ 75 MB    │ 39M        │ 0.3s         │ ⭐⭐        │
│ Base     │ 140 MB   │ 74M        │ 1s           │ ⭐⭐⭐      │
│ Small    │ 466 MB   │ 244M       │ 3s           │ ⭐⭐⭐⭐    │
│ Medium   │ 1.5 GB   │ 769M       │ 10s          │ ⭐⭐⭐⭐⭐  │
│ Large    │ 2.9 GB   │ 1.5B       │ 25s          │ ⭐⭐⭐⭐⭐  │
└──────────┴──────────┴────────────┴──────────────┴─────────────┘

Relación tamaño vs capacidad:
Small = 3.3x más parámetros que Base
Medium = 10x más parámetros que Base
Large = 20x más parámetros que Base
```

### ¿Cuándo usar cada uno?

```
TINY (75 MB):
✅ Dispositivos muy limitados
✅ Transcripción rápida en tiempo real
❌ Poca precisión con ruido
❌ Acentos complicados

BASE (140 MB): ← TU APP ACTUAL
✅ Balance óptimo velocidad/precisión
✅ Bajo consumo de recursos
✅ Bueno para español
⚠️ Problemas con ruido fuerte

SMALL (466 MB): ← RECOMENDADO PARA RUIDO
✅ Mejor manejo de ruido
✅ Mejor con acentos
✅ Mejor precisión general
⚠️ Más lento

MEDIUM (1.5 GB):
✅ Muy buena precisión
✅ Excelente con ruido y acentos
❌ Lento
❌ Consume mucha RAM

LARGE (2.9 GB):
✅ Máxima precisión
✅ Multilingüe perfecto
❌ Muy lento
❌ Requiere GPU
```

---

## Capacidades y Limitaciones

### ✅ Capacidades Demostradas

```
TRANSCRIPCIÓN:
──────────────
• 99 idiomas (incluyendo español)
• Audio con ruido moderado
• Acentos regionales
• Múltiples hablantes (con limitaciones)
• Audio profesional y amateur
• Transcripción automática de pausas y puntuación

ROBUSTEZ:
─────────
• Entrenado en 680k horas (datos reales)
• Maneja ruido de fondo
• Funciona offline (una vez cargado)
• No requiere GPU (funciona en CPU)

VELOCIDAD:
──────────
• Base: 1 segundo de audio en 0.1-0.5s
• Small: 1 segundo de audio en 0.3-1s
• Escalable paralelamente
```

### ❌ Limitaciones

```
NO HACE:
────────
• Traducción (solo transcripción)
• Comprensión de significado
• Identificación de speaker
• Síntesis de voz
• Compresión de audio
• Procesamiento en tiempo real (streaming no nativo)

CON DIFICULTAD:
───────────────
• Audio muy ruidoso (>70 dB)
• Múltiples voces simultáneas
• Letra de canciones (confunde palabras)
• Números y códigos (puede fallar)
• Vocabulario muy técnico
• Acentos muy marcados (mejor con Medium/Large)

PRECISIÓN:
──────────
• Errores típicos: 5-10% con audio limpio
• Errores con ruido: 15-30%+
• Hallucina palabras ocasionalmente
```

### Errores Comunes

```
ALUCINAR (Hallucination):
Modelo inventa palabras/frases que no se dijeron
Causa: Confianza en patrón incorrecto

Ejemplo:
Audio: [silencio de 3 segundos]
Output: "Hola, gracias por usar nuestro servicio"
↑ Inventado completamente

CONFUNDIR IDIOMAS:
Si mezclas español/inglés, puede confundirse

PERDER PUNTUACIÓN:
Algunos modelos no agregan puntos/comas bien
```

---

## Cómo se Usa en Tu App

### Flujo Completo en Tu Gestor IA

```
┌─────────────────────────────────────────────────────────┐
│                  TU APP (Flujo Completo)                │
└─────────────────────────────────────────────────────────┘

USUARIO PRESIONA 🎤
    │
    ▼
INICIA GRABACIÓN (Record)
├─ Formato: WAV
├─ Sample Rate: 16000 Hz
├─ Duración: Variable (hasta 2 minutos)
└─ Ubicación: /cache/recordings/recording_*.wav

USUARIO PRESIONA 🎤 (DETENER)
    │
    ▼
DETIENE GRABACIÓN
    │
    ▼
WHISPER TRANSCRIBE (Tu Modelo Seleccionado)

    ┌─────────────────────────────────────┐
    │  WHISPER PROCESA                    │
    │  1. Mel-Spectrogram                 │
    │  2. Encoder (12 capas)              │
    │  3. Decoder (genera tokens)         │
    │  4. Convierte tokens → palabras     │
    └──────────────┬──────────────────────┘
                   │
                   ▼
    ✅ TRANSCRIPCIÓN EN ESPAÑOL
    "Hola, quiero un café"
    
    │
    ▼
AUTO-LLENA PROMPT
├─ El texto aparece en el campo de entrada
└─ Usuario puede editar si es necesario

    │
    ▼
QWEN PROCESA
├─ Entiende la intención
├─ Genera respuesta
└─ Ejecuta acciones

    │
    ▼
RESULTADO FINAL
├─ Texto en chat
├─ Acciones ejecutadas
└─ Respuesta del sistema
```

### Configuración Actual

```
WHISPER_MODEL = Base
WHISPER_DEFAULT_LANGUAGE = auto
WHISPER_ENABLE_REALTIME = false
WHISPER_ENABLE_TIMESTAMPS = false

EN TU APP:
├─ Puedes cambiar modelo en ⚙️ (Settings)
├─ Puedes seleccionar idioma
├─ Puedes activar tiempo real (cuando esté implementado)
└─ Puedes cargar modelo desde dispositivo
```

### Performance en Tu Dispositivo

```
ESTIMACIONES (Basado en Modelo Base):

Audio de 10 segundos:
├─ Carga modelo: 2-3 segundos (primera vez)
├─ Transcripción: 1-2 segundos
└─ Total: 3-5 segundos

Audio de 30 segundos:
├─ Carga modelo: 2-3 segundos (primera vez)
├─ Transcripción: 3-5 segundos
└─ Total: 5-8 segundos

Memoria:
├─ Modelo Base en RAM: ~500-800 MB
├─ Procesamiento: +300-500 MB
└─ Total: ~1 GB aprox

Batería:
├─ Descarga: ~10-20% por minuto de uso
└─ Recomendación: Usar Small para ahorrar
```

---

## Resumen Visual: Analogía Final

```
WHISPER es como un MÉDICO:

1. ESCUCHA (Encoder)
   └─ Analiza síntomas detalladamente
   └─ Extrae información importante
   └─ Crea diagnóstico mental

2. PIENSA (Contexto)
   └─ Recuerda similares casos
   └─ Considera posibilidades
   └─ Calcula probabilidades

3. ESCRIBE (Decoder)
   └─ Escribe diagnóstico palabra por palabra
   └─ Considera lo que ya escribió
   └─ Completa la receta

RESULTADO: Diagnóstico (Texto)

Lo especial de Whisper:
• Fue entrenado con MUCHOS casos reales
• Por eso funciona bien en "clínicas" ruidosas
• Y no solo en "quirófanos" silenciosos
```

---

## Fuentes Técnicas

- **Paper Original:** https://arxiv.org/abs/2212.04356
- **Repositorio GitHub:** https://github.com/openai/whisper
- **Versión GGML:** https://github.com/ggerganov/whisper.cpp
- **Documentación OpenAI:** https://platform.openai.com/docs/guides/speech-to-text

---

**Fecha de Creación:** 2024  
**Última Actualización:** 2024  
**Versión:** 1.0
