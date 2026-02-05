-- =====================================================
-- Consultas Analíticas para ClickHouse (Fase 4.2)
-- Archivo: docs/consultas_analiticas.sql
-- Propósito: Validar la carga de datos y demostrar capacidades OLAP
-- =====================================================

-- Consulta 1: Top 10 categorías con mayor volumen de ventas
-- Objetivo: Identificar qué categorías generan más ingresos.
SELECT 
    categoria,
    sum(ventas_totales) as total_ventas_periodo
FROM dw_analitico.ventas_resumen
GROUP BY categoria
ORDER BY total_ventas_periodo DESC
LIMIT 10;

-- Consulta 2: Promedio de ventas diarias por categoría
-- Objetivo: Analizar el rendimiento diario promedio por categoría.
SELECT 
    categoria,
    avg(ventas_totales) as promedio_ventas_diarias,
    sum(cantidad_transacciones) as transacciones_totales
FROM dw_analitico.ventas_resumen
GROUP BY categoria
ORDER BY categoria;
