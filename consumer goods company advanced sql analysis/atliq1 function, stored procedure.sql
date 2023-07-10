use gdb0041;

###### USER DEFINED FUNCTION ##########

/*  Problem: 1 -
As a product owner, I want to generate a report of individual product sales (aggregated on a monthly basis at the product code level) 
for Croma India customer for FY = 2021 so that I can track individual product sales.
The report should have the following fields
1. Month
2. Product name
3. Variant
4. Sold Quantity
5. Gross price per Item
6. Gross price Total 
*/

select distinct * 
from dim_customer
where customer like '%croma%' and market ='india'
;

-- Getting fiscal year calculation. 
select * 
from fact_sales_monthly
where customer_code = 90002002 and 
year(date_add(date, interval 4 month)) = 2021
order by date desc
;

# Now we will create a function to get fiscal year date
delimiter &&
create function get_fiscal_year(calender_date date) 		-- calender_date is the parameter which is input to the function
    returns int											-- after passing from function, value returned will be of integer datatype

deterministic		-- deterministic always returns same value for the given value, irrespective of time
begin 
	declare fiscal_year int;		-- declare is used to define the Variable in a function
	set fiscal_year = year(date_add(calender_date, interval 4 month));  -- assigning a value to the declare variable using set. SET is used to define variable
return fiscal_year;
end &&
delimiter ;

# Let us use above created function in our query
select * 
from fact_sales_monthly
where customer_code = 90002002 and 
get_fiscal_year(date) = 2021          -- here we used User defined function to get 2021 fiscal year
order by date asc;



# Additional Exercise: Writing Quarter function -
select month("2019-09-9");

delimiter &&
create function get_fiscal_quarter( calender_date date)
returns char(2)    -- return data type is Q1, Q2, etc so we used character datatype in return 
deterministic
begin
	declare m tinyint;      		-- Declared two variables "m" and "qtr"  
    declare qtr char(2);
	set m = month(calender_date);		-- setting value of m 

	case
		when m in (9,10,11) then set qtr = "Q1";		-- by using case statement developing relationship between the two variables
		when m in (12,1,2) then set qtr = "Q2";
		when m in (3,4,5) then set qtr = "Q3";
		else 
			set qtr = "Q4";
        
    end case ;					-- to end case statement we need to use "end case" clause  in function

return qtr;
end &&
delimiter ;

# Additional Exercise: Now using the above get_fiscal_quarter function as a condition to further refine search
select * 
from fact_sales_monthly
where customer_code = 90002002 and 
get_fiscal_year(date) = 2021 and get_fiscal_quarter(date) = "q4"
order by date desc;


# getting details from product table -- final query to find the solution of problem 1
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

/* Problem:2 -
As a product owner, I need an aggregate monthly sales report for croma india customer so that i can track how much sales this particular customer is generating for 
AtliQ and manage our relationship accordingly.
The report should have following fields:
1. Month
2. Total gross sales amount to croma india this month.

*/

select 
	s.date, 
	round(sum(g.gross_price*sold_quantity), 2) as gross_price_total
from fact_sales_monthly s
join fact_gross_price g
on
	g.product_code = s.product_code and
    g.fiscal_year = get_fiscal_year(s.date)   -- using fiscal year function in JOIN condition
where customer_code = 90002002				-- code for croma india
group by s.date
order by s.date asc;


# Similarly do this Exercise: Yearly Sales Report --> Generate a yearly report for Croma India where there are two columns:
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



############################### STORED PROCEDURES ##################################

-- Writing a stored procedure for getting monthly gross sale for a given customer

delimiter $$
use gdb0041 $$
create procedure get_monthly_gross_sale_for_customer(
				in c_code int)								-- creating a c_code parameter
begin
select 
	s.date, 
	round(sum(g.gross_price*sold_quantity), 2) as gross_price_total
from fact_sales_monthly s
join fact_gross_price g
on
	g.product_code = s.product_code and
    g.fiscal_year = get_fiscal_year(s.date)   
where customer_code = c_code				-- using c_code paramerter for different customers
group by s.date
order by s.date asc;

end $$
delimiter ;

-- calling the above stored procedure for croma india having customer_code= 90002002
call gdb0041.get_monthly_gross_sale_for_customer(90002002);


-- Now, we can extract any data for a given customer code 
select distinct customer_code, customer 
from dim_customer;

select *
from dim_customer
where customer like '%amazon%' and market = 'india';

/* now we have two customer code for the same customer(amazon), and this happens usually in industry. to tackle this problem we have to change our stored procedure 
parameter in such a way that it takes the value in text format. Also we need to use a function "FIND_IN_SET", which will tell that which all texts to be searched for 
finding the customer code.

*/

-- FIND_IN_SET Function -> it returns the position of the text in a set
select find_in_set(200, "300,100,400,250,560,200");

select find_in_set(250, "300,100,400,250,560,200");

-- now lets create the stored procedure- which can take multiple customer codes
use gdb0041;
drop procedure if exists get_monthly_gross_sale_for_customer;


delimiter $$
use gdb0041 $$
create procedure get_monthly_gross_sale_for_customer(
				in in_customer_codes text)								-- we are using text datatype to pass string of customer codes
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

-- lets call the above created procedure for multiple customer codes like in the case of amazon.
-- two important points here to remember
-- 1. since it is text everything should be in inverted comma
-- 2. string of values should be comma separated only i.e., without any space

call get_monthly_gross_sale_for_customer('90002008,90002016');   



/* Problem: 3-
Create a stored procedure that can determine the market badge based on following logic,
If total sold quantity > 5 million that market is considered gold else silver
My input -> 1. Market, 2. fiscal year
Output-> market badge

*/

-- First lets write a select query to get total sold quantity for 2021 fiscal year and country india
select c.market,
	sum(sold_quantity) as total_qty
from fact_sales_monthly s 
join dim_customer c
on 
	s.customer_code = c.customer_code
where get_fiscal_year(s.date) = 2021 
group by c.market;


select 
	sum(sold_quantity) as total_qty
from fact_sales_monthly s 
join dim_customer c
	on s.customer_code = c.customer_code
where 
	get_fiscal_year(s.date) = 2021 and market = 'India'
group by c.market;

# Now creating the stored procedure 

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





