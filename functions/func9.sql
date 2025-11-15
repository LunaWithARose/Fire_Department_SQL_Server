SET @StartDateTime = '2024-01-01 00:00:00';
SET @EndDateTime   = '2024-01-31 23:59:59';

SELECT COUNT(distinct CALLID)
From(
	Select CALLID
    FROM fire_dep
    WHERE CallGEOFDID = '31D04'
    AND ArrivalOrder = 1
    AND FDID <> '31D04'
	AND CreateDateTime BETWEEN @StartDateTime AND @EndDateTime
) AS temp_table;