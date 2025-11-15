
-- CALL `d4schema`.`concurrent_calucate`();

select * from gen_concurrent_events
where concurrent_count = 15


select * from dispatched_units
where CallID = 7835105

-- looking at all the calls in January. This is a spot check to manually verify the concurrency for CallID 7828076 which has a concurrency of 5. the call directly after is grouped by callid in the script
select CallID, StartDatetime, ClearDateTime from dispatched_units 
where StartDateMonth = 'November' and CallGEOFDID = '31D04'
Order by StartDatetime

select cur_id as CallID, count(*) as concurrent_count from call_view as compare where 
 (cur_start_timestamp >= compare.StartDateTime and cur_start_timestamp <= compare.ClearDatetime) -- when current event starts between others
 OR (compare.StartDateTime >= cur_start_timestamp and compare.StartDateTime <= cur_end_timestamp); -- when others start between