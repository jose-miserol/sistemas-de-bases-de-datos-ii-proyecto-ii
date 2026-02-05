-- =====================================================
-- Schema de ClickHouse para Proyecto Data Pipeline
-- Archivo: schema.sql
-- Propósito: Crear base de datos y tabla para OLAP
-- =====================================================

-- Crear base de datos analítica
CREATE DATABASE IF NOT EXISTS dw_analitico;

-- Usar la base de datos
USE dw_analitico;

-- Crear tabla de resumen de ventas
-- Engine: ReplacingMergeTree para idempotencia (permite re-ejecuciones sin duplicados)
-- ORDER BY: Optimiza queries por fecha y categoría
CREATE TABLE IF NOT EXISTS ventas_resumen (
    fecha_venta Date,
    categoria String,
    ventas_totales Decimal(18, 2),
    cantidad_transacciones UInt32
) ENGINE = ReplacingMergeTree()
ORDER BY (fecha_venta, categoria)
COMMENT 'Tabla analítica OLAP con datos agregados de ventas por día y categoría';

-- Verificación
DESCRIBE TABLE ventas_resumen;

-- Consulta de prueba (debe retornar 0 filas inicialmente)
SELECT COUNT(*) as total_registros FROM ventas_resumen;
