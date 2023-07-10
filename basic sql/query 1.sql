SELECT * FROM sales;

select SaleDate, Amount, Customers, Boxes from sales;

select SaleDate, Amount, Boxes, Amount/Boxes from sales;

select SaleDate, Amount, Boxes, Amount/Boxes as 'Amnt per box' from sales;

select * from sales
where Amount> 10000;

select * from sales
where Amount > 10000
order by Amount desc;

select * from sales
where GeoID= 'g1'
order by PID, Amount desc ;

select * from sales
where amount > 10000 and SaleDate >= '2022-01-01';

select SaleDate, Amount from sales
where Amount > 10000 and year(saledate) = 2022
order by amount desc;

select * from sales 
where Boxes > 0 and Boxes<= 50;

select * from sales 
where boxes between 0 to 50;

select SaleDate, amount, Boxes, weekday(SaleDate) as 'Day of week'  from sales
where weekday(Saledate)=4;

select * from people;

select * from people
where team = 'delish' or team = 'jucies';

select * from people
where location in ('hyderabad', 'paris', 'seattle');

select * from people
where salesperson like 'b%';

select * from people
where salesperson like '%b%';

select * from sales; 

select SaleDate, Amount,
		case 	when amount < 1000 then 'Under 1k'
				when amount < 2000 then 'Under 2k'
                when amount <= 5000 then 'Under 5k'
                else 'more than 5k'
		end as 'amount categories'
        from sales; 
        



