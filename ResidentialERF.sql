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
        f.FinalCallType,
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
      AND f.FinalCallType IN ('FR', 'FRC')
	  AND f.Quadrant IN ('AD1218C', 'AD1118A', 'AD1118B', 'AD1118C', 'AD1118D', 'AD1119A', -- Checks for urban quandrant
					   'AD1119B', 'AD1018B', 'AD1018C', 'AD1018D',
                       'AD1019A', 'AD1019B', 'AD0918A', 'AD0918B',
                       'AD0919A', 'AD0919B', 'AD0919C', 'AD0919D')
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
-- 3. Identify the unit that delivers the 16th firefighter
-- ======================================================
SixteenthFirefighter AS (
    SELECT *
    FROM (
        SELECT
            callid,
            UnitNumber,
            ArrivalOrder,
            ArriveDateTime,
            DispatchDateTime,
            FinalCallType,
            total_response_time_sec,
            cumulative_firefighters,
            ROW_NUMBER() OVER (
                PARTITION BY callid
                ORDER BY ArriveDateTime, UnitNumber
            ) AS rn
        FROM RunningTotals
        WHERE cumulative_firefighters >= 16
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
            FinalCallType,
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
    )) AS total_time_16th_firefighter,
    f.DispatchDateTime,
    t.ArriveDateTime,
    f.UnitNumber as First_unit_on_scene,
    t.UnitNumber as 16th_unit_on_scene,
    f.FinalCallType
FROM FirstFireFighter f
JOIN SixteenthFirefighter t
    ON f.CallID = t.CallID;
