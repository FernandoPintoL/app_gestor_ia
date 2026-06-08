# 📊 Entidades del Backend - GestorVentas API

## Descripción General

**GestorVentas API** es un backend serverless desarrollado en **Node.js + Express + TypeScript** con **Prisma ORM** y **PostgreSQL**. Gestiona un sistema completo de ventas, compras, productos, almacenes y clientes.

**Tecnologías principales:**
- Node.js + Express
- TypeScript
- Prisma ORM
- PostgreSQL
- JWT para autenticación
- Zod para validaciones

---

## 🏗️ Diagrama de Entidades

```
┌─────────────────────────────────────────────────────────────┐
│                      COMPANY (Empresa)                       │
│ • id, name, email, phone, address, city                     │
└──────────────┬──────────────┬──────────────┬────────────────┘
               │              │              │
        ┌──────▼──┐    ┌──────▼──┐    ┌─────▼────┐
        │   USER  │    │ CLIENT  │    │ SUPPLIER │
        └─────────┘    └─────────┘    └──────────┘
        │
        └──► PersonalAccessToken


PRODUCTS (Catálogo)
┌────────────────────────┐
│       CATEGORY         │
│ • id, name             │
└───────────┬────────────┘
            │
      ┌─────▼──────┐
      │   PRODUCT  │
      │ • id, name │
      └─────┬──────┘
            │
    ┌───────┼───────┬──────────┐
    │       │       │          │
┌───▼──┐ ┌──▼──┐ ┌─▼────┐ ┌──▼──────────┐
│STOCK │ │PURCH│ │SALES │ │ProductMove. │
└──────┘ └─────┘ └──────┘ └─────────────┘


WAREHOUSE (Almacén)
┌──────────────────────────────────┐
│ • id, name                        │
└───────────┬──────────────────────┘
            │
    ┌───────┼──────────┐
    │       │          │
┌───▼──┐ ┌──▼──────┐
│STOCK │ │Movements│
└──────┘ └─────────┘


COMPRAS & VENTAS
┌──────────────┐      ┌────────────┐
│   PURCHASE   │      │    SALE    │
│ • id, number │      │ • id,number│
└──────┬───────┘      └────┬───────┘
       │                   │
    ┌──▼────────┐    ┌─────▼────┐
    │PurchaseItem    │ SaleItem  │
    └────────────┘   └──────────┘
```

---

## 📋 Entidades Detalladas

### 1. **COMPANY** (Empresas/Tenants)
Representa las empresas que usan el sistema (multi-tenancy).

| Campo | Tipo | Descripción |
|-------|------|-------------|
| `id` | Int (PK) | ID único de la empresa |
| `name` | String | Nombre de la empresa |
| `email` | String? | Email de contacto |
| `phone` | String? | Teléfono principal |
| `address` | String? | Dirección |
| `city` | String? | Ciudad |
| `active` | Boolean | Estado activo/inactivo (default: true) |
| `created_at` | DateTime | Fecha de creación |
| `updated_at` | DateTime | Fecha última actualización |

**Relaciones:**
- `users[]` → Usuarios de la empresa
- `clients[]` → Clientes de la empresa
- `suppliers[]` → Proveedores de la empresa
- `products[]` → Productos disponibles (via ProductCompany)

**Casos de uso:**
- Separar datos por empresa (multi-tenancy)
- Auditoría y reportes por empresa

---

### 2. **USER** (Usuarios)
Usuarios del sistema con control de acceso.

| Campo | Tipo | Descripción |
|-------|------|-------------|
| `id` | Int (PK) | ID único |
| `empresa_id` | Int (FK) | Empresa a la que pertenece |
| `name` | String | Nombre completo |
| `usernick` | String? | Username único |
| `email` | String? | Email único |
| `password` | String | Contraseña hasheada |
| `activo` | Boolean | Usuario activo/inactivo (default: true) |
| `roles[]` | String[] | Array de roles (ej: ["admin", "vendedor"]) |
| `permisos[]` | String[] | Array de permisos |
| `can_access_web` | Boolean | Acceso a web (default: true) |
| `can_access_mobile` | Boolean | Acceso a móvil (default: true) |
| `created_at` | DateTime | Fecha creación |
| `updated_at` | DateTime | Fecha actualización |

**Relaciones:**
- `company` → Empresa a la que pertenece
- `tokens[]` → Tokens de acceso personal

**Casos de uso:**
- Autenticación y autorización
- Control de permisos y roles
- Acceso multi-dispositivo (web/móvil)

---

### 3. **PERSONALACCESSTOKEN** (Tokens de Acceso)
Tokens para acceso a API (similar a API keys).

| Campo | Tipo | Descripción |
|-------|------|-------------|
| `id` | BigInt (PK) | ID único |
| `tokenable_id` | Int (FK) | Usuario propietario |
| `name` | String | Nombre del token (ej: "Mobile App", "API Integration") |
| `token` | String | Token único y encriptado |
| `last_used_at` | DateTime? | Último uso |
| `expires_at` | DateTime? | Fecha expiración |
| `created_at` | DateTime | Creación |
| `updated_at` | DateTime | Actualización |

**Relaciones:**
- `user` → Usuario propietario (ON DELETE: Cascade)

**Casos de uso:**
- Acceso por API key
- Integración con aplicaciones móviles
- Auditoría de último uso

---

### 4. **CLIENT** (Clientes)
Clientes que compran productos.

| Campo | Tipo | Descripción |
|-------|------|-------------|
| `id` | Int (PK) | ID único |
| `empresa_id` | Int (FK) | Empresa propietaria |
| `name` | String | Nombre del cliente |
| `ci` | String | Cédula de identidad |
| `phone` | String? | Teléfono de contacto |
| `created_at` | DateTime | Creación |
| `updated_at` | DateTime | Actualización |

**Relaciones:**
- `company` → Empresa propietaria (ON DELETE: Cascade)

**Casos de uso:**
- Registro de clientes para ventas
- Identificación por CI
- Contacto directo

---

### 5. **SUPPLIER** (Proveedores)
Proveedores de productos.

| Campo | Tipo | Descripción |
|-------|------|-------------|
| `id` | Int (PK) | ID único |
| `empresa_id` | Int (FK) | Empresa propietaria |
| `name` | String | Nombre del proveedor |
| `email` | String? | Email |
| `phone` | String? | Teléfono |
| `address` | String? | Dirección |
| `city` | String? | Ciudad |
| `created_at` | DateTime | Creación |
| `updated_at` | DateTime | Actualización |

**Relaciones:**
- `company` → Empresa propietaria (ON DELETE: Cascade)

**Casos de uso:**
- Gestión de proveedores
- Contacto para reabastecimiento
- Localización geográfica

---

### 6. **CATEGORY** (Categorías de Productos)
Categorización de productos en el catálogo.

| Campo | Tipo | Descripción |
|-------|------|-------------|
| `id` | Int (PK) | ID único |
| `name` | String | Nombre de la categoría |
| `created_at` | DateTime | Creación |
| `updated_at` | DateTime | Actualización |

**Relaciones:**
- `products[]` → Productos en esta categoría (ON DELETE: Cascade)

**Casos de uso:**
- Clasificación de productos
- Búsqueda y filtrado por categoría
- Reportes por línea de negocio

---

### 7. **PRODUCT** (Productos)
Productos del catálogo disponibles para venta/compra.

| Campo | Tipo | Descripción |
|-------|------|-------------|
| `id` | Int (PK) | ID único |
| `category_id` | Int (FK) | Categoría a la que pertenece |
| `name` | String | Nombre del producto |
| `codigo` | String | Código interno único |
| `codigo_barra` | String? | Código de barras (UPC/EAN) |
| `precio_compra` | Decimal | Precio unitario de compra |
| `precio_venta` | Decimal | Precio unitario de venta |
| `created_at` | DateTime | Creación |
| `updated_at` | DateTime | Actualización |

**Relaciones:**
- `category` → Categoría (ON DELETE: Cascade)
- `companies[]` → Empresas que venden este producto (via ProductCompany)
- `stocks[]` → Stock en almacenes
- `purchases[]` → Compras de este producto
- `sales[]` → Ventas de este producto
- `movements[]` → Movimientos de inventario

**Casos de uso:**
- Catálogo centralizado
- Margen de ganancia (venta - compra)
- Código de barras para escaneo
- Trazabilidad en movimientos

---

### 8. **PRODUCTCOMPANY** (Productos por Empresa)
Relación muchos-a-muchos: productos disponibles para cada empresa.

| Campo | Tipo | Descripción |
|-------|------|-------------|
| `id` | Int (PK) | ID único |
| `product_id` | Int (FK) | Producto |
| `empresa_id` | Int (FK) | Empresa |
| `created_at` | DateTime | Creación |
| `updated_at` | DateTime | Actualización |

**Constrains:**
- `UNIQUE(product_id, empresa_id)` - Cada empresa tiene cada producto una sola vez

**Relaciones:**
- `product` → Producto (ON DELETE: Cascade)
- `company` → Empresa (ON DELETE: Cascade)

**Casos de uso:**
- Cada empresa decide qué productos vender
- Catálogo centralizado pero con acceso granular
- Auditoría de qué empresa usa qué productos

---

### 9. **WAREHOUSE** (Almacenes)
Ubicaciones físicas de almacenamiento.

| Campo | Tipo | Descripción |
|-------|------|-------------|
| `id` | Int (PK) | ID único |
| `name` | String | Nombre del almacén |
| `created_at` | DateTime | Creación |
| `updated_at` | DateTime | Actualización |

**Relaciones:**
- `stocks[]` → Stock de productos en este almacén
- `movements[]` → Movimientos de inventario

**Casos de uso:**
- Múltiples ubicaciones de almacenamiento
- Distribución geográfica
- Trazabilidad de ubicación

---

### 10. **PRODUCTSTOCK** (Stock de Productos)
Stock actual de cada producto en cada almacén.

| Campo | Tipo | Descripción |
|-------|------|-------------|
| `id` | Int (PK) | ID único |
| `product_id` | Int (FK) | Producto |
| `warehouse_id` | Int (FK) | Almacén |
| `quantity` | Int | Cantidad disponible (default: 0) |
| `created_at` | DateTime | Creación |
| `updated_at` | DateTime | Actualización |

**Constrains:**
- `UNIQUE(product_id, warehouse_id)` - Un registro por producto-almacén

**Relaciones:**
- `product` → Producto (ON DELETE: Cascade)
- `warehouse` → Almacén (ON DELETE: Cascade)

**Casos de uso:**
- Inventario por almacén
- Alertas de bajo stock
- Ubicación de productos
- Consulta rápida de disponibilidad

---

### 11. **PURCHASE** (Compras a Proveedores)
Órdenes de compra realizadas a proveedores.

| Campo | Tipo | Descripción |
|-------|------|-------------|
| `id` | Int (PK) | ID único |
| `empresa_id` | Int (FK) | Empresa que compra |
| `supplier_id` | Int (FK) | Proveedor |
| `purchase_number` | String? | Número de comprobante |
| `total` | Decimal | Total de la compra (default: 0) |
| `purchase_date` | DateTime | Fecha de la compra (default: now) |
| `observations` | String? | Notas adicionales |
| `created_at` | DateTime | Creación |
| `updated_at` | DateTime | Actualización |

**Relaciones:**
- `items[]` → Items/líneas de la compra
- `movements[]` → Movimientos de inventario asociados

**Casos de uso:**
- Registro de compras
- Control de gastos
- Historial por proveedor
- Auditoría de entradas

---

### 12. **PURCHASEITEM** (Ítems de Compra)
Líneas individuales dentro de una compra.

| Campo | Tipo | Descripción |
|-------|------|-------------|
| `id` | Int (PK) | ID único |
| `purchase_id` | Int (FK) | Compra padre |
| `product_id` | Int (FK) | Producto comprado |
| `quantity` | Int | Cantidad comprada |
| `unit_price` | Decimal | Precio unitario |
| `subtotal` | Decimal | Total línea (quantity × unit_price) |
| `created_at` | DateTime | Creación |
| `updated_at` | DateTime | Actualización |

**Relaciones:**
- `purchase` → Compra padre (ON DELETE: Cascade)
- `product` → Producto (ON DELETE: Cascade)

**Casos de uso:**
- Detalles de cada compra
- Cálculo de costos
- Reportes de volumen por producto

---

### 13. **SALE** (Ventas a Clientes)
Órdenes de venta realizadas a clientes.

| Campo | Tipo | Descripción |
|-------|------|-------------|
| `id` | Int (PK) | ID único |
| `empresa_id` | Int (FK) | Empresa vendedora |
| `client_id` | Int (FK) | Cliente comprador |
| `sale_number` | String? | Número de comprobante |
| `total` | Decimal | Total de la venta (default: 0) |
| `sale_date` | DateTime | Fecha de la venta (default: now) |
| `observations` | String? | Notas adicionales |
| `created_at` | DateTime | Creación |
| `updated_at` | DateTime | Actualización |

**Relaciones:**
- `items[]` → Ítems/líneas de la venta
- `movements[]` → Movimientos de inventario asociados

**Casos de uso:**
- Registro de ventas
- Facturación
- Historial por cliente
- Auditoría de salidas
- Cálculo de ingresos

---

### 14. **SALEITEM** (Ítems de Venta)
Líneas individuales dentro de una venta.

| Campo | Tipo | Descripción |
|-------|------|-------------|
| `id` | Int (PK) | ID único |
| `sale_id` | Int (FK) | Venta padre |
| `product_id` | Int (FK) | Producto vendido |
| `quantity` | Int | Cantidad vendida |
| `unit_price` | Decimal | Precio unitario vendido |
| `subtotal` | Decimal | Total línea |
| `created_at` | DateTime | Creación |
| `updated_at` | DateTime | Actualización |

**Relaciones:**
- `sale` → Venta padre (ON DELETE: Cascade)
- `product` → Producto (ON DELETE: Cascade)

**Casos de uso:**
- Detalles de cada venta
- Cálculo de ingresos por producto
- Reportes de volumen vendido

---

### 15. **PRODUCTMOVEMENT** (Movimientos de Inventario)
Trazabilidad de cada movimiento de producto en el almacén.

| Campo | Tipo | Descripción |
|-------|------|-------------|
| `id` | Int (PK) | ID único |
| `product_id` | Int (FK) | Producto movido |
| `warehouse_id` | Int (FK) | Almacén |
| `type` | String | Tipo: "entrada", "salida", "ajuste" |
| `quantity` | Int | Cantidad movida |
| `purchase_id` | Int? (FK) | Compra origen (si aplica) |
| `sale_id` | Int? (FK) | Venta origen (si aplica) |
| `created_at` | DateTime | Creación |
| `updated_at` | DateTime | Actualización |

**Relaciones:**
- `product` → Producto (ON DELETE: Cascade)
- `warehouse` → Almacén (ON DELETE: Cascade)
- `purchase` → Compra origen (ON DELETE: SetNull)
- `sale` → Venta origen (ON DELETE: SetNull)

**Casos de uso:**
- Auditoría completa de movimientos
- Tipos de movimiento: 
  - **"entrada"** = llegada de compra
  - **"salida"** = despacho de venta
  - **"ajuste"** = pérdidas, daños, ajustes manuales
- Trazabilidad de origen (compra/venta)
- Reportes de movimiento por período

---

## 🔗 Relaciones Clave

### Multi-tenancy (Aislamiento por Empresa)
```
Company
  ├─ User (cada usuario pertenece a 1 empresa)
  ├─ Client (clientes de la empresa)
  ├─ Supplier (proveedores de la empresa)
  ├─ Purchase (compras de la empresa)
  └─ Sale (ventas de la empresa)
```

### Catálogo de Productos
```
Category
  └─ Product
      ├─ ProductCompany (qué empresas pueden vender)
      ├─ ProductStock (stock en almacenes)
      ├─ PurchaseItem (en compras)
      ├─ SaleItem (en ventas)
      └─ ProductMovement (historial de movimientos)
```

### Transacciones
```
Purchase ──→ PurchaseItem ──→ Product
   │                           └─→ ProductMovement ("entrada")
   └─→ ProductMovement (origen compra)

Sale ──→ SaleItem ──→ Product
  │                   └─→ ProductMovement ("salida")
  └─→ ProductMovement (origen venta)
```

---

## 📊 Flujos de Negocio Principales

### 1. **Flujo de Compra**
```
1. Crear Purchase (empresa_id, supplier_id)
2. Agregar PurchaseItem(s) con product_id, quantity, unit_price
3. Actualizar Purchase.total = SUM(PurchaseItem.subtotal)
4. Crear ProductMovement("entrada") para cada item
5. Actualizar ProductStock (incrementar cantidad)
```

### 2. **Flujo de Venta**
```
1. Crear Sale (empresa_id, client_id)
2. Agregar SaleItem(s) con product_id, quantity, unit_price
3. Actualizar Sale.total = SUM(SaleItem.subtotal)
4. Crear ProductMovement("salida") para cada item
5. Actualizar ProductStock (decrementar cantidad)
6. Validar que hay suficiente stock
```

### 3. **Gestión de Stock**
```
- ProductStock: stock actual por almacén
- ProductMovement: historial completo de cambios
- Queries: stock por producto, por almacén, por período
```

### 4. **Multi-tenancy**
```
- Cada consulta debe filtrar por empresa_id
- Middleware de autenticación valida empresa del usuario
- Reportes aislados por empresa
```

---

## 🎯 Restricciones Importantes

| Restricción | Descripción |
|-----------|------------|
| `UNIQUE(usernick)` | No puede haber dos usuarios con el mismo nickname |
| `UNIQUE(email)` en User | No puede haber dos usuarios con el mismo email |
| `UNIQUE(token)` en PersonalAccessToken | Token único para cada acceso |
| `UNIQUE(product_id, empresa_id)` | Cada empresa tiene cada producto máximo una vez |
| `UNIQUE(product_id, warehouse_id)` | Un registro de stock por producto-almacén |
| `ON DELETE: Cascade` | Eliminar empresa → elimina usuarios, clientes, compras, ventas |
| `ON DELETE: SetNull` | Eliminar compra/venta no borra movimientos, solo desvincula |

---

## 📈 Escalabilidad

**Consideraciones para crecimiento:**

1. **Índices recomendados:**
   - `empresa_id` en User, Client, Supplier, Purchase, Sale
   - `product_id` en ProductStock, PurchaseItem, SaleItem, ProductMovement
   - `warehouse_id` en ProductStock, ProductMovement
   - `created_at` para reportes por período

2. **Particionamiento (si crece mucho):**
   - ProductMovement por empresa_id (muchos registros)
   - PurchaseItem y SaleItem por documento

3. **Caché recomendado:**
   - ProductStock (cambia frecuentemente)
   - ProductCompany (cambia rara vez)

---

## 🔐 Seguridad

- **Autenticación:** JWT + PersonalAccessToken
- **Autorización:** Roles y permisos por usuario
- **Aislamiento:** Multi-tenancy por empresa_id
- **Contraseñas:** Hasheadas con bcryptjs
- **Auditoría:** created_at, updated_at en todas las tablas

---

## 📚 Stack Técnico

```json
{
  "framework": "Express.js",
  "language": "TypeScript",
  "orm": "Prisma",
  "database": "PostgreSQL",
  "auth": "JWT + bcryptjs",
  "validation": "Zod",
  "deployment": "Google Cloud Functions"
}
```

---

**Documento generado:** 2026-06-07  
**Última actualización del schema:** v5.8.0 de Prisma
