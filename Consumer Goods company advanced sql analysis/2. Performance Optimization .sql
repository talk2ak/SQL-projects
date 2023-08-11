

################ Performance Optimisation  ###############

explain analyze
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


-- Altering fact_sales_monthly table to insert a generatd column fiscal_year

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










 



