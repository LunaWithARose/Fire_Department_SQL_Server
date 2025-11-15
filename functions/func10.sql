SET @StartDateTime = '2024-01-01 00:00:00';
SET @EndDateTime   = '2024-01-31 23:59:59';

WITH Table_1 as(
SELECT COUNT(distinct CALLID) as d1
From(
	Select CALLID
    FROM fire_dep
    WHERE CallGEOFDID = '31D04'
    AND ArrivalOrder = 1
    AND FDID <> '31D04'
	AND CreateDateTime BETWEEN @StartDateTime AND @EndDateTime
) AS temp_table
),
Table_2 as(
	SELECT COUNT(distinct CALLID) as d2
From(
	Select CALLID
    FROM fire_dep
    WHERE CallGEOFDID = '31D04'
    AND ArrivalOrder = 1
    AND FDID = '31D04'
	AND CreateDateTime BETWEEN @StartDateTime AND @EndDateTime
) AS temp_table
)

SELECT
    t1_sum.total_t1 + t2_sum.total_t2 AS combined_sum
FROM
    (SELECT SUM(d1) AS total_t1 FROM Table_1) AS t1_sum
CROSS JOIN
    (SELECT SUM(d2) AS total_t2 FROM Table_2) AS t2_sum;

