
/****************************************************************************
CAMPAIGN PLANNING TOOL - SCRIPT 1
---------------------------------
-- Author: Suraj Chahal
-- Create date: 10/11/2015
-- Description: Build the following tables used for Campaign Planning

--Staging.CampaignPlanning_Brand - analysed partner
--Staging.CampaignPlanning_Brand_CCID - analysed MiDs
--Staging.CampaignPlanning_AllCustomers - whole customer universe
--Staging.CampaignPlanning_Headroom - final HTM classification used in Planning
--Staging.CampaignPlanning_ActivatedBase

BUILDS Staging.CampaignPlanning_TriggerMember
****************************************************************************/

CREATE PROCEDURE Prototype.[CampaignPlanning_1_UniverseBuild]
									
AS
BEGIN
	SET NOCOUNT ON;

/*********************************************************
************Curently Active MarketableUniverse************
*********************************************************/
--**Get all the currently active marketable customers.
--**Flag their birthday and add but not set an engagement flag
/*
CREATE TABLE Staging.CampaignPlanning_AllCustomers
	(
	CINID INT NOT NULL,
	FanID INT NOT NULL,
	ActivatedDate DATE NULL,
	DOB DATE NULL,
	Engaged BIT NULL
	)

ALTER TABLE Staging.CampaignPlanning_AllCustomers
ADD PRIMARY KEY (CINID,FanID)
*/

DECLARE @time DATETIME,
        @msg VARCHAR(2048)


TRUNCATE TABLE Staging.CampaignPlanning_AllCustomers

INSERT INTO Staging.CampaignPlanning_AllCustomers
SELECT	DISTINCT 
	cl.CINID,
	c.FanID,
	ActivatedDate,
	DOB, 
	1 as Engaged
FROM Relational.CINList cl   
INNER JOIN Relational.Customer c   
	ON c.SourceUID = cl.CIN
WHERE	CurrentlyActive = 1 
	AND MarketableByEmail = 1

ALTER INDEX ALL ON Staging.CampaignPlanning_AllCustomers REBUILD

/***********************************************
************Gather Retailer BrandIDs************
***********************************************/
/*
CREATE TABLE Staging.CampaignPlanning_Brand
	(
	RowNo SMALLINT NOT NULL,
	PartnerID SMALLINT PRIMARY KEY NOT NULL,
	BrandID SMALLINT NOT NULL,
	BrandName VARCHAR(150) NOT NULL,
	Halo NUMERIC(32,8) NULL,
	Margin NUMERIC(32,2) NULL,
	[Override] NUMERIC(32,2) NULL,
	BaseOffer NUMERIC(32,2) NULL,
	RetailerTypeID TINYINT NULL,
	isLive BIT NOT NULL DEFAULT 0,
	RetailerClass VARCHAR(20) NULL
	)
	
CREATE NONCLUSTERED INDEX IDX_RN ON Staging.CampaignPlanning_Brand (RowNo)
*/

--**Truncate previous table
TRUNCATE TABLE Staging.CampaignPlanning_Brand


--**Insert new entries
INSERT INTO Staging.CampaignPlanning_Brand (RowNo,PartnerID,BrandID,BrandName)
SELECT	ROW_NUMBER() OVER(ORDER BY a.PartnerID) as RowNo,
	PartnerID,
	BrandID,
	BrandName
FROM	(
	SELECT	p.PartnerID,
		p.BrandID,
		p.BrandName
	FROM Relational.Partner_CBPDates b
	INNER JOIN Relational.Partner p
		ON b.PartnerID = p.PartnerID
	WHERE	GETDATE() <= COALESCE(Scheme_EndDate,GETDATE())
		AND b.PartnerID NOT IN (4433,4447)
	)a


/************************************
******Populate additional fields*****
************************************/
IF OBJECT_ID('tempdb..#Margin') IS NOT NULL DROP TABLE #Margin
SELECT	PartnerID,
	Margin
INTO #Margin
FROM Warehouse.Relational.Master_Retailer_Table
WHERE Margin > 0

IF OBJECT_ID('tempdb..#Margin2') IS NOT NULL DROP TABLE #Margin2
SELECT	BrandID,
	Margin
INTO  #Margin2
FROM MI.BrandMargin
WHERE Margin > 0


IF OBJECT_ID('tempdb..#Halo') IS NOT NULL DROP TABLE #Halo
SELECT	b.BrandID, 
	CASE 
		WHEN SUM(PostActivationSales) > SUM(IncrementalSales) THEN SUM(IncrementalSales)/(SUM(PostActivationSales)-SUM(IncrementalSales))
		ELSE 0.12
	END as Halo
INTO #Halo
FROM Stratification.CBPCardUsageUplift_Results_bySector s 
INNER JOIN Relational.Brand b
	on s.SectorID = b.SectorID
WHERE	MonthID BETWEEN (SELECT MAX(Monthid)-3 FROM Stratification.CBPCardUsageUplift_Results_bySector)
	AND (SELECT MAX(MonthID) FROM Stratification.CBPCardUsageUplift_Results_bySector)
GROUP BY b.BrandID


IF OBJECT_ID ('tempdb..#Brand_Update') IS NOT NULL DROP TABLE #Brand_Update
SELECT	s.PartnerID,
	COALESCE(MAX(h.Halo),0.12) as Halo,
	MAX(COALESCE(CAST(m.Margin AS VarChar),CAST(m2.Margin AS VARCHAR),NULL)) as Margin,
	MAX(CASE
		WHEN s.PartnerID IN (3960,4433,4447) THEN 0
		ELSE  COALESCE(Override_Pct_of_CBP,0.35)
	END) as [Override],
	MAX(COALESCE(1.0*io.TopCashbackRate/100,0)) as BaseOffer,
	CASE
		WHEN MAX(d.Scheme_StartDate) IS NULL THEN NULL
		WHEN MAX(COALESCE(1.0*io.TopCashbackRate/100,0)) > 0 AND MAX(bo.ClientServicesRef) IS NOT NULL THEN 1 
		WHEN MAX(COALESCE(1.0*io.TopCashbackRate/100,0)) = 0 THEN 2
		ELSE 0
	END as RetailerTypeID,
	MAX(CASE WHEN io.IronOfferID IS NULL AND d.Scheme_StartDate IS NULL  THEN 0 ELSE 1 END) as isLive
INTO #Brand_Update
FROM Staging.CampaignPlanning_Brand  s
LEFT JOIN #Margin m
	ON m.PartnerID = s.PartnerID
LEFT JOIN #Margin2 m2
	ON m2.BrandID = s.BrandID
LEFT JOIN #Halo h
	ON h.BrandID = s.BrandID
LEFT JOIN Relational.Master_Retailer_Table r
	ON r.PartnerID = s.PartnerID 
LEFT JOIN Stratification.ReportingBaseOffer bo
	ON bo.PartnerID = s.PartnerID 
LEFT JOIN Relational.IronOffer io
	ON io.IronOfferID = bo.BaseOfferID 
	AND (io.EndDate IS NULL OR io.Enddate >= GETDATE())
	AND IsSignedOff = 1
LEFT JOIN Relational.Partner_CBPDates d
	ON d.PartnerID=s.PartnerID
	AND GETDATE() BETWEEN d.Scheme_StartDate and COALESCE(Scheme_EndDate, GETDATE()) 
GROUP BY S.PartnerID


IF OBJECT_ID('tempdb..#Margin') IS NOT NULL DROP TABLE #Margin
IF OBJECT_ID('tempdb..#Margin2') IS NOT NULL DROP TABLE #Margin2
IF OBJECT_ID('tempdb..#Halo') IS NOT NULL DROP TABLE #Halo


UPDATE Staging.CampaignPlanning_Brand
SET	Halo = bu.Halo,
	Margin = bu.Margin,
	[Override] = bu.[Override],
	BaseOffer = bu.BaseOffer,
	RetailerTypeID = bu.RetailerTypeID,
	isLive = bu.isLive
FROM #Brand_Update bu
INNER JOIN Staging.CampaignPlanning_Brand br
	ON bu.PartnerID = br.PartnerID


IF OBJECT_ID('tempdb..#RetailerClass') IS NOT NULL DROP TABLE #RetailerClass
SELECT	PartnerID,
	CASE
		WHEN CustomerCountThisYear >= (0.05*TotalCustomerCountThisYear) THEN 'Known Retailer'
		WHEN ATV >= 125 THEN 'High ATV'
		WHEN ATV >= 25 AND ATV < 125 THEN 'Medium ATV'
		ELSE 'Low ATV'
	END as RetailerClass
INTO #RetailerClass
FROM	(
	SELECT	b.PartnerID,
		(a.SpendThisYear/a.TranCountThisYear) as ATV,
		a.CustomerCountThisYear,
		c.TotalCustomerCountThisYear
	FROM [MI].[TotalBrandSpend_CBP] a
	INNER JOIN Staging.CampaignPlanning_Brand b
		ON a.BrandID = b.BrandID
	CROSS JOIN MI.GrandTotalCustomersFixedBase_CBP c
	)a



UPDATE Staging.CampaignPlanning_Brand
SET RetailerClass = rc.RetailerClass
FROM Staging.CampaignPlanning_Brand br
INNER JOIN #RetailerClass rc
	ON br.PartnerID = rc.PartnerID

ALTER INDEX ALL ON Staging.CampaignPlanning_Brand REBUILD

/******************************************
******************Dates********************
******************************************/
DECLARE	@OldDate AS DATE
SET @OldDate = (SELECT MaxDate FROM Staging.CampaignPlanning_MaxTranDate)

IF OBJECT_ID('Staging.CampaignPlanning_MaxTranDate') IS NOT NULL DROP TABLE Staging.CampaignPlanning_MaxTranDate
SELECT	MAX(Trandate) as MaxDate
INTO Warehouse.Staging.CampaignPlanning_MaxTrandate
FROM Relational.ConsumerTransaction (NOLOCK)
WHERE	Trandate >= @OldDate

CREATE CLUSTERED INDEX IDX_TD ON Staging.CampaignPlanning_MaxTrandate (MaxDate)



/************************************************************************
*******Cal 4 weeks ago StartDate and EndDate for natural behaviour*******
************************************************************************/
IF OBJECT_ID('tempdb..#Cal') IS NOT NULL DROP TABLE #Cal
SELECT  Stratification.leastdate(CAST(CAST(DATEDIFF(WEEK, 0, GETDATE())*7-7*4-7 AS DATETIME) AS DATE) , CAST(CAST(DATEDIFF(WEEK, 0, MaxDate)*7-7*4 AS DATETIME) AS DATE)) as StartDate, 
	Stratification.leastdate(CAST(CAST(DATEDIFF(WEEK, 0, GETDATE())*7-1-7 AS DATETIME) AS DATE) , CAST(CAST(DATEDIFF(WEEK, 0, MaxDate)*7-1 AS DATETIME) AS DATE)) as EndDate
INTO #Cal
FROM Staging.CampaignPlanning_MaxTranDate


/******************************************
*******28 days before natural spend********
******************************************/
IF OBJECT_ID('tempdb..#CalTrans') IS NOT NULL DROP TABLE #CalTrans
SELECT	DATEADD(DAY,-28,StartDate) as StartDate, 
	DATEADD(DAY,-1,StartDate) EndDate
INTO #CalTrans
FROM #Cal



IF OBJECT_ID('tempdb..#CampaignPlanning_NonEngagedCustomers') IS NOT NULL DROP TABLE #CampaignPlanning_NonEngagedCustomers
SELECT	a.*
INTO #CampaignPlanning_NonEngagedCustomers
FROM Staging.CampaignPlanning_AllCustomers a
INNER JOIN Relational.Customers_ReducedFrequency_ExcludedEver s
	ON s.Fanid = a.FanID
INNER JOIN #Cal c 
	ON c.StartDate BETWEEN s.StartDate AND COALESCE(s.EndDate,'2999-01-01')
WHERE TestGroup = 'C'

CREATE CLUSTERED INDEX IND_Tactical_FanID ON #CampaignPlanning_NonEngagedCustomers(CINID);
CREATE NONCLUSTERED INDEX IND_FD ON #CampaignPlanning_NonEngagedCustomers (FanID);


/*****************************************************************
*******Update the All customers table with engagement flag********
*****************************************************************/
UPDATE Staging.CampaignPlanning_AllCustomers
SET Engaged = 0 
FROM Staging.CampaignPlanning_AllCustomers c
INNER JOIN #CampaignPlanning_NonEngagedCustomers e
	ON c.FanID = e.FanID


IF OBJECT_ID('tempdb..#CampaignPlanning_NonEngagedCustomers') IS NOT NULL DROP TABLE #CampaignPlanning_NonEngagedCustomers;
ALTER INDEX ALL ON Staging.CampaignPlanning_AllCustomers REBUILD



/***********************************************************
*******Create Staging.CampaignPlanning_TriggerMember********
***********************************************************/
--IF OBJECT_ID('Staging.CampaignPlanning_TriggerMember') IS NOT NULL DROP TABLE Staging.CampaignPlanning_TriggerMember
--CREATE TABLE Staging.CampaignPlanning_TriggerMember
--	(
--	FanID INT NOT NULL,
--	PartnerID INT NOT NULL,
--	HTMID INT NULL,
--	CompetitorShopper4wk BIT NOT NULL DEFAULT 0,
--	Homemover BIT NOT NULL DEFAULT 0,
--	Lapser BIT NOT NULL DEFAULT 0,
--	Student	BIT NOT NULL DEFAULT 0,
--	AcquireMember BIT NOT NULL DEFAULT 0,
--	SuperSegmentID TINYINT NULL,
--	Total_SalesValue_Wk1 NUMERIC(32,2) NULL,
--	Total_Transactions_Wk1 NUMERIC(32,2) NULL,
--	HeatMapID SMALLINT NULL,
--	Gender CHAR(1) NULL,
--	MinAge SMALLINT NULL,
--	MaxAge SMALLINT NULL,
--	CAMEO_CODE_GROUP VARCHAR(2) NULL,
--	SocialClass VARCHAR(2) NULL,
--	DriveTimeBandID TINYINT NULL,
--	ResponseIndexScore NUMERIC(32,2) NULL,
--	NonCoreBO_CSRef VARCHAR(12) NULL,
--	)


TRUNCATE TABLE Staging.CampaignPlanning_TriggerMember


ALTER INDEX IDX_F ON Staging.[CampaignPlanning_TriggerMember]	 DISABLE
ALTER INDEX IDX_P ON Staging.[CampaignPlanning_TriggerMember]	 DISABLE
ALTER INDEX IDX_H ON Staging.[CampaignPlanning_TriggerMember]	 DISABLE
ALTER INDEX IDX_NCBO ON Staging.[CampaignPlanning_TriggerMember] DISABLE
ALTER INDEX IDX_G ON Staging.[CampaignPlanning_TriggerMember]	 DISABLE
ALTER INDEX IDX_L ON Staging.[CampaignPlanning_TriggerMember]	 DISABLE
ALTER INDEX IDX_S ON Staging.[CampaignPlanning_TriggerMember]	 DISABLE
ALTER INDEX IDX_C ON Staging.[CampaignPlanning_TriggerMember]	 DISABLE
ALTER INDEX IDX_St ON Staging.[CampaignPlanning_TriggerMember]	 DISABLE


SELECT @msg = 'Populate TriggerMember with FanID, PartnerID'
EXEC Warehouse.Staging.oo_TimerMessage @msg, @time OUTPUT
---------------------------------------------------------

DECLARE @PartnerID INT,
	@StartRow INT

SET @StartRow = 1
SET @PartnerID = (SELECT PartnerID FROM Staging.CampaignPlanning_Brand WHERE RowNo = @StartRow)

WHILE @StartRow <= (SELECT MAX(RowNo) FROM Staging.CampaignPlanning_Brand)

BEGIN
		INSERT INTO Staging.CampaignPlanning_TriggerMember (FanID, PartnerID)
		SELECT	acb.FanID,
			b.PartnerID			
		FROM Staging.CampaignPlanning_AllCustomers acb
		INNER JOIN Staging.CampaignPlanning_Brand b
			ON b.PartnerID = @PartnerID
		
	SET @StartRow = @StartRow+1
	SET @PartnerID = (SELECT PartnerID FROM Staging.CampaignPlanning_Brand WHERE RowNo = @StartRow) 

END

--ALTER TABLE Staging.CampaignPlanning_TriggerMember
--ADD CONSTRAINT pk_FanP PRIMARY KEY (FanID,PartnerID)

/******************************************************************
**********Build Staging.CampaignPlanning_Brand_CCID**********
******************************************************************/
--Table includes all CCIDs for Partners
IF OBJECT_ID('Staging.CampaignPlanning_Brand_CCID') IS NOT NULL DROP TABLE Staging.CampaignPlanning_Brand_CCID
SELECT	DISTINCT
	p.PartnerID,
	m.ConsumerCombinationID
INTO Staging.CampaignPlanning_Brand_CCID 
FROM Relational.ConsumerCombination m (NOLOCK)
INNER JOIN Staging.CampaignPlanning_Brand p
	ON m.BrandID = p.BrandID
WHERE IsUKSpend = 1

CREATE CLUSTERED INDEX IND ON Staging.CampaignPlanning_Brand_CCID (ConsumerCombinationID)



SELECT @msg = 'Update Trigger Flags'
EXEC Warehouse.Staging.oo_TimerMessage @msg, @time OUTPUT
---------------------------------------------------------

/********************************************************
*******************Update Trigger Flags******************
********************************************************/
--**Homemover Update
UPDATE Staging.CampaignPlanning_TriggerMember
SET Homemover = 1
WHERE FanID IN	(
		SELECT	DISTINCT
			FanID
		FROM Relational.Homemover_Details h
		INNER JOIN #CalTrans cal
			ON h.LoadDate BETWEEN cal.StartDate AND  cal.Enddate
		)


--**Student Update
UPDATE Staging.CampaignPlanning_TriggerMember
SET Student = 1
WHERE FanID IN	(
		SELECT	DISTINCT
			FanID
		FROM Relational.CBP_StudentAccountHolders
		)


--**CompetitorShopper4wk Update
--Find Competitors
IF OBJECT_ID ('tempdb..#CompetitorBrands') IS NOT NULL DROP TABLE #CompetitorBrands
SELECT	b.BrandID,
	b.PartnerID,
	CompetitorID
INTO #CompetitorBrands
FROM Staging.CampaignPlanning_Brand b
INNER JOIN Relational.BrandCompetitor bc
	ON b.BrandID = bc.BrandID


--Find Competitor CCIDS
IF OBJECT_ID ('tempdb..#CompetitorCCIDs') IS NOT NULL DROP TABLE #CompetitorCCIDs
SELECT	cb.CompetitorID,
	cb.BrandID,
	cb.PartnerID,
	ConsumerCombinationID
INTO #CompetitorCCIDs
FROM Relational.ConsumerCombination cc (NOLOCK)
INNER JOIN #CompetitorBrands cb
	ON cc.BrandID = cb.CompetitorID
--(182927 row(s) affected)

CREATE CLUSTERED INDEX IDX_CCID ON #CompetitorCCIDs (ConsumerCombinationID)


/***************************************************
--Find Competitor Transactors within tran date range
***************************************************/
DECLARE	@StartDate2 AS DATE,
	@Enddate2 AS DATE

SET @StartDate2 = (SELECT Startdate FROM #CalTrans)
SET @Enddate2 = (SELECT Enddate FROM #CalTrans)

IF OBJECT_ID('tempdb..#CompetitorTransactors') IS NOT NULL DROP TABLE #CompetitorTransactors
SELECT	DISTINCT
	FanID,
	cc.PartnerID
INTO #CompetitorTransactors
FROM Relational.ConsumerTransaction ct (NOLOCK)
INNER JOIN Staging.CampaignPlanning_AllCustomers t
	ON t.CINID = ct.CINID
INNER JOIN #CompetitorCCIDs cc 
	ON cc.ConsumerCombinationID = ct.ConsumerCombinationID
WHERE	ct.TranDate BETWEEN @StartDate2 AND @EndDate2
	AND Amount > 0

CREATE CLUSTERED INDEX IDX_Fan ON #CompetitorTransactors (FanID,PartnerID)


/***********************************************************************
--Find a customers last transaction with a PARTNER within the date range
***********************************************************************/
DECLARE	@EndDate3 AS DATE
SET @EndDate3 = (SELECT EndDate FROM #CalTrans)

IF OBJECT_ID('tempdb..#Partner_LastTransactions') IS NOT NULL DROP TABLE #Partner_LastTransactions
SELECT	ac.FanID,
	cc.PartnerID,	
	MAX(ct.TranDate) as Last_TranDate
INTO #Partner_LastTransactions
FROM Relational.ConsumerTransaction ct WITH (NOLOCK)
INNER JOIN Staging.CampaignPlanning_AllCustomers ac
	ON ct.CINID = ac.CINID
INNER JOIN Staging.CampaignPlanning_Brand_CCID cc 
	ON ct.ConsumerCombinationID = cc.ConsumerCombinationID
WHERE	Amount > 0 
	AND  ct.TranDate <= @EndDate3
GROUP BY ac.FanID, cc.PartnerID

CREATE CLUSTERED INDEX IDX_FB ON #Partner_LastTransactions (FanID,PartnerID)


--Update Competitor Flag
UPDATE Staging.CampaignPlanning_TriggerMember
SET CompetitorShopper4Wk = 1
FROM Staging.CampaignPlanning_TriggerMember tm
INNER JOIN #CompetitorTransactors ct
	ON tm.FanID = ct.FanID
	AND tm.PartnerID = ct.PartnerID
--**Left Join and exclude anyone who shopped at a partner at the same time as a competitor	
LEFT OUTER JOIN #Partner_LastTransactions plt
	ON tm.FanID = plt.FanID
	AND tm.PartnerID = plt.PartnerID
	AND plt.Last_TranDate >= (SELECT Startdate FROM #CalTrans)
WHERE plt.FanID IS NULL



--Lapsers Flag Update
DECLARE	@EndDate4 AS DATE
SET @EndDate4 = (SELECT EndDate FROM #CalTrans)

UPDATE Staging.CampaignPlanning_TriggerMember
SET Lapser = 1
FROM Staging.CampaignPlanning_TriggerMember tm
INNER JOIN #Partner_LastTransactions plt
	ON tm.PartnerID = plt.PartnerID
	AND tm.FanID = plt.FanID
INNER JOIN Stratification.LapsersDefinition ld
	ON ld.PartnerID = plt.PartnerID
	AND plt.Last_TranDate <= DATEADD(MONTH,-ld.Months, @EndDate4)


SELECT @msg = 'Update SoW Flags'
EXEC Warehouse.Staging.oo_TimerMessage @msg, @time OUTPUT
---------------------------------------------------------

/************************************************************
**************************SOW Flags**************************
************************************************************/
--**Delete most recent activations (not enought time to have SoW)
DECLARE	@MaxSoWStart AS DATE
SET @MaxSoWStart = 
		(
		SELECT MAX(htm.StartDate)
		FROM Relational.ShareOfWallet_Members (NOLOCK) htm 
		INNER JOIN #Cal ps 
			ON  ps.StartDate >= htm.StartDate
		)

DELETE FROM Staging.CampaignPlanning_AllCustomers
WHERE ActivatedDate > @MaxSoWStart


--**Exclude SoW state for previous SoW boundries
IF OBJECT_ID('tempdb..#SoWDates') IS NOT NULL DROP TABLE #SoWDates
SELECT	p.BrandID,
	p.PartnerID,
	MAX(CAST(l.RunTime AS DATE)) as LowerLimit
INTO #SoWDates  
FROM Relational.ShareofWallet_RunLog l
INNER JOIN Staging.CampaignPlanning_Brand p
	ON	CAST(CASE
			WHEN LEFT(l.PartnerString,2) = '00' THEN RIGHT(l.PartnerString,2)
			ELSE PartnerString
		END AS INT) = p.PartnerID
GROUP BY p.BrandID, p.PartnerID



IF OBJECT_ID('tempdb..#SowPartnerStringDates') IS NOT NULL DROP TABLE #SowPartnerStringDates
SELECT	ps.BrandID,
	ps.PartnerID,
	COALESCE(LowerLimit, cal.StartDate) as LowerLimit,
	cal.StartDate as CalStart
INTO #SowPartnerStringDates
FROM #SoWDates ps
CROSS JOIN #Cal cal




/*******************************************************************
******Final HTM classification for each customer and Partner********
*******************************************************************/
IF OBJECT_ID ('Staging.CampaignPlanning_Headroom') IS NOT NULL DROP TABLE Staging.CampaignPlanning_Headroom
CREATE TABLE Staging.CampaignPlanning_Headroom
	(
	FanID INT NOT NULL,
	HTMID TINYINT NULL,
	PartnerID SMALLINT NOT NULL
	)


TRUNCATE TABLE Staging.CampaignPlanning_Headroom


DECLARE @StartRow4 INT,
	@PartnerID4 INT

SET @StartRow4 = 1
SET @PartnerID4 = (SELECT PartnerID FROM Staging.CampaignPlanning_Brand WHERE RowNo = @StartRow4)

WHILE @StartRow4 <= (SELECT MAX(RowNo) FROM Staging.CampaignPlanning_Brand)
BEGIN

	INSERT INTO Staging.CampaignPlanning_Headroom
	SELECT	FanID,
		HTMID,
		PartnerID
	FROM	(
		SELECT	htm.FanID, 
			htm.HTMID,
			b.PartnerID,
			DENSE_RANK() OVER (PARTITION BY htm.FanID, b.PartnerID ORDER BY ID DESC) as Rnk
		FROM Relational.ShareOfWallet_Members  htm 
		INNER JOIN #SowPartnerStringDates ps
			ON ps.PartnerID = HTM.PartnerID
			AND (htm.EndDate >= ps.CalStart OR htm.EndDate IS NULL) 
			AND ps.CalStart >= HTM.StartDate
		INNER JOIN Staging.CampaignPlanning_AllCustomers t 
			ON htm.FanID = t.FanID
		INNER JOIN Staging.CampaignPlanning_Brand b 
			ON ps.PartnerID = b.PartnerID 
			AND htm.PartnerID = @PartnerID4
		)a
	WHERE a.Rnk = 1


	SET @StartRow4 = @StartRow4+1
	SET @PartnerID4 = (SELECT PartnerID FROM Staging.CampaignPlanning_Brand WHERE RowNo = @StartRow4)

END

CREATE CLUSTERED INDEX IND_FP ON Staging.CampaignPlanning_Headroom (FanID)
CREATE NONCLUSTERED INDEX IND_PID ON Staging.CampaignPlanning_Headroom (PartnerID)
CREATE NONCLUSTERED INDEX IND_HTMID ON Staging.CampaignPlanning_Headroom (HTMID)


IF OBJECT_ID('tempdb..#SowPartnerString') IS NOT NULL DROP TABLE #SowPartnerString
IF OBJECT_ID('tempdb..#SoWDates') IS NOT NULL DROP TABLE #SoWDates
IF OBJECT_ID('tempdb..#SowPartnerDates') IS NOT NULL DROP TABLE #SowPartnerDates

/******************************02-03-2016 Edit********************************/

IF OBJECT_ID ('tempdb..#Partner_NonInSOW') IS NOT NULL DROP TABLE #Partner_NonInSOW
SELECT	DISTINCT
	b.PartnerID
INTO #Partner_NonInSOW
FROM Staging.CampaignPlanning_Brand b
LEFT OUTER JOIN
	(
	SELECT	DISTINCT
		PartnerID
	FROM Staging.CampaignPlanning_Headroom
	)h
	ON h.PartnerID = b.PartnerID
WHERE h.PartnerID IS NULL


INSERT INTO Staging.CampaignPlanning_Headroom
SELECT	FanID,
	HTMID,
	pr.PartnerID
FROM Relational.ShareOfWallet_Members_Prior35 pr
INNER JOIN #Partner_NonInSOW pn
	ON pr.PartnerID = pn.PartnerID
WHERE pr.EndDate IS NULL

/******************************02-03-2016 Edit********************************/

/***********************************
*********Update HTMID Flag**********
***********************************/
DECLARE @StartRow5 INT,
	@PartnerID5 INT

SET @StartRow5 = 1
SET @PartnerID5 = (SELECT PartnerID FROM Staging.CampaignPlanning_Brand WHERE RowNo = @StartRow5)

WHILE @StartRow5 <= (SELECT MAX(RowNo) FROM Staging.CampaignPlanning_Brand)
BEGIN
--***************************************************************************

	UPDATE Staging.CampaignPlanning_TriggerMember
	SET	HTMID = htm.HTMID,
		SuperSegmentID = htms.SuperSegmentID
	FROM Staging.CampaignPlanning_TriggerMember tm
	INNER JOIN Staging.CampaignPlanning_Headroom htm
		ON tm.FanID = htm.FanID
		AND tm.PartnerID = htm.PartnerID
	INNER JOIN Staging.CampaignPlanning_Segments htms
		ON htm.HTMID = htms.HTMID
	WHERE tm.PartnerID = @PartnerID5
		
--****************************************************************************
	SET @StartRow5 = @StartRow5+1
	SET @PartnerID5 = (SELECT PartnerID FROM Staging.CampaignPlanning_Brand WHERE RowNo = @StartRow5)

END


/***********************************
********Acquire Member Update*******
***********************************/
DECLARE @StartRow6 INT,
	@PartnerID6 INT

SET @StartRow6 = 1
SET @PartnerID6 = (SELECT PartnerID FROM Staging.CampaignPlanning_Brand WHERE RowNo = @StartRow6)

WHILE @StartRow6 <= (SELECT MAX(RowNo) FROM Staging.CampaignPlanning_Brand)
BEGIN
--***********************************************************************************************

UPDATE Staging.CampaignPlanning_TriggerMember
SET AcquireMember = 1
WHERE	HTMID IN (10,11,12)
	AND PartnerID = @PartnerID6

--***********************************************************************************************
	SET @StartRow6 = @StartRow6+1
	SET @PartnerID6 = (SELECT PartnerID FROM Staging.CampaignPlanning_Brand WHERE RowNo = @StartRow6)

END

TRUNCATE TABLE Staging.CampaignPlanning_Headroom



SELECT @msg = 'Update HeatMap Flags'
EXEC Warehouse.Staging.oo_TimerMessage @msg, @time OUTPUT
---------------------------------------------------------
/***************************************************
*******************HeatMap Flags********************
***************************************************/
CREATE TABLE #HeatMap
	(
	FanID INT,
	PartnerID SMALLINT,
	HeatMapID SMALLINT,
	ResponseIndexScore NUMERIC(32,2)
	)

DECLARE @StartRow7 INT,
	@PartnerID7 INT

SET @StartRow7 = 1
SET @PartnerID7 = (SELECT PartnerID FROM Staging.CampaignPlanning_Brand WHERE RowNo = @StartRow7)

WHILE @StartRow7 <= (SELECT MAX(RowNo) FROM Staging.CampaignPlanning_Brand)
BEGIN
--***********************************************************************************************
INSERT INTO #HeatMap
SELECT	geo.FanID,
	b.PartnerID,
	hg.HeatMapID,
	lk.Response_Index as ResponseIndexScore
FROM Relational.GeoDemographicHeatMap_Members geo
INNER JOIN Relational.GeoDemographicHeatMap_HeatMapID hg
	ON hg.HeatMapID = geo.HeatMapID
INNER JOIN Relational.GeoDemographicHeatMap_LookUp_Table lk
	ON hg.HeatMapID = lk.HeatMapID
	AND geo.PartnerID = lk.PartnerID
	AND geo.ResponseIndexBand_ID = lk.ResponseIndexBand_ID
INNER JOIN Staging.CampaignPlanning_AllCustomers t
	ON geo.FanID = t.FanID
INNER JOIN Staging.CampaignPlanning_Brand b
	ON geo.PartnerID = b.PartnerID 
WHERE	geo.EndDate IS NULL
	AND geo.PartnerID = @PartnerID7
--***********************************************************************************************
	SET @StartRow7 = @StartRow7+1
	SET @PartnerID7 = (SELECT PartnerID FROM Staging.CampaignPlanning_Brand WHERE RowNo = @StartRow7)

END

CREATE CLUSTERED INDEX IDX_FanP ON #HeatMap (FanID,PartnerID)
CREATE NONCLUSTERED INDEX IDX_HMI ON #HeatMap (HeatMapID)
CREATE NONCLUSTERED INDEX IDX_RIB ON #HeatMap (ResponseIndexScore)


/*************************************************************
*********Update HeatMap Flags on TriggerMember table**********
*************************************************************/
DECLARE @StartRow8 INT,
	@PartnerID8 INT

SET @StartRow8 = 1
SET @PartnerID8 = (SELECT PartnerID FROM Staging.CampaignPlanning_Brand WHERE RowNo = @StartRow8)

WHILE @StartRow8 <= (SELECT MAX(RowNo) FROM Staging.CampaignPlanning_Brand)
BEGIN
--***********************************************************************************************

	UPDATE Staging.CampaignPlanning_TriggerMember
	SET	HeatmapID = hm.HeatMapID,
		Gender = geo.Gender,
		MinAge = geo.MinAge,
		MaxAge = geo.MaxAge,
		CAMEO_CODE_GROUP = geo.CAMEO_CODE_GROUP,
		SocialClass = geo.SocialClass,
		DriveTimeBandID = geo.DriveTimeBandID,
		ResponseIndexScore = hm.ResponseIndexScore
	FROM Staging.CampaignPlanning_TriggerMember tm
	INNER JOIN #HeatMap hm
		ON tm.FanID = hm.FanID
		AND tm.PartnerID = hm.PartnerID
	INNER JOIN Relational.GeoDemographicHeatMap_HeatMapID geo
		ON hm.HeatMapID = geo.HeatMapID
	WHERE tm.PartnerID = @PartnerID8

--***********************************************************************************************
	SET @StartRow8 = @StartRow8+1
	SET @PartnerID8 = (SELECT PartnerID FROM Staging.CampaignPlanning_Brand WHERE RowNo = @StartRow8)

END



/********************************************************
************Build the customer activation type***********
********************************************************/
IF OBJECT_ID ('tempdb..#CB1') IS NOT NULL DROP TABLE #CB1
SELECT  p.WeekStartDate,
	CASE
		WHEN p.WeekStartDate <= '2015-04-02' THEN 'Full'
		WHEN rfw.ReducedFrequencyGroup = 'D' THEN 'Full'
		WHEN  rfw.ReducedFrequencyGroup = 'C' THEN 'Partial'
		ELSE  'No Send'
	END as Weektype,
	ISNULL(p.ActivationForecast_eligible,0) as CustomerCount,
	1 as CustomerBaseID
INTO #CB1
FROM Warehouse.MI.CBPActivationsProjections_Weekly p (NOLOCK)
LEFT OUTER JOIN Warehouse.Relational.Customers_ReducedFrequency_Weeks rfw
	ON p.WeekStartDate = rfw.WeekBeginning
	AND rfw.ReducedFrequencyGroup IN ('C','D')
WHERE p.WeekStartDate >= CAST(GETDATE() AS DATE)


IF OBJECT_ID ('tempdb..#CB2') IS NOT NULL DROP TABLE #CB2
SELECT  p.WeekStartDate,
	CASE
		WHEN p.WeekStartDate <= '2015-04-02' THEN 'Full'
		WHEN rfw.ReducedFrequencyGroup = 'D' THEN 'Full'
		WHEN  rfw.ReducedFrequencyGroup = 'C' THEN 'Partial'
		ELSE  'No Send'
	END as Weektype,
	CASE
			WHEN p.WeekStartDate <= '2015-04-02' THEN ISNULL(p.ActivationForecast_eligible,0)
			ELSE (CASE
				WHEN (p.ActivationForecast_eligible = 0 OR rfw.ReducedFrequencyGroup IS NULL) THEN 0 
				ELSE p.ActivationForecast_engaged
				END)
		END as CustomerCount,
	2 as CustomerBaseID
INTO #CB2
FROM Warehouse.MI.CBPActivationsProjections_Weekly p (NOLOCK)
LEFT OUTER JOIN Warehouse.Relational.Customers_ReducedFrequency_Weeks rfw
	ON p.WeekStartDate = rfw.WeekBeginning
	AND rfw.ReducedFrequencyGroup IN ('C','D')
WHERE p.WeekStartDate >= CAST(GETDATE() AS DATE)


IF OBJECT_ID ('tempdb..#CB3') IS NOT NULL DROP TABLE #CB3
SELECT  p.WeekStartDate,
	CASE
		WHEN p.WeekStartDate <= '2015-04-02' THEN 'Full'
		WHEN rfw.ReducedFrequencyGroup = 'D' THEN 'Full'
		WHEN  rfw.ReducedFrequencyGroup = 'C' THEN 'Partial'
		ELSE  'No Send'
	END as Weektype,
	ActivationForecast as CustomerCount,
	3 as CustomerBaseID
INTO #CB3
FROM Warehouse.MI.CBPActivationsProjections_Weekly p (NOLOCK)
LEFT OUTER JOIN Warehouse.Relational.Customers_ReducedFrequency_Weeks rfw
	ON p.WeekStartDate = rfw.WeekBeginning
	AND rfw.ReducedFrequencyGroup IN ('C','D')
WHERE p.WeekStartDate >= CAST(GETDATE() AS DATE)



IF OBJECT_ID ('Staging.CampaignPlanning_ActivatedBase') IS NOT NULL DROP TABLE Staging.CampaignPlanning_ActivatedBase
SELECT	a.*
	--,CustomerBaseDesc
INTO Staging.CampaignPlanning_ActivatedBase
FROM	(
	SELECT	WeekStartDate,
		Weektype,
		CustomerBaseID,
		CustomerCount
	FROM #CB1
UNION ALL
	SELECT	WeekStartDate,
		Weektype,
		CustomerBaseID,
		CustomerCount
	FROM #CB2
UNION ALL
	SELECT	WeekStartDate,
		Weektype,
		CustomerBaseID,
		CustomerCount
	FROM #CB3
	)a
ORDER BY WeekStartDate, WeekType, CustomerBaseID


SELECT @msg = 'Populating the Non-Core Base Offer Flag'
EXEC Warehouse.Staging.oo_TimerMessage @msg, @time OUTPUT
---------------------------------------------------------
/**********************************************************************
**************Populating the Non-Core Base Offer Flag******************
**********************************************************************/
IF OBJECT_ID ('tempdb..#NC_OfferID') IS NOT NULL DROP TABLE #NC_OfferID
SELECT	ROW_NUMBER() OVER(ORDER BY ncbo.IronOfferID) as RowNo,
	ncbo.PartnerID,
	ncbo.IronOfferID,
	htm.ClientServicesRef
INTO #NC_OfferID
FROM Relational.Partner_NonCoreBaseOffer ncbo
INNER JOIN Relational.IronOffer_Campaign_HTM htm
	ON ncbo.IronOfferID = htm.IronOfferID
	AND ncbo.PartnerID = htm.PartnerID
WHERE	EndDate IS NULL
	OR CAST(EndDate AS DATE) >= CAST(GETDATE() AS DATE)
--(30 row(s) affected)

CREATE CLUSTERED INDEX IDX_IO ON #NC_OfferID (IronOfferID)
CREATE NONCLUSTERED INDEX IDX_PI ON #NC_OfferID (PartnerID)
CREATE NONCLUSTERED INDEX IDX_CS ON #NC_OfferID (ClientServicesRef)

--***********************************************************************

CREATE TABLE #NCBO_Members
	(
	FanID INT NOT NULL,
	PartnerID SMALLINT NOT NULL,
	ClientServicesRef VARCHAR(12)
	)

--***********************************************************************

DECLARE @StartRow10 SMALLINT,
	@IronOfferID SMALLINT

SET	@StartRow10 = 1
SET	@IronOfferID = (SELECT IronOfferID FROM #NC_OfferID WHERE RowNo = @StartRow10)

WHILE @StartRow10 <= (SELECT MAX(RowNo) FROM #NC_OfferID)

BEGIN

	INSERT INTO #NCBO_Members
	SELECT	c.FanID,
		PartnerID,
		ClientServicesRef
	FROM #NC_OfferID nc
	INNER JOIN Relational.IronOfferMember iom (NOLOCK)
		ON nc.IronOfferID = iom.IronOfferID
	INNER JOIN Relational.Customer c (NOLOCK)
		ON c.CompositeID = iom.CompositeID
	WHERE nc.IronOfferID = @IronOfferID

	SET @StartRow10 = @StartRow10+1
	SET @IronOfferID = (SELECT IronOfferID FROM #NC_OfferID WHERE RowNo = @StartRow10)
	
END

CREATE CLUSTERED INDEX IDX_FI ON #NCBO_Members (FanID)
CREATE NONCLUSTERED INDEX IDX_CSR ON #NCBO_Members (ClientServicesRef)
CREATE NONCLUSTERED INDEX IDX_PI ON #NCBO_Members (PartnerID)

--******************************************************************************************

DECLARE @StartRow11 INT,
	@PartnerID11 INT

SET @StartRow11 = 1
SET @PartnerID11 = (SELECT PartnerID FROM Staging.CampaignPlanning_Brand WHERE RowNo = @StartRow11)

WHILE @StartRow11 <= (SELECT MAX(RowNo) FROM Staging.CampaignPlanning_Brand)
BEGIN
--***************************************************************************

	UPDATE	Staging.CampaignPlanning_TriggerMember
	SET	NonCoreBO_CSRef = ncbo.ClientServicesRef
	FROM	Staging.CampaignPlanning_TriggerMember tm
	INNER JOIN #NCBO_Members ncbo
		ON tm.FanID = ncbo.FanID
		AND tm.PartnerID = ncbo.PartnerID
	WHERE	ncbo.PartnerID = @PartnerID11

--***************************************************************************
	SET @StartRow11 = @StartRow11+1
	SET @PartnerID11 = (SELECT PartnerID FROM Staging.CampaignPlanning_Brand WHERE RowNo = @StartRow11)

END


ALTER INDEX IDX_F ON Staging.[CampaignPlanning_TriggerMember] REBUILD
ALTER INDEX IDX_P ON Staging.[CampaignPlanning_TriggerMember] REBUILD
ALTER INDEX IDX_H ON Staging.[CampaignPlanning_TriggerMember] REBUILD
ALTER INDEX IDX_NCBO ON Staging.[CampaignPlanning_TriggerMember] REBUILD
ALTER INDEX IDX_G ON Staging.[CampaignPlanning_TriggerMember] REBUILD
ALTER INDEX IDX_L ON Staging.[CampaignPlanning_TriggerMember] REBUILD
ALTER INDEX IDX_S ON Staging.[CampaignPlanning_TriggerMember] REBUILD
ALTER INDEX IDX_C ON Staging.[CampaignPlanning_TriggerMember] REBUILD
ALTER INDEX IDX_St ON Staging.[CampaignPlanning_TriggerMember] REBUILD



END