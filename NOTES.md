# Changelog / Notas de Implementación

## Sesión: Organización y Fase 2 (Ingesta Cassandra)

**Fecha:** 2026-02-04

### Cambios Realizados

- [x] Creación de este archivo `NOTES.md`.
- [x] Renombrado y organización de notebooks:
  - `Untitled3.ipynb` -> `02_generador_datos.ipynb`
  - `Untitled2.ipynb` -> `03_etl_spark.ipynb`
  - `Untitled.ipynb` -> `LEGACY_connectivity_test.ipynb`
  - `Untitled1.ipynb` -> `LEGACY_failed_connection.ipynb`
- [x] Implementación de lógica de ingesta en `02_generador_datos.ipynb`:
  - Instalación de `cassandra-driver`.
  - Configuración de Schema (Keyspace/Table) automática.
  - Generación de datos aleatorios.
  - Inserción masiva usando `BatchStatement`.
- [x] Reestructuración del proyecto según `Task.md`:
  - Eliminado: `cassandra/` (carpeta duplicada raíz).
  - Movido: `clickhouse/` -> `infra/clickhouse/`.
  - Movido: `docker-compose.yml` -> `infra/docker-compose.yml`.
  - Movido: `docker-compose.yml` -> `infra/docker-compose.yml`.
  - Actualizado: Rutas de volúmenes en `docker-compose.yml` (`./` -> `../`).
- [x] Implementación de `03_etl_spark.ipynb`:
  - Configuración de SparkSession con conectores Cassandra/ClickHouse.
  - Lectura de `ventas_crudas`.
  - Transformación: Agregación por fecha/categoría.
  - Escritura vía JDBC a ClickHouse.
- [x] Creación de `docs/consultas_analiticas.sql` con las Queries OLAP requeridas (Fase 4.2).
- [x] Creación de `docs/arquitectura.md` con el diagrama Mermaid del flujo de datos.
- [x] **REVERSIÓN:** Se movió `docker-compose.yml` de vuelta a la raíz (`./`) para facilitar ejecución.
  - Paths actualizados (`./notebooks` etc).
  - README actualizado.
