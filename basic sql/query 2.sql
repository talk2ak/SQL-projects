select * from sales;

select * from people;

select s.saledate, s.Amount, p.spid, p.Salesperson
from sales as s 
join people as p on p.SPID = s.SPID;

select s.saledate, s.amount, s.pid, pr.pid
from sales s
left join products pr on pr.pid = s.pid;


select s.saledate, s.Amount,  p.Salesperson, s.saledate, s.amount, pr.Product, p.Team
from sales as s 
join people as p on p.SPID = s.SPID
join products pr on pr.pid = s.pid;

select s.saledate, s.Amount,  p.Salesperson, s.saledate, s.amount, pr.Product, p.Team
from sales as s 
join people as p on p.SPID = s.SPID
join products pr on pr.pid = s.pid
where s.Amount < 500 
and p.team = ''; 

select s.saledate, s.Amount,  p.Salesperson, s.saledate, s.amount, pr.Product, p.Team, g.Geo
from sales as s 
join people as p on p.SPID = s.SPID
join products pr on pr.pid = s.pid
join geo g on g.GeoID = s.GeoID
where s.Amount < 500 
and p.Team =''
and g.Geo in ('new zealand', 'India')
order by SaleDate;






