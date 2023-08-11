

############    Data Analysis using Views and Stored procedures to find Sales insight  ##########

/* Problem-1: Generate a report for top market, top products, top customers by net sales for a given financial year.

Approach: Sales data has Gross sales, Pre invoice discount and Post invoice discount. So we will first create some views incorporate those calculations.
          Then, We will write stored procedure for top market, top products, top customers and generate results respectively. 
*/


############## Views #################

#### Pre invoice deduction calculations using CTEs

# Creating a View for Sales_preivoice_discount

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


-- Checking the above created sales_preivoice_discount view with normal sql query

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



# Now, Creating View for getting Net sales after deducting post invoice discount

create view sales_postinv_discount as
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



# Creating view for net sales

create view net_sales as
select *,
	(1-total_post_invoice_discount_pct)*net_invoice_sale as net_sales 
from sales_postinv_discount;


# Creating View for gross sales. Having following columns
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



###### Now we will find answers to our PROBLEM---------->


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


-- Checking the above created Stored procedure with normal SQL Query
SELECT
	market,
    round(sum(net_sales),2)/1000000 as market_sales_mln
from net_sales
where fiscal_year = 2021
group by market
order by market_sales_mln desc
limit 5; 




## Problem:1-(part-2): similarly creating a stored procedure for product:

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


-- Checking the result of above created Stored procedure with SQL query: 
select
		product,
		round(sum(net_sales)/1000000,2) as net_sales_mln
from net_sales
where fiscal_year = 2021
group by product
order by net_sales_mln desc
limit 3;




## Problem:1-(part-3) Now we will write stored procedure for customer:

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


-- calling the above stored procedure
call gdb0041.get_top_n_customer_net_sales('india', 2021, 3);


-- Checking the result of above created stored procedure with normal SQL Query
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





