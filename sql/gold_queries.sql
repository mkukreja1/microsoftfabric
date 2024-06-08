QUERIES FOR webhits_by_country
________________________________________________________________________________________________________________________________________________________________________

CREATE TABLE "electroniz_gold"."webhits_by_country" AS
        (SELECT country_name, count(*) AS hits
         FROM "Electroniz_Lakehouse"."dbo"."silver_geolocation"
         GROUP BY country_name
         HAVING count(*) > 1000);

SELECT TOP (100) [country_name], [hits]
   FROM [Electroniz_Warehouse].[electroniz_gold].[webhits_by_country]
   ORDER BY hits DESC
________________________________________________________________________________________________________________________________________________________________________




QUERIES FOR aggregated_store_sales_by_quarter 
________________________________________________________________________________________________________________________________________________________________________

CREATE TABLE "electroniz_gold"."aggregated_store_sales_by_quarter" AS
(SELECT DATEPART(YEAR, order_date) AS year, DATEPART(QUARTER, order_date) as quarter, round(sum(sale_price_usd),2) as aggregated_sales_price
    FROM "Electroniz_Lakehouse"."dbo"."silver_store_orders"
    GROUP BY DATEPART(YEAR, order_date), DATEPART(QUARTER, order_date))

SELECT CONCAT( [year], '-',[quarter]) as [quarter], [aggregated_sales_price]
FROM [Electroniz_Warehouse].[electroniz_gold].[aggregated_store_sales_by_quarter]
________________________________________________________________________________________________________________________________________________________________________




QUERIES FOR aggregated_store_sales_by_year  
________________________________________________________________________________________________________________________________________________________________________

CREATE TABLE "electroniz_gold"."aggregated_sales_by_year" AS
SELECT year, SUM(aggregated_sales_price) AS aggregated_sales_price FROM
(SELECT DATEPART(YEAR, order_date) AS year, round(sum(sale_price_usd),2) as aggregated_sales_price
FROM "Electroniz_Lakehouse"."dbo"."silver_ecommerce_orders"
GROUP BY DATEPART(YEAR, order_date)
UNION ALL
SELECT DATEPART(YEAR, order_date) AS year, round(sum(sale_price_usd),2) as aggregated_sales_price
FROM "Electroniz_Lakehouse"."dbo"."silver_store_orders"
GROUP BY DATEPART(YEAR, order_date)
) as aggregated_sales GROUP BY year;

SELECT  [year], [aggregated_sales_price]
FROM [Electroniz_Warehouse].[electroniz_gold].[aggregated_sales_by_year]

________________________________________________________________________________________________________________________________________________________________________






QUERIES FOR aggregated_inventory_by_quarter  
________________________________________________________________________________________________________________________________________________________________________

CREATE TABLE "electroniz_gold"."aggregated_inventory_by_quarter" AS
SELECT product_category, product_name, year, quarter, units_sold, inventory
FROM
(
SELECT product_category, product_name, year, quarter, SUM(units_sold) AS units_sold
FROM (
SELECT product_category, silver_products.product_name, DATEPART(YEAR, order_date) AS year, 
DATEPART(QUARTER, order_date) AS quarter, count(*) AS units_sold
FROM "Electroniz_Lakehouse"."dbo"."silver_store_orders"
JOIN "Electroniz_Lakehouse"."dbo"."silver_products"
ON silver_products.product_id=silver_store_orders.product_id
GROUP BY product_category, silver_products.product_name, DATEPART(YEAR, order_date), DATEPART(QUARTER, order_date)
UNION ALL
SELECT product_category, silver_products.product_name, DATEPART(YEAR, order_date) AS year,
DATEPART(QUARTER, order_date) AS quarter, count(*) AS units_sold
FROM "Electroniz_Lakehouse"."dbo"."silver_ecommerce_orders"
JOIN "Electroniz_Lakehouse"."dbo"."silver_products"
ON silver_products.product_name=silver_ecommerce_orders.product_name
GROUP BY product_category, silver_products.product_name, DATEPART(YEAR, order_date), DATEPART(QUARTER, order_date)
) as aggregated_inventory_by_quarter1
WHERE year=DATEPART(yyyy, GETDATE())
GROUP BY product_category, product_name, year, quarter
) as aggregated_inventory_by_quarter1
JOIN "Electroniz_Lakehouse"."dbo"."silver_inventory"
ON silver_inventory.product=aggregated_inventory_by_quarter1.product_name


SELECT [product_category]
            ,[product_name]
            ,[year]
            ,[quarter]
            ,[units_sold]
            ,[inventory]
FROM [Electroniz_Warehouse].[electroniz_gold].[aggregated_inventory_by_quarter]
________________________________________________________________________________________________________________________________________________________________________