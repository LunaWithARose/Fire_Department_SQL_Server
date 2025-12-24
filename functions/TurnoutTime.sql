-- ============================================
-- Turnout Time Analysis (±3σ trimming with negative value filter + 90th percentile)
-- ============================================

SET @StartDateTime   = '2025-01-01 00:00:00';
SET @EndDateTime     = '2026-01-01 00:00:00';
SET @GoalTimeSeconds = 120;  -- example: 2 minutes
SET @Sigma           = 3;

WITH

-- 1. Base data filtered by date, FDID, and non-negative turnout times
BaseData AS (
    SELECT
        `TurnoutTime(Sec)` AS turnout_time_sec
    FROM fire_dep
    WHERE CreateDatetime BETWEEN @StartDateTime AND @EndDateTime
      AND `TurnoutTime(Sec)` >= 5
      AND FDID = '31D04'
),

-- 2. Original statistics (before trimming)
OriginalStats AS (
    SELECT
        COUNT(*) AS original_count,
        AVG(turnout_time_sec) AS mean_rt,
        STDDEV(turnout_time_sec) AS stddev_rt
    FROM BaseData
),

-- 3. Remove ±3σ outliers
TrimmedData AS (
    SELECT
        b.turnout_time_sec
    FROM BaseData b
    CROSS JOIN OriginalStats o
    WHERE b.turnout_time_sec BETWEEN o.mean_rt - @Sigma * o.stddev_rt
                                  AND o.mean_rt + @Sigma * o.stddev_rt
),

-- 4. Statistics after trimming
TrimmedStats AS (
    SELECT
        COUNT(*) AS trimmed_count,
        AVG(turnout_time_sec) AS mean_turnout_time,
        STDDEV(turnout_time_sec) AS stddev_turnout_time,
        MIN(turnout_time_sec) AS min_turnout_time,
        MAX(turnout_time_sec) AS max_turnout_time
    FROM TrimmedData
),

-- 5. Median calculation after trimming
Ranked AS (
    SELECT
        turnout_time_sec,
        ROW_NUMBER() OVER (ORDER BY turnout_time_sec) AS rn,
        COUNT(*) OVER () AS total
    FROM TrimmedData
),
MedianCalc AS (
    SELECT
        CASE
            WHEN total % 2 = 1 THEN
                MAX(CASE WHEN rn = (total + 1) / 2 THEN turnout_time_sec END)
            ELSE
                AVG(CASE WHEN rn IN (total / 2, total / 2 + 1) THEN turnout_time_sec END)
        END AS median_turnout_time
    FROM Ranked
    GROUP BY total
),

-- 6. 90th percentile calculation
Percentile90 AS (
    SELECT
        turnout_time_sec AS p90_turnout_time
    FROM (
        SELECT
            turnout_time_sec,
            ROW_NUMBER() OVER (ORDER BY turnout_time_sec) AS rn,
            COUNT(*) OVER () AS total
        FROM TrimmedData
    ) x
    WHERE rn = CEILING(0.9 * total)
),

-- 7. Goal-time percentage
GoalStats AS (
    SELECT
        100.0 * SUM(turnout_time_sec <= @GoalTimeSeconds) / COUNT(*) AS pct_meeting_goal
    FROM TrimmedData
)

-- 8. Final output
SELECT
    t.trimmed_count,
    ROUND(t.mean_turnout_time, 3)   AS mean_turnout_time,
    ROUND(m.median_turnout_time, 3) AS median_turnout_time,
    ROUND(p.p90_turnout_time, 3)    AS p90_turnout_time,
    ROUND(t.stddev_turnout_time, 3) AS stddev_turnout_time,
    t.min_turnout_time,
    t.max_turnout_time,
    ROUND(g.pct_meeting_goal, 2)    AS pct_meeting_goal
FROM OriginalStats o
CROSS JOIN TrimmedStats t
CROSS JOIN MedianCalc m
CROSS JOIN Percentile90 p
CROSS JOIN GoalStats g;

