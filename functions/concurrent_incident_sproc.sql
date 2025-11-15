DROP PROCEDURE IF EXISTS concurrent_calucate;

DELIMITER //
CREATE PROCEDURE `concurrent_calucate`()
BEGIN

    -- setting up variables, temporary table, and cursor for looping purposes
	DECLARE done INT DEFAULT FALSE;
	declare cur_id varchar(32);
	declare cur_start_timestamp datetime;
	declare cur_end_timestamp datetime;
	DECLARE ordered_events_cur CURSOR FOR SELECT CallID, StartDateTime, TruncatedClearDatetime FROM gen_calls order by StartDateTime desc;
	DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
    DROP TABLE if exists gen_concurrent_events;
    CREATE TABLE gen_concurrent_events(
    CallID varchar(32) primary key,
    concurrent_count INT
    );

  OPEN ordered_events_cur;

  read_loop: LOOP -- loop through every event in the table
  
	-- the values for the current event are stored in the cur_ variables
    FETCH ordered_events_cur INTO cur_id, cur_start_timestamp, cur_end_timestamp;
      IF done THEN
      LEAVE read_loop;
    END IF;
    
    -- for each event, compute the concurrent events
 INSERT INTO gen_concurrent_events
select cur_id as CallID, count(*) as concurrent_count from gen_calls as compare where 
 (cur_start_timestamp >= compare.StartDateTime and cur_start_timestamp <= compare.TruncatedClearDatetime) -- when current event starts between others
 OR (compare.StartDateTime >= cur_start_timestamp and compare.StartDateTime <= cur_end_timestamp); -- when others start between this event
    
  END LOOP;
  
  CLOSE ordered_events_cur;
  
END//
DELIMITER ;

call concurrent_calucate();


-- select concurrent_output.concurrent_count, count(*) / concurrent_output.concurrent_count from 
-- (SELECT inc_id, min(start_timestamp), max(end_timestamp) FROM practice.concurrent_events group by inc_id)
-- as concurrent_output group by concurrent_output.concurrent_count