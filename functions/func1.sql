SET @StartDateTime = '2025-01-01 00:00:00';
SET @EndDateTime   = '2026-01-01 00:00:00';

SELECT COUNT(DISTINCT CallID) AS `Total_Calls_In_District`
FROM fire_dep
WHERE CallGEOFDID = '31D04'
  AND StartDateTime BETWEEN @StartDateTime AND @EndDateTime;