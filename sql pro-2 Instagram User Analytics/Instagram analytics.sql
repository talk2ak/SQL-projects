
-- QM:1- Find the 5 oldest users of the Instagram from the database provided
SELECT username, created_at
FROM users
order by created_at asc
limit 5;

-- QM:2- Find the users who have never posted a single photo on Instagram
SELECT 
    username
FROM
    users
        LEFT JOIN
    photos ON users.id = photos.user_id
WHERE
    photos.id IS NULL;


 -- QM:3- Identify the winner of the contest and provide their details to the team: most liked photo
SELECT 
    username,
    photos.id,
    photos.image_url,
    COUNT(*) AS total_likes
FROM
    likes
        JOIN
    photos ON photos.id = likes.photo_id
        JOIN
    users ON users.id = likes.user_id
GROUP BY photos.id
ORDER BY total_likes desc
limit 5;

 
-- QM:4- Identify and suggest the top 5 most commonly used hashtags on the platform
 
 select  tag_name, count(tag_name) as t_tag
 from tags
 join photo_tags on tags.id = photo_tags.tag_id
 group by tags.id
 order by t_tag desc
 limit 5;
 
-- QM:5- What day of the week do most users register on? Provide insights on when to schedule an ad campaign

select date_format(created_at,'%a') as day_of_week, count(*) as 't_registered'
from users
group by day_of_week
order by t_registered desc;

-- QIM:1- Provide how many times does average user posts on Instagram. Also, provide the total number of photos on Instagram/total number of users

SELECT
	(SELECT count(*) FROM photos) / (SELECT COUNT(*) FROM users) as average_posts_by_user;



-- QIM:2 Provide data on users (bots) who have liked every single photo on the site (since any normal user would not be able to do this).
 select users.id, username, count(users.id) as total_likes_by_users
 from users
 join likes on users.id = likes.user_id
 group by users.id
 having total_likes_by_users = (select count(*) from photos);
 
 -- below query will also give same results 
 select u.id, u.username, count(l.user_id) as total_likes_by_users
 from users u
 join likes l on u.id = l.user_id
 group by l.user_id
 having total_likes_by_users = (select count(*) from photos);
 
  
  
 
 
 
