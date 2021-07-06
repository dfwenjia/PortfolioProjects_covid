Select *
from covidDeaths
order by 3,4

Select *
from covidVaccinations
order by 3,4

--Select Data that we are going to be using
select location, date, total_cases, new_cases, total_deaths, population
from covidDeaths
order by 1,2


--Looking at Total Cases vs Total Deaths
--Shows likelihood of dying if youcontract covid in 'United States'
select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as deathpercentage
from covidDeaths
where location like '%states%'
order by 1,2


--Looking at Total Cases vs Population
--Shows what percentage of population got Covid
select location, date, total_cases, population, (total_cases/population)*100 as casepercentage
from covidDeaths
where location like '%states%'
order by 1,2
--Shows what percentage of population got Covid in Singapore
select location, date, total_cases, population, (total_cases/population)*100 as casepercentage
from covidDeaths
where location='singapore'
order by 1,2


--Looking at countries with highest infection rate compared to population
--Find out the locations with infection rate bigger than 10%
select location, MAX(total_cases), population, (MAX(total_cases)/population)*100 as casepercentage
from covidDeaths
group by location, population
having (MAX(total_cases)/population)*100>'10'
order by casepercentage desc


--LET'S BREAK THINGS DOWN BY COUNTINENT

--Showing Continents with highest Death count per population
select continent, MAX(cast(total_deaths as int)) as totaldeathcount
from covidDeaths
where continent is not null
group by continent
order by totaldeathcount desc



--GLOBAL NUMBERS
select sum(new_cases) as total_cases, sum(cast(new_deaths as int)) as total_deaths, 
	sum(cast(new_deaths as int))/sum(new_cases)*100 as deathpercentage
from covidDeaths
where continent is not null
--group by date
order by 1


--LET'S NAVIGATE TWO TABLES

select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
from covidDeaths dea join covidVaccinations vac on dea.date=vac.date and dea.location=vac.location
where dea.continent is not null
order by 1,2

--Looking at total population vs vaccinations
select dea.location, sum(cast(vac.new_vaccinations as int)) as total
from covidDeaths dea join covidVaccinations vac on dea.date=vac.date and dea.location=vac.location
where dea.continent is not null
group by dea.location
order by 1

select dea.location, dea.date, dea.population,  vac.new_vaccinations,
sum(cast(vac.new_vaccinations as int)) over (partition by dea.location order by dea.location, dea.date) 
	as rollingpeoplevaccinations 
	--(rollingpeoplevaccinations/population)*100
from covidDeaths dea join covidVaccinations vac on dea.date=vac.date and dea.location=vac.location
where dea.continent is not null

--USE CTE

with popvsvac (continent, location, date, population, new_vacination,rollingpeoplevaccinated)
as(
select dea.continent, dea.location, dea.date, dea.population,  vac.new_vaccinations,
sum(cast(vac.new_vaccinations as int)) over (partition by dea.location order by dea.location, dea.date) 
	as rollingpeoplevaccinations
	--(rollingpeoplevaccinations/population)*100
from covidDeaths dea join covidVaccinations vac on dea.date=vac.date and dea.location=vac.location
where dea.continent is not null
)
select *, (rollingpeoplevaccinated/population)*100
from popvsvac

--TEMP TABLE
drop table if exists #percentpopulationvaccinated
create table #percentpopulationvaccinated
(
continent nvarchar(225),
location nvarchar(225),
date datetime,
population numeric,
new_vaccinations numeric,
rollingpeoplevaccinations numeric
)

insert into #percentpopulationvaccinated
select dea.continent, dea.location, dea.date, dea.population,  vac.new_vaccinations,
sum(cast(vac.new_vaccinations as bigint)) over (partition by dea.location order by dea.location, dea.date) 
	as rollingpeoplevaccinations
from covidDeaths dea join covidVaccinations vac on dea.date=vac.date and dea.location=vac.location

select *, (rollingpeoplevaccinations/population)*100
from #percentpopulationvaccinated

--Creating view to store data for later visualizations

create view percentpopulationvaccinated as
select dea.continent, dea.location, dea.date, dea.population,  vac.new_vaccinations,
sum(cast(vac.new_vaccinations as bigint)) over (partition by dea.location order by dea.location, dea.date) 
	as rollingpeoplevaccinations
from covidDeaths dea join covidVaccinations vac on dea.date=vac.date and dea.location=vac.location
where dea.continent is not null

select *
from percentpopulationvaccinated