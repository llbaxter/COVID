SELECT 
	Location, 
	date, 
	total_cases, 
	new_cases, 
	total_deaths, 
	population
FROM Porfolio..CovidDeaths
ORDER BY Location, date

-- Total Cases vs Total Deaths
SELECT 
	Location, 
	Date, 
	total_cases, 
	total_deaths, 
	(total_deaths/total_cases)*100 as DeathPercentage
FROM Porfolio..CovidDeaths
WHERE Location = 'United Kingdom'
ORDER BY DeathPercentage DESC

-- Total Cases vs Population
SELECT 
	Location, 
	Date, 
	Population, 
	total_cases, 
	(total_cases/population)*100 as CasesPercentage
FROM Porfolio..CovidDeaths
WHERE Location = 'United Kingdom'
ORDER BY CasesPercentage DESC

-- Countries with highest infection rate compared to population
SELECT 
	Location, 
	Population, 
	MAX(total_cases) AS HighestInfectionCount, 
	MAX((total_cases/population))*100 AS InfectionPopulationPercentage
FROM Porfolio..CovidDeaths
GROUP BY Location, Population
ORDER BY InfectionPopulationPercentage DESC


-- Countries with highest death rate per population
SELECT 
	Location, 
	MAX(cast(total_deaths as int)) AS TotalDeathCount
FROM Porfolio..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY Location
ORDER BY TotalDeathCount DESC
 
-- Continent 1
SELECT 
	Location, 
	MAX(cast(total_deaths as int)) AS TotalDeathCount
FROM Porfolio..CovidDeaths
WHERE Continent IS NULL
GROUP BY Location
ORDER BY TotalDeathCount DESC

-- Continent 2
SELECT 
	Continent, 
	MAX(cast(total_deaths as int)) AS TotalDeathCount
FROM Porfolio..CovidDeaths
WHERE Continent IS NULL
GROUP BY Continent
ORDER BY TotalDeathCount DESC

-- Total Cases vs Total Deaths
SELECT 
	Date, 
	SUM(new_cases) AS TotalCases, 
	SUM(CAST(new_deaths AS INT)) AS TotalDeaths, 
	SUM(CAST(new_deaths AS INT))/SUM(new_cases)*100 AS DeathPercentage
FROM Porfolio..CovidDeaths
WHERE Continent IS NOT NULL
GROUP BY Date
ORDER BY Date, TotalCases

--Total Population vs Vaccination
-- Using CTE to perform Calculation on Partition By in previous query
WITH PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
AS
(
SELECT
	dea.continent, 
	dea.location, 
	dea.date, 
	dea.population, 
	vac.new_vaccinations, 
	SUM(CONVERT(INT, vac.new_vaccinations)) 
		OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.Date) 
			AS RollingPeopleVaccinated
FROM Porfolio..CovidDeaths dea
JOIN Porfolio..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
)
SELECT 
	*, (RollingPeopleVaccinated/Population)*100 AS CumulativePopVac
FROM PopvsVac

-- Using Temp Table to perform Calculation on Partition By in previous query
DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
	Continent NVARCHAR(255),
	Location NVARCHAR(255),
	Date DATETIME,
	Population NUMERIC,
	New_vaccinations NUMERIC,
	RollingPeopleVaccinated NUMERIC
)

INSERT INTO #PercentPopulationVaccinated
SELECT 
	dea.continent, 
	dea.location,
	dea.date, 
	dea.population, 
	vac.new_vaccinations,
	SUM(CONVERT(INT,vac.new_vaccinations)) 
		OVER (Partition by dea.Location Order by dea.location, dea.Date)
			AS RollingPeopleVaccinated
FROM Porfolio..CovidDeaths dea
JOIN Porfolio..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date

SELECT *, (RollingPeopleVaccinated/Population)*100
FROM #PercentPopulationVaccinated

CREATE VIEW PercentPopulationVaccinated AS
SELECT 
	dea.continent, 
	dea.location, 
	dea.date, 
	dea.population, 
	vac.new_vaccinations, 
	SUM(CONVERT(INT,vac.new_vaccinations)) 
		OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.Date) 
			AS RollingPeopleVaccinated
From Porfolio..CovidDeaths dea
Join Porfolio..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL 