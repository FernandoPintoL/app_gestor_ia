# Refactorización con Provider - Guía de Arquitectura

## ¿Qué cambió?

Tu proyecto ha sido refactorizado usando **Provider** para una mejor organización del código, similar a la arquitectura React.

## Estructura de Carpetas

```
lib/
├── main.dart                 # Punto de entrada - Configura MultiProvider
├── services/                 # Servicios (sin cambios)
│   ├── api_service.dart
│   ├── action_service.dart
│   └── qwen_service.dart
├── providers/                # NUEVO: Gestión de estado centralizada
│   ├── auth_provider.dart    # Estado de autenticación
│   ├── model_provider.dart   # Estado del modelo GGUF
│   └── app_state_provider.dart # Estado general de la app
└── pages/                    # NUEVO: Páginas refactorizadas
    ├── login_page.dart       # Página de login
    └── gestor_page.dart      # Página principal
```

## Ventajas de esta Arquitectura

### 1. **Separación de Responsabilidades**
- **Services**: Lógica de negocio (API, modelos IA)
- **Providers**: Gestión de estado (ChangeNotifier)
- **Pages**: UI (widgets)

### 2. **Código más Limpio**
Antes:
```dart
setState(() {
  _isLoading = true;
  _modelPath = path;
  _log = '$_log\nmessage';
});
```

Ahora:
```dart
context.read<ModelProvider>().loadModel(path);
```

### 3. **Estado Centralizado**
Todo el estado está en un solo lugar, facilitando:
- **Testing**: Fácil de mockear providers
- **Debug**: Inspeccionar estado en tiempo real
- **Reutilización**: Compartir estado entre páginas

## Cómo Usar los Providers

### Leer Estado (Consumer)
```dart
Consumer<ModelProvider>(
  builder: (context, modelProvider, _) {
    return Text('Modelo listo: ${modelProvider.isModelReady}');
  },
)
```

### Modificar Estado (context.read)
```dart
ElevatedButton(
  onPressed: () => context.read<ModelProvider>().loadModel(path),
  child: Text('Cargar'),
)
```

### Acceder en initState
```dart
Future.microtask(() {
  context.read<ModelProvider>().checkSavedModel();
});
```

## Los Tres Providers

### 1. **AuthProvider** (`auth_provider.dart`)
Gestiona:
- `isAuthenticated`: ¿Está el usuario autenticado?
- `isLoading`: ¿Se está autenticando?
- `error`: Mensaje de error
- `token`, `userId`: Datos del usuario

Métodos:
- `login(user, password)`: Realizar login
- `logout()`: Cerrar sesión

### 2. **ModelProvider** (`model_provider.dart`)
Gestiona:
- `isModelLoading`: ¿Se está cargando el modelo?
- `isModelReady`: ¿Está listo para usar?
- `modelPath`: Ruta del archivo .gguf
- `logs`: Mensajes de log

Métodos:
- `checkSavedModel()`: Verificar modelo guardado
- `loadModel(path)`: Cargar nuevo modelo

### 3. **AppStateProvider** (`app_state_provider.dart`)
Gestiona:
- `isProcessing`: ¿Se está procesando un prompt?
- `result`: Resultado de la última acción
- `logs`: Mensajes de log del procesamiento

Métodos:
- `processPrompt(prompt)`: Procesar solicitud natural

## Migración a Whisper

Para agregar **Whisper** (transcripción de voz), solo necesitas:

1. **Crear un nuevo provider**:
```dart
class WhisperProvider extends ChangeNotifier {
  bool _isListening = false;
  String? _transcription;
  
  Future<void> startListening() async {
    // Implementación
  }
}
```

2. **Registrarlo en main.dart**:
```dart
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => WhisperProvider()),
    // ... otros providers
  ],
)
```

3. **Usarlo en la UI**:
```dart
Consumer<WhisperProvider>(
  builder: (context, whisper, _) {
    return ElevatedButton(
      onPressed: whisper.isListening 
        ? null 
        : () => context.read<WhisperProvider>().startListening(),
      child: Text(whisper.isListening ? 'Escuchando...' : 'Grabar'),
    );
  },
)
```

## Siguientes Pasos

1. **Ejecutar `flutter pub get`** para descargar Provider
2. **Prueba la app** para verificar que todo funcione igual
3. **Agregar Whisper** siguiendo el patrón anterior
4. **Agregar speech_to_text** o similar para transcripción

## Ventajas para Whisper

Con esta arquitectura, Whisper será:
- **Fácil de agregar**: Solo un nuevo provider
- **Independiente**: Sin afectar otros providers
- **Reutilizable**: Desde cualquier página
- **Testeable**: Mock del provider para tests

## Debugging

Para ver el estado actual:
```dart
// En cualquier parte del código
print('Auth: ${context.read<AuthProvider>().isAuthenticated}');
print('Model ready: ${context.read<ModelProvider>().isModelReady}');
```

¡Ahora tu código es más organizado y listo para escalabilidad! 🎉
