/*==============================================================
  FINTRUST WEEK 3 — ADVANCED SQL ANALYSIS 1
  TITLE: Customer Segment Performance Deep Dive

  Business Question:
  How do customer segments differ in transaction activity,
  transaction value, average transaction amount, success rate,
  and risk-review rate?
==============================================================*/

WITH segment_analysis AS (
    SELECT
        c.Customer_Segment,
        COUNT(DISTINCT c.Customer_ID) AS Total_Customers,
        COUNT(t.Transaction_ID) AS Total_Transactions,
        SUM(t.Amount_NGN) AS Total_Transaction_Value,
        AVG(t.Amount_NGN) AS Average_Transaction_Amount,

        COUNT(
            CASE
                WHEN t.Transaction_Status = 'Successful'
                THEN 1
            END
        ) AS Successful_Transactions,

        COUNT(
            CASE
                WHEN t.Risk_Review_Flag = 'Yes'
                THEN 1
            END
        ) AS Risk_Review_Transactions

    FROM customers c
    LEFT JOIN transactions t
        ON c.Customer_ID = t.Customer_ID

    GROUP BY c.Customer_Segment
)

SELECT
    Customer_Segment,
    Total_Customers,
    Total_Transactions,
    ROUND(Total_Transaction_Value, 2) AS Total_Transaction_Value,
    ROUND(Average_Transaction_Amount, 2) AS Average_Transaction_Amount,

    ROUND(
        Total_Transactions * 100.0 /
        NULLIF(Total_Customers, 0), 2
    ) AS Transactions_Per_Customer,

    ROUND(
        Successful_Transactions * 100.0 /
        NULLIF(Total_Transactions, 0), 2
    ) AS Success_Rate,

    ROUND(
        Risk_Review_Transactions * 100.0 /
        NULLIF(Total_Transactions, 0), 2
    ) AS Risk_Review_Rate

FROM segment_analysis

ORDER BY Total_Transaction_Value DESC;


/*==============================================================
  FINTRUST WEEK 3 — ADVANCED SQL ANALYSIS 2
  TITLE: Transaction Success Rate by Channel

  Business Question:
  Which transaction channels have the highest transaction
  volume and success rate?
==============================================================*/

SELECT
    Channel,

    COUNT(Transaction_ID) AS Total_Transactions,

    COUNT(
        CASE
            WHEN Transaction_Status = 'Successful'
            THEN 1
        END
    ) AS Successful_Transactions,

    COUNT(
        CASE
            WHEN Transaction_Status <> 'Successful'
            THEN 1
        END
    ) AS Unsuccessful_Transactions,

    ROUND(
        COUNT(
            CASE
                WHEN Transaction_Status = 'Successful'
                THEN 1
            END
        ) * 100.0
        / NULLIF(COUNT(Transaction_ID), 0),
        2
    ) AS Success_Rate,

    ROUND(SUM(Amount_NGN), 2) AS Total_Transaction_Value,

    ROUND(AVG(Amount_NGN), 2) AS Average_Transaction_Amount

FROM transactions

GROUP BY Channel

ORDER BY Success_Rate DESC;


/*==============================================================
  FINTRUST WEEK 3 — ADVANCED SQL ANALYSIS 3
  TITLE: Risk Review Pattern by Customer Segment

  Business Question:
  How does risk-review activity differ across customer
  segments?
==============================================================*/

SELECT
    c.Customer_Segment,

    COUNT(t.Transaction_ID) AS Total_Transactions,

    COUNT(
        CASE
            WHEN t.Risk_Review_Flag = 'Yes'
            THEN 1
        END
    ) AS Risk_Review_Transactions,

    COUNT(
        CASE
            WHEN t.Risk_Review_Flag = 'No'
            THEN 1
        END
    ) AS Non_Risk_Review_Transactions,

    ROUND(
        COUNT(
            CASE
                WHEN t.Risk_Review_Flag = 'Yes'
                THEN 1
            END
        ) * 100.0
        / NULLIF(COUNT(t.Transaction_ID), 0),
        2
    ) AS Risk_Review_Rate,

    ROUND(
        SUM(
            CASE
                WHEN t.Risk_Review_Flag = 'Yes'
                THEN t.Amount_NGN
                ELSE 0
            END
        ),
        2
    ) AS Risk_Review_Transaction_Value,

    ROUND(
        AVG(
            CASE
                WHEN t.Risk_Review_Flag = 'Yes'
                THEN t.Amount_NGN
            END
        ),
        2
    ) AS Average_Risk_Review_Amount

FROM customers c

INNER JOIN transactions t
    ON c.Customer_ID = t.Customer_ID

GROUP BY c.Customer_Segment

ORDER BY Risk_Review_Rate DESC;

/*==============================================================
  FINTRUST WEEK 3 — ADVANCED SQL ANALYSIS 4
  TITLE: International vs Domestic Risk Pattern

  Business Question:
  How does risk-review activity differ between international
  and domestic transactions?
==============================================================*/

SELECT
    CASE
        WHEN International_Transaction = 'Yes'
            THEN 'International'
        ELSE 'Domestic'
    END AS Transaction_Category,

    COUNT(Transaction_ID) AS Total_Transactions,

    COUNT(
        CASE
            WHEN Risk_Review_Flag = 'Yes'
            THEN 1
        END
    ) AS Risk_Review_Transactions,

    ROUND(
        COUNT(
            CASE
                WHEN Risk_Review_Flag = 'Yes'
                THEN 1
            END
        ) * 100.0
        / NULLIF(COUNT(Transaction_ID), 0),
        2
    ) AS Risk_Review_Rate,

    ROUND(SUM(Amount_NGN), 2) AS Total_Transaction_Value,

    ROUND(AVG(Amount_NGN), 2) AS Average_Transaction_Amount

FROM transactions

GROUP BY
    CASE
        WHEN International_Transaction = 'Yes'
            THEN 'International'
        ELSE 'Domestic'
    END

ORDER BY Risk_Review_Rate DESC;

/*==============================================================
  FINTRUST WEEK 3 — ADVANCED SQL ANALYSIS 5
  TITLE: Customer Transaction Frequency & Value

  Business Question:
  Which customers have the highest transaction frequency
  and transaction value?
==============================================================*/

WITH customer_activity AS (
    SELECT
        c.Customer_ID,
        c.Customer_Segment,

        COUNT(t.Transaction_ID) AS Total_Transactions,

        SUM(t.Amount_NGN) AS Total_Transaction_Value,

        AVG(t.Amount_NGN) AS Average_Transaction_Amount

    FROM customers c

    INNER JOIN transactions t
        ON c.Customer_ID = t.Customer_ID

    GROUP BY
        c.Customer_ID,
        c.Customer_Segment
)

SELECT
    Customer_ID,
    Customer_Segment,
    Total_Transactions,

    ROUND(Total_Transaction_Value, 2)
        AS Total_Transaction_Value,

    ROUND(Average_Transaction_Amount, 2)
        AS Average_Transaction_Amount,

    CASE
        WHEN Total_Transactions >= 15
            THEN 'High Activity'
        WHEN Total_Transactions >= 8
            THEN 'Medium Activity'
        ELSE 'Low Activity'
    END AS Activity_Level

FROM customer_activity

ORDER BY Total_Transaction_Value DESC;

/*==============================================================
  FINTRUST WEEK 3 — ADVANCED SQL ANALYSIS 6
  TITLE: High-Value Transaction Analysis

  Business Question:
  Which transactions are unusually high in value, and how do
  they compare with the overall transaction population?
==============================================================*/

WITH transaction_stats AS (
    SELECT
        AVG(Amount_NGN) AS Average_Amount,
        STDDEV(Amount_NGN) AS Standard_Deviation
    FROM transactions
),

high_value_transactions AS (
    SELECT
        t.Transaction_ID,
        t.Customer_ID,
        t.Transaction_Type,
        t.Channel,
        t.Amount_NGN,
        t.Transaction_Status,
        t.Risk_Review_Flag,

        s.Average_Amount,
        s.Standard_Deviation

    FROM transactions t

    CROSS JOIN transaction_stats s

    WHERE t.Amount_NGN >
          s.Average_Amount + (2 * s.Standard_Deviation)
)

SELECT
    Transaction_ID,
    Customer_ID,
    Transaction_Type,
    Channel,
    ROUND(Amount_NGN, 2) AS Transaction_Amount,
    Transaction_Status,
    Risk_Review_Flag,

    ROUND(Average_Amount, 2) AS Overall_Average_Amount,

    ROUND(
        Amount_NGN - Average_Amount,
        2
    ) AS Amount_Above_Average,

    ROUND(
        (Amount_NGN - Average_Amount)
        / NULLIF(Standard_Deviation, 0),
        2
    ) AS Z_Score

FROM high_value_transactions

ORDER BY Amount_NGN DESC;

/*==============================================================
  FINTRUST WEEK 3 — ADVANCED SQL ANALYSIS 7
  TITLE: Customer Ranking by Transaction Value

  Business Question:
  How do customers rank based on their total transaction
  value within each customer segment?
==============================================================*/

WITH customer_totals AS (
    SELECT
        c.Customer_ID,
        c.Customer_Segment,

        COUNT(t.Transaction_ID) AS Total_Transactions,

        SUM(t.Amount_NGN) AS Total_Transaction_Value,

        AVG(t.Amount_NGN) AS Average_Transaction_Amount

    FROM customers c

    INNER JOIN transactions t
        ON c.Customer_ID = t.Customer_ID

    GROUP BY
        c.Customer_ID,
        c.Customer_Segment
)

SELECT
    Customer_ID,
    Customer_Segment,
    Total_Transactions,

    ROUND(
        Total_Transaction_Value,
        2
    ) AS Total_Transaction_Value,

    ROUND(
        Average_Transaction_Amount,
        2
    ) AS Average_Transaction_Amount,

    RANK() OVER (
        PARTITION BY Customer_Segment
        ORDER BY Total_Transaction_Value DESC
    ) AS Segment_Rank

FROM customer_totals

ORDER BY
    Customer_Segment,
    Segment_Rank;


/*==============================================================
  FINTRUST WEEK 3 — ADVANCED SQL ANALYSIS 8
  TITLE: Monthly Transaction Trend & Performance

  Business Question:
  How does transaction activity and transaction value change
  over time?
==============================================================*/

WITH monthly_analysis AS (
    SELECT
        DATE_TRUNC('month', transaction_datetime) AS Transaction_Month,

        COUNT(transaction_id) AS Total_Transactions,

        SUM(amount_ngn) AS Total_Transaction_Value,

        AVG(amount_ngn) AS Average_Transaction_Amount,

        COUNT(
            CASE
                WHEN transaction_status = 'Successful'
                THEN 1
            END
        ) AS Successful_Transactions

    FROM transactions

    GROUP BY
        DATE_TRUNC('month', transaction_datetime)
)

SELECT
    Transaction_Month,

    Total_Transactions,

    ROUND(
        Total_Transaction_Value,
        2
    ) AS Total_Transaction_Value,

    ROUND(
        Average_Transaction_Amount,
        2
    ) AS Average_Transaction_Amount,

    Successful_Transactions,

    ROUND(
        Successful_Transactions * 100.0
        / NULLIF(Total_Transactions, 0),
        2
    ) AS Success_Rate,

    ROUND(
        LAG(Total_Transaction_Value) OVER (
            ORDER BY Transaction_Month
        ),
        2
    ) AS Previous_Month_Value,

    ROUND(
        (
            Total_Transaction_Value
            - LAG(Total_Transaction_Value) OVER (
                ORDER BY Transaction_Month
            )
        ) * 100.0
        / NULLIF(
            LAG(Total_Transaction_Value) OVER (
                ORDER BY Transaction_Month
            ),
            0
        ),
        2
    ) AS Month_on_Month_Growth

FROM monthly_analysis

ORDER BY Transaction_Month;