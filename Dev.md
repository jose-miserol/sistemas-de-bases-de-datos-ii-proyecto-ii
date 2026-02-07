# 🚀 Guía de Desarrollo y Pruebas

> Paso a paso para ejecutar y validar el pipeline completo del proyecto.

---

## Requisitos Previos

- [x] Docker Desktop instalado y corriendo
- [x] Mínimo 8 GB RAM disponible
- [x] 20 GB espacio en disco

---

## Fase 1: Levantar Infraestructura

### 1.1 Iniciar Contenedores

```bash
# Desde la raíz del proyecto
docker-compose up -d
```

### 1.2 Verificar Servicios

```bash
docker ps
```

**Esperado:** 3 contenedores corriendo:

- `cassandra` (puerto 9042)
- `clickhouse` (puertos 8123, 9000)
- `jupyter-spark` (puerto 8888)

### 1.3 Esperar Cassandra (2-3 min)

```bash
# Verificar que Cassandra esté listo
docker exec cassandra cqlsh -e "describe cluster"
```

**Esperado:** Información del cluster sin errores.

---

## Fase 2: Configurar Esquemas

> **Nota:** Con la configuración de `docker-compose.yml`, este paso ahora es **AUTOMÁTICO**.

### Opción A: Automática (Recomendada)

Solo necesitas verificar que los esquemas se crearon correctamente:

1. **Revisar logs de inicialización:**

   ```bash
   docker logs init-cassandra
   ```

   **Esperado:** "✅ Esquema Cassandra creado exitosamente."

2. **Verificar tablas en ClickHouse:**
   ```bash
   docker exec clickhouse clickhouse-client --query "SHOW TABLES FROM dw_analitico"
   ```
   **Esperado:** `ventas_resumen`

---

### Opción B: Manual (Paso a paso)

Si la automatización falla o prefieres hacerlo tú mismo:

#### 2.1 Cassandra

```bash
docker exec -i cassandra cqlsh < infra/cassandra/schema.cql
```

#### 2.2 ClickHouse

```bash
docker exec clickhouse clickhouse-client --query "CREATE DATABASE IF NOT EXISTS dw_analitico"

docker exec clickhouse clickhouse-client --query "CREATE TABLE IF NOT EXISTS dw_analitico.ventas_resumen (fecha_venta Date, categoria String, ventas_totales Decimal(18, 2), cantidad_transacciones UInt32) ENGINE = ReplacingMergeTree() ORDER BY (fecha_venta, categoria)"
```

---

## Fase 3: Acceder a Jupyter

### 3.1 Abrir Jupyter Lab

1. Ir a: **http://localhost:8888**
2. Password: `admin`

### 3.2 Navegar a Notebooks

Ruta: `work/notebooks/`

---

## Fase 4: Ejecutar Notebooks (EN ORDEN)

### 4.1 Validar Conectividad

**Archivo:** `01_connection.ipynb`

1. Ejecutar todas las celdas (Shift+Enter)
2. **Esperado:**
   - Mensaje "Conexión Exitosa"
   - DataFrame con keyspaces de Cassandra

📸 **Captura:** Screenshot de la salida exitosa

### 4.2 Generar e Insertar Datos

**Archivo:** `02_generador_datos.ipynb`

1. Ejecutar todas las celdas
2. **Esperado:**
   - 100,000 registros insertados
   - Tiempo < 1 minuto
   - Mensaje "✅ Ingesta Completada"

📸 **Captura:** Screenshot mostrando el conteo final

### 4.3 ETL Spark → ClickHouse

**Archivo:** `03_etl_spark.ipynb`

1. Ejecutar todas las celdas
2. **Esperado:**
   - Lectura de ~100k registros de Cassandra
   - Transformación con agrupación
   - "✅ Carga en ClickHouse exitosa"

---

## Fase 5: Validar ClickHouse

### 5.1 Ejecutar Consultas Analíticas

**Ejecutar desde el archivo SQL:**

```bash
# Ejecutar las consultas directamente desde el archivo
docker exec -i clickhouse clickhouse-client --multiquery < docs/consultas_analiticas.sql
```

**Ejecutar consultas individuales:**

```bash
# Consulta 1: Top categorías
docker exec clickhouse clickhouse-client --query "SELECT categoria, sum(ventas_totales) as total FROM dw_analitico.ventas_resumen GROUP BY categoria ORDER BY total DESC LIMIT 10"

# Consulta 2: Promedio diario
docker exec clickhouse clickhouse-client --query "SELECT categoria, avg(ventas_totales) as promedio, sum(cantidad_transacciones) as total_tx FROM dw_analitico.ventas_resumen GROUP BY categoria"
```

📸 **Captura:** Screenshot de ambos resultados

### 5.2 Verificar Tiempo de Respuesta

Las consultas deben ejecutarse en **< 3 segundos**.

---

## Fase 6: Capturas Requeridas

| #   | Captura            | Descripción                                     |
| --- | ------------------ | ----------------------------------------------- |
| 1   | PySpark Validación | Output de `01_connection.ipynb`                 |
| 2   | Cassandra COUNT    | `SELECT COUNT(*) FROM ventas_db.ventas_crudas;` |
| 3   | ClickHouse Query 1 | Top 10 categorías                               |
| 4   | ClickHouse Query 2 | Promedio ventas                                 |

---

## Troubleshooting Común

### Error: "Database dw_analitico does not exist"

```bash
docker exec clickhouse clickhouse-client --query "CREATE DATABASE IF NOT EXISTS dw_analitico"
```

### Error: "Couldn't find system_schema"

El contenedor Cassandra no está listo. Esperar 2-3 minutos.

### Error: "Connection refused" en Jupyter

```bash
docker-compose restart jupyter
```

### Reiniciar Todo

```bash
docker-compose down -v
docker-compose up -d
```

---

## Comandos Útiles

```bash
# Ver logs de un servicio
docker logs cassandra
docker logs clickhouse
docker logs jupyter-spark

# Entrar a un contenedor
docker exec -it cassandra bash
docker exec -it clickhouse bash

# Ver uso de recursos
docker stats
```

---

- [ ] 3 contenedores corriendo
- [ ] Keyspace `ventas_db` creado
- [ ] Database `dw_analitico` creado
- [ ] 100k+ registros en Cassandra
- [ ] Datos agregados en ClickHouse
- [ ] 4 capturas tomadas
- [ ] Tiempos documentados
