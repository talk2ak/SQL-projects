
##### Data Analysis of Marketing Survey data ######


/*  Problem Statement: A Market Survey was conducted by a Marketing team, of a fictitious Food & Beverage company CodeX. 
			Which is going to launch a Energy Drink. And Initially test launched a product in ten cities of India, to understand customer behaviour.
	
Approach: Following analysis is done through SQL queries- 1. Demographic Insights, 2. Consumer Preferences, 3. Competition Analysis, 
			4. Marketing Channel and Brand awareness, 5. Brand Penetration, 6. Purchase Behaviour and 7. Product Development
*/

# Creating Database
create database db_codex;
use db_codex;

# First glance into the data
select * from dim_cities;
select * from dim_repondents;
select * from fact_survey_responses;


# Checking for anomalies in the market survey data

-- People who have not heard about the brand but are saying they tried it before
select count(*)
from fact_survey_responses
where heard_before= "no" and tried_before = "yes";  -- It might possible

-- People who have not heard about the brand and are claiming thier prefered brand is CodeX 
select count(*)
from fact_survey_responses
where heard_before= "no" and current_brands = "codex";  -- not possible

-- People who say they have not tried the brand before and claiming thier prefered brand is CodeX
select count(*)
from fact_survey_responses
where tried_before = "no" and  current_brands = "codex"; -- not possible


# combining the records which are not possible
select *
from fact_survey_responses
where tried_before = "no" and  current_brands = "codex"
union
select *
from fact_survey_responses
where heard_before= "no" and current_brands = "codex"; 



# Creating a View which excludes not possible records:

create view corrected_survey as 
with cte as (
	select Respondent_ID
	from fact_survey_responses
	where tried_before = "no" and  current_brands = "codex"
		union
	select Respondent_ID
	from fact_survey_responses
	where heard_before= "no" and current_brands = "codex")
select * 
from fact_survey_responses
where Respondent_ID not in (select Respondent_ID from cte);



###### Demographic Insight  #######

# Q1: Who prefers energy drink more ?
with cte as (
	select gender, count(*) as cnt
	from dim_repondents
	join corrected_survey using (Respondent_ID)
	group by gender
	),
cte1 as (
	select sum(cnt) as total 
	from cte
    )
select gender, cnt, total, cnt/total as pct
from cte, cte1 ;


# Q2 Which are group prefers energy drinks more ?
with cte as (
	select age, count(*) as cnt
	from dim_repondents
	join corrected_survey using (Respondent_ID)
	group by age
	),
cte1 as (
	select sum(cnt) as total 
	from cte
    )
select age, cnt, total, cnt/total as pct
from cte, cte1 ;


# Q3 Which type of marketing reaches the most youth (15-30) ?
with cte as (
	select Marketing_channels, count(*) as cnt
	from corrected_survey
	join dim_repondents using (Respondent_ID)
	where age = '15-18' or age='19-30'
	group by Marketing_channels
	),
cte1 as (
	select sum(cnt) as total 
	from cte
    )
select Marketing_channels, cnt, total, cnt/total as pct
from cte, cte1 ;



############ Consumer Preferences ##############

# Q1 What are the prefered ingredients of energy drinks among respondents ?
with cte as (
	select Ingredients_expected, count(*) as cnt
	from corrected_survey
	group by Ingredients_expected
	),
cte1 as (
	select sum(cnt) as total 
	from cte
    )
select Ingredients_expected, cnt, total, cnt/total as pct
from cte, cte1 ;


# Q2 What packaging preferences do respondents have for energy drinks ?
with cte as (
	select Packaging_preference, count(*) as cnt
	from corrected_survey
	group by Packaging_preference
	),
cte1 as (
	select sum(cnt) as total 
	from cte
    )
select Packaging_preference, cnt, total, cnt/total as pct
from cte, cte1 ;



############ Competition Analysis ##############


# Q1 Who are the current Market Leaders ?
with cte as (
	select Current_brands, count(*) as cnt
	from corrected_survey
	group by Current_brands
	),
cte1 as (
	select sum(cnt) as total 
	from cte
    )
select Current_brands, cnt, total, cnt/total as pct
from cte, cte1 ;


# Q2 What are the primary reasons consumer prefer those brands over ours ?
with cte as (
	select Reasons_preventing_trying, count(*) as cnt
	from corrected_survey
	group by Reasons_preventing_trying
	),
cte1 as (
	select sum(cnt) as total 
	from cte
    )
select Reasons_preventing_trying, cnt, total, cnt/total as pct
from cte, cte1 ;


############ Marketing Channels and Brand Awareness ##############


# Q1 Which marketing channel can be used to reach more customers ?
with cte as (
	select Marketing_channels, count(*) as cnt
	from corrected_survey
	group by Marketing_channels
	),
cte1 as (
	select sum(cnt) as total 
	from cte
    )
select Marketing_channels, cnt, total, cnt/total as pct
from cte, cte1 ;



# Q2 How effective are different marketing strategies and channels in reaching our customers ?
with cte as (
	select Marketing_channels, 
		count(case when Brand_perception = "positive" and heard_before= "yes" then Respondent_ID else null end) as HeardPositive,
        count(case when Brand_perception = "positive" and heard_before= "yes" and current_brands = "codex" then Respondent_ID else null end) HeardPositiveCodex
    from corrected_survey
    join dim_repondents using(Respondent_ID)
	group by 1
    ),
cte1 as (
	select sum(HeardPositive) as TotalHeardPositive,
		sum(HeardPositiveCodex) as TotalHeardPositiveCodex
	from cte
    )
select Marketing_channels, HeardPositive, TotalHeardPositive, HeardPositive/TotalHeardPositive as pct_HeardPositive, 
	HeardPositiveCodex, TotalHeardPositiveCodex, HeardPositiveCodex/ TotalHeardPositiveCodex as pct_HeardPositiveCodex
from cte, cte1 ;  



############ Brand penetration ##############


# Q1: What do people think about our brand ? (Overall rating)
with cte as (
	select brand_perception, 
		case when brand_perception = "Positive" then 5
			when brand_perception = "Neutral" then 3
            else 1 
            end as rating,
		count(*) as cnt
	from corrected_survey
    group by 1
    )
select sum(rating*cnt) / sum(cnt) as overall_rating 
from cte;



# Q2: Which cities do we need to focus more on ?
select city, tier, count(if (Heard_before = 'yes', Respondent_ID, null )) as Heard_yes,
	count(if (Heard_before = 'No', Respondent_ID, null )) as Heard_no
from dim_cities
join dim_repondents using(city_id)
join corrected_survey using(Respondent_ID)
group by 1,2
order by Heard_yes desc, Heard_no desc;




############ Purchase behaviour ##############


# Q1 Where do respondents prefer to purchase energy drinks ?
select Purchase_location, count(*) as cnt
from corrected_survey
group by 1
order by 2 desc;


# Q2 What are typical counsumption situations for energy drinks among respondents ?
select Typical_consumption_situations, count(*) as cnt
from corrected_survey
group by 1
order by 2 desc;

# Q3 What factors influence respondents purchase decisions, such as price range and limited edition packaging ?

-- Packaging_preference
select Packaging_preference, count(*)  as cnt
from corrected_survey
group by 1
order by 2 desc;

-- Limited_edition_packaging
select Limited_edition_packaging, count(*)  as cnt
from corrected_survey
group by 1
order by 2 desc;

-- Price_range
select Price_range, count(*)  as cnt
from corrected_survey
group by 1
order by 2 desc;

-- Interest_in_natural_or_organic
select Interest_in_natural_or_organic, count(*)  as cnt
from corrected_survey
group by 1
order by 2 desc;

-- Ingredients_expected
select Ingredients_expected, count(*)  as cnt
from corrected_survey
group by 1
order by 2 desc;

-- Health_concerns
select Health_concerns, count(*)  as cnt
from corrected_survey
group by 1
order by 2 desc;



############ Product development ##############


# Q1 Which area of business should we focus more on our product development ? (Branding/ taste / Availability)
select Reasons_for_choosing_brands, count(*)  as Total_cnt,
	count(if (Current_brands = 'codex', Respondent_ID, null )) as cnt_codeX,
	count(if (Current_brands = 'Cola-Coka', Respondent_ID, null )) as cnt_cola_coka
from corrected_survey
group by 1
order by 2 desc;




# =====================================================================================================================

# Rough Work

select  count(distinct(Response_ID)), count(distinct(Respondent_ID)), count(distinct(Consume_frequency)), count(distinct(Consume_time)), count(distinct(Consume_reason)), 
count(distinct(Heard_before)), count(distinct(Brand_perception)), count(distinct(General_perception)), count(distinct(Tried_before)), count(distinct(Taste_experience)), 
count(distinct(Reasons_preventing_trying)), count(distinct(Current_brands)), count(distinct(Reasons_for_choosing_brands)), count(distinct(Improvements_desired)), 
count(distinct(Ingredients_expected)), count(distinct(Health_concerns)), count(distinct(Interest_in_natural_or_organic)), count(distinct(Marketing_channels)), 
count(distinct(Packaging_preference)), count(distinct(Limited_edition_packaging)), count(distinct(Price_range)), 
count(distinct(Purchase_location)), count(distinct(Typical_consumption_situations))
from fact_survey_responses;


