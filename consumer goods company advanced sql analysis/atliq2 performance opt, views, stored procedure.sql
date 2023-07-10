
################ Performance Optimisation  ###############
-- explain analyze
select 
	s.date, s.product_code, product, variant, s.sold_quantity, 
    g.gross_price,
    round(g.gross_price*s.sold_quantity,2) as gross_price_total,
    pre.pre_invoice_discount_pct
from fact_sales_monthly s
join dim_product p using(product_code)
join fact_gross_price g 
	on g.product_code = s.product_code and g.fiscal_year = get_fiscal_year(s.date) 
join fact_pre_invoice_deductions pre
	on pre.customer_code = s.customer_code and pre.fiscal_year = get_fiscal_year(s.date)
where 
	s.customer_code =90002002 and 
	get_fiscal_year(date) = 2021
order by date asc
limit 100;

# Creating a date table
CREATE TABLE `gdb0041`.`dim_date` (
  `calender_date` DATE NOT NULL,
  `fiscal_year` YEAR GENERATED ALWAYS AS (year(date_add(calender_date, interval 4 month))) VIRTUAL,
  PRIMARY KEY (`calender_date`));

-- then inserting records from dim_date_seed.csv file
-- Also changing the above query by joining dim_date table and getting ride of get_fiscal_year function

explain analyze
select 
	s.date, s.product_code, product, variant, s.sold_quantity, 
    g.gross_price,
    round(g.gross_price*s.sold_quantity,2) as gross_price_total,
    pre.pre_invoice_discount_pct
from fact_sales_monthly s
join dim_product p using(product_code)
join dim_date dt
	on dt.calender_date = s.date
join fact_gross_price g 
	on g.product_code = s.product_code and g.fiscal_year = dt.fiscal_year 
join fact_pre_invoice_deductions pre
	on pre.customer_code = s.customer_code and pre.fiscal_year = dt.fiscal_year
where 
	s.customer_code =90002002 and 
	dt.fiscal_year = 2021
order by date asc
limit 100;


-- Altering fact_sales_monthly table to insert a generatd column fiscal_yar
ALTER TABLE `gdb0041`.`fact_sales_monthly` 
ADD COLUMN `fiscal_year` YEAR GENERATED ALWAYS AS (year(date_add(date, interval 4 month))) 
	VIRTUAL AFTER `sold_quantity`, RENAME TO  `gdb0041`.`  fact_sales_monthly` ;

select * from fact_sales_monthly
limit 100;

-- Now we will modify the main query in order to incorporate the changes made to fiscal_year table
-- 1. removing join of dim_date table and using fiscal_year column of fact_sales_monthly table
-- All the queries produce same result but below is faster than the other two, because it contain less joins and no user defined functions 

select 
	s.date, s.product_code, product, variant, s.sold_quantity, 
    g.gross_price,
    round(g.gross_price*s.sold_quantity,2) as gross_price_total,
    pre.pre_invoice_discount_pct
from fact_sales_monthly s
join dim_product p using(product_code)
join fact_gross_price g 
	on g.product_code = s.product_code and g.fiscal_year = s.fiscal_year 
join fact_pre_invoice_deductions pre
	on pre.customer_code = s.customer_code and pre.fiscal_year = s.fiscal_year
where 
	s.customer_code =90002002 and 
	s.fiscal_year = 2021
order by date asc
limit 100;


/* Problem: 1-
As a product owner, i want a report for top market, products, customers by net sales for a given financial year so that i can have a holistic view of our financial 
performance and can take appropriate action to address any potential issue.
we will probably wite stored procedure for this report going forward as well.
1. report for top market
2. report for top products,
3. report for top customers

*/

############## Views #################
-- now we have to add some calculated column for pre invoice deduction, for that we will use cte, but if we want other conditions further then it is better to use views 

with cte1 as (
select 
	s.date, s.product_code, product, variant, s.sold_quantity, 
    g.gross_price,
    round(g.gross_price*s.sold_quantity,2) as gross_price_total,
    pre.pre_invoice_discount_pct
from fact_sales_monthly s
join dim_product p using(product_code)
join fact_gross_price g 
	on g.product_code = s.product_code and g.fiscal_year = s.fiscal_year 
join fact_pre_invoice_deductions pre
	on pre.customer_code = s.customer_code and pre.fiscal_year = s.fiscal_year
where 
	s.customer_code =90002002 and 
	s.fiscal_year = 2021
order by date asc)

select *,
	(gross_price_total - (gross_price_total*pre_invoice_discount_pct)) as net_invoice_sale
from cte1; 


### creating a view
-- from above query, removing where condition and joining dim_ccustomer table

create view sales_preinvoice_discount as 
select 
	s.date, s.fiscal_year,
    c.market, s.product_code, 
    p.product, p.variant, 
    s.sold_quantity, g.gross_price,
    round(g.gross_price*s.sold_quantity,2) as gross_price_total,
    pre.pre_invoice_discount_pct
from fact_sales_monthly s
join dim_product p 
	using(product_code)
join dim_customer c
	on s.customer_code =c.customer_code
join fact_gross_price g 
	on g.product_code = s.product_code 
		and g.fiscal_year = s.fiscal_year
join fact_pre_invoice_deductions pre
	on pre.customer_code = s.customer_code 
		and pre.fiscal_year = s.fiscal_year;

-- now using the above created view
select *,
	(gross_price_total - (gross_price_total*pre_invoice_discount_pct)) as net_invoice_sale	
from sales_preinvoice_discount
limit 100;

-- now getting Net sales after deducting post invoice discount
-- and then creating a view out of that

-- create view sales_postinv_discount as
select spd.date, spd.fiscal_year, spd.customer_code, spd.market,
    spd.product_code, spd.product, 
    spd.variant, 
    spd.sold_quantity, 
    spd.gross_price,
    spd.gross_price_total,
    spd.pre_invoice_discount_pct,
	((1 - pre_invoice_discount_pct)*spd.gross_price_total) as net_invoice_sale,
	(po.discounts_pct + po.other_deductions_pct) as total_post_invoice_discount_pct
from sales_preinvoice_discount as spd
join fact_post_invoice_deductions po
	on spd.date = po.date and 
    spd.product_code = po.product_code and
    spd.customer_code = po.customer_code;

-- then again creating view for net sales 
-- create view net_sales as
select *,
	(1-total_post_invoice_discount_pct)*net_invoice_sale as net_sales 
from sales_postinv_discount;


-- Additional Exercise: Create a view for gross sales. It should have the following columns
-- date, fiscal_year, customer_code, customer, market, product_code, product, variant, sold_quantity, gross_price_per item, gross_price_total

create view gross_sales as 
select 
	s.date, s.fiscal_year, s.customer_code, 
    c.customer, c.market, 
    p.product_code, p.product, p.variant, 
    s.sold_quantity, 
    g.gross_price as gross_price_per_item, 
    round(s.sold_quantity*g.gross_price, 2) as gross_price_total
from fact_sales_monthly s
join dim_product p
	on p.product_code = s.product_code
join dim_customer c
	on s.customer_code = c.customer_code
join fact_gross_price g
	on g.fiscal_year = s.fiscal_year
    and g.product_code = s.product_code;

###### Now we will find answers to our PROBLEM NO. 1 ---------->

/* Problem: 1-
As a product owner, i want a report for top market, products, customers by net sales for a given financial year so that i can have a holistic view of our financial 
performance and can take appropriate action to address any potential issue.
we will probably wite stored procedure for this report going forward as well.
1. report for top market
2. report for top products
3. report for top customers

*/

SELECT
	market,
    round(sum(net_sales),2)/1000000 as market_sales_mln
from net_sales
where fiscal_year = 2021
group by market
order by market_sales_mln desc
limit 5; 


## Problem:1-(part-1) Now write stored procedure for market:

delimiter &&
create procedure get_top_n_markets_by_net_sales(
	in in_fiscal_year int,
    in in_top_n int
    )

begin
	SELECT
		market,
		round(sum(net_sales),2)/1000000 as market_sales_mln
	from net_sales
	where fiscal_year = in_fiscal_year
	group by market
	order by market_sales_mln desc
	limit in_top_n; 

end &&

delimiter ;

-- calling the above created stored procedure
call gdb0041.get_top_n_markets_by_net_sales(2020, 10);

## Problem:1-(part-3) Now we will write stored procedure for customer but understand the query first:
SELECT
	c.customer,
    round(sum(net_sales),2)/1000000 as market_sales_mln
from net_sales n
join dim_customer c
	on n.customer_code = c.customer_code
where fiscal_year = 2021
group by c.customer
order by market_sales_mln desc
limit 5; 

-- now we will create a stored procedure

delimiter &&
create procedure get_top_n_customer_net_sales(
	in in_market varchar(45),
    in in_fiscal_year int,
    in in_top_n int
		)
begin
SELECT
	c.customer,
    round(sum(net_sales),2)/1000000 as market_sales_mln
from net_sales n
join dim_customer c
	on n.customer_code = c.customer_code
where fiscal_year = in_fiscal_year and n.market = in_market
group by c.customer
order by market_sales_mln desc
limit in_top_n; 


end &&
delimiter ;

drop procedure if exists get_top_n_custmer_net_sales;

-- calling the above stored procedure
call gdb0041.get_top_n_customer_net_sales('india', 2021, 3);

## Problem:1-(part-2): similarly creating a stored procedure for product:

 select
		product,
		round(sum(net_sales)/1000000,2) as net_sales_mln
from net_sales
where fiscal_year = 2021
group by product
order by net_sales_mln desc
limit 3;

delimiter &&
CREATE PROCEDURE get_top_n_products_by_net_sales(
              in_fiscal_year int,
              in_top_n int
	)
BEGIN
	select
		product,
		round(sum(net_sales)/1000000,2) as net_sales_mln
	from gdb0041.net_sales
	where fiscal_year=in_fiscal_year
	group by product
	order by net_sales_mln desc
	limit in_top_n;
END &&
delimiter ;

-- calling the above created stored procedure
call get_top_n_products_by_net_sales('2020',4)



















 



