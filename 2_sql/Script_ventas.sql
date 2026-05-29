CREATE DATABASE IF NOT EXISTS ventas;

USE ventas;

DROP TABLE IF EXISTS orders;

CREATE TABLE orders (
    row_id INT,
    order_id VARCHAR(50),
    order_date DATE,
    ship_date DATE,
    ship_mode VARCHAR(50),
    customer_id VARCHAR(50),
    customer_name VARCHAR(100),
    segment VARCHAR(50),
    country_region VARCHAR(100),
    city VARCHAR(100),
    state_province VARCHAR(100),
    postal_code VARCHAR(20),
    region VARCHAR(50),
    product_id VARCHAR(50),
    category VARCHAR(50),
    sub_category VARCHAR(50),
    product_name VARCHAR(255),
    sales DECIMAL(10 , 2 ),
    quantity INT,
    discount DECIMAL(5 , 2 ),
    profit DECIMAL(10 , 2 )
);
/* PROCEDIMIENTO ALMACENADO PARA SELECT */

DELIMITER //

CREATE PROCEDURE pe_orders()
BEGIN
    SELECT * FROM orders;
END //

DELIMITER ;

call pe_orders();

/* VALIDACION DE DATOS */

SELECT 
    COUNT(*)
FROM
    orders;

SELECT 
    MIN(order_date), MAX(order_date)
FROM
    orders;

SELECT 
    *
FROM
    orders
LIMIT 5;

/* NULLS */

SELECT 
    SUM(CASE
        WHEN order_id IS NULL THEN 1
        ELSE 0
    END) AS order_id_nulls,
    SUM(CASE
        WHEN order_date IS NULL THEN 1
        ELSE 0
    END) AS order_date_nulls,
    SUM(CASE
        WHEN ship_date IS NULL THEN 1
        ELSE 0
    END) AS ship_date_nulls,
    SUM(CASE
        WHEN sales IS NULL THEN 1
        ELSE 0
    END) AS sales_nulls,
    SUM(CASE
        WHEN profit IS NULL THEN 1
        ELSE 0
    END) AS profit_nulls
FROM
    orders;


/*------ DATA CLEANING -----*/

/* DUPLICADOS */

CALL pe_orders();

/* id y sus duplicados */
SELECT 
    order_id, COUNT(*) AS cantidad_duplicados
FROM
    orders
GROUP BY order_id
HAVING COUNT(*) > 1;

 /* subconsulta para contar duplicados */
 
SELECT 
    COUNT(*) AS cantidad_duplicados
FROM
    (SELECT 
        order_id, COUNT(*) AS cantidad_duplicados
    FROM
        orders
    GROUP BY order_id
    HAVING COUNT(*) > 1) AS subquery;

/* ----- REMOVER DUPLICADOS ----- */

RENAME TABLE orders to conduplicados; /* renombramos tabla */

CREATE TEMPORARY TABLE tem_limpieza AS 
SELECT DISTINCT * FROM CONDUPLICADOS;      /* creamos una tabla temporal sin duplicados usando distinct */

SELECT 
    COUNT(*) AS original
FROM
    conduplicados;      /* verificamos con conteo el numero de registros*/

CREATE TABLE orders AS SELECT * FROM
    tem_limpieza;        /* creamos tabla nueva a partir de la temporal sin duplicados */


/*--------- KPIS ---------*/
use ventas;
SELECT 
    ROUND(SUM(sales), 2) AS ventas_totales
FROM
    orders;

SELECT 
    ROUND(SUM(profit), 2) AS profit_total
FROM
    orders;

SELECT 
    COUNT(DISTINCT order_id) AS ordenes_totales
FROM
    orders;

/* VALIDACION */

/* Verificando valores negativos raros */
SELECT 
    *
FROM
    orders
WHERE
    sales < 0 OR quantity < 0
        OR discount < 0;
   
/* PROFIT NEGATIVO */

/* Perdidas */

SELECT 
    *
FROM
    orders
WHERE
    profit < 0;

/* DESCUENTOS ALTOS */

SELECT 
    discount, COUNT(*) AS total
FROM
    orders
WHERE
    discount > 0.5
GROUP BY discount
ORDER BY discount DESC;

/* COLUMNAS DERIVADAS */

SELECT 
    order_date,
    YEAR(order_date) AS year,
    MONTH(order_date) AS month
FROM
    orders;

/* VENTAS POR MES Y AÑO */

SELECT 
    DATE_FORMAT(order_date, '%Y-%m') AS y_month,
    ROUND(SUM(sales), 2) AS total_sales
FROM
    orders
GROUP BY y_month
ORDER BY y_month;

/* PROFIT POR MES */

SELECT 
MONTH(order_date) AS mes,
SUM(profit) AS total_profit
FROM orders
GROUP BY mes
ORDER BY total_profit DESC;

/* ANALISIS DE NEGOCIO */

call pe_orders();

/* Top 10 productos por ventas */

SELECT 
    product_name,
    SUM(sales) AS total_sales
FROM orders
GROUP BY product_name
ORDER BY total_sales DESC
LIMIT 10;

/* Top 10 productos por profit */

select product_name,
sum(profit) as total_profit
from orders
group by product_name
order by total_profit desc;

/* Productos con perdidas */
SELECT 
    product_name,
    SUM(profit) AS perdidas,
    SUM(sales) AS ventas
FROM orders
WHERE profit < 0
GROUP BY product_name
ORDER BY perdidas ASC
LIMIT 10;

/* Ventas por region */

select sum(sales) as ventas,
country_region from orders
group by country_region
order by ventas desc;

/* Profit por region */

select sum(profit) as total_profit,
country_region from orders
group by country_region
order by total_profit desc;

/* Region mas rentable con porcentaje de ganancias */

SELECT 
    country_region,
    SUM(sales) AS total_sales,
    SUM(profit) AS total_profit,
    ROUND(SUM(profit) / SUM(sales) * 100, 2) AS profit_margin_pct
FROM orders
GROUP BY country_region
ORDER BY total_profit DESC;

/* Ventas por categoria */

call pe_orders();

select category,
sum(sales) as total_sales
from orders
group by category
order by total_sales desc;

/* Profit por categoria */

select category,
sum(profit) as total_profit
from orders
group by category
order by total_profit desc;

/* Subcategorias mas importantes */

call pe_orders();

SELECT 
    sub_category,
    SUM(sales) AS total_sales,
    SUM(profit) AS total_profit,
    ROUND(SUM(profit) / SUM(sales) * 100, 2) AS profit_margin_pct
FROM orders
GROUP BY sub_category
ORDER BY total_profit DESC;

/* Top clientes por ventas */

select customer_name,
sum(sales) as total_sales
from orders
group by customer_name
order by total_sales desc;

/* Numero de ordenes por cliente */

SELECT 
    customer_name,
    COUNT(DISTINCT order_id) AS total_orders
FROM orders
GROUP BY customer_name
ORDER BY total_orders DESC;

/* Clientes recurrentes (compras en el ultimo año) */

SELECT 
    customer_name,
    COUNT(DISTINCT order_id) AS total_orders_2025
FROM orders
WHERE YEAR(order_date) = 2025
GROUP BY customer_name
order by total_orders_2025 desc;

/* Ventas mensuales y filtrar meses altos */

SELECT 
    YEAR(order_date) AS year,
    MONTH(order_date) AS month,
    SUM(sales) AS total_sales
FROM orders
GROUP BY YEAR(order_date), MONTH(order_date)
ORDER BY total_sales DESC
LIMIT 5;

/* Creacion de vista */


CREATE VIEW vw_orders_clean AS
SELECT 
    -- IDs
    order_id,
    customer_id,
    product_id,

    -- Cliente
    customer_name,
    segment,

    -- Ubicación
    country_region,
    city,
    state_province,
    postal_code,
    region,

    -- Producto
    category,
    sub_category,
    product_name,

    -- Logística
    ship_mode,
    order_date,
    ship_date,

    -- Fechas derivadas
    YEAR(order_date) AS order_year,
    MONTH(order_date) AS order_month,
    MONTHNAME(order_date) AS month_name,

    -- Métricas
    sales,
    quantity,
    discount,
    profit,

    -- Métricas derivadas
    ROUND(sales / quantity, 2) AS unit_price,
    DATEDIFF(ship_date, order_date) AS shipping_days

FROM orders;

SHOW CREATE VIEW vw_orders_clean;

SELECT * FROM vw_orders_clean;
