-- ============================================
-- Turnout Time Analysis (±3σ trimming + p90)
-- ============================================

SET @StartDateTime   = '2024-01-01 00:00:00';
SET @EndDateTime     = '2025-01-01 00:00:00';
SET @GoalTimeSeconds = 120;
SET @Sigma           = 3;
SET @Percentile      = 0.9;

WITH
-- 1. Base data
BaseData AS (
    SELECT
        `TurnoutTime(Sec)` AS turnout_time_sec
    FROM data_2024
    WHERE CreateDatetime BETWEEN @StartDateTime AND @EndDateTime
      AND `TurnoutTime(Sec)` >= 1
      AND FDID = '31D04'
      AND InitialCallPriority IN ('1F','2F','3F')
      AND UnitNumber IN (
          'A40','A41','A42','A43','B41','B42','B43',
          'BR42','BR43','E40','E41','E42','E43','MSO43',
          'T43', 'M40', 'M41', 'M42', 'M43'
      )
),

-- 2. Original stats
Stats AS (
    SELECT
        COUNT(*) AS original_count,
        AVG(turnout_time_sec) AS mean_rt,
        STDDEV_POP(turnout_time_sec) AS stddev_rt
    FROM BaseData
),

-- 3. Trim ±3σ
TrimmedData AS (
    SELECT b.turnout_time_sec
    FROM BaseData b
    JOIN Stats s
      ON b.turnout_time_sec BETWEEN
         1
     AND s.mean_rt + @Sigma * s.stddev_rt
),

-- 4. Trimmed statistics
TrimmedStats AS (
    SELECT
        COUNT(*) AS trimmed_count,
        AVG(turnout_time_sec) AS mean_turnout_time,
        STDDEV_POP(turnout_time_sec) AS stddev_turnout_time,
        MIN(turnout_time_sec) AS min_turnout_time,
        MAX(turnout_time_sec) AS max_turnout_time
    FROM TrimmedData
),

-- 5. Ranking once for median & p90
Ranked AS (
    SELECT
        turnout_time_sec,
        ROW_NUMBER() OVER (ORDER BY turnout_time_sec) - 1 AS rn,
        COUNT(*) OVER () AS cnt
    FROM TrimmedData
),

-- 6. Median
MedianCalc AS (
    SELECT
        CASE
            WHEN cnt % 2 = 1 THEN
                MAX(CASE WHEN rn = cnt DIV 2 THEN turnout_time_sec END)
            ELSE
                AVG(CASE WHEN rn IN (cnt / 2 - 1, cnt / 2) THEN turnout_time_sec END)
        END AS median_turnout_time
    FROM Ranked
    GROUP BY cnt
),

-- 7. 90th percentile  -- Cont Percentile not discrete it interpolates between 2 points
Percentile90 AS ( 
	SELECT lo_val + (hi_val - lo_val) * frac AS p90_turnout_time 
		FROM ( 
			SELECT MAX(CASE WHEN rn = lo THEN turnout_time_sec END) AS lo_val, 
            MAX(CASE WHEN rn = hi THEN turnout_time_sec END) AS hi_val, 
            MAX(frac) AS frac FROM ( 
				SELECT turnout_time_sec, rn, lo, hi, frac 
				FROM ( 
					SELECT turnout_time_sec, ROW_NUMBER() OVER (ORDER BY turnout_time_sec) - 1 AS rn, 
					FLOOR(@Percentile * (cnt - 1)) AS lo, 
					CEILING(@Percentile * (cnt - 1)) AS hi, 
					(@Percentile * (cnt - 1)) - FLOOR(@Percentile * (cnt - 1)) AS frac 
					FROM ( 
						SELECT turnout_time_sec, COUNT(*) OVER () AS cnt FROM TrimmedData 
				) c 
            ) r 
		) s 
	) f 
),

-- 8. Goal-time percentage
GoalStats AS (
    SELECT
        100.0 * SUM(turnout_time_sec <= @GoalTimeSeconds) / COUNT(*) AS pct_meeting_goal
    FROM TrimmedData
)

-- 9. Final output
SELECT
    t.trimmed_count,
    ROUND(t.mean_turnout_time, 3)   AS mean_turnout_time,
    ROUND(m.median_turnout_time, 3) AS median_turnout_time,
    ROUND(p.p90_turnout_time, 3)    AS p90_turnout_time,
    ROUND(s.stddev_rt, 3) AS untrimmed_stdev,
    ROUND(t.stddev_turnout_time, 3) AS stddev_turnout_time,
    t.min_turnout_time,
    t.max_turnout_time,
    ROUND(g.pct_meeting_goal, 2)    AS pct_meeting_goal
FROM TrimmedStats t
JOIN Stats s
JOIN MedianCalc m
JOIN Percentile90 p
JOIN GoalStats g;

