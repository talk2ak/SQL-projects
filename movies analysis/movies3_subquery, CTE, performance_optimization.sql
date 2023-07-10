# select a movie with highest imdb rating
select * from movies
where imdb_rating = (select max(imdb_rating) from movies);  

# subquery can return a single value, list of values or a table
-- find actors age between 70 to 85
select * from 
	( select name, year(curdate())-birth_year as age
		from actors) as actors_age
where age > 70 and age < 85;

# select actors who acted in any of these movies with actor code 101, 110, 121
select * 
from actors 
where actor_id in (
	select actor_id from movie_actor 
	where movie_id in (101, 110, 121)); 

# with ANY operator
select * 
from actors 
where actor_id = any (
	select actor_id from movie_actor 
	where movie_id in (101, 110, 121)); 

# select all movies whose rating is greater than *ANY* of the marvel movies rating
select * from movies where imdb_rating = any (
select distinct imdb_rating from movies
where studio = 'marvel studios');

select distinct imdb_rating from movies
where studio = 'marvel studios';


-- or above query can be written as 
select * from movies 
where imdb_rating > (
	select imdb_rating from movies
	where studio = 'marvel studios'); 
    


-- select actor_id and total number of movies they acted in 
select a.actor_id, name, count(*) as movie_count
from movie_actor ma
join actors a using (actor_id)
group by actor_id
order by movie_count desc;



-- we can do above query by using subquery statement. 
-- --> and this particular query is called CORRELATED QUERY. Because the execution of it depends on other table. 
select actor_id, 
		name, 
    (select count(*) 
		from movie_actor 
		where actor_id = actors.actor_id ) as movie_count
from actors
order by movie_count desc;

-- use EXPLAIN ANALYZE to when you are writing complex query use explain analyze to do performance analysis. 
explain	 analyze
select actor_id, 
		name, 
    (select count(*) 
		from movie_actor 
		where actor_id = actors.actor_id ) as movie_count
from actors
order by movie_count desc;

explain analyze
select a.actor_id, name, count(*) as movie_count
from movie_actor ma
join actors a using (actor_id)
group by actor_id
order by movie_count desc;
-- in above case group by worked best

# 1. Select all the movies with minimum and maximum release_year. Note that there can be more than one movie in min and a max year hence output rows can be more than 2.
select * from movies 
where release_year in (
	(select min(release_year) min from movies),
    (select max(release_year) max from movies));

  
# 2. Select all the rows from the movies table whose imdb_rating is higher than the average rating.
select * from movies 
where imdb_rating > (
	(select avg(imdb_rating) min from movies));

-- COMMON TABLE EXPRESSION (CTE)
# get all actors whose age is between 70 and 85
select actor_name, age
from (
		select name as actor_name,
			year(curdate()) - birth_year as age 
		from actors) as actors_age
	where age > 70 and age < 85;

-- same query can be written with CTE. with actors_age as an identifier
with actors_age as (
	select name as actor_name,
		year(curdate()) - birth_year as age
	from actors)

select actor_name, age
from actors_age
where age > 70 and age < 85;

--  you can also specify column names in with clause
with actors_age (actor_name, age) as (
	select name as x,
		year(curdate()) - birth_year as y
	from actors)

select actor_name, age
from actors_age
where age > 70 and age < 85;

# Movies that produced 500% profit and their rating was less than avg rating for all movies
select x.movie_id, x.pct_profit,
		y.title, y.imdb_rating
from (
	select *, (revenue-budget)*100/budget as pct_profit
    from financials) x
join (
	select * from movies
    where imdb_rating < (select avg(imdb_rating) from movies)) y
using (movie_id)
where pct_profit >=500;

-- Now solving above query using CTEs
with
x as 
	(select *, (revenue-budget)*100/budget as pct_profit from financials),
y as 
(select * from movies
    where imdb_rating < (select avg(imdb_rating) from movies))

select x.movie_id, x.pct_profit,
		y.title, y.imdb_rating
from x
join y using (movie_id) 
where pct_profit >=500;


# select all hollywood movies released after the year 2000 that made more than 500 million $ profit or more profit.
with 
x as 
	(select * from movies where release_year>2000),
y as 
    ( select *, (revenue-budget) as profit from financials )
    
select x.movie_id, title, release_year, profit
from x
join y using (movie_id)
where profit >= 500
order by profit desc
-- limit 5,1 
;   

(SELECT name, birth_year 
FROM actors 
ORDER BY birth_year ASC 
LIMIT 3 )
UNION 
(SELECT name, birth_year 
FROM actors 
ORDER BY birth_year DESC 
LIMIT 3)
;







