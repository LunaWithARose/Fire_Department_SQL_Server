SET @StartDateTime = '2024-01-01 00:00:00';
SET @EndDateTime   = '2024-01-31 23:59:59';

SET @GoalTimeSeconds = 90;  -- example: 8 minutes
SET @Sigma = 3;

WITH
-- ======================================================
-- 1. Time-constrained base data
-- ======================================================
BaseData AS (
    SELECT
        `DispatchTime(Sec)` AS dispatch_time_sec
    FROM fire_dep
    WHERE CreateDatetime BETWEEN @StartDateTime AND @EndDateTime
      AND `DispatchTime(Sec)` IS NOT NULL
      AND CallGEOFDID = '31D04'
),

-- ======================================================
-- 2. Original stats (used for trimming)
-- ======================================================
OriginalStats AS (
    SELECT
        COUNT(*) AS original_count,
        AVG(dispatch_time_sec) AS mean_rt,
        STDDEV(dispatch_time_sec) AS stddev_rt
    FROM BaseData
),

-- ======================================================
-- 3. Remove > ±3σ outliers
-- ======================================================
TrimmedData AS (
    SELECT
        b.dispatch_time_sec
    FROM BaseData b
    CROSS JOIN OriginalStats o
    WHERE b.dispatch_time_sec BETWEEN
          o.mean_rt - @Sigma * o.stddev_rt
      AND o.mean_rt + @Sigma * o.stddev_rt
),

-- ======================================================
-- 4. Stats after trimming
-- ======================================================
TrimmedStats AS (
    SELECT
        COUNT(*) AS trimmed_count,
        AVG(dispatch_time_sec) AS mean_dispatch_time,
        STDDEV(dispatch_time_sec) AS stddev_dispatch_time,
        MIN(dispatch_time_sec) AS min_dispatch_time,
        MAX(dispatch_time_sec) AS max_dispatch_time
    FROM TrimmedData
),

-- ======================================================
-- 5. Median after trimming
-- ======================================================
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
                AVG(CASE WHEN rn IN (total / 2, total / 2 + 1)
                         THEN dispatch_time_sec END)
        END AS median_dispatch_time
    FROM Ranked
    GROUP BY total
),

-- ======================================================
-- 6. Goal-time percentage (after trimming)
-- ======================================================
GoalStats AS (
    SELECT
        100.0 * SUM(dispatch_time_sec <= @GoalTimeSeconds)
              / COUNT(*) AS pct_meeting_goal
    FROM TrimmedData
)

-- ======================================================
-- 7. Final output
-- ======================================================
SELECT
    o.original_count,
    t.trimmed_count,
    ROUND(t.mean_dispatch_time, 3)   AS mean_dispatch_time,
    ROUND(m.median_dispatch_time, 3) AS median_dispatch_time,
    ROUND(t.stddev_dispatch_time, 3) AS stddev_dispatch_time,
    t.min_dispatch_time,
    t.max_dispatch_time,
    ROUND(g.pct_meeting_goal, 2)     AS pct_meeting_goal
FROM OriginalStats o
CROSS JOIN TrimmedStats t
CROSS JOIN MedianCalc m
CROSS JOIN GoalStats g;
