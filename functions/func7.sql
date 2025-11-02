-- ==============================================
-- Response Time Summary by Priority and Total
-- ==============================================
-- Calculates average, median, stddev, min, max, and count
-- for each FinalCallPriority, plus true totals for all calls.
-- ==============================================

SET @StartDateTime = '2024-01-01 00:00:00';
SET @EndDateTime   = '2024-01-31 23:59:59';

WITH

-- Filter valid calls
Filtered AS (
    SELECT 
        CallID,
        FinalCallPriority,
        DispatchDateTime,
        ArriveDateTime
    FROM fire_dep
    WHERE 
        CallGEOFDID = '31D04'
        AND FinalCallPriority IN ('1F', '2F', '3F', '4F')
        AND CreateDateTime BETWEEN @StartDateTime AND @EndDateTime
        -- Exclude calls where the first arriving unit is BC/CH/AC/DC/MSO
        AND CallID NOT IN (
            SELECT CallID
            FROM fire_dep
            WHERE UnitNumber REGEXP '^(BC|CH|AC|DC|MSO)'
              AND ArrivalOrder = 1
        )
),

-- Compute per-call response times
CallTimes AS (
    SELECT
        CallID,
        FinalCallPriority,
        TIMESTAMPDIFF(
            SECOND,
            MIN(DispatchDateTime),
            MIN(ArriveDateTime)
        ) AS response_time_seconds
    FROM Filtered
    GROUP BY CallID, FinalCallPriority
),

-- Rank calls within each priority (for medians)
Ranked AS (
    SELECT 
        FinalCallPriority,
        response_time_seconds,
        ROW_NUMBER() OVER (PARTITION BY FinalCallPriority ORDER BY response_time_seconds) AS rn,
        COUNT(*)    OVER (PARTITION BY FinalCallPriority) AS total
    FROM CallTimes
),

-- Calculate median per priority
Medians AS (
    SELECT 
        FinalCallPriority,
        CASE 
            WHEN total % 2 = 1 THEN 
                MAX(CASE WHEN rn = (total + 1) / 2 THEN response_time_seconds END)
            ELSE 
                AVG(CASE WHEN rn IN (total / 2, total / 2 + 1) THEN response_time_seconds END)
        END AS median_response_time_seconds
    FROM Ranked
    GROUP BY FinalCallPriority, total
),


-- Average, standard deviation, min, max per priority
Stats AS (
    SELECT 
        FinalCallPriority,
        COUNT(*) AS call_count,
        AVG(response_time_seconds)  AS avg_response_time_seconds,
        STDDEV(response_time_seconds) AS stddev_time_seconds,
        MIN(response_time_seconds)  AS min_response_time_seconds,
        MAX(response_time_seconds)  AS max_response_time_seconds
    FROM CallTimes
    GROUP BY FinalCallPriority
),


-- True totals across all priorities
Totals AS (
    SELECT
        'TOTAL' AS FinalCallPriority,
        COUNT(*) AS call_count,
        AVG(response_time_seconds)  AS avg_response_time_seconds,
        STDDEV(response_time_seconds) AS stddev_time_seconds,
        MIN(response_time_seconds)  AS min_response_time_seconds,
        MAX(response_time_seconds)  AS max_response_time_seconds
    FROM CallTimes
),


-- Rank all calls globally for the total median
TotalRanked AS (
    SELECT 
        response_time_seconds,
        ROW_NUMBER() OVER (ORDER BY response_time_seconds) AS rn,
        COUNT(*) OVER () AS total
    FROM CallTimes
),


-- True global median
TotalMedian AS (
    SELECT 
        'TOTAL' AS FinalCallPriority,
        CASE 
            WHEN total % 2 = 1 THEN 
                MAX(CASE WHEN rn = (total + 1) / 2 THEN response_time_seconds END)
            ELSE 
                AVG(CASE WHEN rn IN (total / 2, total / 2 + 1) THEN response_time_seconds END)
        END AS median_response_time_seconds
    FROM TotalRanked
    GROUP BY total
)

-- Final output: per-priority + total
SELECT 
    s.FinalCallPriority,
    ROUND(s.avg_response_time_seconds, 3)    AS avg_response_time_seconds,
    ROUND(m.median_response_time_seconds, 3) AS median_response_time_seconds,
    ROUND(s.stddev_time_seconds, 3)          AS stddev_time_seconds,
    s.min_response_time_seconds,
    s.max_response_time_seconds,
    s.call_count
FROM Stats s
JOIN Medians m USING (FinalCallPriority)

UNION ALL

SELECT 
    t.FinalCallPriority,
    ROUND(t.avg_response_time_seconds, 3),
    ROUND(tm.median_response_time_seconds, 3),
    ROUND(t.stddev_time_seconds, 3),
    t.min_response_time_seconds,
    t.max_response_time_seconds,
    t.call_count
FROM Totals t
JOIN TotalMedian tm USING (FinalCallPriority)

ORDER BY 
    CASE WHEN FinalCallPriority = 'TOTAL' THEN 2 ELSE 1 END,
    FinalCallPriority;
