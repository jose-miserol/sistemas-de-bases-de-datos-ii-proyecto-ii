<div align="center">

# 🚀 Scalable Big Data Pipeline & Analytics

![Cassandra](https://img.shields.io/badge/Cassandra-1287B1?style=for-the-badge&logo=apache-cassandra&logoColor=white)
![Spark](https://img.shields.io/badge/Apache%20Spark-E25A1C?style=for-the-badge&logo=apache-spark&logoColor=white)
![ClickHouse](https://img.shields.io/badge/ClickHouse-F9D71C?style=for-the-badge&logo=clickhouse&logoColor=black)
![Docker](https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white)
![Python](https://img.shields.io/badge/Python-3776AB?style=for-the-badge&logo=python&logoColor=white)

### 📚 Universidad Nacional Experimental de Guayana (UNEG)

**Sistemas de Bases de Datos II • Proyecto N° 2 • Semestre 2025-II**

</div>

---

## � Descripción del Proyecto

Implementación de un **Data Pipeline completo** que demuestra la integración de tecnologías NoSQL (Apache Cassandra), procesamiento distribuido (Apache Spark) y almacenamiento analítico (ClickHouse) para simular un sistema de ingesta y análisis de grandes volúmenes de datos.

### 🎯 Objetivo

Diseñar, implementar y validar un prototipo funcional de arquitectura de datos escalable que simula:

- **Carga de grandes volúmenes** de datos transaccionales (NoSQL)
- **Procesamiento distribuido y paralelo** de datos (Spark)
- **Almacenamiento analítico** para generación de informes (Data Warehouse)

---

## 🏗️ Arquitectura del Sistema

```mermaid
graph LR
    A[Generador de Datos] -->|100k registros| B[Apache Cassandra]
    B -->|Lectura paralela| C[Apache Spark]
    C -->|Transformación ETL| D[ClickHouse]
    D -->|Consultas analíticas| E[Reportes]

    style B fill:#1168bd
    style C fill:#e25a1c
    style D fill:#f9d71c
```

| Capa                | Tecnología             | Rol                                            | Tipo   |
| ------------------- | ---------------------- | ---------------------------------------------- | ------ |
| **Ingesta**         | Apache Cassandra       | Almacenamiento de datos transaccionales crudos | OLTP   |
| **Transformación**  | Apache Spark (PySpark) | Procesamiento, limpieza y agregación paralela  | ELT    |
| **Analítica**       | ClickHouse             | Data Warehouse para consultas y reportes       | OLAP   |
| **Infraestructura** | Docker Compose         | Orquestación y despliegue de servicios         | DevOps |

---

## 📁 Estructura del Proyecto

```
proyecto_bigdata/
├── docker-compose.yml              # Definición de servicios Docker
├── infra/
│   ├── cassandra/
│   │   └── schema.cql              # Esquema de tabla ventas_crudas
│   └── clickhouse/
│       └── schema.sql              # Esquema de tabla ventas_resumen
├── notebooks/
│   ├── 01_connection.ipynb         # Validación de conectividad
│   ├── 02_generador_datos.ipynb    # Generación e ingesta de datos
│   ├── 03_etl_spark.ipynb          # Pipeline ETL con PySpark
│   └── 04_validacion_metricas.ipynb # Validación y consultas analíticas
├── docs/
│   ├── metricas.json               # Métricas de ejecución (JSON)
│   ├── metricas_reales.md          # Informe de métricas (Markdown)
│   ├── consultas_analiticas.sql    # Scripts SQL de consultas
│   ├── sistema_de_bases_de_datos...pdf # Informe final del proyecto
│   └── screenshot-v1...v4.jpeg     # Evidencia de ejecución
└── README.md                       # Este archivo
```

---

## 🚀 Inicio Rápido

### Prerrequisitos

- **Docker** instalado según sistema operativo:
  - **Windows/Mac:** [Docker Desktop](https://www.docker.com/products/docker-desktop/) (incluye Docker Engine + Docker Compose)
  - **Linux:** [Docker Engine](https://docs.docker.com/engine/install/) + [Docker Compose](https://docs.docker.com/compose/install/)
- Mínimo **8 GB RAM** disponibles para los contenedores
- **20 GB** de espacio en disco
- **Recomendado:** CPU con 4+ cores para mejor rendimiento de Spark

### Pasos de Instalación

1. **Clonar/crear el directorio del proyecto:**

   ```bash
   mkdir sistemas-de-bases-de-datos-ii-proyecto-ii
   cd sistemas-de-bases-de-datos-ii-proyecto-ii
   ```

2. **Levantar los servicios:**

   ```bash
   docker-compose up -d
   ```

3. **Verificar que todos los servicios estén corriendo:**

   ```bash
   docker-compose ps
   ```

   Deberías ver:
   - `cassandra` (puerto 9042)
   - `clickhouse` (puertos 8123, 9000)
   - `jupyter` (puerto 8888)

4. **Acceder a Jupyter:**

   ```
   http://localhost:8888
   ```

---

## 📊 Fases del Proyecto

### Fase 1: Configuración del Entorno ✓

- Despliegue de infraestructura con Docker Compose
- Configuración de redes y volúmenes
- Creación de esquemas en Cassandra y ClickHouse
- **Validación:** Conectividad de Spark con Cassandra

### Fase 2: Ingesta Masiva de Datos 📥

- Generación de 100,000 registros de ventas sintéticas
- Inserción masiva en Cassandra (objetivo: < 5 minutos)
- **Validación:** COUNT(\*) = 100,000 en `ventas_crudas`

### Fase 3: Procesamiento Paralelo 🔄

- Lectura distribuida desde Cassandra
- Transformaciones con PySpark:
  - Agrupación por `fecha_venta` y `categoria`
  - Cálculo de ventas totales y cantidad de transacciones
  - Limpieza de datos (nulos/negativos)
- **Validación:** DataFrame transformado correcto

### Fase 4: Carga y Consulta Analítica 📈

- Carga de datos agregados en ClickHouse
- Consultas analíticas:
  - Top 10 categorías por volumen
  - Promedio de ventas diarias por categoría
- **Validación:** Consultas < 3 segundos

---

## 📏 Versión Recomendada de Tecnologías

### Apache Cassandra

- **Versión:** 4.x (recomendado: 4.1.x)
- **Imagen Docker:** `cassandra:4.1`
- **Modelo de datos:** Column-family (Wide-column)
- **Características clave:**
  - Alta disponibilidad
  - Escalabilidad horizontal lineal
  - Optimizado para escrituras masivas
  - **Nota:** En laboratorio usar `SimpleStrategy` con `replication_factor=1`; en producción usar `NetworkTopologyStrategy` con replicación ≥ 3

### Apache Spark

- **Versión:** 3.x con PySpark (recomendado: 3.5.x)
- **Imagen Docker:** `jupyter/pyspark-notebook:latest` o `bitnami/spark:3.5`
- **Características clave:**
  - Procesamiento distribuido en memoria
  - API de DataFrames para transformaciones
  - Conector nativo con Cassandra
  - **Configuración de paralelismo:** Ajustar particiones según `(cores × 2-3)`, no usar default de 200 para datasets pequeños

### ClickHouse

- **Versión:** 23.x o 24.x (recomendado: 24.1.x)
- **Imagen Docker:** `clickhouse/clickhouse-server:24.1`
- **Motor:** MergeTree con `ORDER BY (fecha_venta, categoria)`
- **Características clave:**
  - Base de datos columnar
  - Compresión de datos (10x-100x)
  - Optimizado para consultas analíticas (OLAP)
  - Tipos de datos: `Decimal(18,2)` para montos monetarios, `UInt32` para contadores

---

## 📈 Métricas de Rendimiento

### Criterios de Éxito

| Operación                  | Objetivo     | Hardware Mínimo  | Observaciones                                        |
| -------------------------- | ------------ | ---------------- | ---------------------------------------------------- |
| **Ingesta (Cassandra)**    | < 5 minutos  | 4 cores, 8GB RAM | Umbral conservador; típico < 2 min con batch inserts |
| **Transformación (Spark)** | < 2 minutos  | 4 cores, 8GB RAM | Configurar particiones = cores × 2-3                 |
| **Consulta Top 10**        | < 3 segundos | 4 cores, 8GB RAM | ClickHouse sobre 100k registros agregados            |
| **Consulta Promedio**      | < 3 segundos | 4 cores, 8GB RAM | Agregación temporal por categoría                    |

**Nota:** Los tiempos objetivo son conservadores. Documentar hardware real (CPU, RAM, SO) junto con métricas medidas para comparación contextualizada.

---

## 🐛 Troubleshooting

### Problema: Servicios no inician

```bash
# Diagnóstico
docker-compose logs [servicio]
docker ps -a

# Solución
docker-compose down
docker-compose up -d
```

### Problema: Cassandra - Connection refused

**Causa:** Cassandra tarda 30-60 segundos en estar listo

```bash
# Verificar logs hasta ver:
docker logs cassandra-container | grep "Starting listening for CQL clients"
```

### Problema: Spark - OutOfMemoryError

**Solución:** Aumentar memoria en `docker-compose.yml`:

```yaml
jupyter:
  deploy:
    resources:
      limits:
        memory: 4G
```

### Problema: Dataset vacío en Spark

**Causa:** Nombres de keyspace/tabla incorrectos (case-sensitive)

```python
# Verificar nombres exactos
df = spark.read \
    .format("org.apache.spark.sql.cassandra") \
    .option("keyspace", "ventas_db") \
    .option("table", "ventas_crudas") \
    .load()

# Configurar particiones según cores disponibles
spark.conf.set("spark.sql.shuffle.partitions", "12")  # Ejemplo: 4 cores × 3
```

### Problema: Puertos ocupados

```bash
# Diagnóstico - Windows
netstat -ano | findstr :9042

# Diagnóstico - Linux/Mac
ss -tulpn | grep 9042
# o
lsof -i :9042

# Solución: Cambiar puerto en docker-compose.yml
ports:
  - "9043:9042"  # Usar puerto local diferente
```

Ver [`Task.md`](Task.md) sección "Troubleshooting" para más problemas comunes.

---

## 📚 Documentación

- **[Task.md](Task.md)** - Lista de tareas detallada con checklist completo
- **[NOTAS.md](NOTAS.md)** - Notas del proyecto y transcripción original

### Comandos Útiles

```bash
# Ver logs en tiempo real
docker-compose logs -f [servicio]

# Conectar a Cassandra
docker exec -it cassandra-container cqlsh

# Conectar a ClickHouse
docker exec -it clickhouse-container clickhouse-client

# Verificar recursos
docker stats

# Detener servicios
docker-compose down
```

---

## Entregables

El proyecto requiere la entrega de un **documento PDF único** que contenga:

1. **Diagrama de Arquitectura** - Flujo completo del pipeline
2. **Código Fuente** - Scripts CQL, SQL, Python y docker-compose.yml
3. **Resultados y Análisis:**
   - Screenshots de validación (3 capturas mínimo)
   - Código de consultas analíticas
   - Análisis comparativo Cassandra vs ClickHouse
4. **Documentación de Problemas** - Mínimo 2-3 problemas con formato estructurado

---

## 👥 Equipo

Este proyecto fue desarrollado para la asignatura **Sistemas de Bases de Datos II** de la UNEG.

| 🎭 Rol                    | 📋 Responsabilidad                       | 👤 Integrante      |
| :------------------------ | :--------------------------------------- | :----------------- |
| **🏗️ Data Architect**     | Modelado, Pipelines Spark y ClickHouse   | **Jose Miserol**   |
| **🔐 Data Engineer**      | Ingesta Cassandra, Validación y Pruebas  | **Miguel Gomez**   |
| **📊 Analytics Engineer** | Optimización OLAP y Consultas Analíticas | **Anthony Medina** |

</div>

---

## Referencias

- [Apache Cassandra Documentation](https://cassandra.apache.org/)
- [Apache Spark Documentation](https://spark.apache.org/docs/latest/)
- [ClickHouse Documentation](https://clickhouse.com/docs)
- [Docker Compose Reference](https://docs.docker.com/compose/)

---

## 📄 Licencia

Proyecto académico - UNEG 2025-II
