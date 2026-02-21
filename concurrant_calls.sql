DROP PROCEDURE IF EXISTS concurrent_calucate;

DELIMITER //
CREATE PROCEDURE `concurrent_calucate`()
BEGIN
    -- Drop old results table if it exists
    DROP TABLE IF EXISTS gen_concurrent_events;

    -- Create results table by calculating concurrency within FDID = '31d04'
    CREATE TABLE gen_concurrent_events AS
    SELECT 
        a.CallID,
        COUNT(b.CallID) AS concurrent_count
    FROM data_2024 a
    JOIN data_2024 b
      ON a.StartDateTime <= b.ClearDateTime
     AND a.ClearDateTime >= b.StartDateTime
     AND b.FDID = '31d04'
    WHERE a.FDID = '31d04'
    GROUP BY a.CallID;
END//
DELIMITER ;

-- Run it
CALL concurrent_calucate();