use moviesdb;

select * from movies;

-- SELECT, WHERE, LIKE, WILDCARD( % and _ )

select distinct studio 
from movies
where industry= 'bollywood';


-- WILDCARDS are always used with WHERE and LIKE clause. 
select * 
from movies 
where title like 'thor%';

select * 
from movies 
where title like '%america%';

select * 
from movies 
where release_year like '%22';

select * 
from movies 
where release_year like '2_%_';

select * 
from movies 
where title like '%-%';

-- when you want to search for a pattern "_20", which itself includes a wildcard character then we use \ which is a delimiter.
SELECT * 
FROM classicmodels.orderdetails
WHERE productCode LIKE '%\_20%';

select * 
from movies 
where studio = "" or title="";

select release_year 
from movies 
where title = 'the godfather';



-- BETWEEN, IN, ORDER BY, LIMIT, OFFSET

SELECT * 
FROM moviesdb.movies
WHERE imdb_rating > 5 AND title LIKE 'A%'; 

SELECT * 
FROM moviesdb.movies
WHERE imdb_rating > 5 AND title NOT LIKE 'A%';

SELECT * 
FROM moviesdb.movies
WHERE imdb_rating IS NULL; 

SELECT * 
FROM moviesdb.movies
WHERE imdb_rating BETWEEN 8 AND 10;

SELECT * 
FROM moviesdb.movies
WHERE release_year IN (2018, 2019, 2022);


SELECT * 
FROM moviesdb.movies
WHERE studio IN ('MARVEL STUDIOS', 'ZEE studios') OR release_year IN (2018, 2019, 2022);

SELECT * 
FROM moviesdb.movies
WHERE studio IN ('MARVEL STUDIOS', 'ZEE studios') AND release_year IN (2018, 2019, 2022);

-- LIMIT AND OFFSET
SELECT * FROM moviesdb.movies
ORDER BY imdb_rating DESC
LIMIT 10;

SELECT * FROM moviesdb.movies
ORDER BY imdb_rating DESC
LIMIT 10, 3;

SELECT * FROM moviesdb.movies
ORDER BY imdb_rating DESC
LIMIT 3 OFFSET 10;

SELECT * FROM moviesdb.movies
WHERE industry ='BOLLYWOOD'
ORDER BY imdb_rating DESC
LIMIT 10, 3 ;

SELECT * 
FROM moviesdb.movies
WHERE industry ='BOLLYWOOD'
ORDER BY imdb_rating DESC
LIMIT 3 OFFSET 10 ;

-- EXERCISE QUESTIONS

SELECT * FROM moviesdb.movies
ORDER BY release_year DESC;

SELECT * FROM moviesdb.movies
WHERE release_year= 2022
ORDER BY release_year DESC;

SELECT * FROM moviesdb.movies
WHERE release_year > 2020
ORDER BY release_year DESC;

SELECT * FROM moviesdb.movies
WHERE release_year > 2020 AND imdb_rating > 8
ORDER BY release_year DESC;

SELECT * FROM moviesdb.movies
WHERE studio IN ('HOMBALE FILMS', 'MARVEL STUDIOS');

SELECT * FROM moviesdb.movies
WHERE title LIKE '%thor%'
ORDER BY release_year DESC;

SELECT * FROM moviesdb.movies
WHERE studio NOT IN ('MARVEL STUDIOS');


-- COUNT(*)
SELECT COUNT(*)
FROM moviesdb.movies
WHERE STUDIO ='MARVEL STUDIOS';


-- GROUP BY --> no need to present grouping column in select statement
select industry, count(*) as cnt
from moviesdb.movies
group by industry
order by industry asc;


-- AGGREGATE FUNCTIONS: MIN, MAX, AVG,  STDDEV
SELECT MAX(imdb_rating)
FROM moviesdb.movies
WHERE industry = 'bollywood';

SELECT round(avg(imdb_rating),3) as avg_rating,
	min(imdb_rating) as min_rating,
    max(imdb_rating) max_rating
FROM moviesdb.movies
WHERE studio = 'marvel studios';

select industry, 
	count(industry) as cnt,
    avg(imdb_rating) as avg_rating
from moviesdb.movies
group by industry
order by industry asc;

select studio, 
	count(studio) as cnt,
    avg(imdb_rating) as avg_rating
from moviesdb.movies
group by studio
order by cnt desc;

-- to remove space in title string  
select studio, 
	count(studio) as cnt,
    avg(imdb_rating) as avg_rating
from moviesdb.movies
where studio <> ""
group by studio
order by cnt desc;

-- 1. How many movies were released between 2015 and 2022
select release_year as movie_released, count(*) as cnt
from moviesdb.movies 
where release_year between 2015 and 2022
group by release_year
order by cnt desc;

-- 2. Print the max and min movie release year
select 
	max(release_year) as max_movie_release_year, 
	min(release_year) as min_movie_release_year 
from moviesdb.movies;

-- 3. Print a year and how many movies were released in that year starting with the latest year
select 
	release_year, 
	count(*) as movie_count
from movies
group by release_year
order by release_year desc;


-- Exists
select m.movie_id, f.budget, f.unit, m.title from moviesdb.financials f, moviesdb.movies m 
where exists (select * 
		from movies
		where m.movie_id = f.movie_id 
			); 
    
-- HAVING--- Print all the years where more than two movies are released
-- ORDER OF EXECUTION -- FROM --> WHERE --> GROUP BY --> HAVING --> ORDER BY
select release_year, count(*) as movie_count
from movies
group by release_year
having movie_count > 2
order by movie_count;


-- CURRENT YEAR AND CALCULATING CURRENT AGE FOR ACTORS
select curdate(); 

select *, year(curdate())-birth_year as age
from actors;
    
-- IF CONDITION --> when condition is binary i.e, either this or that
SELECT *,
IF (currency = 'usd', round(revenue*77,1), revenue) as revenue_inr
from financials;    

-- CASE WHEN --> used when we have to give multiple conditions
select distinct unit from financials;

select *,
	case when unit = 'billions' then revenue*1000
		when unit = 'thousands' then revenue/1000
        else revenue
        end as revenue_ml
from financials;


-- profit % for all the movies
select *, round((revenue_inr / budget_inr -1)*100,2) as profit_percent
from (select *,
	IF (currency = 'usd', round(revenue_ml*77,2), revenue_ml) as revenue_inr, 
    IF (currency = 'usd', round(budget_ml*77,2), budget_ml) as budget_inr
    from (select *, 
		case when unit = 'billions' then revenue*1000
			when unit = 'thousands' then revenue/1000
			else revenue
			end as revenue_ml, 
		case when unit = 'billions' then budget*1000
			when unit = 'thousands' then budget/1000
			else budget
			end as budget_ml
from financials) unit_cr) inr_cr;






