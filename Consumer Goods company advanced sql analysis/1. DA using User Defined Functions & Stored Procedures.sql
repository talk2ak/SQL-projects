
 ########### Sales Data Analysis using User Defined Function and Stored Procedures  ############

/* 
Problem: There is a Consumer Goods company who has global presence. They want to analyse Sales data for thier Croma India customer (cust_code = 90002002),
	 on Fiscal year basis (Starts in September).

Approach: 
1. A User defined function is created to generate Fiscal Year based Sales report for Croma India. (on Month and Year basis )	 

2. A Stored Procedure is created to generate Fiscal Year based Sales report with customer code as parameter.

3. A Stored Procedure is created to generate Fiscal Year based Sales report report where Multiple customers can be parameter.
	  
 4. A Stored Procedure is created to generate Market Badge (Gold, Silver) having following logic,
	 If total sold quantity > 5 million that market is considered gold else silver.
*/

	 
############################## 1. USER DEFINED FUNCTION for Fiscal Year ################################


# Getting Record for Croma, India customer (Normal Query)
select distinct * 
from dim_customer
where customer like '%croma%' and market ='india';


# Creating a function to get fiscal year date (FY starts from September)

delimiter &&
create function get_fiscal_year(calender_date date) 		
    returns int											

deterministic		
begin 
	declare fiscal_year int;		
	set fiscal_year = year(date_add(calender_date, interval 4 month)); 
return fiscal_year;
end &&
delimiter ;



## Using get_fiscal_year user defined function to generate --> Month wise report for Croma India having following columns:
-- Date, Product code, Product, Variant, Sold Quantity, Gross Price and Total Gross Price

select 
	s.date, s.product_code, product, variant, s.sold_quantity, 
    g.gross_price,
    round(g.gross_price*s.sold_quantity,2) as gross_price_total
from fact_sales_monthly s
join dim_product p using(product_code)
join fact_gross_price g 
on g.product_code = s.product_code and g.fiscal_year = get_fiscal_year(s.date) 
where 
	customer_code = 90002002 and 
	get_fiscal_year(date) = 2021
order by date asc
limit 100;



### Using get_fiscal_year user defined function to generate --> Yearly sales report for Croma India where there are two columns:
-- 1. Fiscal Year
-- 2. Total Gross Sales amount In that year from Croma

select 
	get_fiscal_year(date) as fiscal_year_re,     			-- using fiscal year function to get fiscal year
	round(sum(g.gross_price*sold_quantity),2) as gross_price_total
from fact_sales_monthly s
join fact_gross_price g
on 
	g.product_code = s.product_code and
    g.fiscal_year = get_fiscal_year(s.date)   -- using fiscal year function as join condition
where customer_code = 90002002
group by fiscal_year_re
order by fiscal_year_re asc;





############################### 2. CREATING STORED PROCEDURES for a given customer on monthly basis  ##################################

## Writing a stored procedure for getting yearly gross sale for a given customer

delimiter $$
use gdb0041 $$
create procedure get_monthly_gross_sale_for_customer(
				in c_code int)							
begin
select 
	s.date, 
	round(sum(g.gross_price*sold_quantity), 2) as gross_price_total
from fact_sales_monthly s
join fact_gross_price g
on
	g.product_code = s.product_code and
    g.fiscal_year = get_fiscal_year(s.date)   
where customer_code = c_code			
group by s.date
order by s.date asc;

end $$
delimiter ;


-- calling the above stored procedure for croma india having customer_code= 90002002
call gdb0041.get_monthly_gross_sale_for_customer(90002002);





############################### 3. CREATING STORED PROCEDURES for a Multiple customer on monthly basis  ##################################

use gdb0041;
drop procedure if exists get_monthly_gross_sale_for_customer;


delimiter $$
use gdb0041 $$
create procedure get_monthly_gross_sale_for_customer(
				in in_customer_codes text)							
begin
select 
	s.date, 
	round(sum(g.gross_price*sold_quantity), 2) as gross_price_total
from fact_sales_monthly s
join fact_gross_price g
on
	g.product_code = s.product_code and
    g.fiscal_year = get_fiscal_year(s.date)   
where 				
	find_in_set(s.customer_code, in_customer_codes) > 0
group by s.date
order by s.date asc;

end $$
delimiter ;


-- lets call the above created Stored procedure for multiple customers
call get_monthly_gross_sale_for_customer('90002008,90002016');   





############################### 4. CREATING STORED PROCEDURES for Market Badge (Gold & Silver)  ##################################


# First lets write a select query to get total sold quantity for 2021 fiscal year and country india

select c.market,
	sum(sold_quantity) as total_qty
from fact_sales_monthly s 
join dim_customer c
	on s.customer_code = c.customer_code
where 
	get_fiscal_year(s.date) = 2021 and market = 'India'
group by c.market;



## Creating the stored procedure for Market Badge; Condition --> total sold quantity > 5 million that market is considered gold else silver 

delimiter &&
create procedure get_market_badge( 
			in in_market varchar(25),
            in in_fiscal_year year,
            out out_badge varchar(45)
            )
begin 
	declare qty int default 0;    
    
-- set default market to be india
	if in_market ='' then 
		set in_market = 'india';
	end if ;
    
-- retrieve total qty for a given market + financial year
	select 
		sum(sold_quantity) into qty			-- 
	from fact_sales_monthly s 
	join dim_customer c
		on s.customer_code = c.customer_code
	where 
		get_fiscal_year(s.date) = in_fiscal_year 
			and market = in_market
	group by c.market;

-- determine market badge
	if qty > 5000000 then 
		set out_badge = 'Gold';
	else
		set out_badge = 'Silver';
	end if;

end &&
delimiter ;

# calling the above created stored procedure
set @out_badge = 0;
call get_market_badge('india',2020,@out_badge);
select @out_badge;


=====================================================================================================================================

# Other useful Queries


# Writing a Quarter user defined function -
delimiter &&
create function get_fiscal_quarter( calender_date date)
returns char(2)     
deterministic
begin
	declare m tinyint;      		
    declare qtr char(2);
	set m = month(calender_date);	

	case
		when m in (9,10,11) then set qtr = "Q1";	
		when m in (12,1,2) then set qtr = "Q2";
		when m in (3,4,5) then set qtr = "Q3";
		else 
			set qtr = "Q4";
        
    end case ;				

return qtr;
end &&
delimiter ;

# Now using the above get_fiscal_quarter function as a condition to further refine search
select * 
from fact_sales_monthly
where customer_code = 90002002 and 
get_fiscal_year(date) = 2021 and get_fiscal_quarter(date) = "q4"
order by date desc;




