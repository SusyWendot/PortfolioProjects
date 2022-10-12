USE PortfolioProjectMyOwn
GO

SELECT *
FROM [dbo].[CovidDeaths]
WHERE [continent] IS NOT NULL
ORDER BY 3,4

--SELECT *
--FROM [dbo].[CovidVaccinations]
--ORDER BY 3,4

--Select the Data that we are going to be using

SELECT[location], [date],[total_cases],[new_cases],[total_deaths],[population]
FROM [dbo].[CovidDeaths]
WHERE [continent] IS NOT NULL
ORDER BY [location],[date]

--Looking at Total Cases vs Total Deaths
--Shows the Likelihood of dying if you contract Covid in your country

SELECT[location], [date],[total_cases],[total_deaths],([total_deaths]/[total_cases])*100 AS PercentageDeaths
FROM [dbo].[CovidDeaths]
WHERE LOCATION LIKE '%States%'
ORDER BY [location],[date]

--Looking at the Total Cases vs Population
--Shows what percentage of the Population got Covid

SELECT[location], [date],[population] ,[total_cases],([total_cases]/[population])*100 AS PercentPopulationInfected
FROM [dbo].[CovidDeaths]
WHERE [continent] IS NOT NULL
ORDER BY [location],[date]

--Looking at countries with highest infection rate compared to population.

SELECT[location],[population] ,MAX([total_cases]) AS HighestInfectionCount,MAX(([total_cases]/[population]))*100 AS PercentPopulationInfected
FROM [dbo].[CovidDeaths]
WHERE [continent] IS NOT NULL
GROUP BY [population],[location]
ORDER BY PercentPopulationInfected DESC


--Showing the countries with the Highest Death Count per Population

SELECT[location],MAX(CAST([total_deaths] AS int)) AS TotalDeathCount
FROM [dbo].[CovidDeaths]
WHERE [continent] IS NOT NULL
GROUP BY [location]
ORDER BY TotalDeathCount DESC

--Now Let's break things down by continent
--Showing the Continents with the highest Death Counts

SELECT[continent],MAX(CAST([total_deaths] AS int))  AS TotalDeathCount
FROM [dbo].[CovidDeaths]
WHERE [continent] IS NOT NULL
GROUP BY [continent]
ORDER BY TotalDeathCount DESC


--Global numbers per day

SELECT [date],SUM([new_cases]) AS 'Total Cases',SUM(CAST([new_deaths] AS int)) AS 'Total Deaths',SUM(CAST([new_deaths] AS int))/SUM([new_cases])*100 AS PercentageDeaths
FROM [dbo].[CovidDeaths]
WHERE [continent] IS NOT NULL
GROUP BY [date]
ORDER BY [date],2

--Global numbers total  to date

SELECT SUM([new_cases]) AS 'Total Cases',SUM(CAST([new_deaths] AS int)) AS 'Total Deaths',SUM(CAST([new_deaths] AS int))/SUM([new_cases])*100 AS PercentageDeaths
FROM [dbo].[CovidDeaths]
WHERE [continent] IS NOT NULL
ORDER BY 1,2

--Looking at Total Population VS Vaccinations

SELECT dea.Continent, dea.location,dea.date,dea.population,vac.new_vaccinations,SUM(CAST( vac.new_vaccinations AS bigint)) OVER (Partition by dea.Location)
FROM [dbo].[CovidDeaths] dea
JOIN [dbo].[CovidVaccinations] vac
ON dea.Location=vac.Location
and dea.date=vac.date
WHERE dea.Continent IS NOT NULL
ORDER BY 2,3

--You can also use CONVERT instead of CAST to convert data type, see below

SELECT dea.Continent, dea.location,dea.date,dea.population,vac.new_vaccinations,SUM(CONVERT(bigint, vac.new_vaccinations )) OVER (Partition by dea.Location ORDER BY dea.Location,dea.Date) 
AS RollingPeopleVaccinated
FROM [dbo].[CovidDeaths] dea
JOIN [dbo].[CovidVaccinations] vac
ON dea.Location=vac.Location
and dea.date=vac.date
WHERE dea.Continent IS NOT NULL
ORDER BY 2,3

--USE CTE
WITH PopvsVac(Continent,Location,Date,Population, New_Vaccinations,RollingPeopleVaccinated)
AS
(
SELECT dea.Continent, dea.location,dea.date,dea.population,vac.new_vaccinations,SUM(CONVERT(bigint, vac.new_vaccinations )) OVER (Partition by dea.Location ORDER BY dea.Location,dea.Date) 
AS RollingPeopleVaccinated
FROM [dbo].[CovidDeaths] dea
JOIN [dbo].[CovidVaccinations] vac
ON dea.Location=vac.Location
and dea.date=vac.date
WHERE dea.Continent IS NOT NULL
)
SELECT *,(RollingPeopleVaccinated/Population)*100
FROM PopvsVac

--TEMP TABLE


DROP Table if exists #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
Continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
RollingPeopleVaccinated numeric
)

INSERT INTO #PercentPopulationVaccinated
SELECT dea.Continent, dea.location,dea.date,dea.population,vac.new_vaccinations,SUM(CONVERT(bigint, vac.new_vaccinations )) OVER (Partition by dea.Location ORDER BY dea.Location,dea.Date) 
AS RollingPeopleVaccinated
FROM [dbo].[CovidDeaths] dea
JOIN [dbo].[CovidVaccinations] vac
ON dea.Location=vac.Location
and dea.date=vac.date
WHERE dea.Continent IS NOT NULL

SELECT *,(RollingPeopleVaccinated/Population)*100
FROM #PercentPopulationVaccinated

--Create View to store data to use later Visualizations

CREATE VIEW PercentPopulationVaccinated as
SELECT dea.Continent, dea.location,dea.date,dea.population,vac.new_vaccinations,SUM(CONVERT(bigint, vac.new_vaccinations )) OVER (Partition by dea.Location ORDER BY dea.Location,dea.Date) 
AS RollingPeopleVaccinated
FROM [dbo].[CovidDeaths] dea
JOIN [dbo].[CovidVaccinations] vac
ON dea.Location=vac.Location
and dea.date=vac.date
WHERE dea.Continent IS NOT NULL