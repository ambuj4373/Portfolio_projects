--checking data what we have imported
SELECT *
FROM covid_data.dbo.covid_death
WHERE continent IS NOT NULL
ORDER BY 3,4

----2nd table
SELECT *
FROM covid_data.dbo.covid_vaccination
ORDER BY 3,4


----------------------------------------------------------------------------------------------------------

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM covid_data.dbo.covid_death
ORDER BY 1,2


----loooking at total cases vs deaths in whole world

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS percentage_deaths_per_cases
FROM covid_data.dbo.covid_death
ORDER BY 1,2


----loooking at total cases vs deaths in India

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS percentage_deaths_per_cases
FROM covid_data.dbo.covid_death
WHERE location ='India'
ORDER BY 1,2


--loooking at total cases vs deaths in Latvia

---(CHANCES OF DYING IN LATVIA)

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS percentage_deaths_per_cases
FROM covid_data.dbo.covid_death
WHERE location ='Latvia'
ORDER BY 1,2



--loooking at total cases vs population in India, Latvia (Population Getting Covid)

SELECT location, date, total_cases, population, (total_cases/population)*100 AS infection_rate_to_population
FROM covid_data.dbo.covid_death
--WHERE location LIKE 'India'
ORDER BY 1,2


--looking at countries with highest infection rate compared to population

SELECT location, MAX(total_cases) AS Highest_infection_count, population, MAX((total_cases/population))*100 AS infection_rate
FROM covid_data.dbo.covid_death
--WHERE location LIKE 'India'
GROUP BY population, location
ORDER BY infection_rate DESC


--looking at countries with highest DEATH rate compared to population


SELECT location, MAX(CAST(total_deaths as int)) AS total_death_count
FROM covid_data.dbo.covid_death
--WHERE location LIKE 'India'
WHERE continent IS NOT NULL
GROUP BY population, location
ORDER BY total_death_count  DESC



--BREAK IT DOWN BY CONTINENT,World

SELECT location, MAX(CAST(total_deaths as int)) AS total_death_count
FROM covid_data.dbo.covid_death
--WHERE location LIKE 'India'
WHERE continent IS NULL
GROUP BY location
ORDER BY total_death_count  DESC



--SHOWING THE CONTINENT WITH HIGHEST DEATH COUNT

SELECT continent, MAX(CAST(total_deaths as int)) AS total_death_count
FROM covid_data.dbo.covid_death
--WHERE location LIKE 'India'
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY total_death_count  DESC



--GLOBAL NUMBERS

SELECT date, SUM(new_cases) AS global_new_cases, SUM(CAST(new_deaths as int)) AS global_new_deaths, SUM(CAST(new_deaths as int))/SUM(new_cases)*100 AS Global_death_rate
FROM covid_data.dbo.covid_death
--WHERE location ='India'
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1,2



SELECT SUM(new_cases) AS global_new_cases, SUM(CAST(new_deaths as int)) AS global_new_deaths, SUM(CAST(new_deaths as int))/SUM(new_cases)*100 AS Global_death_rate
FROM covid_data.dbo.covid_death
--WHERE location ='India'
WHERE continent IS NOT NULL
--GROUP BY date
ORDER BY 1,2


  

  ----------------------------------------------------Bringing another table into context and let us join the tables (vaccination table)-----------------------------


  SELECT *
  FROM covid_data..covid_death dea
	JOIN covid_data..covid_vaccination vac
	ON dea.location = vac.location AND
	dea.date	=	vac.date


	--Looking at total population vs new_vaccinations


	  SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
  FROM covid_data..covid_death dea
	JOIN covid_data..covid_vaccination vac
	ON dea.location = vac.location AND
	dea.date	=	vac.date
	WHERE dea.continent IS NOT NULL
	ORDER BY dea.continent, dea.location, dea.date DESC



	--FINDING OUT ROLLING VACCINATIONS


 SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
		  SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.location ORDER BY dea.location, dea.date) AS Rolling_People_Vaccinated
  FROM covid_data..covid_death dea
	JOIN covid_data..covid_vaccination vac
	ON dea.location = vac.location AND dea.date	=	vac.date
	WHERE dea.continent IS NOT NULL
	ORDER BY 2,3


	--now we are creating a temp table inorder to use our last calculations MAX ((Rolling_vacciantions ) / Population ))*100 to check number of people vaccinated

	--USE CTE

With PopvsVac (Continent, Location, Date, Population, new_vaccinations, Rolling_People_Vaccinated)

AS
	(
	SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
		  SUM(CAST(vac.new_vaccinations AS int)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS Rolling_People_Vaccinated
  FROM covid_data..covid_death dea
	JOIN covid_data..covid_vaccination vac
	ON dea.location = vac.location AND dea.date	=	vac.date
	WHERE dea.continent IS NOT NULL
	--ORDER BY 2,3
	)
	SELECT *, (Rolling_People_Vaccinated/Population)*100
	FROM PopvsVac




	----TEMP TABLE


	DROP Table if exists #Percent_population_vaccinated
	Create Table #Percent_population_vaccinated
	(
	Continent nvarchar(255),
	Location nvarchar(255),
	Date datetime,
	Population numeric,
	New_vaccinations numeric,
	Rolling_People_Vaccinated numeric
	)

	INSERT INTO #Percent_population_vaccinated
	SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
		  SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS Rolling_People_Vaccinated
  FROM covid_data..covid_death dea
	JOIN covid_data..covid_vaccination vac
	ON dea.location = vac.location AND dea.date	=	vac.date
	--WHERE dea.continent IS NOT NULL
	--ORDER BY 1,2

	SELECT *, (Rolling_People_Vaccinated/Population)*100
	FROM #Percent_population_vaccinated



	--CREATING VIEW FOR LATER VISUALIZATION

