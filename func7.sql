SET @StartDateTime = '2024-01-01 00:00:00';
SET @EndDateTime   = '2024-01-31 23:59:59';

WITH
-- ======================================================
-- 1. Filter valid calls
-- ======================================================
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
        AND StartDateTime BETWEEN @StartDateTime AND @EndDateTime
        AND CallID NOT IN (
            SELECT CallID
            FROM fire_dep
            WHERE UnitNumber REGEXP '^(BC|CH|AC|DC|MSO)'
              AND ArrivalOrder = 1
        )
),

-- ======================================================
-- 2. Per-call response times
-- ======================================================
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

-- ======================================================
-- 3. ORIGINAL per-priority stats
-- ======================================================
OrigStats AS (
    SELECT
        FinalCallPriority,
        COUNT(*) AS original_call_count,
        AVG(response_time_seconds) AS mean_rt,
        STDDEV(response_time_seconds) AS stddev_rt
    FROM CallTimes
    GROUP BY FinalCallPriority
),

-- ======================================================
-- 4. ORIGINAL TOTAL stats
-- ======================================================
OrigTotalStats AS (
    SELECT
        'TOTAL' AS FinalCallPriority,
        COUNT(*) AS original_call_count,
        AVG(response_time_seconds) AS mean_rt,
        STDDEV(response_time_seconds) AS stddev_rt
    FROM CallTimes
),

-- ======================================================
-- 5. Trimmed per-priority calls (± 3σ)
-- ======================================================
TrimmedCalls AS (
    SELECT
        c.CallID,
        c.FinalCallPriority,
        c.response_time_seconds
    FROM CallTimes c
    JOIN OrigStats o
      ON c.FinalCallPriority = o.FinalCallPriority
    WHERE c.response_time_seconds BETWEEN
          o.mean_rt - 3 * o.stddev_rt
      AND o.mean_rt + 3 * o.stddev_rt
),

-- ======================================================
-- 6. Trimmed TOTAL calls (± 3σ, global)
-- ======================================================
TrimmedTotalCalls AS (
    SELECT
        c.CallID,
        'TOTAL' AS FinalCallPriority,
        c.response_time_seconds
    FROM CallTimes c
    JOIN OrigTotalStats t
    WHERE c.response_time_seconds BETWEEN
          t.mean_rt - 3 * t.stddev_rt
      AND t.mean_rt + 3 * t.stddev_rt
),

-- ======================================================
-- 7. Union trimmed data (priority + total)
-- ======================================================
AllTrimmed AS (
    SELECT * FROM TrimmedCalls
    UNION ALL
    SELECT * FROM TrimmedTotalCalls
),

-- ======================================================
-- 8. Stats after trimming
-- ======================================================
TrimmedStats AS (
    SELECT
        FinalCallPriority,
        COUNT(*) AS trimmed_call_count,
        AVG(response_time_seconds) AS avg_response_time_seconds,
        STDDEV(response_time_seconds) AS stddev_time_seconds,
        MIN(response_time_seconds) AS min_response_time_seconds,
        MAX(response_time_seconds) AS max_response_time_seconds
    FROM AllTrimmed
    GROUP BY FinalCallPriority
),

-- ======================================================
-- 9. Medians after trimming
-- ======================================================
Ranked AS (
    SELECT
        FinalCallPriority,
        response_time_seconds,
        ROW_NUMBER() OVER (
            PARTITION BY FinalCallPriority
            ORDER BY response_time_seconds
        ) AS rn,
        COUNT(*) OVER (
            PARTITION BY FinalCallPriority
        ) AS total
    FROM AllTrimmed
),

Medians AS (
    SELECT
        FinalCallPriority,
        CASE
            WHEN total % 2 = 1 THEN
                MAX(CASE WHEN rn = (total + 1) / 2 THEN response_time_seconds END)
            ELSE
                AVG(CASE WHEN rn IN (total / 2, total / 2 + 1)
                         THEN response_time_seconds END)
        END AS median_response_time_seconds
    FROM Ranked
    GROUP BY FinalCallPriority, total
),

-- ======================================================
-- 10. Combine original counts (priority + total)
-- ======================================================
AllOriginalCounts AS (
    SELECT FinalCallPriority, original_call_count FROM OrigStats
    UNION ALL
    SELECT FinalCallPriority, original_call_count FROM OrigTotalStats
)

-- ======================================================
-- 11. Final output
-- ======================================================
SELECT
    t.FinalCallPriority,
    o.original_call_count,
    t.trimmed_call_count,
    ROUND(t.avg_response_time_seconds, 3)    AS avg_response_time_seconds,
    ROUND(m.median_response_time_seconds, 3) AS median_response_time_seconds,
    ROUND(t.stddev_time_seconds, 3)          AS stddev_time_seconds,
    t.min_response_time_seconds,
    t.max_response_time_seconds
FROM TrimmedStats t
JOIN Medians m USING (FinalCallPriority)
JOIN AllOriginalCounts o USING (FinalCallPriority)

ORDER BY
    CASE WHEN FinalCallPriority = 'TOTAL' THEN 2 ELSE 1 END,
    FinalCallPriority;
