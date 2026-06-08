# 🤖 Gestor de Ventas IA

Sistema inteligente de gestión de ventas que convierte prompts en lenguaje natural a acciones en el backend mediante un modelo Qwen GGUF ejecutado localmente en Android.

---

## 📋 Descripción

Esta aplicación Flutter permite a los usuarios:
- **Escribir prompts naturales** como: `"creame una venta para maria con 2 zapatos y 3 poleras"`
- **El modelo Qwen entiende automáticamente** qué acción realizar (crear venta, listar clientes, etc.)
- **Genera JSON estructurado** compatible con el backend
- **Ejecuta acciones** contra los endpoints del API

**Ejemplo de flujo:**
```
Usuario: "listame todos los clientes"
         ↓
Modelo Qwen detecta: action = "list_clients"
         ↓
API ejecuta: GET /clientes
         ↓
Resultados mostrados en la UI
```

---

## ✨ Características Principales

✅ **Intent Detection automático** - El modelo entiende la intención del usuario  
✅ **Autenticación automática** - Login con credenciales del `.env`  
✅ **Múltiples acciones soportadas:**
- 🛍️ Crear/Listar ventas
- 👥 Crear/Listar clientes
- 📦 Crear/Listar productos
- 🚚 Crear/Listar compras
- 🤝 Crear/Listar proveedores
- 👤 Crear/Listar usuarios

✅ **Model caching** - Reutiliza el modelo cargado  
✅ **File picker integrado** - Selecciona el archivo GGUF desde el dispositivo  
✅ **Configuración por .env** - URLs y credenciales desde archivo de entorno  
✅ **Logs en tiempo real** - Visualiza cada paso del procesamiento  

---

## 🏗️ Arquitectura

### Servicios principales:

**`ApiService`** (Singleton)
- Maneja autenticación con JWT
- Realiza requests HTTP al backend
- Soporta GET, POST, PUT, DELETE
- Maneja tanto responses Map como List

**`ActionService`** (Singleton)
- Carga el modelo Qwen GGUF
- Procesa prompts naturales con el modelo
- Detecta intención y genera JSON
- Orquesta la ejecución de acciones

**`main.dart`**
- `LoginPage`: Autenticación automática
- `GestorPage`: UI principal con file picker y procesamiento de prompts

---

## 🛠️ Tecnologías Utilizadas

### Backend
- **Express.js** - API REST
- **TypeScript** - Type safety
- **Prisma** - ORM para base de datos
- **JWT** - Autenticación

### Frontend (Mobile)
- **Flutter** - Framework multiplataforma
- **Dart** - Lenguaje de programación
- **llamadart** ^0.7.2 - Inference local de modelos GGUF
- **file_picker** ^10.0.0 - Selector de archivos
- **http** ^1.1.0 - Cliente HTTP
- **flutter_dotenv** ^5.1.0 - Variables de entorno

### Modelo IA
- **Qwen 2.5 1.5B** - Modelo cuantizado (Q4_K_M)
- **Tamaño:** ~1GB
- **Parámetros:** 1.5 billones

---

## 📦 Instalación

### Requisitos previos
- Flutter 3.12+
- Dart 3.12+
- Android SDK (API 36+)
- NDK (instalado automáticamente)
- Archivo modelo: `qwen2.5-1.5b-instruct-q4_k_m.gguf` (~1GB)

### Pasos

1. **Clonar/Descargar el proyecto**
```bash
cd gestor_ia
```

2. **Configurar variables de entorno**
Editar `.env`:
```env
BUSINESS_API_URL=http://192.168.100.24:9090
DEFAULT_LOGIN_USER=admin
DEFAULT_LOGIN_PASSWORD=Admin123!
```

3. **Instalar dependencias**
```bash
flutter pub get
```

4. **Compilar APK**
```bash
flutter build apk --release
```

5. **Instalar en dispositivo**
```bash
flutter install
```

---

## 🚀 Uso

### Inicio de la app

1. La app intenta login automático con las credenciales del `.env`
2. Si es exitoso, muestra la pantalla principal
3. Usuario hace clic en **"Explorar"** para seleccionar el modelo GGUF
4. Una vez cargado el modelo, puede escribir prompts naturales

### Ejemplos de prompts

**Crear venta:**
```
"creame una venta para maria con 2 zapatos nike y 4 poleras polo"
"registrame una venta a juan con 3 camisetas y 2 pantalones"
```

**Listar datos:**
```
"listame todos los clientes"
"dame la lista de productos"
"muestra las compras"
```

**Crear cliente:**
```
"creame un cliente llamado carlos con cedula 12345678 y telefono 04121234567"
```

**Crear proveedor:**
```
"creame un proveedor llamado acme inc con email acme@example.com"
```

---

## 🔧 Configuración del Modelo

Las configuraciones del modelo Qwen están en `lib/services/action_service.dart`:

```dart
contextParams.nCtx = 512;        // Tamaño del contexto
contextParams.nPredict = 256;    // Tokens máximos
samplerParams.temp = 0.7;        // Creatividad (0.3-1.0)
samplerParams.topK = 40;         // Top-K sampling
samplerParams.topP = 0.9;        // Top-P sampling
```

**Recomendaciones:**
- `temp = 0.3-0.5` para respuestas más deterministas (JSON)
- `nPredict = 256` es suficiente para JSON estructurado
- No modificar sin probar primero

---

## 📡 Endpoints Soportados

| Acción | Método | Endpoint |
|--------|--------|----------|
| Listar ventas | GET | `/ventas` |
| Crear venta | POST | `/ventas` |
| Listar clientes | GET | `/clientes` |
| Crear cliente | POST | `/clientes` |
| Listar productos | GET | `/productos` |
| Crear producto | POST | `/productos` |
| Listar proveedores | GET | `/proveedores` |
| Crear proveedor | POST | `/proveedores` |
| Listar compras | GET | `/compras` |
| Crear compra | POST | `/compras` |
| Listar usuarios | GET | `/usuarios` |
| Crear usuario | POST | `/usuarios` |

---

## 🎯 Flujo de Procesamiento

```
┌─────────────────────────────────┐
│   Usuario escribe prompt         │
│   "creame una venta para maria"  │
└──────────────┬──────────────────┘
               │
               ▼
┌─────────────────────────────────┐
│   Sistema Prompt (instrucciones) │
│   al modelo Qwen                │
└──────────────┬──────────────────┘
               │
               ▼
┌─────────────────────────────────┐
│   Modelo genera JSON:            │
│   {                             │
│     "action": "create_sale",    │
│     "data": { ... }             │
│   }                             │
└──────────────┬──────────────────┘
               │
               ▼
┌─────────────────────────────────┐
│   ActionService ejecuta acción   │
│   POST /ventas con datos         │
└──────────────┬──────────────────┘
               │
               ▼
┌─────────────────────────────────┐
│   Resultado mostrado en UI       │
│   con logs de cada paso          │
└─────────────────────────────────┘
```

---

## 🐛 Troubleshooting

### "Endpoint no encontrado"
- Verificar que `BUSINESS_API_URL` en `.env` es correcto
- Los endpoints no llevan prefijo `/api`

### "No autenticado"
- Verificar credenciales en `.env`
- Revisar que el backend está corriendo
- Checar logs de autenticación

### "No se encontró JSON en la respuesta"
- El modelo no generó JSON válido
- Probar con un prompt más claro
- Revisar los logs del modelo

### "Modelo se tranca"
- Reducir `nPredict` (max tokens)
- Usar `temp = 0.3` para respuestas más rápidas
- Verificar que el dispositivo tiene suficiente RAM

---

## 📝 Notas de Desarrollo

### Arquitectura de singletons
- `ApiService` es singleton → comparte token entre LoginPage y ActionService
- `ActionService` es singleton → reutiliza el modelo en memoria

### Manejo de respuestas
- Algunos endpoints devuelven `[...]` (array directo)
- Otros devuelven `{...}` (Map)
- `request()` normaliza a Map con clave "data"

### Intent Detection
El sistema prompt en `ActionService._buildSystemPrompt()` define:
- Acciones disponibles
- Formato de respuesta esperado
- Mapeos de campos para cada acción

---

## 🚧 Trabajo Futuro

- [ ] Implementar endpoints de `product_movements` y `product_stocks`
- [ ] Agregar Grammar constraints para JSON más robusto
- [ ] Soporte para múltiples idiomas
- [ ] Caché de respuestas frecentes
- [ ] Interfaz de configuración de parámetros del modelo
- [ ] Exportar resultados a CSV/PDF
- [ ] Modo offline con sincronización

---

## 📄 Licencia

Proyecto personal - Todos los derechos reservados.

---

## 👨‍💻 Autor

Desarrollado como sistema IA inteligente para gestión de ventas.

**Fecha:** Junio 2026

---

## 📞 Soporte

Para reportar problemas o sugerencias:
- Revisar logs en la UI (sección "Logs")
- Verificar que el backend está corriendo
- Comprobar conectividad de red
- Usar prompts claros y específicos

---

**¡Gracias por usar Gestor de Ventas IA!** 🚀
