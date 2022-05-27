/***************************************************************************
Author:	Main Code written by Jenny Hurley - SP Created by Suraj Chahal
Date: 20-01-2016
Purpose: Gather Customers, Date ranges and brands to assess
***************************************************************************/
CREATE PROCEDURE [Prototype].[ROCP2_Code_01_CustsDatesBrands_V3_Fix]
	(
	@IndividualBrand SMALLINT
	)
AS
BEGIN

--DECLARE	@IndividualBrand SMALLINT
--SET @IndividualBrand = 0


/*****************************************************
ROC Phase 2 - Calculating Customers, Dates and Brands
*****************************************************/
--IF OBJECT_ID('tempdb..#Dates_0') IS NOT NULL DROP TABLE #Dates_0
CREATE TABLE #Dates_0 
	(
	Edate DATE NULL,  -- Last complete month of full data
	Rundate DATE NULL
	) 

--IF @IndividualBrand <> 0
--BEGIN

--INSERT INTO #Dates_0
--SELECT *
--FROM Prototype.Dates_0

--END
--ELSE
--BEGIN

--TRUNCATE TABLE Prototype.Dates_0

--INSERT INTO #Dates_0  VALUES 
--	(
--	DATEADD(DD,-14,CAST(GETDATE() AS DATE)),
--	--'2016-02-28',  -- Fix as a static date depending on the run monthly refresh... only change when running and change to be approx -14 days from today
--        CAST(GETDATE() AS DATE)
--	)
----select top 10 * from #Dates_0

--INSERT INTO Prototype.Dates_0
--SELECT	*
--FROM #Dates_0

INSERT INTO #Dates_0
	SELECT *
	FROM Prototype.Dates_0

--END

/****************************************************************
Date frames: Generating the period of which Natural sales is base
	     last full month (at least 28 days of data)
****************************************************************/
IF OBJECT_ID ('tempdb..#BuildDates') IS NOT NULL DROP TABLE #BuildDates
SELECT	monthID1 as Build_Month,
	RIGHT(monthID1,4) as Yr1  
INTO #BuildDates
FROM	(
	SELECT	a.*,
		b.NoDays_Full,
		ROW_NUMBER() OVER (ORDER BY StartDate DESC) as LastMonth
	FROM	(
		SELECT	MonthID1,
			MIN(StartDate) as StartDate,
			COUNT(DISTINCT Linedate) as NoDays_Avail  
		FROM Prototype.ROCP2_SegFore_DayRef 
		WHERE Enddate <= (SELECT Edate FROM #Dates_0)
		GROUP BY monthID1
		)a
	LEFT JOIN
		(
		SELECT	MonthID1,
			COUNT(DISTINCT Linedate) as NoDays_Full
		FROM Prototype.ROCP2_SegFore_DayRef 
		GROUP BY MonthID1
		) b
		ON a.MonthID1 = b.MonthID1 
	WHERE a.NoDays_Avail = b.NoDays_Full
	) c
WHERE LastMonth = 1

CREATE CLUSTERED INDEX IDX_BM ON #BuildDates (Build_Month)


-- Creating the weeks which are the current weeks on which the natural sales behaviour is based
-- create as perm
IF OBJECT_ID ('tempdb..#WeekBuild') IS NOT NULL DROP TABLE #WeekBuild
SELECT	StartDate,
	EndDate,
	ROW_NUMBER() OVER (ORDER BY startdate) as WeekNo
INTO #WeekBuild
FROM Prototype.ROCP2_SegFore_DayRef 
WHERE	MonthID1 = (SELECT Build_Month FROM #BuildDates)
	AND EndDate <= (SELECT EDate FROM #Dates_0)
GROUP BY StartDate, EndDate
ORDER BY StartDate

--select * from #weekbuild


-----------------------------------------------------------------------
------  Building back to the dates and weeklookup space
-- Will change each month run provided the dates change

IF OBJECT_ID('Prototype.ROCP2_SegFore_Rundaylk') IS NOT NULL DROP TABLE Prototype.ROCP2_SegFore_Rundaylk
select d.*
,case when r.StartDate is not null then 1 else 0 end as buildweek
into Prototype.ROCP2_SegFore_Rundaylk
 from Prototype.ROCP2_SegFore_DayRef d
left join #weekbuild r on d.StartDate=r.StartDate and d.Enddate=r.Enddate
order by linedate

--select top 100 * from Staging.ROCP2_SegFore_Rundaylk  order by linedate
--select * from Staging.STOSalesForecast_Rundaylk order by linedate

 /**********************************************************************************************/
 /*  CREATING BASES - NOW THERE ARE 2
 --- 1/ NFi nuetral from RBS cards not on MyRewards
 --- 2/ MyRewards base of cards -- avoid use of publisher scaling and since a separate algorithm is currently used makes sense to have own base      */
 /*********************************************************************************************/

 /**********************************************************************************************/
 /*  Dates for the Fixed BASE                                                              */
 /*********************************************************************************************/

 ---- The daily range with the latest customer attributes dates 
IF OBJECT_ID('tempdb..#Dates_Lookup') IS NOT NULL DROP TABLE #Dates_Lookup
select d.*
,case when ca.EndDate is not null then 1 else NUll end as LastCADate
into #Dates_Lookup
from Prototype.ROCP2_SegFore_Rundaylk d
left join relational.CustomerAttributeDates ca on d.LineDate=ca.EndDate
order by LineDate


--- Defining the seasonal data values (could explore going back further than a year and using averages)


--- key dates (for fixed base etc)
IF OBJECT_ID('tempdb..#Dates') IS NOT NULL DROP TABLE #Dates
select	*
	,datediff(day,buildend,CA_date) as BetweenDays
	---- creating the rules for the fixed base
	,dateadd(week,-52,buildstart) as FixedStart -- Retail spend anytime the year before
	,dateadd(day,-28,CA_date) as FixedEnd --- retail spend in the last 28 days -- IN some cases this might overlap with the 
	into #Dates
	from (
		select max(case when buildweek=1 then Enddate else null end) as BuildEnd
		,min(case when buildweek=1 then StartDate else null end) as BuildStart
		,max(case when lastCAdate=1 then linedate else null end) as CA_Date
		from #dates_lookup
	 ) a
---------------------------------------------------------------
----  Add these to the date lookup

IF OBJECT_ID('Prototype.ROCP2_SegFore_RunDates') IS NOT NULL DROP TABLE Prototype.ROCP2_SegFore_RunDates
select d.*
,d0.Edate as LastAvailable
into Prototype.ROCP2_SegFore_RunDates
from #dates d
cross join #dates_0 d0

--select top 20 * from Staging.ROCP2_SegFore_RunDates

CREATE CLUSTERED INDEX IDX_BE ON Prototype.ROCP2_SegFore_RunDates (BuildEnd,BuildStart)


/************************
Gather CINs of Customers
************************/
IF OBJECT_ID('tempdb..#CINs') IS NOT NULL DROP TABLE #CINs
SELECT	DISTINCT
	cl.CIN as SourceUID,
	cl.CINID
INTO #CINs
FROM Relational.CINList cl WITH (NOLOCK) 
INNER JOIN relational.CustomerAttribute ca WITH (NOLOCK)
	ON ca.cinid=cl.cinid
LEFT JOIN Staging.Customer_DuplicateSourceUID dup WITH (NOLOCK) 
	ON dup.sourceUID = cl.CIN 
WHERE	FirstTranDate < (SELECT fixedstart FROM #dates)
	AND recencyYearRetail > (SELECT Fixedend FROM #dates) 
	AND dup.sourceuid  is NULL
--(7547009 row(s) affected)
CREATE CLUSTERED INDEX IDX_CID ON #CINs (CINID)
CREATE NONCLUSTERED INDEX IDX_CIN ON #CINs (SourceUID)

-----------  Exlcude the CINS that Are in CBP
--- This is to make sure that uplift is not included
--- exclude those who have ever been active!! 

IF OBJECT_ID('tempdb..#CBPBase') IS NOT NULL DROP TABLE #CBPBase
SELECT c.SourceUID
INTO #CBPBase
FROM Relational.customer c
--(2509591 row(s) affected)
CREATE CLUSTERED INDEX IDX_UID ON #CBPBase (SourceUID)


IF OBJECT_ID('tempdb..#CINs_excCBP') IS NOT NULL DROP TABLE #CINs_excCBP
SELECT  b.*
	,ROW_NUMBER() over (order by newID()) as rand1
INTO #CINs_excCBP
FROM #CINs b
LEFT JOIN #CBPBase cbp
	ON b.SourceUID = cbp.SourceUID
WHERE cbp.SourceUID IS NULL


IF OBJECT_ID('Prototype.ROCP2_SegFore_FixedBase') IS NOT NULL DROP TABLE Prototype.ROCP2_SegFore_FixedBase
CREATE TABLE Prototype.ROCP2_SegFore_FixedBase
	(
	CINID INT PRIMARY KEY NOT NULL
	)

INSERT INTO Prototype.ROCP2_SegFore_FixedBase
SELECT	DISTINCT
	CINID
FROM #cins_excCBP
WHERE rand1 <= 1000000 -- Restricting customer base to 1m.

-------------------------------------------------------
--- MYRewards Base 
--- COde is not that efficient as doubled from above -- but last min tack on with limited time
-- Making code efficient here not a priority.
-------------------------------------------------------



IF OBJECT_ID('tempdb..#cins2') IS NOT NULL DROP TABLE #cins2
Select distinct C.fANID
, CL.CINID
,c.Gender
,ROW_NUMBER() over (order by newID()) as randrow
	,	CASE	
			WHEN c.AgeCurrent < 18 OR c.AgeCurrent IS NULL THEN '99. Unknown'
			WHEN c.AgeCurrent BETWEEN 18 AND 24 THEN '01. 18 to 24'
			WHEN c.AgeCurrent BETWEEN 25 AND 29 THEN '02. 25 to 29'
			WHEN c.AgeCurrent BETWEEN 30 AND 39 THEN '03. 30 to 39'
			WHEN c.AgeCurrent BETWEEN 40 AND 49 THEN '04. 40 to 49'
			WHEN c.AgeCurrent BETWEEN 50 AND 59 THEN '05. 50 to 59'
			WHEN c.AgeCurrent BETWEEN 60 AND 64 THEN '06. 60 to 64'
			WHEN c.AgeCurrent >= 65 THEN '07. 65+' 
		END AS Age_Group

	,	ISNULL((cam.[CAMEO_CODE_GROUP] +'-'+ camg.CAMEO_CODE_GROUP_Category),'99. Unknown') as CAMEO_CODE_GRP
		,coalesce(c.region,'Unknown') as Region
,MarketableByEmail
into #cins2
From warehouse.relational.customer c with (nolock) 
join warehouse.Relational.CINList cl with (nolock) on c.SourceUID = cl.CIN
left join warehouse.Relational.CAMEO cam with (nolock)  on cam.postcode = c.postcode
left join warehouse.relational.cameo_code_group camG with (nolock)  on camG.CAMEO_CODE_GROUP =cam.CAMEO_CODE_GROUP
left join Staging.Customer_DuplicateSourceUID dup with (nolock)  on dup.sourceUID = c.SourceUID 
where dup.sourceuid  is NULL
and CurrentlyActive=1 
--and MarketableByEmail=1    --- Taken out as for RBS ROC need to have in (might make STO tool slight more inaccurate but....) 
and ActivatedDate<= (select buildstart from  Warehouse.Prototype.ROCP2_SegFore_RunDates )                     --- only want customers who had activated before last transaction considered.  This is to avoid any issues with new cards..  I should i make this 4 weeks before last trans considered i.e. the build week


IF OBJECT_ID('Warehouse.Prototype.ROCP2_RBS_MyRewardsBase') IS NOT NULL DROP TABLE Warehouse.Prototype.ROCP2_RBS_MyRewardsBase
select fANID
,CINID
,Gender
,Age_Group
,CAMEO_CODE_GRP
,Region
,MarketableByEmail
into Warehouse.Prototype.ROCP2_RBS_MyRewardsBase
from #cins2
where randrow <= 1000000   

CREATE INDEX IND_C on Warehouse.Prototype.ROCP2_RBS_MyRewardsBase(CINID);









/************************************************
*******3 Brand : base code for the top 250*******
************************************************/
--SELECT 'paste into DataBrandPub A7'

IF OBJECT_ID('tempdb..#masterretailerfile') IS NOT NULL DROP TABLE #masterretailerfile
SELECT BrandID
		,BrandName
	  ,[SS_AcquireLength]
      ,[SS_LapsersDefinition]
      ,[SS_WelcomeEmail]
	  ,cast(SS_Acq_Split*100 as int) as Acquire_Pct
into	#masterretailerfile
  FROM [Warehouse].[Relational].[MRF_ShopperSegmentDetails] a
  inner join warehouse.Relational.Partner p on a.PartnerID = p.PartnerID

  --select * from #masterretailerfile

IF OBJECT_ID('Prototype.ROCP2_BrandList_ForModel') IS NOT NULL DROP TABLE Prototype.ROCP2_BrandList_ForModel
CREATE TABLE Prototype.ROCP2_BrandList_ForModel
	(
	BrandName VARCHAR(150) NULL,
	BrandID SMALLINT NOT NULL PRIMARY KEY,
	AcquireL SMALLINT NULL,
	LapserL SMALLINT NULL,
	Acquire_Pct INT NULL
	)

IF OBJECT_ID('Prototype.ROCP2_BrandList_ForModel_Individual') IS NOT NULL DROP TABLE Prototype.ROCP2_BrandList_ForModel_Individual
CREATE TABLE Prototype.ROCP2_BrandList_ForModel_Individual
	(
	BrandName VARCHAR(150) NULL,
	BrandID SMALLINT NOT NULL PRIMARY KEY,
	AcquireL SMALLINT NULL,
	LapserL SMALLINT NULL,
	Acquire_Pct INT NULL
	)

IF @IndividualBrand = 0
BEGIN

IF OBJECT_ID('Prototype.ROCP2_BrandList') IS NOT NULL DROP TABLE Prototype.ROCP2_BrandList
SELECT	a.*,
	COALESCE(mrf.SS_AcquireLength,blk.acquireL,AcquireL0) as AcquireL,
	COALESCE (mrf.SS_LapsersDefinition,blk.LapserL,LapserL0) as LapserL,
	COALESCE(mrf.Acquire_Pct,blk.Acquire_Pct,Acquire_Pct0) as Acquire_Pct
INTO Prototype.ROCP2_BrandList
FROM	(
	SELECT	b.BrandID,
		b.BrandName,
		b.SectorID,
		---- Overrite big 4 : could consider other overrides -- and using MTR for current brands
		CASE
			WHEN Brandname IN ('Tesco', 'Asda','Sainsburys','Morrisons') THEN 3
			ELSE lk.acquireL
		END AS AcquireL0,
		CASE
			WHEN Brandname IN ('Tesco', 'Asda','Sainsburys','Morrisons') THEN 1
			ELSE lk.LapserL
		END AS LapserL0,
		Acquire_Pct as Acquire_Pct0,
		ROW_NUMBER() OVER (ORDER BY b.BrandID) as RowNo
		FROM Relational.Brand b WITH (NOLOCK) 
		INNER JOIN Prototype.ROCP2_AssessmentBrands ab
			ON b.BrandID = ab.BrandID
		LEFT JOIN Prototype.ROCP2_SegFore_SectorTimeFrame_LK lk
			ON lk.sectorid = b.sectorID
		WHERE	b.SectorID IN
			(
			SELECT	DISTINCT 
				SectorID 
			FROM Relational.BrandSector 
			WHERE SectorGroupID in (1,2) AND SectorName NOT IN ('Gambling')
			)
		)a
LEFT JOIN Prototype.ROCP2_SegFore_BrandTimeFrame_LK blk
	ON blk.brandid = a.brandID
LEFT JOIN #masterretailerfile mrf 
on mrf.BrandID = a.BrandID



INSERT INTO Prototype.ROCP2_BrandList_ForModel
SELECT	Brandname,
	BrandID,
	AcquireL,
	LapserL,
	Acquire_Pct
FROM Prototype.ROCP2_BrandList

--select * from Prototype.ROCP2_BrandList

END
ELSE
BEGIN


IF OBJECT_ID('Prototype.ROCP2_BrandList_Individual') IS NOT NULL DROP TABLE Prototype.ROCP2_BrandList_Individual
SELECT	a.*,
	COALESCE(mrf.SS_AcquireLength,blk.acquireL,AcquireL0) as AcquireL,
	COALESCE (mrf.SS_LapsersDefinition,blk.LapserL,LapserL0) as LapserL,
	COALESCE(mrf.Acquire_Pct,blk.Acquire_Pct,Acquire_Pct0) as Acquire_Pct
INTO Prototype.ROCP2_BrandList_Individual
FROM	(
	SELECT	b.BrandID,
		b.BrandName,
		b.SectorID,
		---- Overrite big 4 : could consider other overrides -- and using MTR for current brands
		CASE
			WHEN Brandname IN ('Tesco', 'Asda','Sainsburys','Morrisons') THEN 3
			ELSE lk.acquireL
		END AS AcquireL0,
		CASE
			WHEN Brandname IN ('Tesco', 'Asda','Sainsburys','Morrisons') THEN 1
			ELSE lk.LapserL
		END AS LapserL0,
		Acquire_Pct as Acquire_Pct0,
		ROW_NUMBER() OVER (ORDER BY b.BrandID) as RowNo
		FROM Relational.Brand b WITH (NOLOCK) 
		LEFT JOIN Prototype.ROCP2_SegFore_SectorTimeFrame_LK lk
			ON lk.sectorid = b.sectorID
		WHERE	b.SectorID IN
			(
			SELECT	DISTINCT 
				SectorID 
			FROM Relational.BrandSector 
			WHERE SectorGroupID in (1,2) AND SectorName NOT IN ('Gambling')
			)
			AND b.BrandID = @IndividualBrand
	)a
LEFT JOIN Prototype.ROCP2_SegFore_BrandTimeFrame_LK blk
	ON blk.brandid = a.brandID
LEFT JOIN #masterretailerfile mrf 
on mrf.BrandID = a.BrandID




INSERT INTO Prototype.ROCP2_BrandList_ForModel_Individual
SELECT	Brandname,
	BrandID,
	AcquireL,
	LapserL,
	Acquire_Pct
FROM Prototype.ROCP2_BrandList_Individual


END



END


--select * from  warehouse.Prototype.ROCP2_BrandList_Individual