# 📊 Métricas de Rendimiento - Valores Reales

**Fecha de ejecución:** 2026-02-05 18:58:00

## Tabla Comparativa

| Operación | Tiempo Real | Objetivo | Cumple |
|:---|:---:|:---:|:---:|
| Ingesta Cassandra (100k) | 8.05 s | < 5 min | ✅ |
| Transformación Spark ETL | 22.73 s | < 2 min | ✅ |
| Consulta Top 10 (ClickHouse) | 0.0088 s | < 3 seg | ✅ |
| Consulta Promedio (ClickHouse) | 0.0099 s | < 3 seg | ✅ |

## Detalles de Ejecución

- **Registros insertados en Cassandra:** 100,000
- **Registros procesados por Spark:** 411,474
- **Registros en ClickHouse:** 5,490
