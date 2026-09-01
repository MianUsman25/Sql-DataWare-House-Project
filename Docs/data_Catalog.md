# Golden Layer --- Data Catalog

The **Gold Layer** contains business-ready dimensional and fact views
designed for analytics, reporting, KPI generation, and Power BI
consumption.

The Gold Layer consists of: 1. `gold.dim_customers` 2.
`gold.dim_products` 3. `gold.fact_sales`

------------------------------------------------------------------------

# 1. `gold.dim_customers`

-   **Purpose:** Stores enriched customer information by combining CRM
    customer data with demographic and geographic information from ERP
    sources.
-   **Type:** View
-   **Business Role:** Customer Dimension
-   **Grain:** One row per customer.

## Columns

  -----------------------------------------------------------------------
  Column Name             Data Type               Description
  ----------------------- ----------------------- -----------------------
  `Customer_key`          BIGINT                  Surrogate key generated
                                                  using `ROW_NUMBER()` to
                                                  uniquely identify each
                                                  customer in the Gold
                                                  model.

  `customer_id`           INT                     Original customer
                                                  identifier from the CRM
                                                  system.

  `customer_number`       NVARCHAR(50)            Business/customer
                                                  identifier used to
                                                  connect CRM customer
                                                  records with ERP data.

  `first_name`            NVARCHAR(50)            Customer's first name.

  `last_name`             NVARCHAR(50)            Customer's last name or
                                                  family name.

  `country`               NVARCHAR(50)            Customer's country
                                                  obtained from ERP
                                                  location data.

  `material_status`       NVARCHAR(50)            Customer's marital
                                                  status, such as
                                                  `Married` or `Single`.

  `gender`                NVARCHAR(50)            Customer gender. CRM
                                                  gender is used when
                                                  available; ERP gender
                                                  is used as a fallback.

  `birth_date`            DATE                    Customer's date of
                                                  birth obtained from ERP
                                                  customer data.

  `create_date`           DATE                    Date on which the
                                                  customer record was
                                                  created in the CRM
                                                  system.
  -----------------------------------------------------------------------

## Data Sources

``` text
silver.crm_cust_info
        |
        +----> silver.erp_cust_az12
        |
        +----> silver.erp_loc_a101
                    |
                    v
             gold.dim_customers
```

## Key Transformation Logic

-   Generates `Customer_key` using `ROW_NUMBER()`.
-   Uses `cst_id` as the original customer identifier.
-   Uses `cst_key` as the customer business key.
-   Adds country from `silver.erp_loc_a101`.
-   Adds birth date and fallback gender from `silver.erp_cust_az12`.
-   Uses CRM gender when available; otherwise uses ERP gender or `n/a`.

------------------------------------------------------------------------

# 2. `gold.dim_products`

-   **Purpose:** Stores business-ready product information enriched with
    category, sub-category, and maintenance information.
-   **Type:** View
-   **Business Role:** Product Dimension
-   **Grain:** One row per product.

## Columns

  -----------------------------------------------------------------------
  Column Name             Data Type               Description
  ----------------------- ----------------------- -----------------------
  `Product_number`        BIGINT                  Surrogate key generated
                                                  using `ROW_NUMBER()` to
                                                  uniquely identify
                                                  products in the Gold
                                                  model.

  `product_id`            INT                     Original product
                                                  identifier from the CRM
                                                  product system.

  `product_Key`           NVARCHAR(50)            Business/product key
                                                  used to identify the
                                                  product, such as
                                                  `PK-7098` or `TT-R982`.

  `product_name`          NVARCHAR(50)            Name or description of
                                                  the product.

  `category_id`           NVARCHAR(50)            Product category
                                                  identifier used to
                                                  connect the product
                                                  with category
                                                  information.

  `category`              NVARCHAR(50)            Main product category.

  `sub_category`          NVARCHAR(50)            Product sub-category.

  `maintenance`           NVARCHAR(50)            Product maintenance
                                                  classification obtained
                                                  from ERP category data.

  `cost`                  INT                     Cost associated with
                                                  the product.

  `line`                  NVARCHAR(50)            Product line or
                                                  business/product family
                                                  classification.

  `star_Date`             DATE                    Date from which the
                                                  product record became
                                                  active or valid.
  -----------------------------------------------------------------------

## Data Sources

``` text
silver.crm_prd_info
        |
        +----> silver.erp_px_cat_g1v2
                    |
                    v
             gold.dim_products
```

## Key Transformation Logic

-   Generates `Product_number` using `ROW_NUMBER()`.
-   Uses `prd_key` as the product business key.
-   Enriches products with category, sub-category, and maintenance
    information.
-   Connects CRM products with ERP category data using `cat_id`.
-   Preserves product cost, product line, and start date from CRM data.

## Key Design

``` text
Product_number
      |
      +---- Surrogate Key
      |
      +---- 1, 2, 3, 4, ...

product_Key
      |
      +---- Business Key
      |
      +---- PK-7098
            TT-R982
            TI-T723
```

------------------------------------------------------------------------

# 3. `gold.fact_sales`

-   **Purpose:** Stores business-ready sales transaction data by
    connecting sales transactions with customer and product dimensions.
-   **Type:** View
-   **Business Role:** Sales Fact
-   **Grain:** One row per sales order line / sales transaction from
    `silver.crm_sales_details`.

## Columns

  -----------------------------------------------------------------------
  Column Name             Data Type               Description
  ----------------------- ----------------------- -----------------------
  `Customer_key`          BIGINT                  Surrogate key from
                                                  `gold.dim_customers`
                                                  identifying the
                                                  customer associated
                                                  with the transaction.

  `Product_key`           BIGINT                  Surrogate key from
                                                  `gold.dim_products`
                                                  identifying the product
                                                  associated with the
                                                  transaction.

  `order_date`            DATE                    Date when the sales
                                                  order was placed.

  `ship_date`             DATE                    Date when the product
                                                  was shipped.

  `due_date`              DATE                    Expected or due date
                                                  associated with the
                                                  sales transaction.

  `sales`                 INT                     Sales amount associated
                                                  with the transaction.

  `quantity`              INT                     Number of units sold in
                                                  the transaction.

  `price`                 INT                     Price associated with
                                                  the product
                                                  transaction.
  -----------------------------------------------------------------------

## Data Sources

``` text
                         +---------------------+
                         |   dim_customers     |
                         |                     |
                         | Customer_key (PK)   |
                         | customer_id         |
                         +----------+----------+
                                    |
                                    | Customer Lookup
                                    |
silver.crm_sales_details -----------+----------> gold.fact_sales
                                    |
                                    | Product Lookup
                                    |
                         +----------+----------+
                         |    dim_products     |
                         |                     |
                         | Product_key         |
                         | Product_number      |
                         +---------------------+
```

## Key Transformation Logic

Product lookup:

``` sql
sd.sls_prd_key = pr.Product_number
```

Customer lookup:

``` sql
TRY_CONVERT(BIGINT, sd.sls_cust_id) = cu.customer_id
```

The fact view uses surrogate keys from the dimensions and retains the
main sales measures and transaction dates.

------------------------------------------------------------------------

# Gold Layer Relationship

The three Gold objects form a basic **Star Schema**:

``` text
                    +---------------------+
                    |   dim_customers     |
                    |                     |
                    | Customer_key (PK)   |
                    | customer_id         |
                    | customer_number     |
                    | first_name          |
                    | last_name            |
                    | country             |
                    | gender              |
                    +----------+----------+
                               |
                               | Customer_key
                               v
                    +---------------------+
                    |     fact_sales      |
                    |                     |
                    | Customer_key (FK)   |
                    | Product_key  (FK)   |
                    | order_date          |
                    | ship_date            |
                    | due_date             |
                    | sales               |
                    | quantity            |
                    | price               |
                    +----------+----------+
                               |
                               | Product_key
                               v
                    +---------------------+
                    |    dim_products     |
                    |                     |
                    | Product_number (PK) |
                    | product_id          |
                    | product_Key         |
                    | product_name        |
                    | category            |
                    | sub_category        |
                    | cost                |
                    | line                |
                    +---------------------+
```

## Gold Layer Design Summary

  ------------------------------------------------------------------------------------------------------
  Object                 Type           Role           Grain              Main Key
  ---------------------- -------------- -------------- ------------------ ------------------------------
  `gold.dim_customers`   View           Dimension      One row per        `Customer_key`
                                                       customer           

  `gold.dim_products`    View           Dimension      One row per        `Product_number`
                                                       product            

  `gold.fact_sales`      View           Fact           One row per sales  `Customer_key + Product_key`
                                                       transaction/line   
  ------------------------------------------------------------------------------------------------------

## Analytical Purpose

The Gold Layer supports:

-   Total sales analysis
-   Sales by customer
-   Sales by product
-   Sales by category
-   Sales by country
-   Sales by date
-   Product performance analysis
-   Customer purchasing behavior
-   Quantity and price analysis
-   Sales trend analysis
-   Customer and product segmentation
-   Power BI dashboards and reporting

------------------------------------------------------------------------

## Recommended Naming Convention

For a professional data warehouse model, it is clearer to distinguish
surrogate keys from business keys:

``` text
Product_key
    |
    +---- Surrogate Key
    |
    +---- 1, 2, 3, 4, ...

product_number
    |
    +---- Business Key
    |
    +---- PK-7098
          TT-R982
          TI-T723
```
