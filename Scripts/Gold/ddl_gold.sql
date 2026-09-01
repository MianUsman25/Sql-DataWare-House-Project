--Golden Layer

CREATE VIEW gold.dim_customers AS
SELECT
	ROW_NUMBER () OVER (ORDER BY cst_id) AS Customer_key,
	ci.cst_id AS customer_id,
	ci.cst_key AS customer_number,
	ci.cst_firstname AS first_name,
	ci.cst_lastname AS last_name,
	lc.cntry AS country,
	ci.cst_material_status AS material_status,
	CASE WHEN ci.cst_gndr != 'n/a'  THEN ci.cst_gndr
		ELSE COALESCE( sc.GEN, 'n/a')
	END AS gender,
	sc.bdate AS birth_date,
	ci.cst_create_date AS  create_date
FROM Silver.crm_cust_info AS ci
LEFT JOIN silver.erp_cust_az12 AS sc
ON sc.cid = ci.cst_key
LEFT JOIN silver.erp_loc_a101 AS lc
ON lc.cid = ci.cst_key


--2nd Table 

CREATE VIEW gold.dim_products AS
SELECT
	ROW_NUMBER () OVER (ORDER BY prd_start_dt, prd_key) AS Product_number,
	pn.prd_id AS product_id ,
	pn.prd_key AS product_Key,
	pn.prd_nm AS product_name,
	pn.cat_id AS category_id,	
	ct.cat AS category,
	ct.sub_cat AS sUB_category,
	ct.maintenance,
	pn.prd_cost AS cost,
	pn.prd_line AS line ,
	pn.prd_start_dt AS  star_Date
	
FROM silver.crm_prd_info AS pn
LEFT JOIN silver.erp_px_cat_g1v2 AS ct
ON ct.id = pn.cat_id


--3rd Table 



DROP VIEW IF EXISTS gold.fact_sales;
GO

CREATE VIEW gold.fact_sales AS
SELECT
    cu.Customer_key,
    pr.Product_key,

    sd.sls_order_dt AS order_date,
    sd.sls_ship_dt AS ship_date,
    sd.sls_due_dt AS due_date,

    sd.sls_sales AS sales,
    sd.sls_quantity AS quantity,
    sd.sls_price AS price

FROM silver.crm_sales_details AS sd

LEFT JOIN gold.dim_products AS pr
    ON sd.sls_prd_key = pr.Product_number

LEFT JOIN gold.dim_customers AS cu
    ON TRY_CONVERT(BIGINT, sd.sls_cust_id) = cu.customer_id;
GO

SELECT *
FROM gold.dim_customers AS f
LEFT JOIN gold.fact_sales AS c
ON f.Customer_key = c.Customer_key
WHERE c.Customer_key IS NULL
