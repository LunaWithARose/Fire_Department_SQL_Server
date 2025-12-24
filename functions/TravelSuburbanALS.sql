-- ============================================
-- Travel Suburban ALS Time Analysis (±3σ trimming with negative value filter + 90th percentile)
-- ============================================

SET @StartDateTime   = '2025-01-01 00:00:00';
SET @EndDateTime     = '2026-01-01 00:00:00';
SET @GoalTimeSeconds = 600;  -- example: 2 minutes
SET @Sigma           = 3;

WITH

-- 1. Base data filtered by date, FDID, and non-negative travel times
BaseData AS (
    SELECT
        `TravelTime(Sec)` AS travel_time_sec
    FROM fire_dep
    WHERE CreateDatetime BETWEEN @StartDateTime AND @EndDateTime
      AND `TravelTime(Sec)` >= 5
      AND CallGEOFDID = '31D04'
      AND Quadrant NOT IN ('AD1218c', 'AD1118', 'AD1119c', 'AD1119d', 'AD1018b', 'AD1018c', 'AD1018d', 'AD1019', 'AD0918a', 'AD0918c', 'AD1919')
      AND UnitNumber REGEXP '^(M)'
),

-- 2. Original statistics (before trimming)
OriginalStats AS (
    SELECT
        COUNT(*) AS original_count,
        AVG(travel_time_sec) AS mean_rt,
        STDDEV(travel_time_sec) AS stddev_rt
    FROM BaseData
),

-- 3. Remove ±3σ outliers
TrimmedData AS (
    SELECT
        b.travel_time_sec
    FROM BaseData b
    CROSS JOIN OriginalStats o
    WHERE b.travel_time_sec BETWEEN o.mean_rt - @Sigma * o.stddev_rt
                                  AND o.mean_rt + @Sigma * o.stddev_rt
),

-- 4. Statistics after trimming
TrimmedStats AS (
    SELECT
        COUNT(*) AS trimmed_count,
        AVG(travel_time_sec) AS mean_travel_time,
        STDDEV(travel_time_sec) AS stddev_travel_time,
        MIN(travel_time_sec) AS min_travel_time,
        MAX(travel_time_sec) AS max_travel_time
    FROM TrimmedData
),

-- 5. Median calculation after trimming
Ranked AS (
    SELECT
        travel_time_sec,
        ROW_NUMBER() OVER (ORDER BY travel_time_sec) AS rn,
        COUNT(*) OVER () AS total
    FROM TrimmedData
),
MedianCalc AS (
    SELECT
        CASE
            WHEN total % 2 = 1 THEN
                MAX(CASE WHEN rn = (total + 1) / 2 THEN travel_time_sec END)
            ELSE
                AVG(CASE WHEN rn IN (total / 2, total / 2 + 1) THEN travel_time_sec END)
        END AS median_travel_time
    FROM Ranked
    GROUP BY total
),

-- 6. 90th percentile calculation
Percentile90 AS (
    SELECT
        travel_time_sec AS p90_travel_time
    FROM (
        SELECT
            travel_time_sec,
            ROW_NUMBER() OVER (ORDER BY travel_time_sec) AS rn,
            COUNT(*) OVER () AS total
        FROM TrimmedData
    ) x
    WHERE rn = CEILING(0.9 * total)
),

-- 7. Goal-time percentage
GoalStats AS (
    SELECT
        100.0 * SUM(travel_time_sec <= @GoalTimeSeconds) / COUNT(*) AS pct_meeting_goal
    FROM TrimmedData
)

-- 8. Final output
SELECT
    t.trimmed_count,
    ROUND(t.mean_travel_time, 3)   AS mean_travel_time,
    ROUND(m.median_travel_time, 3) AS median_travel_time,
    ROUND(p.p90_travel_time, 3)    AS p90_travel_time,
    ROUND(t.stddev_travel_time, 3) AS stddev_travel_time,
    t.min_travel_time,
    t.max_travel_time,
    ROUND(g.pct_meeting_goal, 2)    AS pct_meeting_goal
FROM OriginalStats o
CROSS JOIN TrimmedStats t
CROSS JOIN MedianCalc m
CROSS JOIN Percentile90 p
CROSS JOIN GoalStats g;