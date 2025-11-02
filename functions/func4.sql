SET @StartDateTime = '2024-01-01 00:00:00';
SET @EndDateTime   = '2024-01-31 23:59:59';

SELECT 
    COUNT(DISTINCT CallID) AS call_count,
    SUM(`TotalCallTime(Sec)`) AS `total_call_time(sec)`
FROM fire_dep
WHERE 
    CallGEOFDID = '31D04'
    AND FDID <> '31D04'
    AND CreateDateTime BETWEEN @StartDateTime AND @EndDateTime;
