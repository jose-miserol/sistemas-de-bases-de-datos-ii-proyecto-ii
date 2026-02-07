CREATE KEYSPACE IF NOT EXISTS ventas_db
WITH replication = {'class': 'SimpleStrategy', 'replication_factor': 1};

USE ventas_db;

CREATE TABLE IF NOT EXISTS ventas_crudas (
    id_venta UUID,
    id_cliente UUID,
    id_producto UUID,
    fecha_venta DATE,
    categoria TEXT,
    producto TEXT,
    cantidad INT,
    precio_unitario DECIMAL,
    monto_total DECIMAL,
    metodo_pago TEXT,
    region TEXT,
    PRIMARY KEY (fecha_venta, id_venta)
) WITH CLUSTERING ORDER BY (id_venta ASC);
