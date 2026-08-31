/* Stored Procedures and created amd loaded */


create or alter procedure silver.load_silver AS 	
BEGIN
	-- Transfroming or inserting the data into Silver.crm_cust_info 
	--Table 1 Transformation
	TRUNCATE TABLE Silver.crm_cust_info
	INSERT INTO Silver.crm_cust_info
	(
		cst_id,
		cst_key,
		cst_firstname,
		cst_lastname,
		cst_material_status,
		cst_gndr,
		cst_create_date
	)
	SELECT
		cst_id,
		cst_key,

		TRIM(cst_firstname),

		TRIM(cst_lastname),

		CASE
			WHEN UPPER(TRIM(cst_material_status)) = 'S'
				THEN 'Single'
			WHEN UPPER(TRIM(cst_material_status)) = 'M'
				THEN 'Married'
			ELSE 'n/a'
		END,

		CASE
			WHEN UPPER(TRIM(cst_gndr)) = 'M'
				THEN 'Male'
			WHEN UPPER(TRIM(cst_gndr)) = 'F'
				THEN 'Female'
			ELSE 'n/a'
		END,

		cst_create_date

	FROM CTE
	WHERE Flag_Last = 1;



	--Table 2 Transformation
	TRUNCATE TABLE Silver.crm_prd_info
	INSERT INTO Silver.crm_prd_info (

		prd_id,
		cat_id,
		prd_key, 
		prd_nm,
		prd_cost, 
		prd_line,
		prd_start_dt, 
		prd_end_dt 
	)
	SELECT 
		prd_id,

		REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_') AS 	Cat_id,
		SUBSTRING(prd_key, 7 , LEN(prd_key)) AS prd_kay,
		prd_nm,
		ISNULL(prd_cost,0) AS prd_cost,
		CASE  UPPER(TRIM(prd_line))
			WHEN 'R' THEN 'Road'
			WHEN 'S' THEN 'Other Sales'
			WHEN 'M' THEN 'Mountain'
			WHEN 'T' THEN 'Touring'
			ELSE 'n/a'
		END AS prd_line,
		CAST(prd_start_dt AS DATE ) AS prd_start_date,
		CAST(LEAD (prd_start_dt) OVER(PARTITION BY prd_key ORDER BY prd_start_dt )-1 AS DATE)AS prd_end_dt
		FROM bronze.crm_prd_info




	--Table 3 Transformation
	TRUNCATE TABLE Silver.crm_sales_details	
	INSERT INTO silver.crm_sales_details(
		sls_ord_num,
		sls_prd_key,
		sls_cust_id,
		sls_order_dt,
		sls_ship_dt,
		sls_due_dt,
		sls_sales,
		sls_quantity,
		sls_price
	)		
	SELECT 
		sls_ord_num,
		sls_prd_key,
		sls_cust_id,
		CASE WHEN sls_order_dt  = 0 OR LEN(sls_order_dt) != 8 THEN NULL
			ELSE CAST(CAST(sls_order_dt AS VARCHAR) AS DATE)
		END AS sls_order_dt,

		CASE WHEN sls_Ship_dt  = 0 OR LEN(sls_Ship_dt) != 8 THEN NULL
			ELSE CAST(CAST(sls_Ship_dt AS VARCHAR) AS DATE)
		END AS sls_Ship_dt,

		CASE WHEN sls_due_dt  = 0 OR LEN(sls_due_dt) != 8 THEN NULL
			ELSE CAST(CAST(sls_due_dt AS VARCHAR) AS DATE)
		END AS sls_due_dt,

		CASE WHEN sls_sales IS NULL OR sls_sales <= 0 OR sls_sales != sls_quantity * ABS(sls_price)
			THEN sls_quantity * ABS(sls_price) 
			ELSE sls_sales
		END AS sls_sales,
		sls_quantity,
		CASE WHEN sls_price IS NULL OR sls_price <= 0
			THEN sls_sales/NULLIF(sls_quantity, 0)
			ELSE sls_price
		END AS sls_price

	FROM bronze.crm_sales_details




	 --	Table 4 Transformation 

	TRUNCATE TABLE silver.erp_cust_az12	
	INSERT INTO silver.erp_cust_az12(cid, bdate, gen)
	 SELECT 
		CASE WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4, LEN(cid))
			ELSE cid
		END cid,
		CASE WHEN bdate > GETDATE() THEN NULL
			ELSE bdate
		END bdate,
		CASE WHEN UPPER(TRIM(gen)) IN  ('F', 'FEMALE') THEN 'Female'
			WHEN UPPER(TRIM(gen)) IN  ('M', 'MALE') THEN 'Male'
			ELSE 'n/a'
		END gen
	FROM bronze.erp_cust_az12



	--Table 5 Transformation

	TRUNCATE TABLE silver.erp_loc_a101
	INSERT INTO silver.erp_loc_a101(
	cid, 
	cntry
	)
	SELECT 
		REPLACE(cid,'-' , '' )cid,
		CASE WHEN UPPER(TRIM(cntry)) IN ('USA',		'UNITED STATES', 'US') THEN 'USA'
			WHEN UPPER(TRIM(cntry)) IN ('GERMANY', 'DE') THEN 'Germany'
			WHEN UPPER(TRIM(cntry)) = 'UNITED KINGDOM' THEN 'UK'
			WHEN TRIM(cntry) = 'null' OR cntry = ' ' THEN 'n/a'
		ELSE cntry
		END AS cntry
	FROM bronze.erp_loc_a101



	--Table 6 Transformation


	TRUNCATE TABLE Bronze.erp_px_cat_g1v2	
	INSERT INTO Bronze.erp_px_cat_g1v2(
	id, cat, sub_cat, maintenance)

	select 
	id, 
	cat,
	sub_cat,
	maintenance
	FROM Bronze.erp_px_cat_g1v2

END
