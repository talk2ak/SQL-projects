
select * from users;

select * from events;

select * from email_events;

-- Q:A- User Engagement: To measure the activeness of a user. Measuring if the user finds quality in a product/service.
-- 	Your task: Calculate the weekly user engagement?

select 
	concat(extract(week from occurred_at), ' - ', extract(year from occurred_at)) as week_no,
    count(distinct user_id) as weekely_active_users
from events
where event_type = 'engagement' and event_name = 'login'
group by 1;


select 
	extract(year from occurred_at) as year_no,
    extract(week from occurred_at) as week_no,
    count(distinct user_id) as weekely_active_users
from events
where event_type = 'engagement' and event_name = 'login'
group by 1,2;

-- Q:B- User Growth: Amount of users growing over time for a product.
-- 	Your task: Calculate the user growth for product?
--  user growth = number of active users per week

select
	year_no, week_no, users_active,
	sum(users_active) over(order by week_no rows between unbounded preceding and current row) 
    as cum_active_users
from
(select 
	extract(year from activated_at) as year_no, 
    extract(week from activated_at) as week_no,
    count(distinct user_id) as users_active
from users
where state = 'active'
group by 1,2
	) a 
order by 1   ;

-- you can use lag and lead function to calculate percentage grouth.

-- Q:C- Weekly Retention: Users getting retained weekly after signing-up for a product.
-- 	Your task: Calculate the weekly retention of users-sign up cohort?

select 	user_id, count(user_id),
    sum(case when retention_week = 1 then 1 else 0 end) as week_ret_F
from
(select 
	a.user_id, a.signup_week, b.engmnt_week,
    b.engmnt_week - a.signup_week as retention_week
from ((select 
	distinct user_id, 
    date(occurred_at) as signup_date,
	extract(week from occurred_at) as signup_week
from events
where event_type = 'signup_flow'
and event_name = 'complete_signup'
and extract(week from occurred_at) = 18
) a
left join ( select	distinct user_id, extract(week from occurred_at) as engmnt_week
    from events where event_type = 'engagement') b
on a.user_id = b.user_id ) 
order by 1,2,3
) c group by 1;


-- Q:D- Weekly Engagement: To measure the activeness of a user. Measuring if the user finds quality in a product/service weekly.
-- 	Your task: Calculate the weekly engagement per device?

select
	extract(year from occurred_at) as yearnum,
    extract(week from occurred_at) as weeknum,
    device,
    count(distinct user_id) as engagmnt_count
from events
where event_type ='engagement'
group by 1,2,3
order by 1,2,3
;

-- Q:E- Email Engagement: Users engaging with the email service.
--     Your task: Calculate the email engagement metrics?

SELECT distinct action FROM op_ana.email_events;

select 
	100*sum(case when email_cat = 'email_open' then 1 else 0 end ) / sum(case when email_cat = 'email_sent' then 1 else 0 end )
	as email_open_rate,
    100*sum(case when email_cat = 'email_clicked' then 1 else 0 end ) / sum(case when email_cat = 'email_sent' then 1 else 0 end )
	as email_clicked_rate
from
( select *,
	case 
		when action in ('sent_weekly_digest', 'sent_reengagement_email')
        then 'email_sent'
        when action in ('email_open')
        then 'email_open'
        when action in ('email_clickthrough')
        then 'email_clicked'
end as email_cat
from email_events ) a
;