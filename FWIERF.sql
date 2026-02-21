SET @StartDateTime = '2024-01-01 00:00:00';
SET @EndDateTime   = '2025-01-01 00:00:00';

WITH
-- ======================================================
-- 1. Base unit-level data (filtered)
-- ======================================================
BaseUnits AS (
    SELECT
        f.CallId AS callid,
        f.UnitNumber,
        f.ArrivalOrder,
        f.ArriveDateTime,
        f.DispatchDateTime,
        f.`TotalResponseTime(Sec)` AS total_response_time_sec,
        s.firefighters_per_unit
    FROM data_2024 f
    JOIN unit_staffing s
      ON s.unit_prefix =
         LEFT(f.UnitNumber, REGEXP_INSTR(f.UnitNumber, '[0-9]') - 1)
    WHERE f.CreateDatetime BETWEEN @StartDateTime AND @EndDateTime
      AND f.ArriveDateTime IS NOT NULL
      AND f.`TotalResponseTime(Sec)` IS NOT NULL
      AND f.CallGEOFDID = '31D04'
      AND f.FinalCallType = 'FWI'
),

RunningTotals AS (
    SELECT
        *,
        SUM(firefighters_per_unit) OVER (
            PARTITION BY callid
            ORDER BY ArriveDateTime
            ROWS UNBOUNDED PRECEDING
        ) AS cumulative_firefighters
    FROM BaseUnits
),
-- ======================================================
-- 3. Identify the unit that delivers the 19th firefighter
-- ======================================================
NineteenthFirefighter AS (
    SELECT *
    FROM (
        SELECT
            callid,
            UnitNumber,
            ArrivalOrder,
            ArriveDateTime,
            DispatchDateTime,
            total_response_time_sec,
            cumulative_firefighters,
            ROW_NUMBER() OVER (
                PARTITION BY callid
                ORDER BY ArriveDateTime, UnitNumber
            ) AS rn
        FROM RunningTotals
        WHERE cumulative_firefighters >= 19
    ) x
    WHERE rn = 1
),


FirstFireFighter AS (
    SELECT *
    FROM (
        SELECT
            callid,
            UnitNumber,
            ArrivalOrder,
            ArriveDateTime,
            DispatchDateTime,
            ROW_NUMBER() OVER (
                PARTITION BY callid
                ORDER BY ArriveDateTime, UnitNumber
            ) AS rn
        FROM BaseUnits
    ) x
    WHERE rn = 1
)

-- ======================================================
-- 4. Final incident-level output
-- ======================================================
SELECT 
    f.CallID,
    SEC_TO_TIME(TIMESTAMPDIFF(
        SECOND, 
        f.DispatchDateTime, 
        t.ArriveDateTime
    )) AS total_time_19th_firefighter
FROM FirstFireFighter f
JOIN NineteenthFirefighter t
    ON f.CallID = t.CallID;