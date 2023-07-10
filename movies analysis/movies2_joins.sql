-- JOINS
-- By default Join is Inner join. 
-- using table abbreviations simplifies the task
-- JOIN, ON & AND clause will enable you to perform joins based on multiple coulumns.
 use moviesdb;
 
select m.movie_id, m.title, budget, revenue, currency, unit
from movies m
join financials f
on m.movie_id = f.movie_id;

-- LEFT JOIN
select m.movie_id, m.title, budget, revenue, currency, unit
from movies m
left join financials f
on m.movie_id = f.movie_id;

-- RIGHT JOIN
select f.movie_id, m.title, budget, revenue, currency, unit
from movies m
right join financials f
on m.movie_id = f.movie_id;

-- FULL JOIN is not available in MySQL --> you need to use UNION statement on LEFT and RIGHT JOIN to perform that task.
-- UNION --> only unique records are shown
-- UNION ALL --> It will return all the records including duplicates 
select m.movie_id, m.title, budget, revenue, currency, unit
from movies m
left join financials f
on m.movie_id = f.movie_id

union

select f.movie_id, m.title, budget, revenue, currency, unit
from movies m
right join financials f
on m.movie_id = f.movie_id ;


-- 1. Show all the movies with their language names
-- use USING clause if the column name in both the joining table is same 
select * 
from movies m
join languages l
using (language_id) ;

select m.movie_id, title, name as language
from movies m
left join languages l
on m.language_id = l.language_id ;

-- 2. Show all Telugu movie names (assuming you don't know the language id for Telugu)
select *
from movies m
join languages l
using (language_id) 
where name ='telugu';

-- 3. Show the language and number of movies released in that language
select name as language, count(*) as movie_count
from movies
join languages
using (language_id)
group by name
order by movie_count desc;


-- CROSS JOIN --> 
select *, 
	concat_ws(' - ', name, variant_name) as full_name,
    (price+variant_price) as full_price
from food_db.items
cross join food_db.variants;


-- analytics using join
select m.movie_id, title, budget, revenue, currency, unit,
	case 
		when unit='thousands' then round((revenue-budget)/1000,2) 
		when unit='billions' then round((revenue-budget)*1000,2) 
		else round((revenue-budget),2)
    end as profit_mln
from movies m
join financials f using (movie_id)  
where industry = 'bollywood'
order by profit_mln desc;

-- joining multiple tables
select m.title, group_concat(name separator " | ") as full_name
from movies m
join movie_actor ma on m.movie_id = ma.movie_id
join actors a on ma.actor_id = a.actor_id
group by m.title;


-- GROUP_CONCAT function list actors and movies in which they worked
select a.name, 
	group_concat(title separator " | ") as full_name,
    count(m.title) as movie_count
from actors a
join movie_actor ma on a.actor_id = ma.actor_id
join movies m on m.movie_id = ma.movie_id
group by a.name
order by movie_count desc;

-- 1. Generate a report of all Hindi movies sorted by their revenue amount in millions. Print movie name, revenue, currency, and unit.
select title, currency, unit, 
	 if(unit='billions', revenue*1000, revenue) as revenue_ml
from movies m	
join financials f using (movie_id)
join languages l using (language_id)
where name ='hindi'
order by revenue_ml desc;














