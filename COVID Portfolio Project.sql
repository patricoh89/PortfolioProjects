SELECT *
FROM ProjectPortfolio.dbo.CovidDeaths
WHERE continent IS NOT NULL
ORDER BY location, date;

--SELECT *
--FROM ProjectPortfolio.dbo.CovidVaccinations
--ORDER BY location, date;

-- SELECT data that we are going to be using

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM ProjectPortfolio.dbo.CovidDeaths
WHERE continent IS NOT NULL
ORDER BY location, date;

-- Looking at total cases vs total deaths
-- Shows the likelihood of dying if you contract COVID in United States

SELECT location, date, total_cases, total_deaths, ROUND((total_deaths/total_cases)*100,2) AS DeathPercentage
FROM ProjectPortfolio.dbo.CovidDeaths
WHERE location LIKE '%state%' AND continent IS NOT NULL
ORDER BY location, date;

-- Looking at total cases vs population
-- Shows what percentage of population got COVID

SELECT location, date, total_cases, population, ROUND((total_cases/population)*100,2) AS PercentPopulationInfected
FROM ProjectPortfolio.dbo.CovidDeaths
--WHERE location LIKE '%state%'
WHERE continent IS NOT NULL
ORDER BY location, date;

-- Looking at countries with highest infection rate compared to population

SELECT location, population, MAX(total_cases) AS HighestInfectionCount, ROUND(MAX((total_cases/population))*100,2) AS HighestPercentPopulationInfected
FROM ProjectPortfolio.dbo.CovidDeaths
--WHERE location LIKE '%state%'
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY HighestPercentPopulationInfected DESC;

-- Showing countries with highest death count

SELECT location, MAX(CAST(total_deaths AS int)) AS TotalDeathCount
FROM ProjectPortfolio.dbo.CovidDeaths
--WHERE location LIKE '%state%'
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY TotalDeathCount DESC;

-- Let's break things down by continent

SELECT location, MAX(CAST(total_deaths AS int)) AS TotalDeathCount
FROM ProjectPortfolio.dbo.CovidDeaths
--WHERE location LIKE '%state%'
WHERE continent IS NULL
GROUP BY location
ORDER BY TotalDeathCount DESC;

-- Global numbers by day

SELECT date, SUM(new_cases) AS TotalCases, SUM(CAST(new_deaths AS int)) AS TotalDeaths, SUM(CAST(new_deaths AS int))/SUM(new_cases)*100 AS DeathPercentage
FROM ProjectPortfolio.dbo.CovidDeaths
--WHERE location LIKE '%state%' 
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY date;

-- Total global numbers

SELECT SUM(new_cases) AS TotalCases, SUM(CAST(new_deaths AS int)) AS TotalDeaths, ROUND(SUM(CAST(new_deaths AS int))/SUM(new_cases)*100,2) AS DeathPercentage
FROM ProjectPortfolio.dbo.CovidDeaths
--WHERE location LIKE '%state%' 
WHERE continent IS NOT NULL;

-- Looking at total population vs vaccinations

SELECT dea.continent, dea.location, dea.date, dea.population, CAST(vac.new_vaccinations AS int), 
	SUM(CAST(vac.new_vaccinations AS int)) OVER(PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingTotalVaccinations
FROM ProjectPortfolio.dbo.CovidDeaths AS dea
JOIN ProjectPortfolio.dbo.CovidVaccinations AS vac
	ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2, 3;

-- CTE

WITH PopvsVac (continent, location, date, population, new_vaccinations, RollingTotalVaccinations) AS
	(SELECT dea.continent, dea.location, dea.date, dea.population, CAST(vac.new_vaccinations AS int), 
	 SUM(CAST(vac.new_vaccinations AS int)) OVER(PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingTotalVaccinations
FROM ProjectPortfolio.dbo.CovidDeaths AS dea
JOIN ProjectPortfolio.dbo.CovidVaccinations AS vac
	ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.continent IS NOT NULL)
SELECT *, (RollingTotalVaccinations/population)*100
FROM PopvsVac;

-- Temp Table

DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
continent nvarchar(255), 
location nvarchar(255),
date datetime, 
population numeric,
new_vaccinations numeric,
RollingTotalVaccinations numeric
)

INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, CAST(vac.new_vaccinations AS int), 
	 SUM(CAST(vac.new_vaccinations AS int)) OVER(PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingTotalVaccinations
FROM ProjectPortfolio.dbo.CovidDeaths AS dea
JOIN ProjectPortfolio.dbo.CovidVaccinations AS vac
	ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.continent IS NOT NULL

SELECT *, (RollingTotalVaccinations/population)*100
FROM #PercentPopulationVaccinated

-- Creating view to store data for later visualizations

CREATE VIEW PercentPopulationVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
	 SUM(CAST(vac.new_vaccinations AS int)) OVER(PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingTotalVaccinations
FROM ProjectPortfolio.dbo.CovidDeaths AS dea
JOIN ProjectPortfolio.dbo.CovidVaccinations AS vac
	ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.continent IS NOT NULL

