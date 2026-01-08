-- ============================================
-- Dispatch Time Analysis (with ±3σ trimming)
-- ============================================

SET @StartDateTime   = '2025-01-01 00:00:00';
SET @EndDateTime     = '2026-01-01 00:00:00';
SET @GoalTimeSeconds = 90;  
SET @Sigma           = 3;
SET @Percentile      = 0.9;

WITH

-- 1. Base data filtered by date, dispatch time, and specific CallGEOFDID
BaseData AS (
    SELECT
	
        `DispatchTime(Sec)` AS dispatch_time_sec
    FROM fire_dep
    WHERE CreateDatetime BETWEEN @StartDateTime AND @EndDateTime
      AND `DispatchTime(Sec)` >= 1 -- take out bad data
      AND CallGEOFDID = '31D04'  -- within out distric
      AND InitialCallPriority IN ('1F', '2F', '3F', '4f')  -- is it within the priority calls?
),

-- 2. Original statistics (before trimming)
OriginalStats AS (
    SELECT
        COUNT(*) AS original_count,
        AVG(dispatch_time_sec) AS mean_rt,
        STDDEV(dispatch_time_sec) AS stddev_rt
    FROM BaseData
),

-- 3. Remove ±3σ outliers
TrimmedData AS (
    SELECT
        b.dispatch_time_sec
    FROM BaseData b
    CROSS JOIN OriginalStats o
    WHERE b.dispatch_time_sec BETWEEN o.mean_rt - @Sigma * o.stddev_rt
                                  AND o.mean_rt + @Sigma * o.stddev_rt
),

-- 4. Statistics after trimming
TrimmedStats AS (
    SELECT
        COUNT(*) AS trimmed_count,
        AVG(dispatch_time_sec) AS mean_dispatch_time,
        STDDEV(dispatch_time_sec) AS stddev_dispatch_time,
        MIN(dispatch_time_sec) AS min_dispatch_time,
        MAX(dispatch_time_sec) AS max_dispatch_time
    FROM TrimmedData
),

-- 5. Median calculation after trimming
Ranked AS (
    SELECT
        dispatch_time_sec,
        ROW_NUMBER() OVER (ORDER BY dispatch_time_sec) AS rn,
        COUNT(*) OVER () AS total
    FROM TrimmedData
),
MedianCalc AS (
    SELECT
        CASE
            WHEN total % 2 = 1 THEN
                MAX(CASE WHEN rn = (total + 1) / 2 THEN dispatch_time_sec END)
            ELSE
                AVG(CASE WHEN rn IN (total / 2, total / 2 + 1) THEN dispatch_time_sec END)
        END AS median_dispatch_time
    FROM Ranked
    GROUP BY total
),

-- 6. 90th percentile after trimming
Percentile90 AS (
    SELECT
        lo_val + (hi_val - lo_val) * frac AS p90_dispatch_time
    FROM (
        SELECT
            MAX(CASE WHEN rn = lo THEN dispatch_time_sec END) AS lo_val,
            MAX(CASE WHEN rn = hi THEN dispatch_time_sec END) AS hi_val,
            MAX(frac) AS frac
        FROM (
            SELECT
                dispatch_time_sec,
                rn,
                lo,
                hi,
                frac
            FROM (
                SELECT
                    dispatch_time_sec,
                    ROW_NUMBER() OVER (ORDER BY dispatch_time_sec) - 1 AS rn,
                    FLOOR(@Percentile  * (cnt - 1)) AS lo,
                    CEILING(@Percentile  * (cnt - 1)) AS hi,
                    (@Percentile  * (cnt - 1)) - FLOOR(@Percentile  * (cnt - 1)) AS frac
                FROM (
                    SELECT
							dispatch_time_sec,
                        COUNT(*) OVER () AS cnt
                    FROM TrimmedData
                ) c
            ) r
        ) s
    ) f
),
-- 7. Goal-time percentage
GoalStats AS (
    SELECT
        100.0 * SUM(dispatch_time_sec <= @GoalTimeSeconds) / COUNT(*) AS pct_meeting_goal
    FROM TrimmedData
)

-- 8. Final output
SELECT
    t.trimmed_count,
    ROUND(t.mean_dispatch_time, 3)   AS mean_dispatch_time,
    ROUND(m.median_dispatch_time, 3) AS median_dispatch_time,
    ROUND(p.p90_dispatch_time, 3)    AS p90_dispatch_time,
    ROUND(t.stddev_dispatch_time, 3) AS stddev_dispatch_time,
    t.min_dispatch_time,
    t.max_dispatch_time,
    ROUND(g.pct_meeting_goal, 2)     AS pct_meeting_goal
FROM OriginalStats o
CROSS JOIN TrimmedStats t
CROSS JOIN MedianCalc m
CROSS JOIN Percentile90 p
CROSS JOIN GoalStats g;

