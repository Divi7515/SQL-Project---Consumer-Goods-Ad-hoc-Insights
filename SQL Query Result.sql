--Question1
SELECT DISTINCT market FROM dim_customer
WHERE customer = 'Atliq Exclusive'
AND region = 'APAC';
--Question2
WITH CTE AS
(SELECT 
    COUNT(DISTINCT product_code) AS unique_products_2020
FROM
    fact_sales_monthly
WHERE
    fiscal_year = 2020),
CTE2 AS
(SELECT 
    COUNT(DISTINCT product_code) AS unique_products_2021
FROM
    fact_sales_monthly
WHERE
    fiscal_year = 2021)
SELECT unique_products_2020, unique_products_2021,
ROUND(((unique_products_2021-unique_products_2020)*100.0/unique_products_2020),2) AS percentage_chg
FROM 
cte,cte2;
--Question3
SELECT 
    segment,
    COUNT(DISTINCT product_code) AS product_count
FROM 
    dim_product
GROUP BY 
    segment
ORDER BY 
    product_count DESC;
--Question4
    WITH cte1 AS
(SELECT dp.segment,
    COUNT(DISTINCT dp.product_code) AS product_count_2020
FROM dim_product dp
JOIN fact_sales_monthly fsm 
ON dp.product_code = fsm.product_code
WHERE fsm.fiscal_year = 2020
GROUP BY dp.segment),
cte2 AS
(SELECT dp.segment,
    COUNT(DISTINCT dp.product_code) AS product_count_2021
FROM dim_product dp
JOIN fact_sales_monthly fsm 
ON dp.product_code = fsm.product_code
WHERE fsm.fiscal_year = 2021
GROUP BY dp.segment)
SELECT cte1.segment,product_count_2020,product_count_2021, (product_count_2021-product_count_2020) AS difference
FROM cte1 JOIN cte2
ON cte1.segment = cte2.segment;
--Question 5
(SELECT 
    dp.product_code, dp.product, manufacturing_cost
FROM
    dim_product dp
         JOIN
    fact_manufacturing_cost fmc ON dp.product_code = fmc.product_code
ORDER BY manufacturing_cost DESC
LIMIT 1)
UNION
(SELECT 
    dp.product_code, dp.product, manufacturing_cost
FROM
    dim_product dp
        JOIN
    fact_manufacturing_cost fmc ON dp.product_code = fmc.product_code
ORDER BY manufacturing_cost ASC
LIMIT 1); 
--Question 6
SELECT 
    dc.customer_code,
    dc.customer,
    ROUND(AVG(pre_invoice_discount_pct) * 100, 2) AS average_discount_percentage
FROM
    dim_customer dc
        LEFT JOIN
    fact_pre_invoice_deductions fpre ON dc.customer_code = fpre.customer_code
WHERE
    fiscal_year = 2021 AND market = 'India'
GROUP BY dc.customer_code , dc.customer
ORDER BY average_discount_percentage DESC
LIMIT 5; 
--Question 7
SELECT MONTHNAME(fsm.date) AS MONTH, 
fsm.fiscal_year as YEAR,
CONCAT(FORMAT(SUM(fsm.sold_quantity*fgp.gross_price)/1000000,2),'M')
AS Gross_Sales_Amount
FROM fact_sales_monthly fsm
JOIN dim_customer c 
ON fsm.customer_code = c.customer_code
JOIN fact_gross_price fgp
ON fsm.product_code = fgp.product_code
WHERE c.customer = 'AtliQ Exclusive'
GROUP BY MONTH, YEAR
ORDER BY fsm.fiscal_year; 
--Question 8
SELECT 
    CASE
        WHEN date BETWEEN '2019-09-01' AND '2019-11-01' THEN 'Q1'
        WHEN date BETWEEN '2019-12-01' AND '2020-02-01' THEN 'Q2'
        WHEN date BETWEEN '2020-03-01' AND '2020-05-01' THEN 'Q3'
        WHEN date BETWEEN '2020-06-01' AND '2020-08-01' THEN 'Q4'
    END AS Quarters,
    ROUND(SUM(sold_quantity) / 1000000, 2) AS total_sold_quantity_in_mln
FROM
    fact_sales_monthly
WHERE
    fiscal_year = 2020
GROUP BY quarters
ORDER BY total_sold_quantity_in_mln DESC;
--Question 9
WITH cte AS (
    SELECT 
        channel, 
        ROUND(SUM(gross_price * sold_quantity) / 1000000, 2) AS gross_sales_mln
    FROM 
        fact_sales_monthly s
    JOIN 
        fact_gross_price g USING (product_code, fiscal_year)
    JOIN 
        dim_customer c USING (customer_code)
    WHERE 
        fiscal_year = 2021
    GROUP BY 
        channel
)
SELECT 
    channel,
    gross_sales_mln,
    ROUND((gross_sales_mln * 100) / SUM(gross_sales_mln) OVER (), 2) AS pct
FROM 
    cte
ORDER BY 
    pct DESC;
    
    --Subquery--
    
    SELECT 
    channel,
    gross_sales_mln,
    ROUND((gross_sales_mln * 100) / total_sales, 2) AS percentage
FROM (
    SELECT 
        channel, 
        ROUND(SUM(gross_price * sold_quantity) / 1000000, 2) AS gross_sales_mln,
        SUM(ROUND(SUM(gross_price * sold_quantity) / 1000000, 2)) OVER () AS total_sales
    FROM 
        fact_sales_monthly s
    JOIN 
        fact_gross_price g USING (product_code, fiscal_year)
    JOIN 
        dim_customer c USING (customer_code)
    WHERE 
        fiscal_year = 2021
    GROUP BY 
        channel
) subquery
ORDER BY 
    percentage DESC;
--Question 10
    WITH cte1 AS (
    SELECT p.division,
           s.product_code,
           CONCAT(p.product, " (", p.variant, ")") AS product,
           SUM(s.sold_quantity) AS total_sold_qty,
           ROW_NUMBER() OVER (PARTITION BY p.division ORDER BY SUM(s.sold_quantity) DESC) AS rank_order
    FROM dim_product p
    JOIN fact_sales_monthly s 
        ON p.product_code = s.product_code
    WHERE s.fiscal_year = 2021
    GROUP BY p.division, s.product_code, p.product, p.variant
)
SELECT division, product_code, product, total_sold_qty, rank_order
FROM cte1
WHERE rank_order IN (1, 2, 3)
ORDER BY division, rank_order ASC;


  

