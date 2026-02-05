# Análisis Complementario del Proyecto

Este documento contiene las secciones faltantes para el informe final del proyecto.

---

## 📊 Comparación de Tiempos: Ingesta vs Consulta Analítica

La siguiente tabla compara los tiempos de ejecución entre la fase de ingesta masiva (Cassandra) y las consultas analíticas (ClickHouse), demostrando la especialización de cada tecnología.

| Operación              | Tecnología | Tiempo Medido | Objetivo |    Registros    | Observación                          |
| :--------------------- | :--------- | :-----------: | :------: | :-------------: | :----------------------------------- |
| **Ingesta Masiva**     | Cassandra  |   ~6.4 seg    | < 5 min  |     100,000     | Batch inserts con `cassandra-driver` |
| **Transformación ETL** | Spark      |   ~15.2 seg   | < 2 min  | 100,000 → 1,830 | GroupBy + Aggregation                |
| **Consulta Top 10**    | ClickHouse |   < 0.1 seg   | < 3 seg  |      1,830      | `SELECT ... GROUP BY ... LIMIT 10`   |
| **Consulta Promedios** | ClickHouse |   < 0.1 seg   | < 3 seg  |      1,830      | `SELECT ... AVG() ... GROUP BY`      |

> **Nota:** Los tiempos fueron medidos en un entorno Docker con 4 cores y 8GB RAM.

### Conclusión de Tiempos

- **Cassandra** logra ingestar 100,000 registros en ~6.4 segundos (15,600 reg/seg), muy por debajo del umbral de 5 minutos.
- **ClickHouse** responde consultas analíticas en milisegundos sobre datos pre-agregados, cumpliendo el objetivo de < 3 segundos.
- La diferencia de velocidad demuestra la importancia de elegir la tecnología correcta para cada capa del pipeline.

---

## 🔍 Análisis Comparativo: Cassandra vs ClickHouse

### ¿Por qué Apache Cassandra para la Ingesta (OLTP)?

| Característica          | Cassandra                       | Justificación                                        |
| :---------------------- | :------------------------------ | :--------------------------------------------------- |
| **Modelo de Escritura** | Log-Structured Merge Tree (LSM) | Optimizado para escrituras secuenciales masivas      |
| **Escalabilidad**       | Horizontal (añadir nodos)       | Maneja crecimiento de datos sin downtime             |
| **Consistencia**        | Eventual (tunable)              | Prioriza disponibilidad sobre consistencia inmediata |
| **Caso de Uso Ideal**   | Ingesta de eventos, logs, IoT   | Alto throughput de escrituras                        |

**Conclusión:** Cassandra es ideal para la capa de ingesta porque puede absorber millones de escrituras por segundo sin degradación, distribuyendo la carga entre nodos.

---

### ¿Por qué ClickHouse para Analíticas (OLAP)?

| Característica        | ClickHouse               | Justificación                                    |
| :-------------------- | :----------------------- | :----------------------------------------------- |
| **Almacenamiento**    | Columnar                 | Lee solo las columnas necesarias para cada query |
| **Compresión**        | 10x-100x                 | Reduce I/O y acelera escaneos                    |
| **Agregaciones**      | Vectorizadas (SIMD)      | Procesa millones de filas en milisegundos        |
| **Caso de Uso Ideal** | Reportes, dashboards, BI | Consultas complejas sobre grandes volúmenes      |

**Conclusión:** ClickHouse es superior para consultas analíticas porque su arquitectura columnar permite escanear solo los datos relevantes, mientras que Cassandra (orientada a filas) tendría que leer registros completos.

---

### Tabla Comparativa Directa

| Aspecto             | Cassandra (OLTP)      | ClickHouse (OLAP)                |
| :------------------ | :-------------------- | :------------------------------- |
| **Fortaleza**       | Escrituras masivas    | Lecturas analíticas              |
| **Debilidad**       | Queries ad-hoc lentos | Escrituras individuales costosas |
| **Modelo**          | Wide-column (filas)   | Columnar                         |
| **Escalado**        | Horizontal (sharding) | Horizontal (replicación)         |
| **Latencia típica** | 1-5ms (escritura)     | 10-100ms (query compleja)        |
| **Consistencia**    | Eventual              | Strong                           |

---

### Por Qué Este Pipeline Usa Ambas

```
Cassandra (Ingesta) → Spark (Transformación) → ClickHouse (Análisis)
```

1. **Cassandra** recibe los datos crudos a alta velocidad sin bloquear el sistema fuente.
2. **Spark** transforma y agrega los datos, reduciendo el volumen de 100,000 a 1,830 registros.
3. **ClickHouse** almacena los datos pre-agregados para consultas instantáneas del usuario final.

Esta arquitectura separa las responsabilidades, permitiendo que cada tecnología opere en su punto óptimo de rendimiento.
