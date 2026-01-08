-- ============================================
-- Turnout Time Analysis (±3σ trimming with negative value filter + 90th percentile)
-- ============================================

SET @StartDateTime   = '2025-01-01 00:00:00';
SET @EndDateTime     = '2026-01-01 00:00:00';
SET @GoalTimeSeconds = 120; 
SET @Sigma           = 3;
SET @Percentile      = 0.9;

WITH

-- 1. Base data filtered by date, FDID, and non-negative turnout times
BaseData AS (
    SELECT
        `TurnoutTime(Sec)` AS turnout_time_sec
    FROM fire_dep
    WHERE CreateDatetime BETWEEN @StartDateTime AND @EndDateTime
      AND `TurnoutTime(Sec)` >= 1 -- knock out bad data
      AND FDID = '31D04'  -- Our district units??
      AND FinalCallPriority IN ('1F', '2F', '3F', '4F')  -- is it within the priority calls?
	  AND UnitNumber IN ('A40', 'A41', 'A42', 'A43', 'A43A', 'B41', 
						 'B42', 'B43', 'BR42', 'BR43', 'E40', 'E41', 
                         'E42', 'E43', 'E43A', 'MSO43', 'TN43')
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

-- 6. 90th percentile calculation    -- Long stupid way around not having percent_cont :(
Percentile90 AS (
    SELECT
        lo_val + (hi_val - lo_val) * frac AS p90_turnout_time
    FROM (
        SELECT
            MAX(CASE WHEN rn = lo THEN turnout_time_sec END) AS lo_val,
            MAX(CASE WHEN rn = hi THEN turnout_time_sec END) AS hi_val,
            MAX(frac) AS frac
        FROM (
            SELECT
                turnout_time_sec,
                rn,
                lo,
                hi,
                frac
            FROM (
                SELECT
                    turnout_time_sec,
                    ROW_NUMBER() OVER (ORDER BY turnout_time_sec) - 1 AS rn,
                    FLOOR(@Percentile  * (cnt - 1)) AS lo,
                    CEILING(@Percentile  * (cnt - 1)) AS hi,
                    (@Percentile  * (cnt - 1)) - FLOOR(@Percentile  * (cnt - 1)) AS frac
                FROM (
                    SELECT
                        turnout_time_sec,
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

