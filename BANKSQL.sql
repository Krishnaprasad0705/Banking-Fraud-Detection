USE master;
GO

ALTER DATABASE banking_db
SET SINGLE_USER
WITH ROLLBACK IMMEDIATE;
GO

DROP DATABASE banking_db;
GO

CREATE DATABASE banking_db;
GO

USE banking_db;
GO

CREATE TABLE customers (
    customer_id INT IDENTITY(1,1) PRIMARY KEY,
    age INT CHECK (age BETWEEN 18 AND 80),
    income FLOAT CHECK (income > 0),
    cibil_score INT CHECK (cibil_score BETWEEN 300 AND 900),
    account_age_years INT CHECK (account_age_years >= 0)
);

CREATE TABLE transactions (
    transaction_id INT IDENTITY(1,1) PRIMARY KEY,
    customer_id INT NOT NULL,
    amount FLOAT CHECK (amount > 0),
    merchant_category VARCHAR(50),
    location VARCHAR(50),
    device_type VARCHAR(20),
    transaction_type VARCHAR(20),
    transaction_time DATETIME DEFAULT GETDATE(),

    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);

CREATE TABLE fraud_scores (
    fraud_id INT IDENTITY(1,1) PRIMARY KEY,
    transaction_id INT,
    fraud_score INT CHECK (fraud_score BETWEEN 0 AND 100),
    risk_level VARCHAR(20),
    score_time DATETIME DEFAULT GETDATE(),

    FOREIGN KEY (transaction_id) REFERENCES transactions(transaction_id)
);

CREATE TABLE txn_features (
    transaction_id INT PRIMARY KEY,
    txn_velocity INT,
    night_txn BIT,
    device_change BIT,
    location_risk INT,
    amount_ratio FLOAT,

    FOREIGN KEY (transaction_id) REFERENCES transactions(transaction_id)
);


SELECT COUNT(*) FROM customers;

SELECT COUNT(*) AS total_transactions FROM transactions;
SELECT TOP 5 * FROM transactions ORDER BY transaction_id DESC;

CREATE TABLE location_risk (
    location VARCHAR(50) PRIMARY KEY,
    risk_score INT
);

INSERT INTO location_risk VALUES
('Mumbai',70),('Delhi',75),('New Delhi',75),
('Chennai',60),('Bengaluru',65),('Kolkata',60),
('Hyderabad',55),('Jaipur',50),('Lucknow',50),
('Patna',55),('Ranchi',50),('Bhopal',45),
('Gandhinagar',40),('Dispur',45),('Imphal',40),
('Shillong',40),('Aizawl',35),('Kohima',35),
('Agartala',35),('Gangtok',30),('Panaji',30),
('Raipur',40),('Amaravati',45),('Dehradun',45),
('Shimla',35),('Bhubaneswar',45),('Port Blair',30),
('Daman',30),('Srinagar',50),('Jammu',45),
('Leh',40),('Kavaratti',25),('Puducherry',35);




INSERT INTO txn_features
SELECT
    t.transaction_id,

    -- Transaction velocity (last 10 mins)
    (
        SELECT COUNT(*)
        FROM transactions t2
        WHERE t2.customer_id = t.customer_id
        AND t2.transaction_time BETWEEN DATEADD(MINUTE, -10, t.transaction_time)
        AND t.transaction_time
    ) AS txn_velocity,

    -- Night transaction flag
    CASE 
        WHEN DATEPART(HOUR, t.transaction_time) >= 22 
          OR DATEPART(HOUR, t.transaction_time) < 6
        THEN 1 ELSE 0
    END AS night_txn,

    -- Device change flag
    CASE WHEN t.device_type = 'New' THEN 1 ELSE 0 END AS device_change,

    -- Location risk score
    ISNULL(l.risk_score, 40) AS location_risk,

    -- Amount ratio vs customer average
    t.amount / 
    (
        SELECT AVG(t3.amount)
        FROM transactions t3
        WHERE t3.customer_id = t.customer_id
    ) AS amount_ratio

FROM transactions t
LEFT JOIN location_risk l ON t.location = l.location;


SELECT TOP 10 * FROM txn_features;
SELECT COUNT(*) FROM txn_features;


SELECT COUNT(*) FROM transactions;

TRUNCATE TABLE txn_features;

TRUNCATE TABLE txn_features;
GO

DROP TABLE IF EXISTS txn_features;
GO


CREATE TABLE txn_features (
    transaction_id INT PRIMARY KEY,
    amount FLOAT,
    is_high_amount BIT,
    is_new_device BIT,
    is_unknown_location BIT,
    txn_hour INT,
    weekday_flag BIT
);
GO

INSERT INTO txn_features
(
    transaction_id,
    amount,
    is_high_amount,
    is_new_device,
    is_unknown_location,
    txn_hour,
    weekday_flag
)
SELECT
    t.transaction_id,
    t.amount,
    CASE WHEN t.amount > 50000 THEN 1 ELSE 0 END,
    CASE WHEN t.device_type = 'New' THEN 1 ELSE 0 END,
    CASE WHEN t.location = 'Unknown' THEN 1 ELSE 0 END,
    DATEPART(HOUR, t.transaction_time),
    CASE WHEN DATEPART(WEEKDAY, t.transaction_time) IN (1,7) THEN 1 ELSE 0 END
FROM transactions t;
GO

SELECT COUNT(*) FROM txn_features;
SELECT TOP 10 * FROM txn_features;

SELECT COUNT(*) AS total_transactions FROM transactions;


SELECT
    COUNT(*) AS total_rows,
    MAX(transaction_time) AS last_insert_time,
    DATEDIFF(SECOND, MAX(transaction_time), GETDATE()) AS seconds_since_last_insert
FROM transactions;


    SELECT
        COUNT(*) AS total_rows,
        MAX(transaction_time) AS last_insert_time
    FROM transactions;

DROP TABLE IF EXISTS fraud_scores;
GO

CREATE TABLE fraud_scores (
    transaction_id INT PRIMARY KEY,
    fraud_score INT,
    risk_level VARCHAR(20)
);
GO


INSERT INTO fraud_scores
(
    transaction_id,
    fraud_score,
    risk_level
)
SELECT
    f.transaction_id,

    (
        (CASE WHEN f.is_high_amount = 1 THEN 30 ELSE 0 END) +
        (CASE WHEN f.is_new_device = 1 THEN 25 ELSE 0 END) +
        (CASE WHEN f.is_unknown_location = 1 THEN 25 ELSE 0 END) +
        (CASE WHEN f.txn_hour BETWEEN 0 AND 5 THEN 20 ELSE 0 END)
    ) AS fraud_score,

    CASE
        WHEN (
            (CASE WHEN f.is_high_amount = 1 THEN 30 ELSE 0 END) +
            (CASE WHEN f.is_new_device = 1 THEN 25 ELSE 0 END) +
            (CASE WHEN f.is_unknown_location = 1 THEN 25 ELSE 0 END) +
            (CASE WHEN f.txn_hour BETWEEN 0 AND 5 THEN 20 ELSE 0 END)
        ) >= 70 THEN 'High'
        WHEN (
            (CASE WHEN f.is_high_amount = 1 THEN 30 ELSE 0 END) +
            (CASE WHEN f.is_new_device = 1 THEN 25 ELSE 0 END) +
            (CASE WHEN f.is_unknown_location = 1 THEN 25 ELSE 0 END) +
            (CASE WHEN f.txn_hour BETWEEN 0 AND 5 THEN 20 ELSE 0 END)
        ) >= 40 THEN 'Medium'
        ELSE 'Low'
    END AS risk_level

FROM txn_features f;
GO


SELECT TOP 10 * FROM fraud_scores ORDER BY fraud_score DESC;
SELECT risk_level, COUNT(*) FROM fraud_scores GROUP BY risk_level;


CREATE VIEW live_monitor AS
SELECT
    COUNT(*) AS total_txns,
    MAX(transaction_time) AS last_txn_time
FROM transactions;


ALTER TABLE transactions
ADD fraud_score INT;


ALTER TABLE transactions ADD
    is_high_amount BIT,
    is_new_device BIT,
    is_unknown_location BIT,
    txn_hour INT,
    weekday_flag BIT;


UPDATE transactions
SET is_high_amount =
    CASE WHEN amount > 50000 THEN 1 ELSE 0 END;

    UPDATE transactions
SET is_new_device =
    CASE WHEN device_type = 'New' THEN 1 ELSE 0 END;

    UPDATE transactions
SET is_unknown_location =
    CASE
        WHEN location NOT IN ('Chennai','Bangalore','Mumbai','Delhi')
        THEN 1 ELSE 0
    END;

    UPDATE transactions
SET weekday_flag =
    CASE
        WHEN DATEPART(WEEKDAY, transaction_time) IN (1,7)
        THEN 1 ELSE 0
    END;

    UPDATE transactions
SET fraud_score =
    (is_high_amount * 40) +
    (is_new_device * 25) +
    (is_unknown_location * 20) +
    (CASE WHEN txn_hour < 6 OR txn_hour > 22 THEN 10 ELSE 0 END) +
    (weekday_flag * 5);

    SELECT
    transaction_id,
    amount,
    txn_hour,
    fraud_score
FROM transactions
ORDER BY transaction_id DESC;


ALTER TABLE transactions
ADD fraud_flag BIT;

UPDATE transactions
SET fraud_flag =
    CASE
        WHEN fraud_score >= 60 THEN 1
        ELSE 0
    END;

    SELECT TOP 20
    transaction_id,
    fraud_score,
    fraud_flag
FROM transactions
ORDER BY fraud_score DESC;


SELECT
    COUNT(*) AS total_transactions,
    SUM(CASE WHEN fraud_flag = 1 THEN 1 ELSE 0 END) AS fraud_transactions,
    ROUND(
        SUM(CASE WHEN fraud_flag = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*),
        2
    ) AS fraud_percentage
FROM transactions;


SELECT
    COUNT(*) AS total_rows,
    MAX(transaction_time) AS last_insert_time,
    DATEDIFF(SECOND, MAX(transaction_time), GETDATE()) AS seconds_since_last_insert
FROM transactions;




CREATE VIEW vw_fraud_analytics AS
SELECT
    transaction_id,
    customer_id,
    amount,
    merchant_category,
    location,
    device_type,
    transaction_type,
    transaction_time,

    -- Feature Engineering
    CASE WHEN amount >= 50000 THEN 1 ELSE 0 END AS is_high_amount,
    CASE WHEN device_type = 'New' THEN 1 ELSE 0 END AS is_new_device,
    CASE WHEN location NOT IN ('Chennai','Bangalore','Mumbai','Delhi') THEN 1 ELSE 0 END AS is_unknown_location,
    DATEPART(HOUR, transaction_time) AS txn_hour,
    CASE WHEN DATEPART(WEEKDAY, transaction_time) IN (1,7) THEN 1 ELSE 0 END AS weekday_flag,

    fraud_score,
    fraud_flag
FROM transactions;


SELECT TOP 50 * FROM vw_fraud_analytics;



SELECT COLUMN_NAME
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'transactions';


SELECT fraud_flag, COUNT(*) 
FROM vw_fraud_analytics
GROUP BY fraud_flag;


UPDATE transactions
SET fraud_flag = 1
WHERE
    amount > 75000
    OR fraud_score > 70;


    SELECT fraud_flag, COUNT(*) 
FROM transactions
GROUP BY fraud_flag;


UPDATE transactions
SET fraud_flag = 1
WHERE
    amount > 75000
    OR fraud_score > 70
    OR is_new_device = 1
    OR is_unknown_location = 1;

    USE banking_db;
GO

SELECT * FROM sys.tables;

USE banking_db;
GO


DROP TABLE IF EXISTS customers;
GO

CREATE TABLE customers (
    customer_id INT IDENTITY(1,1) PRIMARY KEY,
    age INT CHECK (age BETWEEN 18 AND 80),
    income FLOAT CHECK (income >= 0),
    cibil_score INT CHECK (cibil_score BETWEEN 300 AND 900),
    account_age_years INT CHECK (account_age_years >= 0)
);
GO

SELECT 
    DB_NAME() AS database_name, 
    name AS table_name
FROM sys.tables;

SELECT * FROM customers;

SELECT * FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_NAME = 'transactions';

CREATE TABLE transactions (
    transaction_id INT IDENTITY(1,1) PRIMARY KEY,
    customer_id INT,
    amount FLOAT,
    merchant_category VARCHAR(100),
    location VARCHAR(100),
    device_type VARCHAR(50),
    transaction_type VARCHAR(50),
    transaction_time DATETIME
);

SELECT * FROM transactions;

INSERT INTO dbo.transactions