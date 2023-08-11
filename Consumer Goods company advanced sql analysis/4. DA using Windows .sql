

######## Data Analysis using WINDOWS Function ####
 
/* Problem-1: Present Region Wise (APAC, EU, LTAM etc.) percentage net sales breakdown by customers in a respective region. for FY=2021.

Approach: Since we have to do region wise, row level calculation, we will use Windows function to calculate region wise % net sales.
	
*/

#  % net sales, region wise using windows function 

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



/* Problem: 2- Get top n products in each division by their sold quantity.

Approach: We will write stored procedure for getting top n products in each division by their quantity sold also using windows function. 
		we will analyse for three categories: 1.Division, 2.Product, 3.Total quantity 

*/

# Query to rank division wise total quantity
with cte1 as (
select p.division,
	p.product,
	sum(sold_quantity) as total_qty

from fact_sales_monthly s
join dim_product p using(product_code)
where fiscal_year =2021
group by p.product, p.division
),
cte2 as (select *, 
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



-- calling the above stored procedure for FY and Top n 
call gdb0041.get_top_n_product_per_division_by_qty_sold(2021, 6);

call gdb0041.get_top_n_product_per_division_by_qty_sold(2021, 3);



# Problem 3: Fetch the top 2 markets in every region by their gross sales amount in FY=2021. 

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









