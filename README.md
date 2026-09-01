# ERP Analytics — SQL Data Warehouse & Analytics Project

![SQL Server](https://img.shields.io/badge/SQL%20Server-2025-red?style=for-the-badge&logo=microsoftsqlserver)
![SQL](https://img.shields.io/badge/SQL-T--SQL-blue?style=for-the-badge)
![Data Warehouse](https://img.shields.io/badge/Data%20Warehouse-Bronze%20%7C%20Silver%20%7C%20Gold-orange?style=for-the-badge)
![Status](https://img.shields.io/badge/Project-In%20Progress-yellow?style=for-the-badge)
![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)

A practical **SQL Server Data Warehouse and Analytics project** focused on transforming raw CRM and ERP data into clean, integrated, business-ready analytical data.

The project follows a layered **Bronze → Silver → Gold** architecture and demonstrates data ingestion, cleaning, standardization, validation, dimensional modeling, and analytical data preparation.

---

## 👨‍💻 About Me

**Muhammad Usman Abid**  
**BS Data Science — 4th Semester**

I am currently polishing my **SQL and Data Analytics skills** through practical projects.

My current focus includes:

- SQL Server and T-SQL
- Data Cleaning and Transformation
- ETL / ELT Concepts
- Data Warehousing
- Dimensional Modeling
- Star Schema
- Advanced SQL Analytics
- Data Quality and Validation
- Power BI / Business Intelligence
- Python for Data Analytics

This project is part of my practical journey toward becoming a strong **Data Analyst / Data Engineer** and eventually progressing into **Data Science**.

---

# 📊 Project Overview

The objective of this project is to transform raw operational data from CRM and ERP systems into a structured analytical data model.

The overall architecture follows:

```text
                    SOURCE SYSTEMS
                         │
             ┌───────────┴───────────┐
             │                       │
            CRM                     ERP
             │                       │
             └───────────┬───────────┘
                         │
                         ▼
                  ┌─────────────┐
                  │    BRONZE   │
                  │ Raw Layer   │
                  └──────┬──────┘
                         │
                         │ Cleaning
                         │ Standardization
                         │ Deduplication
                         ▼
                  ┌─────────────┐
                  │    SILVER   │
                  │ Clean Layer │
                  └──────┬──────┘
                         │
                         │ Integration
                         │ Business Rules
                         │ Dimensional Modeling
                         ▼
                  ┌─────────────┐
                  │     GOLD    │
                  │ Analytics   │
                  └──────┬──────┘
                         │
             ┌───────────┴───────────┐
             │                       │
             ▼                       ▼
        SQL Analytics            Power BI
```

---

# 🏗️ Project Architecture

> **Architecture Diagram:** Add your final architecture image below.

![ERP Analytics Architecture](docs/images/architecture.png)

Place your architecture image at:

```text
docs/images/architecture.png
```

Recommended repository structure:

```text
ERP-Analytics/
│
├── docs/
│   └── images/
│       └── architecture.png
│
├── scripts/
├── analysis/
├── powerbi/
├── README.md
└── LICENSE
```

---

# 🧱 Data Warehouse Architecture

## 🥉 Bronze Layer — Raw Data

The Bronze Layer is the initial landing layer where source data is loaded with minimal transformation.

### Responsibilities

- Load raw CRM and ERP data
- Preserve source information
- Provide a reliable raw-data layer
- Keep source-level records available for downstream processing

### Main Bronze Tables

```text
bronze.crm_cust_info
bronze.crm_prd_info
bronze.crm_sales_details

bronze.erp_cust_az12
bronze.erp_loc_a101
bronze.erp_px_cat_g1v2
```

---

# 🥈 Silver Layer — Clean & Standardized Data

The Silver Layer contains cleaned and standardized data prepared for integration and business modeling.

### Responsibilities

- Remove duplicate records
- Handle missing and invalid values
- Standardize categorical values
- Trim unnecessary whitespace
- Normalize identifiers
- Validate data types
- Standardize dates
- Apply transformation rules
- Perform data quality checks

### Example: Duplicate Removal

```sql
WITH CTE AS
(
    SELECT
        *,
        ROW_NUMBER() OVER
        (
            PARTITION BY cst_id
            ORDER BY cst_create_date DESC
        ) AS Flag_Last
    FROM bronze.crm_cust_info
)
DELETE FROM CTE
WHERE Flag_Last > 1;
```

### Example: Gender Standardization

```sql
CASE
    WHEN UPPER(TRIM(cst_gndr)) = 'M' THEN 'Male'
    WHEN UPPER(TRIM(cst_gndr)) = 'F' THEN 'Female'
    ELSE 'n/a'
END
```

### Example: Country Standardization

```sql
CASE
    WHEN UPPER(TRIM(cntry))
        IN ('USA', 'UNITED STATES', 'US')
        THEN 'USA'

    WHEN UPPER(TRIM(cntry))
        IN ('GERMANY', 'DE')
        THEN 'Germany'

    WHEN UPPER(TRIM(cntry))
        = 'UNITED KINGDOM'
        THEN 'UK'

    ELSE cntry
END
```

---

# 🥇 Gold Layer — Business-Ready Data

The Gold Layer contains analytical views designed for reporting, KPI analysis, and BI tools.

Current Gold objects:

```text
gold.dim_customers
gold.dim_products
gold.fact_sales
```

---

## 👥 `gold.dim_customers`

### Purpose

Stores enriched customer information by combining CRM customer data with ERP demographic and geographic information.

### Grain

**One row per customer.**

### Sources

```text
silver.crm_cust_info
        │
        ├──────> silver.erp_cust_az12
        │
        └──────> silver.erp_loc_a101
                       │
                       ▼
              gold.dim_customers
```

### Main Attributes

- Customer surrogate key
- Customer ID
- Customer number
- First name
- Last name
- Country
- Marital status
- Gender
- Birth date
- Create date

---

## 📦 `gold.dim_products`

### Purpose

Stores business-ready product information enriched with category, sub-category, and maintenance information.

### Grain

**One row per product.**

### Sources

```text
silver.crm_prd_info
        │
        └──────> silver.erp_px_cat_g1v2
                       │
                       ▼
              gold.dim_products
```

### Main Attributes

- Product surrogate key
- Product ID
- Product business key
- Product name
- Category
- Sub-category
- Maintenance
- Cost
- Product line
- Start date

### Key Design

```text
Product_number
      │
      └── Surrogate Key
          1, 2, 3, 4...

product_Key
      │
      └── Business Key
          PK-7098
          TT-R982
          TI-T723
```

---

# 💰 `gold.fact_sales`

### Purpose

Stores business-ready sales transactions connected to customer and product dimensions.

### Grain

**One row per sales order line / sales transaction.**

### Sources

```text
                       ┌─────────────────────┐
                       │   dim_customers     │
                       │                     │
                       │ Customer_key        │
                       └──────────┬──────────┘
                                  │
                                  │
silver.crm_sales_details ─────────┼──────> gold.fact_sales
                                  │
                                  │
                       ┌──────────┴──────────┐
                       │    dim_products     │
                       │                     │
                       │ Product_key         │
                       └─────────────────────┘
```

### Measures

- Sales
- Quantity
- Price

### Dates

- Order date
- Ship date
- Due date

### Dimension Lookups

Product:

```sql
sd.sls_prd_key = pr.Product_number
```

Customer:

```sql
TRY_CONVERT(BIGINT, sd.sls_cust_id) = cu.customer_id
```

---

# ⭐ Star Schema

The Gold Layer follows a basic **Star Schema**:

```text
                    ┌──────────────────────┐
                    │    dim_customers     │
                    │                      │
                    │ Customer_key (PK)    │
                    │ customer_id          │
                    │ customer_number      │
                    │ first_name           │
                    │ last_name            │
                    │ country              │
                    │ gender               │
                    └──────────┬───────────┘
                               │
                               │ Customer_key
                               ▼
                    ┌──────────────────────┐
                    │      fact_sales      │
                    │                      │
                    │ Customer_key (FK)    │
                    │ Product_key  (FK)    │
                    │ order_date           │
                    │ ship_date            │
                    │ due_date             │
                    │ sales                │
                    │ quantity             │
                    │ price                │
                    └──────────┬───────────┘
                               │
                               │ Product_key
                               ▼
                    ┌──────────────────────┐
                    │     dim_products     │
                    │                      │
                    │ Product_number (PK)  │
                    │ product_id           │
                    │ product_Key          │
                    │ product_name         │
                    │ category             │
                    │ sub_category         │
                    │ cost                 │
                    │ line                 │
                    └──────────────────────┘
```

---

# 🔄 ETL / Data Processing Flow

```text
Raw Source Data
      │
      ▼
Data Ingestion
      │
      ▼
Bronze Layer
      │
      ├── Duplicate Detection
      ├── Data Type Validation
      ├── Null Handling
      ├── Whitespace Cleaning
      └── Raw Data Validation
      │
      ▼
Silver Layer
      │
      ├── Standardization
      ├── Business Rules
      ├── Data Integration
      └── Data Quality Checks
      │
      ▼
Gold Layer
      │
      ├── Customer Dimension
      ├── Product Dimension
      └── Sales Fact
      │
      ▼
Analytics / BI
      │
      ├── SQL Analysis
      └── Power BI
```

---

# 🔍 Data Quality & Validation

Data quality checks are used to identify issues before analytical consumption.

### Duplicate Detection

```sql
SELECT
    cst_id,
    COUNT(*) AS cnt
FROM bronze.crm_cust_info
GROUP BY cst_id
HAVING COUNT(*) > 1;
```

### Product Category Duplicate Check

```sql
SELECT
    id,
    COUNT(*) AS cnt
FROM silver.erp_px_cat_g1v2
GROUP BY id
HAVING COUNT(*) > 1;
```

### Fact-to-Dimension Validation

```sql
SELECT *
FROM gold.dim_customers AS f
LEFT JOIN gold.fact_sales AS c
    ON f.Customer_key = c.Customer_key
WHERE c.Customer_key IS NULL;
```

These checks help validate data integrity and relationships between the analytical dimensions and fact data.

---

# 📈 Analytical Objectives

The Gold Layer is designed to support:

### Sales Analysis

- Total sales
- Sales by year
- Sales by month
- Sales trends
- Sales by product
- Sales by category

### Customer Analysis

- Total customers
- Customer purchasing behavior
- Customers by country
- Customer-level sales
- Customer segmentation

### Product Analysis

- Best-selling products
- Product revenue
- Product quantity sold
- Category performance
- Sub-category performance
- Product cost vs sales

### Operational Analysis

- Order-to-ship duration
- Shipping performance
- Due-date analysis
- Sales transaction analysis

---

# 🛠️ Technology Stack

| Technology | Purpose |
|---|---|
| **Microsoft SQL Server 2025 Express** | Database Engine |
| **SQL Server Management Studio (SSMS)** | Database development and management |
| **T-SQL** | Data transformation and analytics |
| **Git** | Version control |
| **GitHub** | Project documentation and portfolio |
| **Power BI** | Business intelligence and visualization |
| **Python** | Future analytics and automation |

---

# 📁 Repository Structure

```text
ERP-Analytics/
│
├── datasets/
│   └── source_data/
│
├── docs/
│   ├── images/
│   │   └── architecture.png
│   └── data_catalog/
│
├── scripts/
│   ├── bronze/
│   ├── silver/
│   └── gold/
│
├── analysis/
│   └── sql/
│
├── powerbi/
│
├── README.md
│
└── LICENSE
```

---

# 📚 Documentation

Project documentation covers:

- Data Architecture
- Data Warehouse Layers
- Data Catalog
- Data Cleaning Rules
- Data Transformation Logic
- Data Quality Checks
- Dimensional Modeling
- Star Schema
- SQL Analytics
- Business KPIs
- Power BI Semantic Model

---

# 🚀 Project Status

- [x] SQL Server environment setup
- [x] Bronze layer creation
- [x] Bronze data loading
- [x] Silver layer creation
- [x] Data cleaning and standardization
- [x] Duplicate handling
- [x] Customer dimension
- [x] Product dimension
- [x] Sales fact
- [x] Gold-layer data catalog
- [x] Star Schema design
- [ ] Advanced SQL analytics
- [ ] Business KPI layer
- [ ] Power BI semantic model
- [ ] Power BI dashboard
- [ ] Python analytics
- [ ] Final project documentation

---

# 🎯 Learning Goals

This project is helping me develop practical skills across:

```text
SQL
 │
 ├── SELECT / JOIN / GROUP BY
 ├── CTEs
 ├── Window Functions
 ├── CASE Expressions
 ├── Data Cleaning
 ├── Data Validation
 └── Advanced SQL
       │
       ▼
Data Warehousing
 │
 ├── Bronze Layer
 ├── Silver Layer
 ├── Gold Layer
 ├── ETL Concepts
 ├── Data Quality
 └── Dimensional Modeling
       │
       ▼
Business Intelligence
 │
 ├── KPIs
 ├── Power BI
 └── Dashboarding
       │
       ▼
Data Science
```

---

# 👨‍🎓 Author

**Muhammad Usman Abid**

**BS Data Science — 4th Semester**

Currently focused on polishing **SQL, Data Analytics, Data Engineering, and Business Intelligence** skills through practical projects.

---

# 📜 License

This project is licensed under the **MIT License**.

You are free to use, copy, modify, merge, publish, distribute, sublicense, and sell copies of the software, subject to the conditions of the MIT License.

See the [`LICENSE`](LICENSE) file for the complete license text.

---

# ⭐ Project Direction

The long-term direction of this project is:

**SQL → Data Warehousing → Data Engineering → Data Analytics → Business Intelligence → Data Science**

