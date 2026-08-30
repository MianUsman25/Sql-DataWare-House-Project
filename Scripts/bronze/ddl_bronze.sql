/*
================================================================================
                    DATA WAREHOUSE - BRONZE LAYER
================================================================================

Purpose:
--------
This script prepares and loads the Bronze Layer of the Data Warehouse.

The Bronze Layer stores raw data extracted directly from the source systems
(ERP and CRM) with minimal transformation.

Data Flow:

    CRM CSV Files ───────────────┐
                                 │
                                 ▼
                          Bronze Layer
                                 │
    ERP CSV Files ───────────────┘

The Bronze Layer acts as the first storage layer in the ETL/ELT pipeline.

Main Responsibilities:
----------------------
1. Create Bronze tables.
2. Remove existing Bronze tables before recreating them.
3. Define table structures based on source CSV files.
4. Load raw CSV data into Bronze tables using BULK INSERT.
5. Provide a reusable stored procedure for Bronze ingestion.

Important:
----------
No major business transformations are performed in this layer.
The objective is to preserve the source data as closely as possible.

================================================================================
*/


/*
================================================================================
1. CRM CUSTOMER INFORMATION
================================================================================

Source:
    CRM System → cust_info.csv

Target:
    Bronze.crm_cust_info

Purpose:
    Stores raw customer information received from the CRM source system.

Before creating the table:
    - Check whether the table already exists.
    - If it exists, remove it.
    - Recreate the table with the required structure.

This ensures that the Bronze table starts from a clean state whenever
the database setup script is executed.
================================================================================
*/

IF OBJECT_ID('Bronze.crm_cust_info', 'U') IS NOT NULL
    DROP TABLE Bronze.crm_cust_info;

CREATE TABLE Bronze.crm_cust_info(
    cst_id INT,
    cst_key NVARCHAR(50),
    cst_firstname NVARCHAR(50),
    cst_lastname NVARCHAR(50),
    cst_material_status NVARCHAR(50),
    cst_gndr NVARCHAR(50),
    cst_create_date DATE
);


/*
================================================================================
2. CRM PRODUCT INFORMATION
================================================================================

Source:
    CRM System → prd_info.csv

Target:
    Bronze.crm_prd_info

Purpose:
    Stores raw product information from the CRM source system.

The table contains:
    - Product ID
    - Product key
    - Product name
    - Product cost
    - Product line
    - Product start date
    - Product end date

The data will later be cleaned and transformed in the Silver Layer.
================================================================================
*/

IF OBJECT_ID('bronze.crm_prd_info', 'U') IS NOT NULL
    DROP TABLE bronze.crm_prd_info;

CREATE TABLE bronze.crm_prd_info(
    prd_id INT,
    prd_key NVARCHAR(50),
    prd_nm NVARCHAR(50),
    prd_cost INT,
    prd_line NVARCHAR(50),
    prd_start_dt DATETIME,
    prd_end_dt DATETIME
);

GO


/*
================================================================================
3. CRM SALES DETAILS
================================================================================

Source:
    CRM System → sales_details.csv

Target:
    Bronze.crm_sales_details

Purpose:
    Stores raw sales transaction information from the CRM system.

This table represents sales transactions and contains information such as:
    - Order number
    - Product key
    - Customer ID
    - Order date
    - Shipping date
    - Due date
    - Sales amount
    - Quantity
    - Price

The date fields are currently stored as INT because the Bronze Layer is
designed to capture the source structure with minimal transformation.

Date conversion and validation will be handled in a later transformation
layer.
================================================================================
*/

IF OBJECT_ID('bronze.crm_sales_details', 'U') IS NOT NULL
    DROP TABLE bronze.crm_sales_details;

CREATE TABLE bronze.crm_sales_details(
    sls_ord_num NVARCHAR(50),
    sls_prd_key NVARCHAR(50),
    sls_cust_id INT,
    sls_order_dt INT,
    sls_ship_dt INT,
    sls_due_dt INT,
    sls_sales INT,
    sls_quantity INT,
    sls_price INT
);

GO


/*
================================================================================
4. ERP LOCATION INFORMATION
================================================================================

Source:
    ERP System → LOC_A101.csv

Target:
    Bronze.erp_loc_a101

Purpose:
    Stores raw customer/location information received from the ERP system.

Main fields:
    - cid    → Customer identifier
    - cntry  → Country

This dataset will later be integrated with CRM customer information during
the Silver/Gold transformation process.
================================================================================
*/

IF OBJECT_ID('bronze.erp_loc_a101', 'U') IS NOT NULL
    DROP TABLE bronze.erp_loc_a101;

CREATE TABLE bronze.erp_loc_a101(
    cid NVARCHAR(50),
    cntry NVARCHAR(50)
);

GO


/*
================================================================================
5. ERP CUSTOMER INFORMATION
================================================================================

Source:
    ERP System → CUST_AZ12.csv

Target:
    Bronze.erp_cust_az12

Purpose:
    Stores raw customer demographic information from the ERP system.

Main fields:
    - cid → Customer identifier
    - bdate → Customer birth date
    - GEN → Customer gender

This data will later be integrated with CRM customer information to create
a unified customer dimension.
================================================================================
*/

IF OBJECT_ID('bronze.erp_cust_az12', 'U') IS NOT NULL
    DROP TABLE bronze.erp_cust_az12;

CREATE TABLE bronze.erp_cust_az12(
    cid NVARCHAR(50),
    bdate DATE,
    GEN NVARCHAR(50)
);

GO


/*
================================================================================
6. ERP PRODUCT CATEGORY INFORMATION
================================================================================

Source:
    ERP System → PX_CAT_G1V2.csv

Target:
    Bronze.erp_px_cat_g1v2

Purpose:
    Stores raw product category and maintenance information from the ERP
    source system.

Main fields:
    - id          → Product/category identifier
    - cat         → Product category
    - sub_cat     → Product sub-category
    - maintenance → Maintenance information

This data will later be used to enrich product information in the analytical
data model.
================================================================================
*/

IF OBJECT_ID('bronze.erp_px_cat_g1v2', 'U') IS NOT NULL
    DROP TABLE bronze.erp_px_cat_g1v2;

CREATE TABLE bronze.erp_px_cat_g1v2(
    id NVARCHAR(50),
    cat NVARCHAR(50),
    sub_cat NVARCHAR(50),
    maintenance NVARCHAR(50)
);

GO



/*
================================================================================
                    BRONZE DATA LOAD PROCEDURE
================================================================================

Procedure:
    bronze.load_bronze

Purpose:
    Loads raw data from the CRM and ERP CSV files into the Bronze Layer.

Why use a stored procedure?
---------------------------
Instead of manually executing six separate BULK INSERT statements every time,
the entire Bronze ingestion process is wrapped inside one reusable procedure.

Execution:

    EXEC bronze.load_bronze;

Data Sources:
-------------
CRM:
    1. cust_info.csv
    2. prd_info.csv
    3. sales_details.csv

ERP:
    4. PX_CAT_G1V2.csv
    5. CUST_AZ12.csv
    6. LOC_A101.csv

Loading Method:
---------------
BULK INSERT is used to efficiently load CSV files directly into SQL Server.

Important:
----------
The Bronze Layer intentionally performs minimal transformation.

The main purpose is to:
    Source Files → Raw Bronze Tables

Data cleaning, standardization, validation, and business logic will be
implemented in subsequent layers.
================================================================================
*/

CREATE OR ALTER PROCEDURE bronze.load_bronze AS
BEGIN


    /*
    ============================================================================
    1. LOAD CRM CUSTOMER DATA
    ============================================================================

    Source File:
        cust_info.csv

    Target Table:
        bronze.crm_cust_info

    FIRSTROW = 2:
        Skips the CSV header row.

    FIELDTERMINATOR = ',':
        Specifies comma as the delimiter between CSV columns.

    TABLOCK:
        Requests a table-level lock during the bulk load operation, which can
        improve loading performance.
    ============================================================================
    */

    BULK INSERT bronze.crm_cust_info
    FROM 'D:\Downloads\sql-data-warehouse-project\sql-data-warehouse-project\datasets\source_crm\cust_info.csv'
    WITH (
        FIRSTROW = 2,
        FIELDTERMINATOR = ',',
        TABLOCK
    );

    -- Verify that CRM customer data was successfully loaded.
    SELECT *
    FROM bronze.crm_cust_info;


    /*
    ============================================================================
    2. LOAD CRM PRODUCT DATA
    ============================================================================

    Source File:
        prd_info.csv

    Target Table:
        bronze.crm_prd_info

    The raw product data is loaded without applying business transformations.
    ============================================================================
    */

    BULK INSERT bronze.crm_prd_info
    FROM 'D:\Downloads\sql-data-warehouse-project\sql-data-warehouse-project\datasets\source_crm\prd_info.csv'
    WITH (
        FIRSTROW = 2,
        FIELDTERMINATOR = ',',
        TABLOCK
    );

    -- Verify that CRM product data was successfully loaded.
    SELECT *
    FROM bronze.crm_prd_info;


    /*
    ============================================================================
    3. LOAD CRM SALES DATA
    ============================================================================

    Source File:
        sales_details.csv

    Target Table:
        bronze.crm_sales_details

    This table contains the raw sales transaction records that will become
    one of the main sources for sales analytics and the future fact table.
    ============================================================================
    */

    BULK INSERT bronze.crm_sales_details
    FROM 'D:\Downloads\sql-data-warehouse-project\sql-data-warehouse-project\datasets\source_crm\sales_details.csv'
    WITH (
        FIRSTROW = 2,
        FIELDTERMINATOR = ',',
        TABLOCK
    );

    -- Verify that CRM sales data was successfully loaded.
    SELECT *
    FROM bronze.crm_sales_details;


    /*
    ============================================================================
    4. LOAD ERP PRODUCT CATEGORY DATA
    ============================================================================

    Source File:
        PX_CAT_G1V2.csv

    Target Table:
        bronze.erp_px_cat_g1v2

    This dataset provides product category and sub-category information that
    will later be used to enrich product-related analytical data.
    ============================================================================
    */

    BULK INSERT bronze.erp_px_cat_g1v2
    FROM 'D:\Downloads\sql-data-warehouse-project\sql-data-warehouse-project\datasets\source_erp\PX_CAT_G1V2.csv'
    WITH (
        FIRSTROW = 2,
        FIELDTERMINATOR = ',',
        TABLOCK
    );

    -- Verify that ERP product category data was successfully loaded.
    SELECT *
    FROM bronze.erp_px_cat_g1v2;


    /*
    ============================================================================
    5. LOAD ERP CUSTOMER DATA
    ============================================================================

    Source File:
        CUST_AZ12.csv

    Target Table:
        bronze.erp_cust_az12

    Contains additional customer attributes such as birth date and gender.

    This data will later be combined with CRM customer data to build a more
    complete customer profile.
    ============================================================================
    */

    BULK INSERT bronze.erp_cust_az12
    FROM 'D:\Downloads\sql-data-warehouse-project\sql-data-warehouse-project\datasets\source_erp\CUST_AZ12.csv'
    WITH (
        FIRSTROW = 2,
        FIELDTERMINATOR = ',',
        TABLOCK
    );

    -- Verify that ERP customer data was successfully loaded.
    SELECT *
    FROM bronze.erp_cust_az12;


    /*
    ============================================================================
    6. LOAD ERP LOCATION DATA
    ============================================================================

    Source File:
        LOC_A101.csv

    Target Table:
        bronze.erp_loc_a101

    Contains customer location/country information.

    This dataset will later be used to enrich the customer dimension and
    support geographic analysis.
    ============================================================================
    */

    BULK INSERT bronze.erp_loc_a101
    FROM 'D:\Downloads\sql-data-warehouse-project\sql-data-warehouse-project\datasets\source_erp\LOC_A101.csv'
    WITH (
        FIRSTROW = 2,
        FIELDTERMINATOR = ',',
        TABLOCK
    );

    -- Verify that ERP location data was successfully loaded.
    SELECT *
    FROM bronze.erp_loc_a101;

END;


/*
================================================================================
                        EXECUTE BRONZE LOAD
================================================================================

The following statement executes the stored procedure and loads all six
source datasets into their corresponding Bronze tables.

Execution Flow:

    CRM:
        cust_info.csv
              ↓
        crm_cust_info

        prd_info.csv
              ↓
        crm_prd_info

        sales_details.csv
              ↓
        crm_sales_details


    ERP:
        PX_CAT_G1V2.csv
              ↓
        erp_px_cat_g1v2

        CUST_AZ12.csv
              ↓
        erp_cust_az12

        LOC_A101.csv
              ↓
        erp_loc_a101

================================================================================
*/

EXEC bronze.load_bronze;
