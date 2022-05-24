-- =============================================-- Author:  <Rory Francis>-- Create date: <2020-03-06>-- Description: < sProc to run preselection code per camapign >-- =============================================CREATE PROCEDURE Selections.HIE009_PreSelection_sProcASBEGINDECLARE @CYCLESTARTDATE DATE = '2020-03-12'

-- Create Customer Actions Table, with Newsletter Engagement
IF OBJECT_ID('tempdb..#CustomerActions') IS NOT NULL DROP TABLE #CustomerActions
SELECT	DISTINCT ee.FanID
	,	ee.EventDate
INTO	#CustomerActions
FROM	Relational.EmailEvent ee with (nolock)
INNER JOIN Relational.EmailCampaign ec with (nolock) ON ec.CampaignKey = ee.CampaignKey
WHERE	ee.EventDate >= DATEADD(YEAR,-2,@CYCLESTARTDATE)
AND		ee.EventDate <= @CYCLESTARTDATE
AND		ee.EmailEventCodeID IN (1301, 605)
AND		ec.CampaignName LIKE '%Newsletter%'
CREATE CLUSTERED INDEX ix_FanID_EventDate_1 ON #CustomerActions(FanID, EventDate)


-- Create Customer Web Actions Table, with Login Engagement
IF OBJECT_ID('tempdb..#CustomerWebActions') IS NOT NULL DROP TABLE #CustomerWebActions
SELECT	DISTINCT FanID
	,	CONVERT(DATE, TrackDate)	AS EventDate
INTO	#CustomerWebActions
FROM	Relational.WebLogins with (nolock)
WHERE	TrackDate >= DATEADD(YEAR,-2,@CYCLESTARTDATE)
AND		TrackDate <= @CYCLESTARTDATE
CREATE CLUSTERED INDEX ix_FanID_EventDate_2 ON #CustomerWebActions(FanID, EventDate)


-- Merging Customer Web Actions data into Customer Actions Table
INSERT INTO	#CustomerActions (FanID, EventDate)
SELECT		FanID, EventDate
FROM		#CustomerWebActions with (nolock)

IF OBJECT_ID('tempdb..#Max') IS NOT NULL DROP TABLE #Max
SELECT FanID, MAX(EventDate) MaxEventDate
INTO #Max
FROM #CustomerWebActions with (nolock)
GROUP BY fanid




-- Compiliting Customer Awareness Table
IF OBJECT_ID('tempdb..#CustomerAwareness') IS NOT NULL DROP TABLE #CustomerAwareness
SELECT	*
	,	CASE	WHEN DateDiff(Day,MaxEventDate,@CycleStartDate) <= 28						THEN '1 - Gold'
				WHEN DateDiff(Day,MaxEventDate,@CycleStartDate) > 28	AND DateDiff(Day,MaxEventDate,@CycleStartDate) <= 84	THEN '2 - Silver'
				WHEN DateDiff(Day,MaxEventDate,@CycleStartDate) > 84	AND DateDiff(Day,MaxEventDate,@CycleStartDate) <= 364	THEN '3 - Bronze'
				ELSE '4 - Blue' END
		AS AwarenessLevel
INTO	#CustomerAwareness
FROM	#Max with (nolock)
CREATE CLUSTERED INDEX ix_FanID ON #CustomerAwareness(FanID)

IF OBJECT_ID('tempdb..#AWS') IS NOT NULL DROP TABLE #AWS
SELECT DISTINCT LEFT(PostCode,LEN(PostCode) - 2) PostCode
		,CPC.ConsumerCombinationID
INTO	#AWS
FROM	AWSFile.ComboPostCode CPC 
JOIN	Relational.ConsumerCombination CC ON CC.ConsumerCombinationID = CPC.ConsumerCombinationID
WHERE	CC.BrandID IN (2096,351,468,2091)
CREATE CLUSTERED INDEX ix_CC ON #AWS(ConsumerCombinationID)

IF OBJECT_ID('tempdb..#DTM') IS NOT NULL DROP TABLE #DTM
SELECT PostCode, REPLACE(ToSector,' ','') ToSector
INTO #DTM
FROM Relational.DriveTimeMatrix DTM
JOIN #AWS A ON A.PostCode = REPLACE(FromSector,' ','')
AND PeakTime_Mins < = 10

IF OBJECT_ID('tempdb..#WithinDistance') IS NOT NULL DROP TABLE #WithinDistance
SELECT DISTINCT ConsumerCombinationID
INTO #WithinDistance
FROM AWSFile.ComboPostCode
WHERE LEFT(PostCode,LEN(PostCode) - 2) IN (SELECT DISTINCT ToSector FROM #DTM)

IF OBJECT_ID('tempdb..#FB') IS NOT NULL DROP TABLE #FB
SELECT CINID
		,C.FanID
		,AwarenessLevel
INTO #FB
FROM	Relational.Customer C
JOIN	Relational.CINList CL ON CL.CIN = C.SourceUID
JOIN	#CustomerAwareness CA ON CA.FanID = C.FanID
WHERE C.CurrentlyActive = 1
AND	 SourceUID NOT IN (SELECT SourceUID FROM Staging.Customer_DuplicateSourceUID)
AND		AwarenessLevel IN ('1 - Gold', '2 - Silver')
CREATE CLUSTERED INDEX ix_FanID ON #FB(FanID)


IF OBJECT_ID('Sandbox.ewan.WithinDistanceIHG100120') IS NOT NULL DROP TABLE Sandbox.ewan.WithinDistanceIHG100120
SELECT	DISTINCT F.CINID
	,	FanID
INTO	Sandbox.ewan.WithinDistanceIHG100120
FROM	#FB F
JOIN	Relational.ConsumerTransaction_MyRewards CTMR ON F.CINID = CTMR.CINID
JOIN	#WithinDistance W ON CTMR.ConsumerCombinationID = W.ConsumerCombinationID
WHERE	TranDate >= DATEADD(YEAR, - 1, @CYCLESTARTDATE)
AND		Amount > 0
AND		DATENAME(WEEKDAY, TranDate) IN ('FRIDAY','SATURDAY','SUNDAY')If Object_ID('Warehouse.Selections.HIE009_PreSelection') Is Not Null Drop Table Warehouse.Selections.HIE009_PreSelectionSelect FanIDInto Warehouse.Selections.HIE009_PreSelectionFROM SANDBOX.EWAN.WITHINDISTANCEIHG100120END