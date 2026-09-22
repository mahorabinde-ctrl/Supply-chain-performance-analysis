-- =====================================================================
-- Project: E-Commerce Supply Chain & Delivery Performance Analysis
-- Dataset: Brazilian E-Commerce Public Dataset by Olist
-- Database: Microsoft SQL Server (T-SQL)
-- Author: Binde Mahora Marie
-- =====================================================================

USE OlistSupplyChain;
GO

-- 1. Create Analytical View: Consolidating Orders, Reviews, and Items
CREATE OR ALTER VIEW vw_DeliveryPerformance AS
WITH FilteredOrders AS (
    SELECT 
        order_id,
        customer_id,
        order_status,
        TRY_CONVERT(DATETIME2, order_purchase_timestamp) AS purchase_date,
        TRY_CONVERT(DATETIME2, order_delivered_customer_date) AS delivered_date,
        TRY_CONVERT(DATETIME2, order_estimated_delivery_date) AS estimated_date
    FROM orders
    WHERE order_status = 'delivered'
      AND order_delivered_customer_date IS NOT NULL
),
ItemSummary AS (
    SELECT 
        order_id,
        SUM(TRY_CONVERT(FLOAT, price)) AS total_order_value,
        SUM(TRY_CONVERT(FLOAT, freight_value)) AS total_freight_value
    FROM items
    GROUP BY order_id
),
ReviewSummary AS (
    SELECT 
        order_id,
        AVG(TRY_CONVERT(FLOAT, review_score)) AS avg_review_score
    FROM reviews
    GROUP BY order_id
)
SELECT 
    o.order_id,
    o.customer_id,
    o.purchase_date,
    o.delivered_date,
    o.estimated_date,
    DATEDIFF(day, o.purchase_date, o.delivered_date) AS actual_delivery_days,
    DATEDIFF(day, o.estimated_date, o.delivered_date) AS delay_days,
    CASE 
        WHEN o.delivered_date > o.estimated_date THEN 1 
        ELSE 0 
    END AS is_delayed,
    r.avg_review_score,
    i.total_order_value,
    i.total_freight_value
FROM FilteredOrders o
INNER JOIN ReviewSummary r ON o.order_id = r.order_id
INNER JOIN ItemSummary i ON o.order_id = i.order_id;
GO

-- 2. Business Impact Query: Evaluating Delay Impact on Customer Satisfaction
SELECT 
    CASE 
        WHEN is_delayed = 1 THEN 'En retard (Delayed)' 
        ELSE 'À temps (On Time)' 
    END AS delivery_status,
    COUNT(*) AS total_orders,
    ROUND(AVG(actual_delivery_days), 1) AS avg_delivery_days,
    ROUND(AVG(avg_review_score), 2) AS avg_review_score
FROM vw_DeliveryPerformance
GROUP BY is_delayed;
GO
