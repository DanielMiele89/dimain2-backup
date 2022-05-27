
/***************************************************************************
Author:	Main Code written by Jenny Hurley - SP Created by Suraj Chahal
Date: 20-01-2016
Purpose: Building Natural Sales
***************************************************************************/
CREATE PROCEDURE [Prototype].[ROCP2_Code_02_FindNaturalSales_V2]
	(
	@IndividualBrand BIT
	)
AS
BEGIN

--DECLARE	@IndividualBrand BIT
--SET @IndividualBrand = 1


IF OBJECT_ID ('tempdb..#WeekBuild') IS NOT NULL DROP TABLE #WeekBuild
SELECT	*,
	ROW_NUMBER() OVER (ORDER BY StartDate) as WeekNo
INTO #WeekBuild
FROM	(
	SELECT	WeekNum,
		MIN(StartDate) as StartDate,
		MAX(Enddate) as EndDate
	FROM Prototype.ROCP2_SegFore_Rundaylk 
	WHERE BuildWeek = 1
	GROUP BY WeekNum 
	) a


IF OBJECT_ID ('tempdb..#Dates') IS NOT NULL DROP TABLE #Dates
select	DATEADD(DAY,-1,MIN(Startdate)) as EndDate,   -- the segmentation enddate
	MIN(Startdate) as fStartDate,
	MAX(Enddate) as fEnddate
into #Dates
from #WeekBuild

--select * from #dates
--select * from #weekbuild


IF OBJECT_ID ('tempdb..#SegmentList') IS NOT NULL DROP TABLE #SegmentList
CREATE TABLE #SegmentList
	(
	Segment VARCHAR(25) NULL,
	RowNo SMALLINT NULL
	)

INSERT INTO #SegmentList
VALUES	('Acquire',1),
	('Winback',2),
	('WinbackPrime',3),
	('Retain',4),
	('Grow',5),
	('AllBase',6)

CREATE CLUSTERED INDEX IDX_Seg ON #SegmentList (Segment)
CREATE NONCLUSTERED INDEX IDX_RowNo ON #SegmentList (RowNo)


IF OBJECT_ID ('tempdb..#SegmentSummary0') IS NOT NULL DROP TABLE #SegmentSummary0
CREATE TABLE #SegmentSummary0
	(
        Segment VARCHAR(25) NULL,
	Counts INT NULL,
	Avgw_sales MONEY NULL,
	Avgw_spder FLOAT NULL,
	Avgw_Sales_InStore MONEY NULL,
        Avgw_spder_InStore REAL NULL
	)			
CREATE CLUSTERED INDEX IDX_Seg ON #SegmentSummary0 (Segment)


--IF OBJECT_ID ('Prototype.ROCP2_SegFore_RBSSeg_NaturalSales') IS NOT NULL DROP TABLE Prototype.ROCP2_SegFore_RBSSeg_NaturalSales
--CREATE TABLE Prototype.ROCP2_SegFore_RBSSeg_NaturalSales
--	(
--        BrandID SMALLINT NULL,
--        Segment VARCHAR(25) NULL,
--        Timepoint SMALLINT NULL,
--	Counts INT NULL,
--	AVGw_Sales MONEY NULL,
--	AVGw_Spder REAL NULL,
--	AVGw_Sales_InStore MONEY NULL,
--        AVGw_Spder_InStore REAL NULL							
--	)

--CREATE CLUSTERED INDEX IDX_BrandID ON Prototype.ROCP2_SegFore_RBSSeg_NaturalSales (BrandID)	
--CREATE NONCLUSTERED INDEX IDX_Seg ON Prototype.ROCP2_SegFore_RBSSeg_NaturalSales (Segment)

/*****************************************************************/
IF OBJECT_ID ('tempdb..#Brand') IS NOT NULL DROP TABLE #Brand
CREATE TABLE #Brand
	(
	BrandID SMALLINT NOT NULL,
	BrandName VARCHAR(75) NULL,
	Sector SMALLINT,
	AcquireL0 SMALLINT,
	LapserL0 SMALLINT,
	Acquire_Pct0 INT,
	RowNo SMALLINT,
	AcquireL SMALLINT,
	LapserL SMALLINT,
	Acquire_Pct INT
	PRIMARY KEY (BrandID)
	)

IF @IndividualBrand <> 0
BEGIN

INSERT INTO #Brand
SELECT *
FROM Prototype.ROCP2_Brandlist_Individual
--
DELETE FROM Prototype.ROCP2_SegFore_RBSSeg_NaturalSales
WHERE BrandID IN (SELECT BrandID FROM #Brand)

END
ELSE
BEGIN

INSERT INTO #Brand
SELECT *
FROM Prototype.ROCP2_Brandlist

TRUNCATE TABLE Prototype.ROCP2_SegFore_RBSSeg_NaturalSales

END
/*****************************************************************/

CREATE NONCLUSTERED INDEX IDX_AcqL ON #Brand (AcquireL)
CREATE NONCLUSTERED INDEX IDX_LapL ON #Brand (LapserL)
CREATE NONCLUSTERED INDEX IDX_RowNo ON #Brand (RowNo)

-- select * from #Brand


/***************************************
****Find CCIDs for Assessment Brands****
***************************************/
DECLARE @BrandID SMALLINT,
	@RowNo SMALLINT

SET @RowNo = 1

WHILE @RowNo <=	(SELECT MAX(RowNo) from #Brand)       ---Limit to just 7 for trial

BEGIN

SET @BrandID = (SELECT BrandID FROM #Brand where rowno=@rowno)

IF OBJECT_ID ('tempdb..#CCIDs') IS NOT NULL DROP TABLE #CCIDs
SELECT  ConsumerCombinationID,
	cc.BrandID
INTO #CCIDs 
FROM Relational.ConsumerCombination cc (NOLOCK)
WHERE	cc.BrandID = @BrandID
	AND IsUKSpend = 1

CREATE CLUSTERED INDEX IND_CC on #CCIDs(ConsumerCombinationID)
CREATE NONCLUSTERED INDEX IDX_BID ON #CCIDs (BrandID)


/********************************************************************************
Build Natural Counts data - Forecast data is the latest 4 weeks (of a full month)
********************************************************************************/
DECLARE	@BuildEnd DATE,
	@TimeBuild DATE,
	@TValue INT,
	@Lapser DATE,
	@LasperL INT

SET @TValue = 1 --- starting at point.  The hard code lapsers values here will hit at months when lapsers should first appear. 
-- Note that the structure is SET up so that having a brand centric timepoint value is possible.  however at this stage I don't have time to refine this for a flexiable lasper time etc..

WHILE @TValue <= (SELECT AcquireL+1 FROM #brand WHERE BrandID = @BrandID)  -- once retail length is full then loop ends.  will mean not limit to top end... Need to make sure Acquire materation is reached. 

BEGIN

SET @LasperL = (SELECT LapserL FROM #Brand where BrandID = @BrandID)
SET @BuildEnd = (SELECT EndDate FROM #Dates)

SET @TimeBuild = DATEADD(MONTH,-@TValue,@BuildEnd)
SET @Lapser = DATEADD(MONTH,-@LasperL,@BuildEnd)


---------- Extracting the date base date frame
IF OBJECT_ID('tempdb..#SpendHistory_t1') IS NOT NULL DROP TABLE #SpendHistory_t1
SELECT	ct.CINID,
	BrandID,
	SUM(Amount) as Sales,
	COUNT(1) as Trans,
	MAX(CASE
		WHEN TranDate BETWEEN @Lapser AND @BuildEnd THEN 1
		ELSE NULL
	END) as SpderLastx,
	DATEDIFF(DAY,MAX(tranDate),@BuildEnd) as DaysSince
INTO #SpendHistory_t1
FROM Relational.ConsumerTransaction ct (NOLOCK) 
INNER JOIN Prototype.ROCP2_SegFore_FixedBase c (NOLOCK)
	ON c.CINID = ct.CINID
INNER JOIN #CCIDs cc
	ON cc.ConsumerCombinationID = ct.ConsumerCombinationID
WHERE	TranDate BETWEEN @TimeBuild AND @BuildEnd --- CHANGE THIS AND BUILD TO RETAILER MAX
	AND isRefund = 0 --- exclude refunds
	AND cc.BrandID = @BrandID 
	AND isonline=0                         ---- Limiting to InStore as felt like most publishers at point of segmentation would only have Instore
GROUP BY ct.CINID, BrandID


--Spenders only NTile bands
IF OBJECT_ID ('tempdb..#Spder_Bands') IS NOT NULL DROP TABLE #Spder_Bands
SELECT	NTILE(3) OVER(ORDER BY Sales DESC) as SalesP3,
	NTILE(3) OVER(ORDER BY Trans DESC) as FreqP3,
	NTILE(3) OVER(ORDER BY Dayssince) as RecentP3,
	*
INTO #Spder_Bands
FROM #SpendHistory_t1

---- Lapser cutpoints
IF OBJECT_ID ('tempdb..#Spder_BandsL') IS NOT NULL DROP TABLE #Spder_BandsL
SELECT	NTILE(3) OVER(ORDER BY Sales DESC) as SalesP3,
	NTILE(3) OVER(ORDER BY Trans DESC) as FreqP3,
	NTILE(3) OVER(ORDER BY Dayssince) as RecentP3,
	*
INTO #Spder_BandsL
FROM #spendHistory_t1
WHERE SpderLastx is NULL


IF OBJECT_ID ('tempdb..#CUTOFFS') IS NOT NULL DROP TABLE #CUTOFFS
SELECT	MIN(CASE WHEN SalesP3 = 1 THEN Sales ELSE NULL END) as TopSalesCut,
	AVG(Trans) as ATF
INTO #CUTOFFS
FROM #Spder_Bands
--


-- When no lapsers this is null so need to make sure it will still work in the process
IF OBJECT_ID ('tempdb..#CUTOFFSL') IS NOT NULL DROP TABLE #CUTOFFSL
SELECT	MIN(CASE WHEN SalesP3 = 1 THEN Sales ELSE NULL END) as TopSalesCut,
	AVG(Trans) as ATF
INTO #CUTOFFSL
FROM #Spder_BandsL
--

/**********************************
******Getting Forecast Spend*******
**********************************/
DECLARE	@fStartDate DATE,
	@fEndDate DATE

SET @fStartDate = (SELECT fStartDate FROM #dates)
SET @fEndDate = (select fEndDate from #dates)

IF OBJECT_ID('tempdb..#ForecastSpend') IS NOT NULL DROP TABLE #ForecastSpend
SELECT	ct.CINID,
	TranDate,
	SUM(Amount) as Fsales,
	SUM(CASE WHEN isOnline = 0 THEN Amount ELSE NULL END) as Fsales_InStore
INTO #ForecastSpend
FROM Relational.ConsumerTransaction ct WITH (NOLOCK)
INNER JOIN Prototype.ROCP2_SegFore_FixedBase c
	on c.cinid = ct.cinid
INNER JOIN #CCIDs cc
	on cc.ConsumerCombinationID = ct.ConsumerCombinationID
WHERE	TranDate BETWEEN @fStartDate AND @fEndDate
	AND cc.BrandID = @BrandID -- building with single brand  
	AND isRefund = 0 --- exclude refunds
GROUP BY ct.CINID, TranDate


IF OBJECT_ID('tempdb..#ForecastSpend2') IS NOT NULL DROP TABLE #ForecastSpend2
SELECT	t.*,
	w.Weekno
INTO #ForecastSpend2
FROM #ForecastSpend t 
CROSS JOIN #WeekBuild w
WHERE t.TranDate BETWEEN w.StartDate AND w.EndDate


/**********************************************************************
Building the customer universe - Reduce down as don't need all of this
**********************************************************************/
/*
Acquire	1
AllBase	6
Grow	5
Retain	4
Winback	2
WinbackPrime	3
*/


IF OBJECT_ID ('tempdb..#Universe1') IS NOT NULL DROP TABLE #Universe1
SELECT	a.*,
	CASE WHEN Segment = 'Acquire' THEN 1 ELSE 0 END as Acquire,
	CASE WHEN Segment = 'WinbackPrime' THEN 1 ELSE 0 END as WinbackPrime,
	CASE WHEN Segment = 'Winback' THEN 1 ELSE 0 END as Winback,
	CASE WHEN Segment = 'Retain' THEN 1 ELSE 0 END as Retain,
	CASE WHEN Segment = 'Grow' THEN 1 ELSE 0 END as Grow,
	1 as AllBase
INTO #Universe1
FROM	(
	SELECT	b.CINID,
		CASE 
			WHEN s.trans IS NULL THEN 'Acquire'
			WHEN s.SpderLastx IS NULL AND s.trans IS NOT NULL AND (Sales >= COALESCE(cl.Topsalescut,0) OR Trans >= COALESCE(cl.ATF,0)*3) THEN 'WinbackPrime'
			WHEN s.SpderLastx IS NULL AND s.trans IS NOT NULL THEN 'Winback'
			WHEN s.trans IS NOT NULL AND (s.sales>=c.Topsalescut OR Trans>=c.ATF*3) THEN 'Retain'
			WHEN s.trans IS NOT NULL THEN 'Grow'
			ELSE 'ERROR'
		END as Segment
	FROM Prototype.ROCP2_SegFore_FixedBase b
	LEFT JOIN #SpendHistory_t1 s
		ON b.CINID = s.CINID
	CROSS JOIN #CutOffs c 
	CROSS JOIN #CutOffsl cl
	)a


/********************************
*****Summarise to get counts*****
********************************/
DECLARE @seq TINYINT,
	@SQL VARCHAR(8000),
	@VarName VARCHAR(50)
SET @seq = 1
WHILE @seq IS NOT NULL
BEGIN
	SELECT @VarName = Segment FROM #SegmentList WHERE RowNo = @seq

	DECLARE @NoWeeks real
	SET @NoWeeks = (select max(WeekNo) from #WeekBuild)
	SET @SQL = '

SELECT	''' +@VarName+ ''' as CustomerType,
	SUM(Sales) / '+cast(@noweeks as varchar)+' as AVGw_Sales,
	SUM(Spender)/ '+cast(@noweeks as varchar)+' as AVGw_spder,
	SUM(Sales_Instore) / '+cast(@noweeks as varchar)+' as AVGw_Sales_InStore,
	SUM(Spender_Instore)/ '+cast(@noweeks as varchar)+' as AVGw_spder_InStore
INTO #ForecastOut
FROM	(
	SELECT	WeekNo,
		SUM(t.Fsales) as sales,
		COUNT(distinct t.cinid) as spender,
		SUM(t.Fsales_InStore) as sales_Instore,
		COUNT(DISTINCT case when Fsales_InStore>0 then t.cinid end) as spender_Instore
	FROM #Universe1 b
	INNER JOIN #ForecastSpend2 t
		on b.CINID = t.CINID
	WHERE '+@Varname+'=1    
	GROUP BY Weekno
	)a

SELECT	'''+@varname+''' as Customertype,
	COUNT(DISTINCT CINID) as Cardholders
INTO #CountsOut
FROM #Universe1
WHERE '+@varname+' = 1    

--Joining the table to get outputs
SELECT	c.*,
	f.avgw_Sales,
	f.avgw_spder,
	f.avgw_Sales_InStore,
	f.avgw_spder_InStore
INTO #Outall
FROM #CountsOut c
LEFT JOIN #forecastout f
	on c.CustomerType = f.CustomerType

INSERT INTO #segmentsummary0
SELECT	*
FROM #OutAll
'

exec(@sql)
	SELECT @seq = MIN(RowNo) FROM #SegmentList WHERE RowNo > @seq

END

--- Add into a perm table
DECLARE @Base INT
SET @Base = (SELECT COUNT(DISTINCT CINID) FROM Prototype.ROCP2_SegFore_FixedBase)


INSERT INTO Prototype.ROCP2_SegFore_RBSSeg_NaturalSales
SELECT	@BrandID,
	Segment,
	@TValue,
	COUNTS,
	AVGw_sales,
	AVGw_spder,
	AVGw_Sales_InStore,
	AVGw_spder_InStore
FROM #SegmentSummary0


SET @TValue = @TValue + 3

TRUNCATE TABLE #Segmentsummary0

END  -- This ends the time loop

SET @rowno = @rowno +1
END  -- This ends the brand loop

-- 
--select * from Staging.ROCP2_SegFore_RBSSeg_NaturalSales

END


