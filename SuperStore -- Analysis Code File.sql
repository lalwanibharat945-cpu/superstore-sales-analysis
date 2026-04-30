-- ============================================================
-- Superstore Sales Analysis
-- Author: Bharat Lalwani
-- Tools: MySQL
--
-- Objective:
-- Analyze sales and profitability across regions, categories,
-- and products to identify key drivers of revenue and losses.
--
-- Key Findings:
-- 1. Central region underperforms despite strong sales
-- 2. Texas and Illinois drive majority of losses
-- 3. Furniture category has very low margins
-- 4. Sub-categories like Binders, Appliances, Tables cause losses
-- ============================================================



-- ============================================================
-- DATABASE SETUP from line 23 to 58 (Run only if database not already created)
-- ============================================================

DROP DATABASE IF EXISTS superstore_db;
CREATE DATABASE superstore_db;
USE superstore_db;

-- Table structure for Superstore dataset
CREATE TABLE superstore (
    Row_ID INT,
    Order_ID VARCHAR(20),
    Order_Date DATE,
    Ship_Date DATE,
    Ship_Mode VARCHAR(50),
    Customer_ID VARCHAR(20),
    Customer_Name VARCHAR(100),
    Segment VARCHAR(50),
    Country VARCHAR(50),
    City VARCHAR(50),
    State VARCHAR(50),
    Postal_Code VARCHAR(20),
    Region VARCHAR(20),
    Product_ID VARCHAR(20),
    Category VARCHAR(50),
    Sub_Category VARCHAR(50),
    Product_Name VARCHAR(255),
    Sales DECIMAL(10,2),
    Quantity INT,
    Discount DECIMAL(5,2),
    Profit DECIMAL(10,2)
);

-- Load data (update file path before running)
LOAD DATA INFILE 'C:/path/to/superstore.csv'
INTO TABLE superstore
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

-- ============================================================
-- DATA UNDERSTANDING
-- ============================================================

-- Preview dataset
SELECT * FROM samplesuperstore;

-- Check column structure
SHOW COLUMNS FROM samplesuperstore;

-- Convert columns to appropriate types
ALTER TABLE samplesuperstore
MODIFY COLUMN `Postal Code` VARCHAR(15),
MODIFY COLUMN `Ship Mode` VARCHAR(50),
MODIFY COLUMN `Segment` VARCHAR(50),
MODIFY COLUMN `Country` VARCHAR(50),
MODIFY COLUMN `City` VARCHAR(50),
MODIFY COLUMN `State` VARCHAR(50),
MODIFY COLUMN `Region` VARCHAR(50),
MODIFY COLUMN `Category` VARCHAR(50),
MODIFY COLUMN `Sub-Category` VARCHAR(50)
;


DESCRIBE samplesuperstore;

-- Check for missing values
-- Insight: No null values found → dataset is clean and ready for analysis
SELECT 																		# Query for Checking Nulls
    SUM(CASE WHEN `Ship Mode` IS NULL THEN 1 ELSE 0 END) AS `Ship Mode_nulls`,
    SUM(CASE WHEN `Segment` IS NULL THEN 1 ELSE 0 END) AS `Segment_nulls`,
    SUM(CASE WHEN `Country` IS NULL THEN 1 ELSE 0 END) AS `Country_nulls`,
    SUM(CASE WHEN `City` IS NULL THEN 1 ELSE 0 END) AS `City_nulls`,
    SUM(CASE WHEN `State` IS NULL THEN 1 ELSE 0 END) AS `State_nulls`,
    SUM(CASE WHEN `Postal Code` IS NULL THEN 1 ELSE 0 END) AS `Postal Code_nulls`,
    SUM(CASE WHEN `Region` IS NULL THEN 1 ELSE 0 END) AS `Region_nulls`,
    SUM(CASE WHEN `Category` IS NULL THEN 1 ELSE 0 END) AS `Category_nulls`,
    SUM(CASE WHEN `Sub-Category` IS NULL THEN 1 ELSE 0 END) AS `Sub-Category_nulls`,
    SUM(CASE WHEN `Sales` IS NULL THEN 1 ELSE 0 END) AS `Sales_nulls`,
    SUM(CASE WHEN `Quantity` IS NULL THEN 1 ELSE 0 END) AS `Quantity_nulls`,
    SUM(CASE WHEN `Discount` IS NULL THEN 1 ELSE 0 END) AS `Discount_nulls`,
    SUM(CASE WHEN `Profit` IS NULL THEN 1 ELSE 0 END) AS `Profit_nulls`
FROM samplesuperstore; 



-- ============================================================
-- KPI ANALYSIS
-- ============================================================

-- Objective: Evaluate overall business performance

SELECT ROUND(SUM(Sales),2) AS 'Total Sales' # Total Sales -- 2297200.86$ 
	FROM samplesuperstore;
    
SELECT ROUND(SUM(profit),2) AS 'Total Profit' # Total Profit -- 286397.02$
	FROM samplesuperstore;

SELECT ROUND((SUM(profit)/SUM(Sales))*100,2) AS Profit_Margins  -- Profit Percentage -- 12.47%
	FROM samplesuperstore; 

-- Insight:
-- Business is profitable (~12.47%) but margin is moderate,
-- indicating inefficiencies in certain segments.



-- ==========================================================
-- Profit and Sales by COUNTRY, State, Region, City
-- ==========================================================


SELECT Country,					-- USA is the only Country is DataSet
		ROUND(SUM(sales),2) AS Total_Sales,
        ROUND(SUM(profit),2) AS Total_Profit
FROM samplesuperstore
GROUP BY country;


-- ============================================================
-- REGIONAL PERFORMANCE ANALYSIS
-- ============================================================

SELECT 
    Region,
    ROUND(SUM(Sales),2) AS Total_Sales,
    ROUND(SUM(Profit),2) AS Total_Profit,
    ROUND(SUM(Profit)*100/SUM(Sales),2) AS Profit_Margin
FROM samplesuperstore
GROUP BY Region
ORDER BY Total_Sales DESC;

-- Insight:
-- West & East are strong performers
-- Central region has lowest margin (~7.9%)
-- Indicates inefficiency, not demand issue


-- ============================================================
-- STATE LEVEL ANALYSIS
-- ============================================================

WITH state_sales_profit AS (
    SELECT 
        State,
        ROUND(SUM(Sales),2) AS Total_Sales,
        ROUND(SUM(Profit),2) AS Total_Profit
    FROM samplesuperstore
    GROUP BY State
)

SELECT *,
       ROUND(Total_Profit*100/Total_Sales,2) AS Profit_Margin
FROM state_sales_profit
ORDER BY Profit_Margin DESC;

-- Insight:
-- Texas → highest losses
-- Illinois → major loss contributor
-- Confirms localized inefficiency






-- ============================================================
-- CATEGORY PERFORMANCE
-- ============================================================


SELECT category,
		ROUND(SUM(sales),2) AS Total_Sales,
        ROUND(SUM(profit),2) AS Total_Profit,
        ROUND(SUM(profit)*100/SUM(sales),2) AS Profit_Margin
FROM samplesuperstore
GROUP BY category
ORDER BY Total_Sales DESC;

-- Insight:
-- Furniture → very low margin (~2.5%)
-- Technology & Office Supplies → strong (~17%)
-- Furniture is main profitability issue

-- ============================================================
-- SUB-CATEGORY ROOT CAUSE ANALYSIS
-- ============================================================

SELECT category,
		`sub-category`, 
        SUM(Quantity) AS Total_Quantity,
		ROUND(SUM(sales)/SUM(Quantity),2) AS AVG_Sales,
        ROUND(SUM(profit)/SUM(Quantity),2) AS AVG_Profit,
        ROUND(SUM(profit)*100/SUM(sales),2) AS Profit_Margin
FROM samplesuperstore
GROUP BY category,`sub-category`
ORDER BY category, Profit_Margin DESC;
-- Insight:
-- Loss drivers identified:
-- Tables, Bookcases, Furnishings (Furniture)
-- Binders, Appliances (Office Supplies)


-- ============================================================
-- REGION × CATEGORY ANALYSIS
-- ============================================================


select region,
		category,
        ROUND(SUM(sales),2) AS Total_Sales,
        ROUND(SUM(profit),2) AS Total_Profit,
        ROUND(SUM(profit)*100/SUM(sales),2) AS Profit_Margin
FROM samplesuperstore
GROUP BY region, 
			category
ORDER BY region, Profit_Margin DESC;

-- Insight:
-- Central + Furniture = negative performance
-- Confirms interaction-based issue



select state,
		category,
        ROUND(SUM(sales),2) AS Total_Sales,
        ROUND(SUM(profit),2) AS Total_Profit,
        ROUND(SUM(profit)*100/SUM(sales),2) AS Profit_Margin
FROM samplesuperstore
WHERE region = 'Central'
GROUP BY state, 
			category
ORDER BY state,
			Profit_Margin DESC;


-- ============================================================
-- FINAL ROOT CAUSE: STATE + SUB-CATEGORY
-- ============================================================

SELECT State,
		category,
		`sub-category`,
        ROUND(SUM(sales),2) AS Total_Sales,
        ROUND(SUM(profit),2) AS Total_Profit,
        ROUND(SUM(profit)*100/SUM(sales),2) AS Profit_Margin
FROM samplesuperstore
WHERE state = 'Illinois' OR state = 'Texas'
GROUP BY state,
			category,
			`sub-category`
ORDER BY state, category, Profit_Margin DESC;

-- Final Insight:
-- Losses are concentrated in specific sub-categories:
-- Binders, Appliances, Tables, Furnishings
-- Indicates pricing/cost inefficiencies rather than demand issue







