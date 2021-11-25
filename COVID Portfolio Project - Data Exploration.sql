-- Create a new database called 'PortfolioProject' in which to load the restructured Excel data files
-- Connect to the 'master' database to run this snippet
USE master
GO
-- Create the new database if it does not exist already
IF NOT EXISTS (
    SELECT [name]
        FROM sys.databases
        WHERE [name] = N'PortfolioProject'
)
CREATE DATABASE PortfolioProject
GO 

-- Received the following error when importing data file into Azure;
--- "Failed to convert parameter value from a String to a DateTime" where the Date column was not recognised as a DateTime format. To resolve this I changed the date format in column D of the Excel file from dd/mm/yyyy to yyyy-mm-dd. Other errors occured where the INT values were not recognised and needed to be converted to decimals manually when importing the data file

-- Ensuring the data was loaded correctly by running a test query on both imported tables;
SELECT *
FROM CovidDeaths

SELECT *
FROM CovidVaccinations

-- Select the data I will be using (IMAGE 1)
SELECT location,
        date,
        total_cases,
        new_cases,
        total_deaths,
        population_density
FROM CovidDeaths
WHERE continent IS NOT NULL
ORDER BY location, date;

-- Looking at the Total Cases vs Total Deaths (What is the % of people affected by COVID-19 that died?) (IMAGE 2)
SELECT location,
        date,
        total_cases,
        new_cases,
        total_deaths,
        (total_deaths/total_cases)*100 AS DeathPercentage 
FROM CovidDeaths
WHERE continent IS NOT NULL
ORDER BY location, date;

-- since the total_deaths and the total_cases are both INT, the percentage calculation returned as INT (meaning this always returned 0) so I needed to CAST
the calculation as a NUMERIC value which updated the query to;

-- Let's look at the DeathPercentage for Belgium
-- Shows the likelihood of dying if you contract COVID-19 in your country
SELECT location,
        date,
        total_cases,
        new_cases,
        total_deaths,
        (total_deaths/total_cases) * 100 AS DeathPercentage 
FROM CovidDeaths
WHERE location LIKE '%Belgium%'
ORDER BY location, date;

-- Looking at the Total Cases vs Population (IMAGE 3)
-- Shows what % of population got COVID-19
SELECT location,
        date,
        total_cases,
        population_density,
        (total_cases/population_density) * 100 AS DeathPercentage 
FROM CovidDeaths
WHERE location LIKE '%Belgium%'
ORDER BY location, date;

-- The issue I kept getting here was that the total_cases and population_density columns were both INT values and kept getting 0 or 0.0000 calculations for the percentage column so I CAST the percentage calculation as NUMERIC with the below query to reseolve this issue;

SELECT location,
        date,
        total_cases,
        population_density,
        CAST((total_cases/population_density) * 100 as NUMERIC) AS PercentOfPopulationInfected 
FROM CovidDeaths
WHERE location LIKE '%Belgium%'
ORDER BY location, date;
/* See image 3.1 for details */

-- Looking at countries with Highest Infection Rate vs Population (IMAGE 4)
SELECT location,
        population_density,
        MAX(total_cases) AS HighestInfectionCount,
        MAX((total_cases/population_density)) * 100 AS PercentPopulationInfected 
FROM CovidDeaths
GROUP BY location, population_density
ORDER BY PercentPopulationInfected DESC;


-- Showing the countries with the Highest Death Count per Population
SELECT location,
        MAX(total_deaths) AS TotalDeathCount
FROM CovidDeaths
GROUP BY location
ORDER BY TotalDeathCount DESC;

-- Let's break things down by Continent (Image 5)
SELECT continent,
        MAX(total_deaths) AS TotalDeathCount
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount DESC;
/* There are definitely issues with the data and totals here */

-- GLOBAL NUMBERS (Image 6)
SELECT date,
        SUM(new_cases) AS TotalNewCases,
        SUM(new_deaths) AS TotalNewDeaths
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY date;


-- Joining the CovidDeaths and CovidVaccinations tables on location and date (IMAGE 7)
SELECT *
FROM CovidDeaths AS cd
JOIN CovidVaccinations AS cv
ON cd.location = cv.location
AND cd.date = cv.date


-- Looking at Total Population vs Vaccinations (IMAGE 8)
SELECT cd.continent,
        cd.location,
        cd.date,
        cd.population_density,
        cv.new_vaccinations
FROM CovidDeaths AS cd
JOIN CovidVaccinations AS cv
ON cd.location = cv.location
AND cd.date = cv.date
WHERE cd.continent IS NOT NULL
ORDER BY cd.continent, cd.location, cd.date;

-- Rolling by location through using PARTITION BY (IMAGE 9)
SELECT cd.continent,
        cd.location,
        cd.date,
        cd.population_density,
        cv.new_vaccinations,
        SUM(new_vaccinations) OVER (PARTITION BY cd.location ORDER BY cd.location, cd.date) AS RollingPeopleVaccinated
FROM CovidDeaths AS cd
JOIN CovidVaccinations AS cv
ON cd.location = cv.location
AND cd.date = cv.date
WHERE cd.continent IS NOT NULL
ORDER BY cd.location, cd.date;

-- Using CTE to perform Calculation on Partition By in previous query (IMAGE 10)
WITH PopulatioVsVaccinations (continent, location, date, population_density, new_vaccinations, RollingPeopleVaccinated)
AS
(
        SELECT cd.continent,
        cd.location,
        cd.date,
        cd.population_density,
        cv.new_vaccinations,
        SUM(new_vaccinations) OVER (PARTITION BY cd.location ORDER BY cd.location, cd.date) AS RollingPeopleVaccinated
FROM CovidDeaths AS cd
JOIN CovidVaccinations AS cv
ON cd.location = cv.location
AND cd.date = cv.date
WHERE cd.continent IS NOT NULL
--ORDER BY cd.location, cd.date  -- Commenting out the ORDER BY clause as this throws an error
)
SELECT *
FROM PopulatioVsVaccinations

-- Changing the query above slightly to calculated the Percentage of People Vaccinated per Country (IMAGE 11)
WITH PopulatioVsVaccinations (continent, location, date, population_density, new_vaccinations, RollingPeopleVaccinated)
AS
(
        SELECT cd.continent,
        cd.location,
        cd.date,
        cd.population_density,
        cv.new_vaccinations,
        SUM(new_vaccinations) OVER (PARTITION BY cd.location ORDER BY cd.location, cd.date) AS RollingPeopleVaccinated
FROM CovidDeaths AS cd
JOIN CovidVaccinations AS cv
ON cd.location = cv.location
AND cd.date = cv.date
WHERE cd.continent IS NOT NULL
--ORDER BY cd.location, cd.date  -- Commenting out the ORDER BY clause as this throws an error
)
-- Amended the below query;
SELECT *,
        (RollingPeopleVaccinated/population_density)*100 AS PercentagePeopleVaccinated
FROM PopulatioVsVaccinations

-- TEMP TABLE to perform Calculation on Partition By in previous query (IMAGE 12)
CREATE TABLE PercentPopVacc (
        Continent nvarchar(255),
        Location nvarchar(255),
        Date datetime,
        population_density numeric,
        new_vaccinations numeric,
        RollingPeopleVaccinated numeric
)
INSERT INTO PercentPopVacc 
SELECT cd.continent,
        cd.location,
        cd.date,
        cd.population_density,
        cv.new_vaccinations,
        SUM(new_vaccinations) OVER (PARTITION BY cd.location ORDER BY cd.location, cd.date) AS RollingPeopleVaccinated
FROM CovidDeaths AS cd
JOIN CovidVaccinations AS cv
ON cd.location = cv.location
AND cd.date = cv.date
-- WHERE cd.continent IS NOT NULL
-- ORDER BY cd.location, cd.date  -- Commenting out the ORDER BY clause as this throws an error

SELECT *,
        (RollingPeopleVaccinated/population_density)*100 AS PercentagePeopleVaccinated
FROM PercentPopVacc

-- Creating View to store data for later visualizations (IMAGE 13)
CREATE VIEW PerPopVac AS
SELECT cd.continent,
                cd.location,
                cd.date,
                cd.population_density,
                cv.new_vaccinations,
                SUM(new_vaccinations) OVER (PARTITION BY cd.location ORDER BY cd.location, cd.date) AS RollingPeopleVaccinated
        FROM CovidDeaths AS cd
        JOIN CovidVaccinations AS cv
        ON cd.location = cv.location
        AND cd.date = cv.date
        WHERE cd.continent IS NOT NULL
