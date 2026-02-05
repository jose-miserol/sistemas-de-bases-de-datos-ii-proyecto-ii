# Diagrama de Arquitectura - Proyecto Data Pipeline

Este diagrama ilustra el flujo de datos desde la generación y captura transaccional hasta el análisis OLAP, destacando las tecnologías y capas utilizadas.

```mermaid
graph LR
    subgraph "Capa de Ingesta (OLTP)"
        GEN[Generador de Datos]
        CAS[(Apache Cassandra)]
        GEN -->|Inserts Masivos| CAS
        style CAS fill:#f9f,stroke:#333,stroke-width:2px
    end

    subgraph "Capa de Transformación (ELT)"
        SPARK[Apache Spark / PySpark]
        CAS -->|Lectura Paralela| SPARK
        SPARK -->|Agregación & Limpieza| SPARK
        style SPARK fill:#ff9,stroke:#333,stroke-width:2px
    end

    subgraph "Capa Analítica (OLAP)"
        CH[(ClickHouse)]
        SPARK -->|Escritura JDBC| CH
        USER((Analista / Usuario))
        USER -->|Consultas SQL| CH
        style CH fill:#9f9,stroke:#333,stroke-width:2px
    end

    %% Definición de estilos
    classDef storage fill:#fff,stroke:#333,stroke-width:1px;
    classDef compute fill:#fff,stroke:#333,stroke-width:1px;
```

## Descripción de Componentes

1.  **Apache Cassandra (OLTP):** Base de datos NoSQL orientada a columnas, optimizada para escrituras masivas. Almacena los datos crudos (`ventas_crudas`).
2.  **Apache Spark (ELT):** Motor de procesamiento distribuido. Lee los datos particionados de Cassandra, realiza agregaciones (suma de ventas, conteo de transacciones) y transformación de tipos de datos.
3.  **ClickHouse (OLAP):** Data Warehouse columnar. Almacena los datos procesados (`ventas_resumen`) optimizando la compresión y la velocidad de consulta para reportes analíticos.
