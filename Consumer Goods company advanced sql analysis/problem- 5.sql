use random_tables;

select * from expenses
order by category;

select sum(amount) from expenses; 		-- 65800

# here our task is to show a percentage row for every row. without group by
select category,
	sum(amount)
		-- amount*100/sum(amount) as pct
from expenses
group by category;	


select *,
	sum(amount)
		-- , amount*100/sum(amount) as pct
from expenses
order by amount; -- here aggregation will not work, since amount table is also aggregatd and it has only two values common (2700)


######## To solve this issue we need to use WINDOWS Function #### over() clause
select *,
		amount*100/sum(amount) over() as pct 	
from expenses
order by category;


# partition by - creates small group by category
select *,
		amount*100/sum(amount) over(partition by category) as pct  
from expenses
order by category;

# For cummulative expenses-- we will use 
select *, 
	 sum(amount) over(partition by category order by date ) as cummulative_sum
from expenses 
order by category, date;

/* Problem no: 5 
As a product owner, i want to see bar chart report for FY =2021 for top 10 market by % net sales. 
*/ 

with cte1 as(
SELECT
	c.customer,
    round(sum(net_sales),2)/1000000 as market_sales_mln
from net_sales n
join dim_customer c
	on n.customer_code = c.customer_code
where fiscal_year = 2021
group by c.customer
)
select *,
	market_sales_mln*100 / sum(market_sales_mln) over() as pct_net_sales
from cte1
order by market_sales_mln desc
limit 10; 

/* Problem: 6 - Atliq hardware
As a product owner, I want to see region wise (APAC, EU, LTAM etc) % net sales breakdown by customers in a respective region so that i can perform my regional 
analysis on financial performance of the company. 
the end result should be bar charts in the following format FY = 2021. Build a reuasable asset that we can use to conduct this analysis for any financial 
year 

*/

with cte1 as(
select
	c.customer,
    c.region,
    round(sum(net_sales),2)/1000000 as market_sales_mln
from net_sales n
join dim_customer c
	on n.customer_code = c.customer_code
where fiscal_year = 2021
group by c.customer, c.region
)
select *,
	market_sales_mln*100 / sum(market_sales_mln) over(partition by region) as pct_share_region
from cte1
order by region, pct_share_region desc;



## show two top expenses in each category (random_tables.expenses) 
use random_tables;

select *,
	row_number() over(partition by category order by amount) as rn
from expenses
order by category;

with cte1 as (
select *,
	row_number() over(partition by category order by amount desc) as rn   -- desc in order by clause added
from expenses
order by category)
select * from cte1 where rn<=2; 

-- row_number is not working well because we should see shravana bhavan in food category as second result So, we will use rank()

with cte1 as (
select *,
	row_number() over(partition by category order by amount desc) as rn,
	rank() over(partition by category order by amount desc) as rk   
    
from expenses
order by category)
select * from cte1 where rk<=2; 

# Difference between row_number and rank
select *,
	row_number() over(partition by category order by amount desc) as rn,
	rank() over(partition by category order by amount desc) as rk   
from expenses
order by category;


# if you want true rank then you need to use dense_rank. Difference between row_number, rank and dense_rank
select *,
	row_number() over(partition by category order by amount desc) as rn,
	rank() over(partition by category order by amount desc) as rk,   
	dense_rank() over(partition by category order by amount desc) as drk   
    
from expenses
order by category;


# similarly in student_marks table we will analyse the difference
select *,
	row_number() over(order by marks desc) as rn,
	rank() over(order by marks desc) as rk,   
	dense_rank() over(order by marks desc) as drk   
    
from student_marks
order by drk;

######## (Atliq hardware) 
/* Problem: 2- 
Get top n products in each division by their sold quantity
Write a stored procedure for getting top n products in each division by their quantity sold in a given financial year. For example below would be the result 
for FY = 2021. 
1.Division 
2.Product and 
3.Total quantity 

*/

with cte1 as (
select p.division,
	p.product,
	sum(sold_quantity) as total_qty

from fact_sales_monthly s
join dim_product p using(product_code)
where fiscal_year =2021
group by p.product, p.division
),

	cte2 as (
			select *, 
			dense_rank() over(partition by division order by total_qty desc) as drnk
		from cte1)

select * from cte2 where drnk<=3
;

# Now we will create stored procedure for above query

delimiter &&
create procedure get_top_n_product_per_division_by_qty_sold(
		in_fiscal_year int,
        in_top_n int
    )

begin

with cte1 as (
	select p.division,
	p.product,
	sum(sold_quantity) as total_qty

	from fact_sales_monthly s
	join dim_product p using(product_code)
	where fiscal_year = in_fiscal_year
	group by p.product, p.division
),

cte2 as (
		select *, 
			dense_rank() over(partition by division order by total_qty desc) as drnk
		from cte1
        )

select * from cte2 where drnk <= in_top_n
;

end &&
delimiter ;

-- calling the above stored procedure
call gdb0041.get_top_n_product_per_division_by_qty_sold(2021, 6);

call gdb0041.get_top_n_product_per_division_by_qty_sold(2021, 3);


### Additional problem: Retrieve the top 2 markets in every region by their gross sales amount in FY=2021. 

with cte1 as (
select 
	c.market,
    c.region,
	sum(g.gross_price* s.sold_quantity) as gross_price1
from dim_customer c
join fact_sales_monthly s using (customer_code)
join fact_gross_price g using (product_code)
group by market, region)
,
cte2 as (
select market, region,
	gross_price1/1000000,
    dense_rank() over(partition by region order by gross_price1 desc) as dsrnk
    from cte1)

select * from cte2 where dsrnk <= 2
;









