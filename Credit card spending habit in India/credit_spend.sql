use credit_db;

SELECT * FROM credit_in;

# Q1: Write a query to print top 5 cities with highest spends and their % contribution of total credit card spends ?

with cte1 as (
select distinct city, 
	sum(amount)	over(partition by city order by amount 
		desc rows between unbounded preceding and unbounded following) as SpentCityWise,
    sum(amount) over() as grand_total
from credit_in
order by SpentCityWise desc
limit 20)
select city, SpentCityWise, 
round( SpentCityWise / grand_total *100,2) as pct_citywise
from cte1;


# Q2: Write a query to print highest spend month and amount spent in that month for each card type ?

with cte1 as (
select 
	date_format(date, "%Y") as trans_year,
	date_format(date, "%b") as trans_month,
    card_type,
    sum(amount) as total_amt
from credit_in
group by date_format(date, "%Y"), date_format(date, "%b"), card_type),
cte2 as (
	select *,
    dense_rank() over(partition by card_type order by total_amt desc) as drnk
    from cte1)
select * from cte2 
where drnk =1 
order by trans_year;


# Q3: Write a query to print the transaction details for gold card type and expenditure type entertainment, when it reaches a cumulative of 10 lakh

with cte1 as (
select *,
	sum(amount) over(partition by card_type order by date) as cumm_sum
from credit_in),
cte2 as (
select *, 
	dense_rank() over(partition by card_type order by cumm_sum) as drnk
from cte1
where cumm_sum >= 1000000 )
select * from cte2
where drnk = 1 and exptype = 'entertainment' and card_type = 'gold';


# Q4: write a query to find city which had lowest percentage spend for gold card type.

with cte1 as (
select city, sum(amount) as gold_total
from credit_in
where card_Type = 'Gold'
group by city ),
cte2 as (
select city,
	sum(amount) as total_city_amount
from credit_in
group by city ),
cte3 as (
select c1.city, c1.gold_total, c2.total_city_amount,
	c1.gold_total /c2.total_city_amount * 100 as pct_contri
from cte1 c1
join cte2 c2 on c1.city = c2.city)
select * from cte3
order by pct_contri asc
limit 1; 


# Q5: Write a query to print 3 columns: city, highest_expense_type, lowest_expense_type 

with cte1 as (
select city, ExpType, sum(amount) as total_amount
from credit_in
group by city, ExpType),
cte2 as (
select city, 
	max(total_amount) as highest_amount_spent,
    min(total_amount) as lowest_amount_spent
from cte1
group by city )
select c1.city,
	max(case when total_amount = highest_amount_spent then exptype end) as highest_exp_type
	,min(case when total_amount = lowest_amount_spent then exptype end) as lowest_exp_type
from cte1 c1
join cte2 c2 on c1.city = c2.city
group by c1.city
order by c1.city;

-- check
SELECT city, ExpType, sum(amount) as s
FROM credit_db.credit_in
where city = 'delhi'
group by city, ExpType
order by 3 desc ;


# Q6: Write a query to find percentage contribution of spends by females for each expense type

with cte1 as (
select ExpType, sum(amount) as total_amount_female
from credit_in
where gender= 'F' 
group by ExpType),
cte2 as (
select ExpType, sum(amount) as total_amount
from credit_in
group by ExpType)
select c1.exptype,
	c1.total_amount_female / c2.total_amount * 100 as pct_female
from cte1 c1
join cte2 c2 on c1.exptype = c2.exptype
order by pct_female desc;


# Q7: Which card and expense type combination saw highest month over month growth in Jan 2024 ?

with cte1 as (
select card_type, exptype,
	date_format(date, '%Y') as trans_year,
	date_format(date, '%c') as trans_month,
    sum(amount) as total_amt
from credit_in
group by  card_type, exptype, trans_year, trans_month
-- order by trans_year, trans_month
),
cte2 as (
select *,
	lag(total_amt, 1) over (partition by card_type, exptype 
		order by trans_year, trans_month) as prev_month_amt
from cte1  )
select *,
   (total_amt - prev_month_amt ) / prev_month_amt *100 as growth_pct
from cte2
where trans_year = 2014 and trans_month = 1
order by growth_pct desc
limit 1;


# Q8: During weekend which city has highest total spend to total number of transactions ratio

select city,
	sum(amount) as total_amt,
    count(*) as total_no_of_transc,
    sum(amount) / count(*) as transc_ratio
from credit_in
where dayofweek(date) in (7,1)
group by city
order by transc_ratio desc
limit 2;


# Q9: Which city took least number of days to reach its 500th transaction after first transaction in that city

with cte1 as (
select city, 
	min(date) as tr_start_date,
    max(date) as tr_end_date,
    count(*) as total_trans
from credit_in
group by city),
cte2 as (select * from cte1 where total_trans >= 500),
cte3 as (
select city, date, row_number() over(partition by city order by date) as rn 
from credit_in
where city in (select city from cte2)),
cte4 as (select c2.city, tr_start_date, tr_end_date, total_trans,
	c3.date as transc_date_500th
from cte2 c2
join cte3 c3 on c2.city = c3.city
where c3.rn = 500)
select city,  tr_start_date, transc_date_500th, 
	datediff(transc_date_500th, tr_start_date) as no_of_days_to_reach_500th_transc
from cte4
order by no_of_days_to_reach_500th_transc
limit 1;
    
        
    
    
