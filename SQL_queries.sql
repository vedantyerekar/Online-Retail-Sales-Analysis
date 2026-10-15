USE retail_analytics;

CREATE TABLE IF NOT EXISTS online_retail_staging (
    InvoiceNo VARCHAR(20),
    StockCode VARCHAR(20),
    Description VARCHAR(255),
    Quantity INT,
    InvoiceDate VARCHAR(50),
    UnitPrice DECIMAL(10, 2),
    CustomerID VARCHAR(20),
    Country VARCHAR(100)
);

SELECT COUNT(*) AS total_rows
FROM online_retail_staging;

SELECT InvoiceDate
FROM online_retail_staging
LIMIT 10;

SHOW WARNINGS;

SELECT UnitPrice
FROM online_retail_staging
WHERE UnitPrice IS NULL OR UnitPrice = 0
LIMIT 10;

USE retail_analytics;

INSERT INTO online_retail_raw (
    InvoiceNo,
    StockCode,
    Description,
    Quantity,
    InvoiceDate,
    UnitPrice,
    CustomerID,
    Country
)
SELECT
    InvoiceNo,
    StockCode,
    Description,
    Quantity,
    CAST(InvoiceDate AS DATETIME),
    UnitPrice,
    CustomerID,
    Country
FROM online_retail_staging;

SELECT
    COUNT(*) AS total_rows,
    SUM(InvoiceDate IS NULL) AS missing_dates
FROM online_retail_raw;

SELECT
    SUM(InvoiceNo IS NULL) AS missing_invoices,
    SUM(StockCode IS NULL) AS missing_stock_codes,
    SUM(Description IS NULL OR TRIM(Description) = '') AS missing_descriptions,
    SUM(InvoiceDate IS NULL) AS missing_dates,
    SUM(UnitPrice IS NULL) AS missing_prices,
    SUM(CustomerID IS NULL OR TRIM(CustomerID) = '') AS missing_customers,
    SUM(Country IS NULL OR TRIM(Country) = '') AS missing_countries
FROM online_retail_raw;

SELECT
    COUNT(*) AS cancellation_rows
FROM online_retail_raw
WHERE InvoiceNo LIKE 'C%';

SELECT
    SUM(Quantity <= 0) AS nonpositive_quantity_rows,
    SUM(UnitPrice < 0) AS negative_price_rows,
    SUM(UnitPrice = 0) AS zero_price_rows
FROM online_retail_raw;

SELECT 
	UnitPrice, InvoiceDate
    FROM online_retail_raw
	WHERE UnitPrice < 0;

SELECT
    InvoiceNo,
    StockCode,
    Description,
    Quantity,
    InvoiceDate,
    UnitPrice,
    CustomerID,
    Country
FROM online_retail_raw
WHERE UnitPrice < 0;

SELECT
    InvoiceNo,
    StockCode,
    Description,
    Quantity,
    InvoiceDate,
    UnitPrice,
    CustomerID,
    Country
FROM online_retail_raw
WHERE Description = 'Adjust bad debt';

SELECT
    InvoiceNo,
    StockCode,
    Description,
    Quantity,
    InvoiceDate,
    UnitPrice,
    Country
FROM online_retail_raw
WHERE UnitPrice = 0
LIMIT 20;

SELECT
    InvoiceNo,
    Quantity,
    UnitPrice,
    InvoiceDate,
    Description
FROM online_retail_raw
WHERE InvoiceNo LIKE 'C%'
LIMIT 20;

SELECT
    COUNT(*) AS total_rows,
    SUM(InvoiceNo LIKE 'C%') AS cancellation_rows,
    SUM(Quantity < 0) AS negative_quantity_rows,
    SUM(Quantity < 0 AND InvoiceNo LIKE 'C%') AS negative_quantity_cancellations,
    SUM(UnitPrice < 0) AS negative_price_rows,
    SUM(UnitPrice = 0) AS zero_price_rows,
    SUM(Description IS NULL OR TRIM(Description) = '') AS missing_descriptions,
    SUM(CustomerID IS NULL OR TRIM(CustomerID) = '') AS missing_customer_ids
FROM online_retail_raw;

SELECT
    InvoiceNo,
    StockCode,
    InvoiceDate,
    Quantity,
    UnitPrice,
    COUNT(*) AS occurrences
FROM online_retail_raw
GROUP BY
    InvoiceNo,
    StockCode,
    InvoiceDate,
    Quantity,
    UnitPrice
HAVING COUNT(*) > 1
ORDER BY occurrences DESC
LIMIT 20;

SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT InvoiceNo) AS distinct_invoices,
    MIN(InvoiceDate) AS first_date,
    MAX(InvoiceDate) AS last_date
FROM online_retail_raw;

SELECT COUNT(*) AS staging_rows
FROM online_retail_staging;

SELECT
    COUNT(*) AS total_rows,
    SUM(InvoiceDate IS NULL OR TRIM(InvoiceDate) = '') AS missing_dates
FROM online_retail_staging;

CREATE TABLE online_retail_raw_backup AS
SELECT * FROM online_retail_raw;

TRUNCATE TABLE online_retail_raw;

INSERT INTO online_retail_raw (
    InvoiceNo,
    StockCode,
    Description,
    Quantity,
    InvoiceDate,
    UnitPrice,
    CustomerID,
    Country
)
SELECT
    InvoiceNo,
    StockCode,
    Description,
    Quantity,
    CAST(InvoiceDate AS DATETIME),
    UnitPrice,
    CustomerID,
    Country
FROM online_retail_staging;

SELECT
    COUNT(*) AS total_rows,
    SUM(InvoiceDate IS NULL) AS missing_dates
FROM online_retail_raw;

SELECT
    COUNT(*) AS total_rows,
    SUM(InvoiceNo LIKE 'C%') AS cancellation_rows,
    SUM(Quantity < 0) AS negative_quantity_rows,
    SUM(UnitPrice < 0) AS negative_price_rows,
    SUM(UnitPrice = 0) AS zero_price_rows,
    SUM(Description IS NULL OR TRIM(Description) = '')
        AS missing_descriptions,
    SUM(CustomerID IS NULL OR TRIM(CustomerID) = '')
        AS missing_customer_ids
FROM online_retail_raw;

SELECT
    InvoiceNo,
    StockCode,
    Description,
    Quantity,
    InvoiceDate,
    UnitPrice,
    CustomerID,
    Country
FROM online_retail_raw
WHERE UnitPrice < 0;

SELECT
    Description,
    StockCode,
    COUNT(*) AS row_count,
    SUM(Quantity) AS total_quantity
FROM online_retail_raw
WHERE UnitPrice = 0
GROUP BY Description, StockCode
ORDER BY row_count DESC
LIMIT 20;

SELECT
    CASE
        WHEN InvoiceNo LIKE 'C%' THEN 'Cancellation invoice'
        WHEN Quantity < 0 THEN 'Negative quantity, other invoice'
        ELSE 'Other transaction'
    END AS transaction_type,
    COUNT(*) AS row_count,
    SUM(Quantity) AS total_quantity
FROM online_retail_raw
WHERE UnitPrice = 0
GROUP BY transaction_type
ORDER BY row_count DESC;

SELECT
    CASE
        WHEN Description IS NULL OR TRIM(Description) = ''
            THEN 'Missing description'
        ELSE 'Description available'
    END AS description_status,
    COUNT(*) AS row_count
FROM online_retail_raw
WHERE UnitPrice = 0
GROUP BY description_status;

CREATE OR REPLACE VIEW online_retail_analysis AS
SELECT
    InvoiceNo,
    StockCode,
    COALESCE(
        NULLIF(TRIM(Description), ''),
        'Unknown product'
    ) AS Description,
    Quantity,
    InvoiceDate,
    UnitPrice,
    Quantity * UnitPrice AS LineTotal,
    CustomerID,
    Country,
    CASE
        WHEN InvoiceNo LIKE 'C%' THEN 'Cancellation'
        WHEN Quantity < 0 THEN 'Negative quantity'
        WHEN UnitPrice < 0 THEN 'Negative price adjustment'
        WHEN UnitPrice = 0 THEN 'Zero price'
        ELSE 'Regular transaction'
    END AS TransactionType
FROM online_retail_raw;

SELECT
    COUNT(*) AS total_rows,
    SUM(LineTotal) AS total_line_value
FROM online_retail_analysis;


SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT InvoiceNo) AS distinct_invoices,
    COUNT(DISTINCT CustomerID) AS unique_customers,
    COUNT(DISTINCT StockCode) AS unique_products,
    COUNT(DISTINCT Country) AS countries,
    ROUND(SUM(LineTotal), 2) AS net_line_value,
    MIN(InvoiceDate) AS first_transaction,
    MAX(InvoiceDate) AS last_transaction
FROM online_retail_analysis;

SELECT
    DATE_FORMAT(InvoiceDate, '%Y-%m') AS sales_month,
    COUNT(DISTINCT InvoiceNo) AS invoice_count,
    ROUND(SUM(LineTotal), 2) AS net_line_value
FROM online_retail_analysis
GROUP BY DATE_FORMAT(InvoiceDate, '%Y-%m')
ORDER BY sales_month;

SELECT
    StockCode,
    Description,
    SUM(Quantity) AS total_quantity_sold,
    ROUND(SUM(LineTotal), 2) AS net_sales_value
FROM online_retail_analysis
WHERE InvoiceNo NOT LIKE 'C%'
  AND UnitPrice >= 0
GROUP BY StockCode, Description
ORDER BY net_sales_value DESC
LIMIT 10;

SELECT
    Country,
    COUNT(DISTINCT InvoiceNo) AS invoice_count,
    COUNT(DISTINCT CustomerID) AS unique_customers,
    ROUND(SUM(LineTotal), 2) AS net_sales_value
FROM online_retail_analysis
WHERE InvoiceNo NOT LIKE 'C%'
  AND UnitPrice >= 0
  AND Country <> 'United Kingdom'
GROUP BY Country
ORDER BY net_sales_value DESC
LIMIT 10;

SELECT
    CustomerID,
    COUNT(DISTINCT InvoiceNo) AS invoice_count,
    ROUND(SUM(Quantity * UnitPrice), 2) AS net_sales_value
FROM online_retail_analysis
WHERE InvoiceNo NOT LIKE 'C%'
  AND UnitPrice >= 0
  AND CustomerID IS NOT NULL
  AND TRIM(CustomerID) <> ''
GROUP BY CustomerID
ORDER BY net_sales_value DESC
LIMIT 10;

SELECT
    COUNT(DISTINCT CASE
        WHEN InvoiceNo NOT LIKE 'C%' THEN InvoiceNo
    END) AS non_cancellation_invoices,

    COUNT(DISTINCT CustomerID) AS customers_with_ids,

    COUNT(DISTINCT StockCode) AS unique_stock_codes,

    ROUND(SUM(CASE
        WHEN InvoiceNo NOT LIKE 'C%'
         AND UnitPrice >= 0
        THEN LineTotal
        ELSE 0
    END), 2) AS filtered_net_sales_value,

    ROUND(AVG(CASE
        WHEN InvoiceNo NOT LIKE 'C%'
         AND UnitPrice >= 0
        THEN LineTotal
    END), 2) AS avg_line_value

FROM online_retail_analysis
WHERE CustomerID IS NOT NULL
  AND TRIM(CustomerID) <> '';