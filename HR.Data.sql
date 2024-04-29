select * from [HR Data];

--DATA CLEANING
select [termdate] from dbo.[HR Data] order by [termdate] desc;

--UPDATE
update dbo.[HR Data]
set [termdate] =convert(datetime,left([termdate],10),120)

alter table dbo.[HR Data]
add new_termdate DATE;

UPDATE dbo.[HR Data]
set new_termdate =case
when termdate is not null and isdate([termdate])=1 then
cast ([termdate] as datetime) else null end;

--create new 'Age' column
alter table dbo.[HR Data]
add  age nvarchar(50);

--population with new age column
update [HR Data]
set age =DATEDIFF(year,birthdate,getdate());

--1.What is the age distribution in company?

select min([age]) as youngest ,max([age]) as eldest from dbo.[HR Data];

--2. Show age group by gender.

select [age_group],count(*) as count from
(select 
case
when age >=21 and age <=30 then '21 to 30'
when age >=31 and age <=40 then '31 to 40'
when age >=41 and age <=50 then '41 to 50'
else '50+'
end as age_group
from dbo.[HR Data])
as subquery group by [age_group] order by [age_group];

--3. Age group by Gender

select age_group, [gender], COUNT(*) as count 
from(
    select
        case
            when age >= 21 AND age <= 30 THEN '21 to 30'
            when age >= 31 AND age <= 40 THEN '31 to 40'
            when age >= 41 AND age <= 50 THEN '41 to 50'
            else '50+'
        end as age_group,
        [gender]
    from dbo.[HR Data]
    where new_termdate IS NULL
) as subquery 
group by age_group, [gender] 
order by age_group, [gender];

--2.What is the gender breakdown in the company ?

select [gender],count(gender) as count from dbo.[HR Data] where new_termdate is not null
group by gender order by gender desc;

--3.How does gender vary across department and jobtitle?

select gender,department,jobtitle,count(gender) as count from dbo.[HR Data] 
where new_termdate is not null
group by gender,jobtitle,department order by count desc;

--4.What is the race distrubution of company?

select race,count(race) as count from dbo.[HR Data]
where new_termdate is not null
group by race order by count desc;

--5. What is the average length of company?

select avg(datediff(year,hire_date,new_termdate))
as tenure from dbo.[HR Data]
where new_termdate is not null and new_termdate <=getdate();

--6.Which department has the highest turnover rate?
  --get total count
  --get terminated count
  --terminated count/total count

  SELECT 
    department,
    total_count,
    terminated_count,
    ROUND(CAST(terminated_count AS FLOAT) / total_count, 2) * 100 AS turnover_rate
FROM
    (
        SELECT 
            department,
            COUNT(*) AS total_count,
            SUM(CASE WHEN new_termdate IS NOT NULL AND new_termdate <= GETDATE() THEN 1 ELSE 0 END) AS terminated_count
        FROM 
            dbo.[HR Data] 
        GROUP BY 
            department
    ) AS subquery 
ORDER BY 
    turnover_rate DESC;

--7.What is the tenure distribution for each department ?

select department,avg(datediff(year,hire_date,new_termdate)) as tenure
from dbo.[HR Data] where new_termdate is not null and new_termdate <=getdate()
group by department order by tenure desc;

--8.How many employees work remotely for each department?

select location,count(*) as count
from dbo.[HR Data] where new_termdate is null group by location;
  
 --9.What is the distribution of employees across different states?

select location_state,count(id) as no_of_employee from
dbo.[HR Data] where new_termdate is null 
group by location_state order by no_of_employee desc;

--10.How are job titles distributed in the company ?

select jobtitle,count(*) as count
from dbo.[HR Data]
where new_termdate is null
group by jobtitle order by count desc;

--11.How have employee hire counts varied over time ?
--calculate hires
--calculate termination
--(hires-terminaitons)/hires percent hire change

SELECT 
    YEAR(hire_date) AS hire_year,
    SUM(CASE 
            WHEN new_termdate IS NOT NULL AND new_termdate <= GETDATE() THEN 1
            ELSE 0
        END) AS Hires
FROM 
    dbo.[HR Data]
GROUP BY 
    YEAR(hire_date);
----------------------------------------

SELECT hire_year,
       hire,
       terminations,
       hire - terminations AS net_change,
       ROUND((CAST(hire - terminations AS FLOAT) / hire) * 100, 1) AS perc_hire_change
FROM
    (SELECT YEAR(hire_date) AS hire_year,
            SUM(CASE 
                    WHEN new_termdate IS NOT NULL AND new_termdate <= GETDATE() THEN 1 
                    ELSE 0 
                END) AS hire,
            SUM(CASE 
                    WHEN new_termdate IS NOT NULL AND new_termdate <= GETDATE() THEN 1 
                    ELSE 0 
                END) AS terminations
     FROM dbo.[HR data]
     GROUP BY YEAR(hire_date)) AS subquery
ORDER BY perc_hire_change;
