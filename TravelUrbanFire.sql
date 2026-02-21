-- MEAN IS OFF??? WHYYYYY(off by 2, stdv off by 1.5, p90 6 off)

-- ============================================
-- Travel Urban Fire Time Analysis (±3σ trimming with negative value filter + 90th percentile)
-- ============================================

SET @StartDateTime   = '2024-01-01 00:00:00';
SET @EndDateTime     = '2025-01-01 00:00:00';
SET @GoalTimeSeconds = 240;  -- example: 2 minutes
SET @Sigma           = 3;
SET @Percentile      = 0.9;

WITH

-- 1. Base data filtered by date, FDID, and non-negative travel times
BaseData AS (
    SELECT
        `TravelTime(Sec)` AS travel_time_sec
    FROM data_2024
    WHERE CreateDatetime BETWEEN @StartDateTime AND @EndDateTime
      AND CallGEOFDID = '31D04'
      AND Quadrant IN ('AD1218C', 'AD1118A', 'AD1118B', 'AD1118C', 'AD1118D', 'AD1119A', -- Checks for urban quandrant
					   'AD1119B', 'AD1018B', 'AD1018C', 'AD1018D',
                       'AD1019A', 'AD1019B', 'AD0918A', 'AD0918B',
                       'AD0919A', 'AD0919B', 'AD0919C', 'AD0919D')
	  AND UnitNumber REGEXP '^(E|BR|HZ|KCE|KCL|KCBR|L)'
      AND FinalCallType IN ('FB', 'FCC', 'FC', 'FR', 'FRC', 'FS', 'FTU', 'FWI', 'GLI', 'GLO', 'HZ')
      AND FinalCallPriority IN ('1F', '2F', '3F')
      AND CallFilter = 'CallRow'
),

-- 2. Original statistics (before trimming)
OriginalStats AS (
    SELECT
        COUNT(*) AS original_count,
        AVG(travel_time_sec) AS mean_rt,
        STDDEV_POP(travel_time_sec) AS stddev_rt
    FROM BaseData
),

-- 3. Remove ±3σ outliers
TrimmedData AS (
    SELECT
        b.travel_time_sec
    FROM BaseData b
    CROSS JOIN OriginalStats o
    WHERE b.travel_time_sec BETWEEN 1
                                  AND o.mean_rt + @Sigma * o.stddev_rt
),

-- 4. Statistics after trimming
TrimmedStats AS (
    SELECT
        COUNT(*) AS trimmed_count,
        AVG(travel_time_sec) AS mean_travel_time,
        STDDEV_POP(travel_time_sec) AS stddev_travel_time,
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
        lo_val + (hi_val - lo_val) * frac AS p90_travel_time
    FROM (
        SELECT
            MAX(CASE WHEN rn = lo THEN travel_time_sec END) AS lo_val,
            MAX(CASE WHEN rn = hi THEN travel_time_sec END) AS hi_val,
            MAX(frac) AS frac
        FROM (
            SELECT
                travel_time_sec,
                rn,
                lo,
                hi,
                frac
            FROM (
                SELECT
                    travel_time_sec,
                    ROW_NUMBER() OVER (ORDER BY travel_time_sec) - 1 AS rn,
                    FLOOR(@Percentile  * (cnt - 1)) AS lo,
                    CEILING(@Percentile  * (cnt - 1)) AS hi,
                    (@Percentile  * (cnt - 1)) - FLOOR(@Percentile  * (cnt - 1)) AS frac
                FROM (
                    SELECT
							travel_time_sec,
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
        100.0 *
        SUM(CASE 
                WHEN travel_time_sec <= @GoalTimeSeconds THEN 1 
                ELSE 0 
            END)
        / NULLIF(COUNT(*), 0) AS pct_meeting_goal
    FROM TrimmedData
)


-- 8. Final output
SELECT
    t.trimmed_count,
    o.stddev_rt,
    ROUND(t.mean_travel_time, 3)   AS mean_travel_time,
    ROUND(m.median_travel_time, 3) AS median_travel_time,
    SEC_TO_TIME(ROUND(p.p90_travel_time, 0))    AS p90_travel_time,
    ROUND(t.stddev_travel_time, 3) AS stddev_travel_time,
    t.min_travel_time,
    t.max_travel_time,
    ROUND(g.pct_meeting_goal, 2)    AS pct_meeting_goal
FROM OriginalStats o
CROSS JOIN TrimmedStats t
CROSS JOIN MedianCalc m
CROSS JOIN Percentile90 p
CROSS JOIN GoalStats g;

