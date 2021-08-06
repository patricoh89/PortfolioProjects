-- COVID Project

-- Looking at entire dataset for covid_deaths only for the US
SELECT *
FROM covid_deaths
WHERE continent IS NOT NULL
  AND location LIKE '%states%'
ORDER BY location, date;

-- Deleting data from 8/1/2021-8/4/2021
-- Only would like data until the end of July 2021
DELETE
FROM covid_deaths
WHERE date BETWEEN '2021-08-01' AND '2021-08-04';

-- Looking at total cases vs total deaths 
-- Shows the likelihood of dying if contracting COVID-19 
SELECT location, 
       date, 
	   total_cases, 
	   total_deaths,
	   ROUND((CASE WHEN total_deaths IS NULL THEN 0 ELSE total_deaths END/total_cases)*100,2) AS death_perc
FROM covid_deaths
WHERE continent IS NOT NULL 
  AND location LIKE '%states%';

-- Liklihood of dying by month
SELECT location,
	   YEAR(date) AS year,
       MONTH(date) AS month,
	   ROUND(AVG((CASE WHEN total_deaths IS NULL THEN 0 ELSE total_deaths END/total_cases)*100),2) AS death_perc
FROM covid_deaths
WHERE continent IS NOT NULL
  AND location LIKE '%states%'
GROUP BY location, YEAR(date), MONTH(date)
ORDER BY location, YEAR(date), MONTH(date);

-- Looking at total cases vs population
-- Shows what percentage of population got COVID
SELECT location,
       date,
       population, 
	   total_cases,
	   ROUND(total_cases/population*100,2) AS infection_perc
FROM covid_deaths
WHERE continent IS NOT NULL
  AND location LIKE '%states%'
ORDER BY location, date;

-- Infection percentage by month
SELECT location,
       YEAR(date) AS year,
	   MONTH(date) AS month,
	   ROUND(AVG(total_cases/population*100),2) AS infection_perc
FROM covid_deaths
WHERE continent IS NOT NULL
  AND location LIKE '%states%'
GROUP BY location, YEAR(date), MONTH(date)
ORDER BY location, YEAR(date), MONTH(date);

-- Looking at countries with the highest infection rate vs population
SELECT location,
       population,
	   MAX(total_cases) AS total_infection_count,
	   ROUND(MAX(total_cases/population)*100,2) AS infection_perc	   
FROM covid_deaths
GROUP BY location, population
ORDER BY infection_perc DESC;

-- Looking at countries with highest death count
SELECT location,
       MAX(CAST(total_deaths AS int)) AS total_death_count -- data type for total_deaths is nvarchar
FROM covid_deaths
GROUP BY location
ORDER BY total_death_count DESC;

-- Highest death count by continent
SELECT location,
       MAX(CAST(total_deaths AS numeric)) AS total_death_count 
FROM covid_deaths
WHERE continent IS NULL -- data has "location" really as being a continent when "continent" is null
GROUP BY location
ORDER BY total_death_count DESC;

-- Global numbers by day
SELECT date,
       SUM(new_cases) AS total_cases,
	   SUM(CAST(new_deaths AS int)) AS total_deaths,
	   ROUND(SUM(CAST(new_deaths AS int))/SUM(new_cases)*100,2) AS death_perc
FROM covid_deaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY date;

-- Total global numbers
SELECT SUM(new_cases) AS total_cases,
       SUM(CAST(new_deaths AS int)) AS total_deaths,
	   ROUND(SUM(CAST(new_deaths AS int))/SUM(new_cases)*100,2) AS death_perc
FROM covid_deaths
WHERE continent IS NOT NULL

-- Looking at global total population vs vaccinations per day
SELECT dea.continent,
       dea.location,
	   dea.date,
	   dea.population,
	   CAST(vac.new_vaccinations AS int) AS new_vaccinations,
	   SUM(CAST(vac.new_vaccinations AS int)) 
	     OVER(PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_total_vaccinations
FROM covid_deaths AS dea
JOIN covid_vaccinations AS vac
  ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY dea.location, dea.date;

-- CTE
WITH pop_vs_vac AS
  (SELECT dea.continent,
          dea.location,
		  dea.date,
		  dea.population,
		  CAST(vac.new_vaccinations AS int) AS new_vaccinations,
		  SUM(CAST(vac.new_vaccinations AS int))
		    OVER(PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_total_vaccinations
   FROM covid_deaths AS dea
   JOIN covid_vaccinations AS vac
     ON dea.location = vac.location AND dea.date = vac.date
   WHERE dea.continent IS NOT NULL)

SELECT *, ROUND((rolling_total_vaccinations/population)*100,2)
FROM pop_vs_vac;
       
-- Creating view to store data for visualization
CREATE VIEW percent_population_vaccinated AS
SELECT dea.continent,
       dea.location,
	   dea.date,
       dea.population,
	   vac.new_vaccinations,
	   SUM(CAST(vac.new_vaccinations AS int))
	     OVER(PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_total_vaccinations
FROM covid_deaths AS dea
JOIN covid_vaccinations AS vac
  ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.continent IS NOT NULL