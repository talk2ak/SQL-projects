select geoID, sum(amount), avg(Amount), sum(Boxes)
from sales
group by GeoID
order by GeoID;

select g.Geo, sum(amount), avg(Amount), sum(Boxes)
from sales s 
join geo g on s.GeoID = g.GeoID
group by g.Geo
order by g.Geo;

select pr.category, p.Team, sum(Boxes), sum(Amount)
from sales s 
join people p on p.spid = s.spid
join products pr on pr.PID = s.PID
where p.team <> ''
group by pr.category, p.team
order by pr.category, p.team;

select pr.product, sum(s.amount) as 'Total Amount'
from sales s 
join products pr on pr.pid = s.pid
group by pr.Product
order by 'Total Amount' desc
limit 10;







 