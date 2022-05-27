-- =============================================-- Author:  <Rory Francis>-- Create date: <2020-07-10>-- Description: < sProc to run preselection code per camapign >-- =============================================CREATE PROCEDURE [Selections].[LW053_PreSelection_sProc]ASBEGIN-- INPUT THE INFO IN THE SPEND STRETCH TABLE BELOW TO GET THE SPEND STRETCHES TO WORK OUT SPEND STRETCH OFFERS--

EXEC [ExcelQuery].[ROCEFT_LIVE_SpendStretch_Calculate] 
 @BrandList = '75', --BRANDID
 @Bespoke = 0, --Non optional parameter – bit flag 0/1
 @TableName = NULL, --Optional parameter, supply a table name as a ‘string’ table must contain a column called CINID that is the CINID
 @StartDate = NULL, --Optional parameter, supply the start of the time period
 @EndDate = NULL --Optional parameter, supply the end of the time period


	DECLARE @AcquireLength INT = 24,
		@LapsedLength INT = 12,
		@PASTMONTHS INT = 12, -- HOW FAR TO LOOK BACK AT TRANSACTIONS
		@BrandID INT = 246,
		@OriginCycleStartDate DATE = '2019-06-21', -- Cycle
		@Year int = 2020,
		@BrandName varchar(500) = 'Laithwaites'

DECLARE @TimeStart DATETIME = GETDATE(), @time DATETIME, @RowsAffected INT
EXEC Prototype.oo_TimerMessage_V2 'STARTED', @RowsAffected, @time OUTPUT


-- Capture Customer Actions Table, with Newsletter Engagement
IF OBJECT_ID('tempdb..#CombinedLogIns') IS NOT NULL DROP TABLE #CombinedLogIns
SELECT	 ee.FanID
	,	EventDate = MAX(ee.EventDate)
INTO	#CombinedLogIns
FROM	Relational.EmailEvent ee 
INNER JOIN Relational.EmailCampaign ec 
	ON ec.CampaignKey = ee.CampaignKey
WHERE	ee.EventDate >= DATEADD(DAY, (4 - DATEPART(WEEKDAY, DATEADD(YEAR, -2, @OriginCycleStartDate))), DATEADD(YEAR, -2, @OriginCycleStartDate))
	AND ee.EventDate <= @OriginCycleStartDate
	AND ee.EmailEventCodeID IN (1301, 605)
	AND ec.CampaignName LIKE '%Newsletter%'
GROUP BY ee.FanID
SET @RowsAffected = @@ROWCOUNT -- (2611467 rows affected) / 00:00:15
EXEC Prototype.oo_TimerMessage_V2 '#CombinedLogIns - 1', @RowsAffected, @time OUTPUT


-- Capture Customer Web Actions Table, with Login Engagement
INSERT INTO #CombinedLogIns (FanID, EventDate)
SELECT	FanID
	,	MAX(CAST(TrackDate AS DATE)) AS EventDate
FROM	Relational.WebLogins 
WHERE	TrackDate >= DATEADD(DAY, (4 - DATEPART(WEEKDAY, DATEADD(YEAR, -2, @OriginCycleStartDate))), DATEADD(YEAR, -2, @OriginCycleStartDate))
	AND TrackDate <= @OriginCycleStartDate
GROUP BY FanID
SET @RowsAffected = @@ROWCOUNT -- (1764914 rows affected) / 00:00:20
CREATE CLUSTERED INDEX ix_FanID_EventDate_1 ON #CombinedLogIns (FanID, EventDate)
EXEC Prototype.oo_TimerMessage_V2 '#CombinedLogIns - 2', @RowsAffected, @time OUTPUT


-- Compiliting Customer Awareness Table
IF OBJECT_ID('tempdb..#CustomerAwareness') IS NOT NULL DROP TABLE #CustomerAwareness
SELECT	*
	,	CASE	WHEN DateDiff(Day,MaxEventDate,@origincyclestartdate) <= 28 THEN '1 - Gold'
				WHEN DateDiff(Day,MaxEventDate,@origincyclestartdate) > 28	AND DateDiff(Day,MaxEventDate,@origincyclestartdate) <= 84	THEN '2 - Silver'
				WHEN DateDiff(Day,MaxEventDate,@origincyclestartdate) > 84	AND DateDiff(Day,MaxEventDate,@origincyclestartdate) <= 364	THEN '3 - Bronze'
				ELSE '4 - Blue' END
		AS AwarenessLevel
INTO #CustomerAwareness
FROM (
	SELECT FanID, MAX(EventDate) MaxEventDate
	FROM #CombinedLogIns 
	GROUP BY fanid
) m 
SET @RowsAffected = @@ROWCOUNT -- (2,959,727 rows affected) / 00:00:07
CREATE CLUSTERED INDEX ix_FanID ON #CustomerAwareness(FanID)
EXEC Prototype.oo_TimerMessage_V2 '#CustomerAwareness', @RowsAffected, @time OUTPUT


IF OBJECT_ID('tempdb..#FB') IS NOT NULL DROP TABLE #FB
SELECT	C.FanID
		,CINID
		,AwarenessLevel
INTO #FB
FROM	Relational.Customer C
JOIN	Relational.CINList CL ON CL.CIN = C.SourceUID
LEFT JOIN	#CustomerAwareness CA ON C.FanID = CA.FanID
WHERE C.CurrentlyActive = 1
	AND SourceUID NOT IN (SELECT SourceUID FROM Staging.Customer_DuplicateSourceUID)
SET @RowsAffected = @@ROWCOUNT -- (2775046 rows affected) / 00:00:06
CREATE CLUSTERED INDEX ix_FanID on #FB(FANID)
EXEC Prototype.oo_TimerMessage_V2 '#FB', @RowsAffected, @time OUTPUT


SELECT DATENAME(dw,'2018-06-21') --CHECK START ON A THURSDAY FOR A CYCLE START DATE IN THE PAST 

--GO TO LINE 64 TO EITHER DASH OUT THE SELECTION CRITERIA OR NOT

-- Populate #Cycles table with cycle dates up to the input year @Year

IF OBJECT_ID('tempdb..#Cycles') IS NOT NULL DROP TABLE #Cycles;
WITH cte AS
 (SELECT @OriginCycleStartDate AS CycleStartDate -- anchor member
 UNION ALL
 SELECT CAST((DATEADD(WEEK, 2, CycleStartDate)) AS DATE) -- Campaign Cycle start date: recursive member
 FROM cte
 WHERE YEAR(DATEADD(WEEK, 2, CycleStartDate)) <= @Year -- terminator
 )
SELECT
 cte.CycleStartDate
 , DATEADD(DAY, -1, (DATEADD(WEEK, 2, cte.CycleStartDate))) AS CycleEndDate
 , ROW_NUMBER() OVER(ORDER BY (cte.CycleStartDate)) AS CycleNumber
INTO #Cycles
FROM cte
WHERE YEAR(CycleStartDate) <= @Year
OPTION (MAXRECURSION 1000)


IF OBJECT_ID('tempdb..#CCIDs') IS NOT NULL DROP TABLE #CCIDs
SELECT ConsumerCombinationID 
INTO #CCIDs
FROM Relational.ConsumerCombination cc WITH (NOLOCK)
WHERE BrandID = @BrandID
CREATE CLUSTERED INDEX CIX_CCID_CCID ON #CCIDs (ConsumerCombinationID)


IF OBJECT_ID('tempdb..#CT') IS NOT NULL DROP TABLE #CT
SELECT ct.CINID
 , ct.TranDate
	 , Amount
	 , CycleStartDate
	 , AwarenessLevel
	 , MAX(CASE WHEN S.CINID IS NOT NULL THEN 1 ELSE 0 END) SELECTION
	 , ROW_NUMBER ( ) 
 OVER ( PARTITION BY CT.CINID, CycleStartDate ORDER BY TranDate ASC) TransactionNumber
INTO #CT
FROM #CCIDs CCs
INNER JOIN Relational.ConsumerTransaction_MyRewards ct
 ON CCs.ConsumerCombinationID = ct.ConsumerCombinationID
INNER JOIN #FB F
	ON F.CINID = CT.CINID
LEFT JOIN Sandbox.SamW.Morrisons_August_Proposalv2 S -- SELECT SANDBOX 
	ON F.CINID = S.CINID
INNER JOIN #Cycles C
	ON TranDate BETWEEN C.CycleStartDate AND C.CycleEndDate
WHERE TranDate > DATEADD(MONTH, -@PASTMONTHS,@OriginCycleStartDate)
AND Amount > 0
GROUP BY CT.CINID
		,TranDate
		, Amount
		, CycleStartDate 
		, AwarenessLevel



IF OBJECT_ID('tempdb..#CT_Lag') IS NOT NULL DROP TABLE #CT_Lag
SELECT *
 , LAG (TranDate) OVER (PARTITION BY CINID ORDER BY TranDate) As PreviousTranDate
 , DATEDIFF(month, LAG (TranDate) OVER (PARTITION BY CINID ORDER BY TranDate), TranDate) AS MonthsSinceLastTran
INTO #CT_Lag
FROM #CT



IF OBJECT_ID('tempdb..#CustomerSegment') IS NOT NULL DROP TABLE #CustomerSegment
SELECT *
 , CASE
 WHEN MonthsSinceLastTran IS NULL OR MonthsSinceLastTran >= @AcquireLength THEN 'Acquire'
 WHEN MonthsSinceLastTran >= @LapsedLength THEN 'Lapsed'
 ELSE 'Shopper'
 END AS CustomerSegmentOnTranDate
INTO #CustomerSegment
FROM #CT_Lag

SELECT TOP 10 *
FROM #CT_Lag


IF OBJECT_ID('tempdb..#SegmentonTranDate') IS NOT NULL DROP TABLE #SegmentonTranDate
SELECT	CINID	
		,CycleStartDate
		,CustomerSegmentOnTranDate
INTO #SegmentonTranDate
FROM	#CustomerSegment
WHERE TransactionNumber = 1

SELECT TOP 10 *
FROM #SegmentonTranDate
ORDER BY CINID DESC


IF OBJECT_ID('Sandbox.SamW.Forecasting') IS NOT NULL DROP TABLE Sandbox.SamW.Forecasting
SELECT	SUM(Amount) Spend
		,COUNT(*) Transactions
		,COUNT(DISTINCT C.CINID) Customers
		,SELECTION
		,AwarenessLevel
		,C.CustomerSegmentOnTranDate
		,C.CycleStartDate
		,@BrandName BrandName
INTO Sandbox.SamW.Forecasting
FROM	#CustomerSegment C
LEFT JOIN #SegmentonTranDate S 
	ON C.CINID = S.CINID
	AND C.CycleStartDate = S.CycleStartDate					
WHERE	C.CycleStartDate >= DATEADD(MONTH, -@PastMonths,GETDATE())
GROUP BY C.CustomerSegmentOnTranDate
		,C.CycleStartDate
		,AwarenessLevel
		,SELECTION



 ----SPEND STRETCH OUTPUT--
 --SELECT 'SpendStretch'
 --SELECT * FROM
 --Warehouse.ExcelQuery.ROCEFT_SpendStretch
 --WHERE BrandID = @BrandID 

 ----FORECASTING OUTPUT
 --SELECT *
 --FROM Sandbox.SamW.Forecasting
 --ORDER BY CycleStartDate DESC

 --SELECT SUM(Amount)
 --FROM #CustomerSegment

 --SELECT SUM(Spend)
 --FROM Sandbox.SamW.Forecasting

 IF OBJECT_ID('tempdb..#LapsedandShoppers') IS NOT NULL DROP TABLE #LapsedandShoppers
 SELECT DISTINCT F.CINID
 INTO #LapsedandShoppers
 FROM #FB F
 JOIN Relational.ConsumerTransaction_MyRewards CT ON CT.CINID = F.CINID
 JOIN Relational.ConsumerCombination CC ON CC.ConsumerCombinationID = CT.ConsumerCombinationID
 WHERE TranDate >= DATEADD(MONTH,-24,GETDATE())
 AND BrandID = 246

 --IF OBJECT_ID('Sandbox.SamW.LaithwaitesAcquiredEngaged02072020') IS NOT NULL DROP TABLE Sandbox.SamW.LaithwaitesAcquiredEngaged02072020
 --SELECT DISTINCT CINID
 --INTO Sandbox.SamW.LaithwaitesAcquiredEngaged02072020
 --FROM	#FB F
 --WHERE	AwarenessLevel = '1 - Gold'
 --AND CINID NOT IN (SELECT CINID FROM #LapsedandShoppers)

 IF OBJECT_ID('Sandbox.SamW.LaithwaitesAcquiredNotEngaged02072020') IS NOT NULL DROP TABLE Sandbox.SamW.LaithwaitesAcquiredNotEngaged02072020
 SELECT DISTINCT CINID, FanID
 INTO Sandbox.SamW.LaithwaitesAcquiredNotEngaged02072020
 FROM	#FB F
 WHERE	AwarenessLevel <> '1 - Gold'
 AND CINID NOT IN (SELECT CINID FROM #LapsedandShoppers)






If Object_ID('Warehouse.Selections.LW053_PreSelection') Is Not Null Drop Table Warehouse.Selections.LW053_PreSelectionSelect FanIDInto Warehouse.Selections.LW053_PreSelectionFROM  SANDBOX.SAMW.LAITHWAITESACQUIREDNOTENGAGED02072020END