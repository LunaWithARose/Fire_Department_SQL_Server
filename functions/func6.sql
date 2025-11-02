SET @StartDateTime = '2024-01-01 00:00:00';
SET @EndDateTime   = '2024-01-31 23:59:59';

With OUT_AID as (
SELECT 
    COUNT(DISTINCT CallID) AS call_count
FROM fire_dep
WHERE 
    CallGEOFDID <> '31D04'
    AND FDID = '31D04'
    AND CreateDateTime BETWEEN @StartDateTime AND @EndDateTime
),

FDID_IN_DISTRICT AS(
SELECT COUNT(DISTINCT CallID) AS `Total_Calls_In_District`
FROM fire_dep
WHERE CallGEOFDID = '31D04'
  AND CreateDateTime BETWEEN @StartDateTime AND @EndDateTime
)

SELECT
    t1_sum.total_t1 + t2_sum.total_t2 AS combined_sum
FROM
    (SELECT SUM(call_count) AS total_t1 FROM OUT_AID) AS t1_sum
CROSS JOIN
    (SELECT SUM(`Total_Calls_In_District`) AS total_t2 FROM FDID_IN_DISTRICT) AS t2_sum;