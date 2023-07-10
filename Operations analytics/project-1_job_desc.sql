
-- Q:A- Number of jobs reviewed: Amount of jobs reviewed over time.
-- 		Your task: Calculate the number of jobs reviewed per hour per day for November 2020?

select sum(hours_spent)/sum(jobs_per_day) as jobs_reviewed_per_hour_per_day
from
(select count(job_id) as jobs_per_day, sum(time_spent/3600) as hours_spent
from table1
where ds between '2020-11-1' and '2020-11-30'
group by ds) a;

-- Q:B- Throughput: It is the no. of events happening per second.
-- Your task: Let’s say the above metric is called throughput. Calculate 7 day rolling average of throughput? For throughput, do you prefer daily metric or 7-day rolling and why?

select ds, num_rev,
    sum(num_rev) over (partition by ds order by ds rows between 6 preceding and current row) / sum(total_time) 
    over (partition by ds order by ds rows between 6 preceding and current row) as thoughput_7day
from (select ds, 
	count(job_id) as num_rev,
    sum(time_spent) as total_time    
from table1
group by ds ) ab;

-- Q:C-Percentage share of each language: Share of each language for different contents.
-- Your task: Calculate the percentage share of each language in the last 30 days?

select lang,
sum(count(lang)) over (partition by lang order by lang rows between unbounded preceding and unbounded following) 
as lang_occ,
sum(count(lang)) over () as lang_tot,
(100*sum(count(lang)) over (partition by lang order by lang rows between unbounded preceding and unbounded following) / sum(count(lang)) 
over () )as percentage 

from table1
group by lang;

select lang,
 	lang_tot,
    lang_tot_sum,
  round(100*lang_tot/lang_tot_sum,2) as percentage
     
 from ( select lang, count(lang) as lang_tot 	
	from table1 group by lang) a

 cross join ( select sum(lang_tot) as lang_tot_sum  	
    from (select count(lang) as lang_tot 
				from table1
                group by lang ) b 
                 ) c ;


-- Q:D-Duplicate rows: Rows that have the same value present in them.
-- Your task: Let’s say you see some duplicate rows in the data. How will you display duplicates from the table?

SELECT job_id, COUNT(*)
FROM table1
GROUP BY job_id
HAVING COUNT(*) > 1;


select *, rownum 
from (
	SELECT *, 
	ROW_NUMBER() OVER (partition by job_id order by job_id) AS rownum 
	FROM table1) a
where rownum > 1;






