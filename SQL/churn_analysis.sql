CREATE DATABASE churn_project;
USE churn_project;

SELECT *
FROM churn;

UPDATE churn
SET TotalCharges = NULL
WHERE TRIM(TotalCharges) = '';

ALTER TABLE churn
MODIFY TotalCharges DECIMAL(10,2);

SELECT *
FROM churn;

UPDATE churn
SET TotalCharges = 0
WHERE TotalCharges IS NULL;

UPDATE churn
SET 
    gender = TRIM(gender),
    Partner = TRIM(Partner),
    Dependents = TRIM(Dependents),
    PhoneService = TRIM(PhoneService),
    MultipleLines = TRIM(MultipleLines),
    InternetService = TRIM(InternetService),
    Contract = TRIM(Contract),
    PaymentMethod = TRIM(PaymentMethod),
    Churn = TRIM(Churn);
    
SELECT customerID, COUNT(*)
FROM churn
GROUP BY customerID
HAVING COUNT(*) > 1;

-- FEATURE ENGINEERING

ALTER TABLE churn ADD customer_segment VARCHAR(50);
UPDATE churn
SET customer_segment = 
CASE 
    WHEN tenure < 12 THEN 'New Customer'
    WHEN tenure BETWEEN 12 AND 48 THEN 'Regular Customer'
    ELSE 'Loyal Customer'
END;

SELECT *
FROM churn;

ALTER TABLE churn ADD risk_level VARCHAR(50);
UPDATE churn
SET risk_level =
CASE
    WHEN Contract = 'Month-to-month' 
         AND MonthlyCharges > 70 
         AND tenure < 12 
        THEN 'High Risk'
    WHEN Contract = 'Month-to-month' 
         AND (MonthlyCharges <= 70 OR tenure >= 12)
        THEN 'Medium Risk'
    ELSE 'Low Risk'
END;

-- CHURN RATE

SELECT 
    Churn,
    COUNT(*) AS total,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM churn),2) AS percentage
FROM churn
GROUP BY Churn;

-- CHURN BY CONTRACT

SELECT 
    Contract,
    COUNT(*) AS total,
    SUM(CASE WHEN Churn='Yes' THEN 1 ELSE 0 END) AS churned,
    ROUND(SUM(CASE WHEN Churn='Yes' THEN 1 ELSE 0 END)*100.0/COUNT(*),2) AS churn_rate
FROM churn
GROUP BY Contract;

-- REVENUE ANALYSIS

SELECT 
    Churn,
    ROUND(SUM(MonthlyCharges),2) AS revenue
FROM churn
GROUP BY Churn;
-- SEGMENT ANALYSIS

SELECT 
    customer_segment,
    COUNT(*) AS total,
    SUM(CASE WHEN Churn='Yes' THEN 1 ELSE 0 END) AS churned
FROM churn
GROUP BY customer_segment;

-- FINDING HIGH RISK CUSTOMERS
SELECT *
FROM churn
WHERE risk_level = 'High Risk';

WITH churn_calc AS (
    SELECT 
        Contract,
        COUNT(*) AS total,
        SUM(CASE WHEN Churn='Yes' THEN 1 ELSE 0 END) AS churned
    FROM churn
    GROUP BY Contract
)
SELECT *,
ROUND(churned * 100.0 / total,2) AS churn_rate
FROM churn_calc;

-- Finding customers contributing to top 30% revenue and checking their churn rate using CTE

WITH revenue_base AS (
    SELECT 
        customerID,
        MonthlyCharges,
        Churn
    FROM churn
),
ranked_revenue AS (
    SELECT 
        customerID,
        MonthlyCharges,
        Churn,
        SUM(MonthlyCharges) OVER (ORDER BY MonthlyCharges DESC) AS running_total,
        SUM(MonthlyCharges) OVER () AS total_revenue
    FROM revenue_base
),
top_customers AS (
    SELECT *
    FROM ranked_revenue
    WHERE running_total <= 0.3 * total_revenue
)
SELECT 
    COUNT(*) AS total_top_customers,
    SUM(CASE WHEN Churn='Yes' THEN 1 ELSE 0 END) AS churned,
    ROUND(SUM(CASE WHEN Churn='Yes' THEN 1 ELSE 0 END)*100.0/COUNT(*),2) AS churn_rate
FROM top_customers;

-- USING WINDOW

SELECT 
    customerID,
    MonthlyCharges,
    RANK() OVER (ORDER BY MonthlyCharges DESC) AS rank_spender
FROM churn;

