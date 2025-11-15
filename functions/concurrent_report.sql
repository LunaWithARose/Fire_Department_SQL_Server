-- Answers the question: How many incidents concurrently with each other and at what frequency?
-- run whole statement for call count sum by geofdid. run internal statement for concurrent count type. 

select sum(piv.callcount) from 
(select concurrent_count, count(*) as callcount from 
gen_concurrent_events 
Group by concurrent_count
order by concurrent_count)
as piv


-- avg and standard dev for concurrent calls
select avg(ResponseTimeSecondsFirstArrivedUnit), std(ResponseTimeSecondsFirstArrivedUnit) from gen_calls where CallID in
(select distinct CallID from gen_concurrent_events where concurrent_count > 1)

-- avg and standard dev for NON concurrent calls
select avg(ResponseTimeSecondsFirstArrivedUnit), std(ResponseTimeSecondsFirstArrivedUnit) from gen_calls where CallID in
(select distinct CallID from gen_concurrent_events where concurrent_count = 1)


select floor(count(*) * .003) from gen_concurrent_events where concurrent_count = 1 -- how many events to offset for non concurrent   ans: 5

-- 99.7% slowest reponse time of NON CONCURRENT CALL
-- 1622 seconds for response time
select * from gen_calls where ResponseTimeSecondsFirstArrivedUnit is not null and CallID in
(select distinct CallID from gen_concurrent_events where concurrent_count = 1)
 ORDER BY ResponseTimeSecondsFirstArrivedUnit desc
 limit 1
 offset 5


select floor(count(*) * .5) from gen_concurrent_events where concurrent_count = 1 -- how many events to offset for non concurrent   ans: 859

-- 50% slowest reponse time of NON CONCURRENT CALL
-- 328 seconds for response time median
select * from gen_calls where ResponseTimeSecondsFirstArrivedUnit is not null and CallID in
(select distinct CallID from gen_concurrent_events where concurrent_count = 1)
 ORDER BY ResponseTimeSecondsFirstArrivedUnit desc
 limit 1
 offset 859



select floor(count(*) * .003) from gen_concurrent_events where concurrent_count > 1 -- how many events to offset for  concurrent   ans: 6

-- 99.7% slowest reponse time of  CONCURRENT CALL
-- 1712 seconds for response time
select * from gen_calls where ResponseTimeSecondsFirstArrivedUnit is not null and CallID in
(select distinct CallID from gen_concurrent_events where concurrent_count > 1)
 ORDER BY ResponseTimeSecondsFirstArrivedUnit desc
 limit 1
 offset 6
 
 select floor(count(*) * .5) from gen_concurrent_events where concurrent_count > 1 -- how many events to offset for  concurrent   ans: 1138

-- 50% slowest reponse time of  CONCURRENT CALL
-- 347 seconds for response time
select * from gen_calls where ResponseTimeSecondsFirstArrivedUnit is not null and CallID in
(select distinct CallID from gen_concurrent_events where concurrent_count > 1)
 ORDER BY ResponseTimeSecondsFirstArrivedUnit desc
 limit 1
 offset 1138


