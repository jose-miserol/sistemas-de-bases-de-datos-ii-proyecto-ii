# Proyecto N° 2: Data Pipeline Escalable y Analítico

**Universidad:** UNEG - Universidad Nacional Experimental de Guayana  
**Asignatura:** Sistemas de Bases de Datos II  
**Semestre:** 2025-11  
**Profesora:** Clinia Cordero  
**Versión:** 0.0.7
**Última actualización:** 2026-01-21

---

## 📋 Objetivo General

Diseñar, implementar y validar un prototipo funcional de arquitectura de datos escalable que simula la carga de grandes volúmenes de datos (NoSQL), su procesamiento distribuido (Paralelo) y su posterior almacenamiento analítico (Data Warehouse).

---

## 🏗️ Arquitectura del Sistema

| Componente                   | Tecnología             | Rol                                                                       |
| ---------------------------- | ---------------------- | ------------------------------------------------------------------------- |
| **Base de Datos NoSQL**      | Apache Cassandra       | Capa de Ingesta (OLTP) - Almacena datos crudos de transacciones           |
| **Procesamiento Paralelo**   | Apache Spark (PySpark) | Capa de Transformación (ELT) - Procesa, limpia y agrega datos en paralelo |
| **Data Warehouse**           | ClickHouse             | Capa Analítica (OLAP) - Almacena datos agregados para informes            |
| **Plataforma de Despliegue** | Docker Compose         | Entorno de desarrollo unificado                                           |

---

## ⚙️ Dependencias y Configuración Crítica

### 🚨 IMPORTANTE: Conectores Spark

**Problema:** Apache Spark NO incluye nativamente los conectores para Cassandra ni ClickHouse. Sin esta configuración, las **Fases 3 y 4 fallarán con `ClassNotFoundException`**.

#### Dependencias Requeridas

| Componente                    | Coordenada Maven                                    | Versión |
| ----------------------------- | --------------------------------------------------- | ------- |
| **Spark-Cassandra Connector** | `com.datastax.spark:spark-cassandra-connector_2.12` | 3.5.0   |
| **ClickHouse JDBC Driver**    | `com.clickhouse:clickhouse-jdbc`                    | 0.5.0   |

### Opción 1: Configuración en docker-compose.yml (RECOMENDADO)

**Archivo:** `infra/docker-compose.yml`

```yaml
version: "3.8"

services:
  cassandra:
    image: cassandra:4.1.4 # ⚠️ Version pinning - NO usar :latest
    container_name: cassandra
    ports:
      - "9042:9042"
    environment:
      - CASSANDRA_CLUSTER_NAME=lab_cluster
      - CASSANDRA_DC=dc1
      - CASSANDRA_ENDPOINT_SNITCH=GossipingPropertyFileSnitch
    volumes:
      - cassandra_data:/var/lib/cassandra
    healthcheck:
      test: ["CMD-SHELL", "cqlsh -e 'describe cluster'"]
      interval: 30s
      timeout: 10s
      retries: 5

  clickhouse:
    image: clickhouse/clickhouse-server:24.1.2 # ⚠️ Version pinning - NO usar :latest
    container_name: clickhouse
    ports:
      - "8123:8123" # HTTP
      - "9000:9000" # Native
    volumes:
      - clickhouse_data:/var/lib/clickhouse
    ulimits:
      nofile:
        soft: 262144
        hard: 262144

  jupyter:
    image: jupyter/pyspark-notebook:spark-3.5.0 # ⚠️ CRÍTICO: Version pinning para estabilidad
    container_name: jupyter-spark
    user: "1000:100" # jovyan UID - evita problemas de permisos en Linux
    ports:
      - "8888:8888"
    volumes:
      - ./notebooks:/home/jovyan/work/notebooks
      - ./src:/home/jovyan/work/src
      - ./infra:/home/jovyan/work/infra
    environment:
      - JUPYTER_ENABLE_LAB=yes
      # ⚠️ CRÍTICO: Configura los JARs necesarios
      - PYSPARK_SUBMIT_ARGS=--packages com.datastax.spark:spark-cassandra-connector_2.12:3.5.0,com.clickhouse:clickhouse-jdbc:0.5.0 pyspark-shell
    depends_on:
      cassandra:
        condition: service_healthy
      clickhouse:
        condition: service_started
    networks:
      - bigdata_net

networks:
  bigdata_net:
    driver: bridge

volumes:
  cassandra_data:
  clickhouse_data:
```

**Ventajas:**

- ✅ Configuración centralizada
- ✅ JARs se descargan automáticamente al iniciar
- ✅ Funciona para todos los notebooks y scripts
- ✅ Versiones inmutables garantizan estabilidad a largo plazo

**⚠️ Importante - Permisos en Linux:**
Si usas Linux y obtienes "Permission Denied" al guardar notebooks:

```bash
# Desde la carpeta del proyecto
sudo chown -R 1000:1000 notebooks/ src/ infra/
# El UID 1000 corresponde al usuario 'jovyan' dentro del contenedor
```

### Opción 2: Configuración en SparkSession (Código)

**Ubicación:** Al inicio de notebooks en Fases 3 y 4

```python
from pyspark.sql import SparkSession

spark = SparkSession.builder \
    .appName("Cassandra ETL") \
    .config("spark.jars.packages",
            "com.datastax.spark:spark-cassandra-connector_2.12:3.5.0,"
            "com.clickhouse:clickhouse-jdbc:0.5.0") \
    .config("spark.cassandra.connection.host", "cassandra") \
    .config("spark.cassandra.connection.port", "9042") \
    .config("spark.driver.memory", "2g") \
    .getOrCreate()
# ⚠️ IMPORTANTE: spark.driver.memory=2g evita OOM (deja espacio para Python/OS)
```

**Ventajas:**

- ✅ Control fino por notebook
- ✅ Fácil de modificar versiones

**Desventajas:**

- ⚠️ Primera ejecución tarda más (descarga JARs)
- ⚠️ Debe repetirse en cada notebook

### Opción 3: Descarga Manual de JARs (NO RECOMENDADO)

```bash
# Desde terminal del contenedor Jupyter
cd /usr/local/spark/jars

# Spark-Cassandra Connector
wget https://repo1.maven.org/maven2/com/datastax/spark/spark-cassandra-connector_2.12/3.5.0/spark-cassandra-connector_2.12-3.5.0.jar

# ClickHouse JDBC
wget https://repo1.maven.org/maven2/com/clickhouse/clickhouse-jdbc/0.5.0/clickhouse-jdbc-0.5.0-all.jar
```

**Solo usar si:**

- Las opciones 1 y 2 fallan
- No hay conexión a Maven Central

---

**Artefactos esperados por fase:**

- **Fase 1:** `infra/docker-compose.yml`, `infra/cassandra/schema.cql`, `infra/clickhouse/schema.sql`
- **Fase 2:** `src/generador_datos.py` o `notebooks/02_generador_datos.ipynb`
- **Fase 3:** `src/etl_spark.py` o `notebooks/03_etl_spark.ipynb`
- **Fase 4:** Consultas SQL documentadas en el notebook o en `docs/consultas_analiticas.sql`

---

## 📝 Lista de Tareas

### Fase 1: Configuración del Entorno y Arquitectura (Docker)

**Objetivo:** Levantar la infraestructura necesaria utilizando Docker Compose.

- [x] **1.1. Configuración Local**
  - [x] **Instalar Docker según sistema operativo:**
    - **Windows/Mac:** [Docker Desktop](https://www.docker.com/products/docker-desktop/) (incluye Docker Engine + Docker Compose)
    - **Linux:** [Docker Engine](https://docs.docker.com/engine/install/) + [Docker Compose](https://docs.docker.com/compose/install/)
  - [x] Crear carpeta de trabajo `proyecto_bigdata`
  - [x] Verificar requisitos del sistema:
    - Mínimo 8 GB RAM disponible
    - 20 GB espacio en disco
  - [ ] **Documentar entorno de desarrollo:**
    - [ ] Sistema operativo y versión
    - [ ] Modelo de CPU y número de cores lógicos
    - [ ] RAM total del sistema

- [x] **1.2. Configuración YAML**
  - [x] Implementar archivo `docker-compose.yml` con los 3 servicios:
    - [x] Servicio Apache Cassandra
    - [x] Servicio ClickHouse
    - [x] Servicio Jupyter/Spark
  - [x] Configurar volúmenes para persistencia de datos
  - [x] Configurar redes entre contenedores

- [x] **1.3. Despliegue**
  - [x] Ejecutar `docker-compose up -d`
  - [x] Verificar que todos los contenedores estén corriendo
  - [x] Revisar logs de cada servicio

- [x] **1.4. Validación de Conectividad**
  - [x] Acceder a Jupyter en `http://localhost:8888`
  - [x] Ejecutar "Hola Mundo" de PySpark
  - [x] Confirmar que el conector de Cassandra funciona
  - [ ] **📸 Captura requerida:** Screenshot de validación PySpark

- [x] **1.5. Configuración de Esquemas**
  - [x] **Cassandra:** Crear Keyspace

    ```cql
    CREATE KEYSPACE IF NOT EXISTS ventas_db
    WITH replication = {'class': 'SimpleStrategy', 'replication_factor': 1};
    ```

    - [ ] **Nota de configuración:**
      - [ ] `SimpleStrategy` con `replication_factor=1` es **solo para entorno de laboratorio**
      - [ ] En producción: `NetworkTopologyStrategy` con replicación ≥ 3
      - [ ] **Seguridad:** Para laboratorio se usa usuario por defecto; en producción configurar autenticación (`cassandra.yaml`: `authenticator: PasswordAuthenticator`)

  - [x] **Cassandra:** Ejecutar script CQL para crear tabla `ventas_crudas` (`infra/cassandra/schema.cql`):
    - [ ] `id_venta` (UUID)
    - [ ] `fecha_venta` (Date/Timestamp) - **Partition Key**
    - [ ] `id_producto` (Text)
    - [ ] `categoria` (Text)
    - [ ] `monto_total` (Decimal)
    - [ ] `id_cliente` (Text)
    - [ ] **Nota de diseño:** En producción se recomienda composite partition key `(fecha_venta, categoria)` para mejor distribución; para este laboratorio se usa solo `fecha_venta` por simplicidad
  - [x] **ClickHouse:** Crear base de datos `dw_analitico`
    ```sql
    CREATE DATABASE IF NOT EXISTS dw_analitico;
    ```
  - [x] **ClickHouse:** Crear tabla `ventas_resumen` en ClickHouse (`infra/clickhouse/schema.sql`) con:
    - [ ] `fecha_venta` (Date)
    - [ ] `categoria` (String)
    - [ ] `ventas_totales` (Decimal(18,2))
    - [ ] `cantidad_transacciones` (UInt32)
    - [ ] **Engine especificado:** `ENGINE = MergeTree() ORDER BY (fecha_venta, categoria)`
    - [ ] Ejemplo completo:

      ```sql
      CREATE TABLE IF NOT EXISTS dw_analitico.ventas_resumen (
          fecha_venta Date,
          categoria String,
          ventas_totales Decimal(18,2),
          cantidad_transacciones UInt32
      ) ENGINE = ReplacingMergeTree()  -- ⚠️ Deduplica automáticamente en re-ejecuciones
      ORDER BY (fecha_venta, categoria);

      -- ALTERNATIVA: MergeTree() si usas mode("overwrite") en Spark
      -- ReplacingMergeTree() es más robusto para idempotencia
      ```

---

### Fase 2: Ingesta Masiva de Datos (NoSQL - Cassandra)

**Objetivo:** Simular proceso de ingesta de datos transaccionales en Cassandra.

- [x] **2.1. Generador de Datos**
  - [x] **⚠️ IMPORTANTE - Ubicación de Ejecución:**
    - [x] **OBLIGATORIO:** Ejecutar DENTRO del contenedor Jupyter
    - [x] **RAZÓN:** Resolución DNS - `cassandra` solo funciona en red Docker interna
    - [x] ❌ NO ejecutar desde IDE local (fallará con error de conexión)
  - [x] **Elegir formato de implementación:**
    - [x] Opción A (Recomendado): Notebook `notebooks/02_generador_datos.ipynb`
    - [ ] Opción B: Script Python `src/generador_datos.py` (ejecutar desde terminal Jupyter)
  - [x] **Gestión de archivos:**
    - [x] La opción elegida será la **fuente de verdad oficial** para evaluación
    - [x] Si se mantienen ambos archivos, marcar el no usado como `LEGACY_` en el nombre
    - [x] Ejemplo: Si se usa notebook, renombrar script a `LEGACY_generador_datos.py`
  - [x] **Instalar dependencias en Jupyter:**
    ```bash
    # Desde terminal Jupyter
    pip install cassandra-driver
    ```
  - [x] Implementar generación de 100,000 registros
  - [x] Implementar generación aleatoria de:
    - [x] `id_venta` (único)
    - [x] `fecha_venta` (rango de fechas realista)
    - [x] `id_producto` (variedad de productos)
    - [x] `categoria` (Electrónica, Ropa, Alimentos, etc.)
    - [x] `monto_total` (valores monetarios realistas)
    - [x] `id_cliente` (pool de clientes)
  - [x] Validar formato de datos generados

- [x] **2.2. Inserción Masiva**
  - [x] Instalar `cassandra-driver` en Python
  - [x] Configurar conexión a Cassandra desde Jupyter
  - [x] Implementar batch inserts para optimizar rendimiento (batches de 100-500 registros)
  - [x] Insertar los 100,000 registros en `ventas_crudas`
  - [x] **Criterio de rendimiento:** Objetivo insertar 100,000 registros en < 5 minutos
    - [x] **Nota:** Este es un umbral conservador para máquinas de bajos recursos; en entornos típicos debería ser < 2 minutos
    - [x] **Tiempo logrado:** ~6.39 segundos (15,642 regs/seg) - Muy por debajo del objetivo
    - [ ] **Si tiempo es significativamente mayor (> 7 min):** Explicar limitaciones del entorno y optimizaciones intentadas
  - [x] Medir y documentar:
    - [x] Tiempo de inserción total: **6.39 segundos**
    - [ ] Hardware del host (CPU, RAM, SO)

- [x] **2.3. Validación de Ingesta**
  - [x] Conectar vía `cqlsh` al contenedor Cassandra
  - [x] Ejecutar `SELECT COUNT(*) FROM ventas_crudas;`
  - [x] Verificar que existen 100,000 registros (**Resultado: 228,657 registros**)
  - [x] Ejecutar consultas de muestra para validar datos
  - [ ] **📸 Captura requerida:** Screenshot mostrando COUNT(\*) = 100,000

---

### Fase 3: Procesamiento Paralelo y Transformación (Spark)

**Objetivo:** Implementar lógica de negocio usando PySpark para transformar datos crudos en datos analíticos.

- [x] **3.1. Lectura Distribuida**
  - [x] **Elegir formato de implementación (consistente con Fase 2):**
    - [x] Opción A: Notebook `notebooks/03_etl_spark.ipynb`
    - [ ] Opción B: Script `src/etl_spark.py`
  - [x] **Gestión de archivos:**
    - [x] La opción elegida será la **fuente de verdad oficial** para evaluación
    - [ ] Si se mantienen ambos, marcar el no usado como `LEGACY_` en el nombre
  - [x] Configurar SparkSession con conector Cassandra
    - [x] **Opción:** Usar configuración de docker-compose.yml (Recomendado - ya tiene JARs)
    - [ ] **O alternativamente:** Configurar JARs en código (ver sección "Dependencias y Configuración Crítica")
    - [x] Ejemplo mínimo:

      ```python
      from pyspark.sql import SparkSession

      # Si usas docker-compose.yml, los JARs ya están configurados
      spark = SparkSession.builder \
          .appName("Cassandra ETL") \
          .config("spark.cassandra.connection.host", "cassandra") \
          .config("spark.driver.memory", "2g") \
          .getOrCreate()
      # Nota: spark.driver.memory=2g evita OOM killer
      ```

  - [ ] **Configurar paralelismo de Spark:**
    - [ ] Ajustar número de particiones según: (número de cores) × (2-3)
    - [ ] Para dataset de 100k registros, evitar usar default de 200 particiones
    - [ ] Ejemplo: 4 cores → configurar 8-12 particiones
  - [x] Leer datos de tabla `ventas_crudas`
  - [x] Especificar `fecha_venta` como Partition Key para lectura paralela
  - [x] Verificar que los datos se carguen correctamente en DataFrame

- [x] **3.2. Lógica de Transformación**
  - [x] Implementar agrupación por `fecha_venta` y `categoria`
  - [x] Calcular suma de `monto_total` (Ventas Totales por Categoría)
  - [x] Calcular conteo de `id_venta` (Cantidad de Transacciones)
  - [x] Crear DataFrame resultante con columnas:
    - [x] `fecha_venta`
    - [x] `categoria`
    - [x] `ventas_totales`
    - [x] `cantidad_transacciones`
  - [x] **Definir esquema explícito con DecimalType (RECOMENDADO):**
    - [ ] **RAZÓN:** Spark infiere `Double` por defecto, no `Decimal` preciso
    - [ ] Ejemplo completo:

      ```python
      from pyspark.sql.types import StructType, StructField, DateType, StringType, DecimalType, IntegerType

      # Esquema para ventas_resumen
      schema_resumen = StructType([
          StructField("fecha_venta", DateType(), False),
          StructField("categoria", StringType(), False),
          StructField("ventas_totales", DecimalType(18, 2), False),  # ✅ Precisión monetaria
          StructField("cantidad_transacciones", IntegerType(), False)
      ])

      # Aplicar al crear DataFrame
      df_resumen = df_agrupado.select(
          col("fecha_venta").cast(DateType()),
          col("categoria"),
          col("ventas_totales").cast(DecimalType(18, 2)),
          col("cantidad_transacciones").cast(IntegerType())
      )
      ```

- [ ] **3.3. Limpieza de Datos (Opcional pero Recomendado)**
  - [ ] Implementar filtro para eliminar registros con `monto_total` nulo
  - [ ] Implementar filtro para eliminar registros con `monto_total` negativo
  - [ ] **Documentación obligatoria:**
    - [ ] Número de registros descartados
    - [ ] Porcentaje sobre el total original (ej. "150 registros / 0.15%")
    - [ ] Razón de descarte por categoría (nulos vs negativos)

---

### Fase 4: Carga y Consulta Analítica (Data Warehouse)

**Objetivo:** Cargar datos transformados a ClickHouse y demostrar potencial analítico.

- [x] **4.1. Carga (ELT)**
  - [x] **⚠️ IMPORTANTE - Idempotencia:**
    - [x] **Opción A (Recomendado):** Usar `ReplacingMergeTree` en ClickHouse (ya configurado en schema)
      - Deduplica automáticamente por ORDER BY key
      - Permite re-ejecutar el pipeline sin duplicados
  - [x] Configurar conector PySpark-ClickHouse
  - [x] Escribir DataFrame resultante en `dw_analitico.ventas_resumen`
  - [x] Verificar modo de escritura (append/overwrite)

- [x] **4.2. Validación Analítica**
  - [x] Conectarse al cliente ClickHouse
  - [x] **Consulta Analítica 1:** Top 10 categorías con mayor volumen de ventas
    ```sql
    -- Implementar consulta que muestre las 10 categorías con
    -- mayor volumen de ventas en todo el período
    ```
  - [x] **Consulta Analítica 2:** Promedio de ventas diarias por categoría
    ```sql
    -- Implementar consulta que calcule el promedio de
    -- ventas diarias por categoría
    ```
  - [ ] Ejecutar ambas consultas y documentar resultados
  - [ ] **📸 Capturas requeridas:** Screenshots de resultados de ambas consultas
  - [x] **Obligatorio:** Exportar consultas a `docs/consultas_analiticas.sql` (incluso si se ejecutaron en notebook)

- [ ] **4.3. Informe de Rendimiento**
  - [ ] Documentar tiempo de ejecución de ingesta (Fase 2)
  - [ ] Documentar tiempo de ejecución de consultas analíticas (Fase 4.2)
  - [ ] **Criterio de rendimiento:** Las consultas analíticas deben ejecutarse en < 3 segundos para el dataset de 100,000 registros
    - [ ] **Si no se alcanza el objetivo:** Documentar explícitamente limitaciones del entorno y optimizaciones intentadas
  - [ ] Comparar tiempos y analizar eficiencia
  - [ ] Crear tabla comparativa (incluir hardware para contexto):
        | Operación | Tiempo medido | Hardware (CPU/RAM/SO) | Observaciones |
        |-----------|---------------|----------------------|---------------|
        | Ingesta Cassandra | X min Y seg | CPU: ..., RAM: ..., SO: ... | |
        | Transformación Spark | Z seg | CPU: ..., RAM: ..., SO: ... | |
        | Consulta 1 ClickHouse | W seg | CPU: ..., RAM: ..., SO: ... | |
        | Consulta 2 ClickHouse | V seg | CPU: ..., RAM: ..., SO: ... | |

---

## 📦 Entrega Final del Proyecto

**Formato:** Documento único en PDF vía Ungevirtual  
**Integrantes:** 3 por equipo

### Contenido del Documento

- [ ] **1. Diagrama de Arquitectura**
  - [ ] Crear diagrama de bloques mostrando flujo:
    - Cassandra → Spark → ClickHouse
  - [ ] Incluir etiquetas de tecnologías
  - [ ] Mostrar tipo de capa (OLTP, ELT, OLAP)

- [ ] **2. Código Fuente**
  - [ ] Adjuntar `docker-compose.yml` completo
  - [ ] Adjuntar script generador de datos (Python)
  - [ ] Adjuntar script Spark ETL (PySpark)
  - [ ] Adjuntar scripts SQL/CQL (esquemas y consultas)
  - [ ] Incluir comentarios explicativos en el código

- [ ] **3. Resultados y Análisis**
  - [ ] **Captura 1:** Validación de conectividad PySpark (Fase 1.4)
  - [ ] **Captura 2:** 100,000 registros en Cassandra (Fase 2.3)
  - [ ] **Consultas:** Código de las 2 consultas analíticas ClickHouse (Fase 4.2)
  - [ ] **Análisis Cassandra:** Explicar por qué Cassandra fue la elección correcta para ingesta
    - [ ] Mencionar arquitectura distribuida
    - [ ] Mencionar escalabilidad horizontal
    - [ ] Mencionar optimización para escrituras
  - [ ] **Análisis ClickHouse:** Explicar por qué ClickHouse es superior para consultas analíticas
    - [ ] Mencionar arquitectura columnar
    - [ ] Mencionar optimización para lecturas agregadas
    - [ ] Mencionar compresión de datos

- [ ] **4. Documentación Adicional**
  - [ ] Incluir instrucciones de ejecución paso a paso
    - [ ] **Recomendado:** Centralizar en `README.md` del proyecto (ver estructura en sección "Estructura del Proyecto")
  - [ ] **Documentar problemas encontrados (mínimo 2-3) en formato estructurado:**
    - [ ] Problema 1:
      - Síntoma/Error (mensaje exacto)
      - Comando de diagnóstico usado
      - Solución aplicada
    - [ ] Problema 2:
      - Síntoma/Error (mensaje exacto)
      - Comando de diagnóstico usado
      - Solución aplicada
    - [ ] Problema 3 (si aplica):
      - Síntoma/Error (mensaje exacto)
      - Comando de diagnóstico usado
      - Solución aplicada
  - [ ] Conclusiones del equipo sobre cada tecnología

---

## 📌 Notas Técnicas

### Comandos Útiles

```bash
# Iniciar servicios
docker-compose up -d

# Ver logs
docker-compose logs -f [servicio]

# Conectar a Cassandra
docker exec -it [cassandra-container] cqlsh

# Conectar a ClickHouse
docker exec -it [clickhouse-container] clickhouse-client

# Detener servicios
docker-compose down
```

### Consideraciones de Diseño

#### Cassandra - Modelado de Datos

- **Partition Key recomendada:** En producción, usar composite partition key `(fecha_venta, categoria)` para mejorar distribución en escenarios reales con grandes volúmenes
- **Para este laboratorio:** Se usa solo `fecha_venta` por simplicidad didáctica
- **Justificación:** La distribución por fecha permite lectura paralela eficiente en Spark y evita hot spots si las fechas están bien distribuidas

#### Cassandra - Ingesta

- **Batch Inserts:** Agrupar inserts en batches de 100-500 registros para mejor rendimiento
- **Driver:** Usar `cassandra-driver` con prepared statements para optimizar

#### Spark - Procesamiento

- **Spark Parallelism:** Ajustar número de particiones según: `(número de cores) × (2-3)`
  - **Evitar usar el default ciegamente** (200 particiones): para datasets pequeños como 100k registros, esto genera overhead innecesario
  - Ejemplo: En máquina con 4 cores, configurar 8-12 particiones
- **Lectura optimizada:** Especificar partition key en la lectura de Cassandra para pushdown

#### ClickHouse - Almacenamiento Analítico

- **Engine:** `ReplacingMergeTree() ORDER BY (fecha_venta, categoria)` para idempotencia y mejor rendimiento
  - `ReplacingMergeTree` deduplica automáticamente por ORDER BY key
  - Alternativa: `MergeTree()` si se usa `.mode("overwrite")` en Spark
- **Ordenamiento:** El ORDER BY permite queries eficientes por rango de fechas y categorías
- **Compresión:** ClickHouse comprime automáticamente datos columnares (típicamente 10x-100x)

### Troubleshooting: Problemas Típicos

#### Problema 1: Servicios no inician o puertos ocupados

**Diagnóstico:**

```bash
# Verificar estado de contenedores
docker ps -a

# Ver logs de un servicio específico
docker-compose logs cassandra
docker-compose logs clickhouse
docker-compose logs jupyter

# Verificar puertos ocupados
# Windows:
netstat -ano | findstr :9042    # Cassandra
netstat -ano | findstr :9000    # ClickHouse
netstat -ano | findstr :8888    # Jupyter

# Linux/Mac:
ss -tulpn | grep 9042           # Cassandra
ss -tulpn | grep 9000           # ClickHouse
ss -tulpn | grep 8888           # Jupyter
# o alternativamente:
lsof -i :9042
```

**Soluciones:**

- Si el puerto está ocupado, cambiar el mapeo en `docker-compose.yml`:
  ```yaml
  ports:
    - "9043:9042" # Usar puerto local diferente
  ```
- Si el contenedor falló al iniciar, revisar logs y reintentar:
  ```bash
  docker-compose down
  docker-compose up -d
  ```

#### Problema 2: Falta de memoria en contenedor Spark

**Síntomas:**

- Jupyter kernel muere durante procesamiento
- Error: `OutOfMemoryError: Java heap space`

**Diagnóstico:**

```bash
# Verificar uso de recursos
docker stats

# Ver logs de Spark
docker-compose logs jupyter | grep -i memory
```

**Solución:**
Aumentar memoria del contenedor en `docker-compose.yml`:

```yaml
services:
  jupyter:
    # ... otras configuraciones
    deploy:
      resources:
        limits:
          memory: 4G
        reservations:
          memory: 2G
    # Nota: deploy.resources solo aplica en Docker Swarm mode;
    # para Docker Compose estándar es orientativo. Alternativamente:
    mem_limit: 4g
    mem_reservation: 2g
```

#### Problema 3: Error de conexión con Cassandra

**Síntomas:**

- `NoHostAvailable: ('Unable to connect to any servers')`
- Timeout al intentar conectar desde Python

**Diagnóstico:**

```bash
# Verificar que Cassandra esté completamente iniciado
docker logs [cassandra-container] | grep "Starting listening for CQL clients"

# Intentar conexión manual
docker exec -it [cassandra-container] cqlsh

# Verificar red Docker (el nombre varía según carpeta del proyecto)
docker network ls
docker network inspect <nombre_de_red>  # Típicamente: <carpeta>_default
```

**Soluciones:**

- Cassandra tarda 30-60 segundos en estar listo; esperar mensaje en logs
- Verificar nombre del contenedor en código Python:
  ```python
  from cassandra.cluster import Cluster
  cluster = Cluster(['cassandra'])  # Usar nombre del servicio, no 'localhost'
  ```
- Si persiste, reiniciar contenedor:
  ```bash
  docker-compose restart cassandra
  ```

#### Problema 4: Error de conexión con ClickHouse

**Síntomas:**

- `Network error: Connection refused`
- No se pueden ejecutar consultas desde PySpark

**Diagnóstico:**

```bash
# Verificar que ClickHouse esté corriendo
docker exec -it [clickhouse-container] clickhouse-client

# Verificar conectividad desde Jupyter
docker exec -it [jupyter-container] ping clickhouse

# Ver logs
docker logs [clickhouse-container]
```

**Soluciones:**

- Verificar que el puerto 9000 (protocolo nativo) esté mapeado
- Usar nombre de servicio en conexión, no IP:
  ```python
  clickhouse_host = "clickhouse"  # No usar 'localhost'
  ```

#### Problema 5: ClassNotFoundException - Conector Cassandra/ClickHouse

**Síntomas:**

- Error al ejecutar `spark.read.format("org.apache.spark.sql.cassandra")`
- Mensaje completo:
  ```
  java.lang.ClassNotFoundException: org.apache.spark.sql.cassandra.DefaultSource
  ```
- O similar para ClickHouse JDBC

**Diagnóstico:**

```python
# El error ocurre en esta línea:
df = spark.read.format("org.apache.spark.sql.cassandra").load()
```

**Causa:**

- ⚠️ **CRÍTICO:** Faltan los JARs de los conectores
- Spark NO incluye estos conectores nativamente
- Sin configurarlos, las Fases 3 y 4 son INOPERABLES

**Solución:**

1. Ver sección **"⚙️ Dependencias y Configuración Crítica"** al inicio del documento
2. Implementar Opción 1 (docker-compose.yml) o Opción 2 (SparkSession)
3. Reiniciar kernel de Jupyter después de configurar

**Verificación:**

```python
# Después de configurar, esto NO debe dar error:
spark = SparkSession.builder \
    .appName("Test") \
    .config("spark.jars.packages",
            "com.datastax.spark:spark-cassandra-connector_2.12:3.5.0") \
    .getOrCreate()

# Verificar que el conector esté disponible
spark.sparkContext._jsc.sc().listJars()  # Debe aparecer cassandra-connector
```

#### Problema 6: Dataset vacío en Spark al leer de Cassandra

**Síntomas:**

- `df.count()` retorna 0
- No se leen datos aunque existan en Cassandra

**Diagnóstico:**

```python
# Verificar configuración del conector
df = spark.read \
    .format("org.apache.spark.sql.cassandra") \
    .option("keyspace", "ventas_db") \
    .option("table", "ventas_crudas") \
    .load()

print(f"Conteo: {df.count()}")
df.printSchema()

# Verificar datos en Cassandra directamente
# docker exec -it cassandra-container cqlsh
# SELECT COUNT(*) FROM ventas_db.ventas_crudas;
```

**Soluciones:**

- Verificar nombres exactos de keyspace y tabla (case-sensitive)
- Confirmar que el conector Cassandra-Spark esté instalado
- Verificar versión de compatibilidad entre Spark y Cassandra

#### Problema 7: Error al escribir en ClickHouse desde Spark

**Síntomas:**

- `JDBC connection failed`
- Timeout al escribir DataFrame

**Diagnóstico:**

```python
# Verificar string de conexión JDBC
jdbc_url = "jdbc:clickhouse://clickhouse:8123/dw_analitico"

# Test de conexión simple
df_test = spark.createDataFrame([(1, "test")], ["id", "value"])
df_test.write \
    .format("jdbc") \
    .option("url", jdbc_url) \
    .option("dbtable", "test_table") \
    .mode("overwrite") \
    .save()
```

**Soluciones:**

- Usar puerto HTTP (8123) para JDBC, no puerto nativo (9000)
- Instalar driver JDBC de ClickHouse en Spark
- Verificar permisos de usuario en ClickHouse

---

## ✅ Criterios de Éxito

- [ ] Todos los servicios Docker funcionando correctamente
- [ ] 100,000 registros insertados exitosamente en Cassandra
- [ ] Transformación Spark ejecutada sin errores
- [ ] Datos cargados correctamente en ClickHouse
- [ ] Consultas analíticas funcionando y retornando resultados
- [ ] Documentación completa con todas las capturas requeridas
- [ ] Análisis comparativo Cassandra vs ClickHouse bien fundamentado
- [ ] Hardware documentado para contextualizar métricas de rendimiento
- [ ] Archivos legacy claramente marcados (si aplica)

---

## 🔒 Consideraciones de Seguridad (Informativas)

**Nota:** Este proyecto usa configuración de laboratorio. Para entornos de producción considerar:

### Cassandra

- Habilitar autenticación: `authenticator: PasswordAuthenticator` en `cassandra.yaml`
- Cambiar credenciales por defecto (usuario: `cassandra`, password: `cassandra`)
- Habilitar SSL/TLS para conexiones cliente-servidor
- Configurar `authorizer: CassandraAuthorizer` para control de acceso

### ClickHouse

- Configurar usuarios y passwords en `users.xml`
- No exponer puerto 9000 (nativo) fuera del host en producción
- Usar perfiles de usuario para limitar recursos
- Habilitar SSL para conexiones HTTP

### Docker

- **Puertos expuestos:** En laboratorio se mapean a `0.0.0.0`; en producción limitar a `127.0.0.1:puerto`
- Ejemplo seguro: `127.0.0.1:9042:9042` en lugar de `9042:9042`
- Usar Docker secrets para credenciales en lugar de variables de entorno
- Definir networks aisladas entre servicios

**Para este laboratorio:** Usar configuración por defecto está bien; solo tener conciencia de que no es production-ready.

---

## 📝 Changelog

### v0.0.7 (2026-01-21) - Calidad Industrial (Staff Engineer)

**Nivel de madurez:** Functional Prototype → Resilient Pipeline

**🔒 Version Pinning (Inmutabilidad):**

- Changed: `cassandra:4.1` → `cassandra:4.1.4`
- Changed: `clickhouse-server:24.1` → `clickhouse-server:24.1.2`
- Changed: `jupyter/pyspark-notebook:latest` → `jupyter/pyspark-notebook:spark-3.5.0`
- **RAZÓN:** `:latest` rompe el laboratorio cuando cambian versiones de Spark/Scala

**⚡ Gestión de Recursos (OOM Prevention):**

- Added: `.config("spark.driver.memory", "2g")` en todos los snippets de SparkSession
- **RAZÓN:** Evita que el contenedor muera por OOM cuando Spark consume toda la memoria

**♻️ Idempotencia del Pipeline:**

- Changed: Engine ClickHouse de `MergeTree()` → `ReplacingMergeTree()`
- Added: Sección de idempotencia en Fase 4.1 con dos estrategias
- **RAZÓN:** Re-ejecutar el notebook NO duplica datos (problema crítico de Data Engineering)

**🐧 Permisos Linux:**

- Added: `user: "1000:100"` en servicio Jupyter (UID jovyan)
- Added: Instrucciones de `chown` para resolver Permission Denied
- **RAZÓN:** Evita frustración de estudiantes en Linux con problemas de permisos

**Impacto:** Pipeline ahora es reproducible, idempotente y estable a largo plazo.

### v0.0.5 (2026-01-21) - Corrección de Bloqueadores Críticos

**🚨 BLOQUEADORES RESUELTOS (Auditoría de Ingeniería):**

- Added: **Sección completa "Dependencias y Configuración Crítica"** (130+ líneas)
  - Tabla de coordenadas Maven para Spark-Cassandra Connector y ClickHouse JDBC
  - docker-compose.yml FUNCIONAL completo con:
    - Volúmenes para persistencia (notebooks/, src/, infra/)
    - PYSPARK_SUBMIT_ARGS con JARs pre-configurados
    - Healthchecks para Cassandra
    - Networks aisladas
  - 3 opciones de configuración (docker-compose, SparkSession, manual)
  - Código de ejemplo completo para SparkSession

**Estandarización de ejecución:**

- Added: Advertencia OBLIGATORIA de ejecutar en contenedor Jupyter
- Added: Explicación de problema DNS (cassandra vs localhost)
- Added: Requisito de instalación de cassandra-driver
- Fixed: Ambigüedad eliminada - TODO se ejecuta en Jupyter

**Precisión de datos:**

- Added: Guía completa de esquema Decimal explícito con DecimalType(18,2)
- Added: Código de ejemplo de StructType completo para ventas_resumen
- Added: Explicación de por qué Spark infiere Double por defecto

**Troubleshooting ampliado:**

- Added: **Problema 5: ClassNotFoundException** (CRÍTICO)
  - Síntomas exactos del error
  - Diagnóstico con código
  - Solución con referencias a sección de Dependencias
  - Verificación post-configuración
- Renumerados problemas posteriores (5→6, 6→7)

**Impacto:** Sin estas correcciones, Fases 3 y 4 eran 100% INOPERABLES. Ahora el proyecto es completamente ejecutable.

### v0.0.4 (2026-01-21) - Refinamiento Crítico

**Consideraciones de seguridad añadidas:**

- Added: Sección completa "Consideraciones de Seguridad" con buenas prácticas para producción
- Added: Notas sobre autenticación en Cassandra y ClickHouse
- Added: Advertencias sobre exposición de puertos Docker (0.0.0.0 vs 127.0.0.1)
- Added: Mención de Docker secrets para credenciales

**Clarificaciones Docker/Compose:**

- Fixed: Aclaración sobre `deploy.resources` (solo Swarm) vs `mem_limit` (Compose estándar)
- Enhanced: Nombre de red Docker explicado como variable según nombre de carpeta del proyecto
- Added: Comando `docker network ls` para identificar nombre correcto

**Manejo de expectativas de rendimiento:**

- Added: Criterio explícito para cuando NO se alcanzan objetivos (documentar limitaciones)
- Enhanced: Guía bidireccional: qué hacer si tiempo es menor O mayor que objetivo
- Added: Umbrales específicos (< 1 min = superior, > 7 min = explicar)

**Gestión de archivos y fuente de verdad:**

- Added: Convención `LEGACY_` para marcar archivos no oficiales
- Enhanced: Clarificación de cuál será evaluado y por qué
- Added: Ejemplo concreto de renombrado

**Referencias cruzadas:**

- Added: Referencia explícita a `README.md` como lugar recomendado para instrucciones de ejecución
- Enhanced: Conexión entre estructura de proyecto y documentación adicional

**Criterios de éxito ampliados:**

- Added: Hardware documentado como criterio
- Added: Archivos legacy marcados como criterio

### v0.0.3 (2026-01-21) - Pulido de Ingeniería

**Claridad multiplataforma:**

- Added: Instrucciones específicas para Docker Engine (Linux) vs Docker Desktop (Windows/Mac)
- Added: Comandos de diagnóstico multiplataforma (netstat para Windows, ss/lsof para Linux/Mac)
- Added: Links directos a instalación de Docker según plataforma

**Especificaciones técnicas mejoradas:**

- Fixed: Tipo de dato ClickHouse de `Decimal128(2)` a `Decimal(18,2)` (más apropiado para montos monetarios)
- Added: Nota explícita sobre `SimpleStrategy` solo para laboratorio, recomendar `NetworkTopologyStrategy` en producción
- Enhanced: Guía de paralelismo Spark con fórmula `(cores × 2-3)` en lugar de default ciego de 200 particiones

**Consistencia y fuente de verdad:**

- Added: Directriz para elegir UNA fuente de verdad entre notebooks y scripts
- Added: Requisito obligatorio de exportar consultas SQL a `docs/consultas_analiticas.sql`
- Added: Clarificación de qué opción será la evaluada

**Contextualización de rendimiento:**

- Enhanced: Criterio de < 5 min explicado como umbral conservador (típico debería ser < 2 min)
- Added: Requisito de documentar hardware (CPU, RAM, SO) junto con métricas de tiempo
- Enhanced: Tabla comparativa de rendimiento incluye columna de hardware para contexto

**Documentación del entorno:**

- Added: Checklist de documentar SO, CPU (modelo y cores), RAM total
- Added: Requisito de documentar si tiempo mejora significativamente el objetivo

**Mejoras de forma:**

- Fixed: Emojis rotos en encabezados (📁, 📝)
- Enhanced: Comentarios inline en código SQL para claridad

### v0.0.2 (2026-01-21) - Rigor de Ingeniería

- Added: Estructura completa del proyecto con carpetas y artefactos esperados
- Enhanced: Modelado de datos con especificaciones SQL/CQL completas
- Added: Criterios cuantitativos de rendimiento (5 min ingesta, 3 seg consultas)
- Enhanced: Documentación de problemas con formato estructurado obligatorio
- Added: Sección troubleshooting con 6 problemas comunes documentados
- Enhanced: Consideraciones de diseño organizadas por tecnología
- Added: Metadatos de versión y fecha de actualización

### v0.0.1 (2026-01-21) - Versión Inicial

- Versión inicial basada en el enunciado del proyecto oficial
- Estructura de 4 fases con checklists detallados
- Requisitos técnicos y entregables definidos

---

**Fecha de creación:** 2026-01-21  
**Última actualización:** 2026-01-21  
**Versión actual:** 0.0.7  
**Estado:** Pendiente de inicio
