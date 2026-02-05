CREATE KEYSPACE IF NOT EXISTS ventas_db
WITH replication = {'class': 'SimpleStrategy', 'replication_factor': 1};

USE ventas_db;

CREATE TABLE IF NOT EXISTS ventas_crudas (
    id_venta UUID,
    fecha_venta TIMESTAMP,
    id_producto TEXT,
    categoria TEXT,
    monto_total DECIMAL,
    id_cliente TEXT,
    PRIMARY KEY (fecha_venta)
);
