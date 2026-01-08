SET @StartDateTime = '2025-01-01 00:00:00';
SET @EndDateTime   = '2026-01-01 00:00:00';

WITH
-- ======================================================
-- 1. Base unit-level data (filtered)
-- ======================================================
BaseUnits AS (
    SELECT
        f.CallId AS callid,
        f.UnitNumber,
        f.ArriveDateTime,
        f.ArrivalOrder,
        f.`TotalResponseTime(Sec)` AS total_response_time_sec,
        s.firefighters_per_unit
    FROM fire_dep f
    JOIN unit_staffing s
      ON s.unit_prefix =
         LEFT(f.UnitNumber, REGEXP_INSTR(f.UnitNumber, '[0-9]') - 1)
    WHERE f.CreateDatetime BETWEEN @StartDateTime AND @EndDateTime
      AND f.ArriveDateTime IS NOT NULL
      AND f.`TotalResponseTime(Sec)` IS NOT NULL
      AND f.CallGEOFDID = '31D04'
      AND f.FinalCallType = 'FWI'
      AND f.FinalCallPriority IN ('1F', '2F', '3F', '4F')
),

-- ======================================================
-- 2. Cumulative firefighter count per call
-- ======================================================
RunningTotals AS (
    SELECT
        *,
        SUM(firefighters_per_unit) OVER (
            PARTITION BY callid
            ORDER BY ArriveDateTime, UnitNumber
            ROWS UNBOUNDED PRECEDING
        ) AS cumulative_firefighters
    FROM BaseUnits
),

RunningTotals AS (
    SELECT
        *,
        SUM(firefighters_per_unit) OVER (
            PARTITION BY callid
            ORDER BY ArrivalOrder
            ROWS UNBOUNDED PRECEDING
        ) AS cumulative_firefighters
    FROM BaseUnits
),

-- ======================================================
-- 3. Identify the unit that delivers the 22nd firefighter
-- ======================================================
NineteenthFirefighter AS (
    SELECT
        callid,
        UnitNumber,
        ArrivalOrder,
        ArriveDateTime,
        total_response_time_sec,
        cumulative_firefighters,
        ROW_NUMBER() OVER (
            PARTITION BY callid
            ORDER BY ArriveDateTime, UnitNumber
        ) AS rn
    FROM RunningTotals
    WHERE cumulative_firefighters >= 19
)

-- ======================================================
-- 4. Final incident-level output
-- ======================================================
SELECT
    callid,
    UnitNumber                AS unit_delivering_19th_firefighter,
    ArriveDateTime            AS arrival_time_19th_firefighter,
    ArrivalOrder              AS arrival_number,
    total_response_time_sec   AS total_response_time_sec_19th
FROM NineteenthFirefighter
WHERE rn = 1
ORDER BY total_response_time_sec;