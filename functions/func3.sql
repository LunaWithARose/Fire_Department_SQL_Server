SET @StartDateTime = '2024-01-01 00:00:00';
SET @EndDateTime   = '2024-01-31 23:59:59';

SELECT COUNT(DISTINCT CallID) AS call_count
FROM fire_dep
WHERE FDID = '31D04'
  AND CallGeoFDID = '31D04'
  AND StartDateTime BETWEEN @StartDateTime AND @EndDateTime;