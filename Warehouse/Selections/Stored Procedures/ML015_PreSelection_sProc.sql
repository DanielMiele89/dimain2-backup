-- =============================================-- Author:  <Rory Francis>-- Create date: <2020-11-03>-- Description: < sProc to run preselection code per camapign >-- =============================================CREATE PROCEDURE Selections.ML015_PreSelection_sProcASBEGIN
DECLARE @Today DATETIME = GETDATE()
	,	@TwoYearsAgo DATETIME = DATEADD(DAY, (4 - DATEPART(WEEKDAY, DATEADD(YEAR, -2, GETDATE()))), DATEADD(YEAR, -2, GETDATE()))


-- Capture Customer Actions Table, with Newsletter Engagement
IF OBJECT_ID('tempdb..#CombinedLogIns') IS NOT NULL DROP TABLE #CombinedLogIns
SELECT	 ee.FanID
	,	EventDate = MAX(ee.EventDate)
INTO	#CombinedLogIns
FROM	Relational.EmailEvent ee 
INNER JOIN Relational.EmailCampaign ec 
	ON ec.CampaignKey = ee.CampaignKey
WHERE	ee.EventDate >= @TwoYearsAgo
	AND ee.EventDate <= @Today
	AND ee.EmailEventCodeID IN (1301, 605)
	AND ec.CampaignName LIKE '%Newsletter%'
GROUP BY ee.FanID




-- Capture Customer Web Actions Table, with Login Engagement
INSERT INTO #CombinedLogIns (FanID, EventDate)
SELECT	FanID
	,	MAX(CAST(TrackDate AS DATE)) AS EventDate
FROM	Relational.WebLogins 
WHERE	TrackDate >= @TwoYearsAgo
	AND TrackDate <= @Today
GROUP BY FanID
CREATE CLUSTERED INDEX ix_FanID_EventDate_1 ON #CombinedLogIns (FanID, EventDate)



-- Compiliting Customer Awareness Table
IF OBJECT_ID('tempdb..#CustomerAwareness') IS NOT NULL DROP TABLE #CustomerAwareness
SELECT	*
	,	CASE	WHEN DaysSinceMaxEventDate <= 28 THEN '1 - Gold'
				WHEN DaysSinceMaxEventDate > 28	AND DaysSinceMaxEventDate <= 84	THEN '2 - Silver'
				WHEN DaysSinceMaxEventDate > 84	AND DaysSinceMaxEventDate <= 364 THEN '3 - Bronze'
				ELSE '4 - Blue' END
		AS AwarenessLevel
INTO #CustomerAwareness
FROM (	SELECT	FanID
			,	MAX(EventDate) MaxEventDate
			,	DATEDIFF(Day, MAX(EventDate), @Today) AS DaysSinceMaxEventDate
		FROM #CombinedLogIns 
		GROUP BY FanID) m

CREATE CLUSTERED INDEX ix_FanID ON #CustomerAwareness(FanID)


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
CREATE CLUSTERED INDEX ix_FanID on #FB(FANID)


IF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC
SELECT	ConsumerCombinationID
		,BrandID
INTO #CC
FROM	Relational.ConsumerCombination CC
WHERE	BrandID IN (304,505,24,1050,303,187,130)

CREATE CLUSTERED INDEX CIX_CC ON #CC (ConsumerCombinationID)

DECLARE @OneYearAgo DATETIME = DATEADD(MONTH,-12,GETDATE())

IF OBJECT_ID('Sandbox.SamW.MatalanCompetitorSteal') IS NOT NULL DROP TABLE Sandbox.SamW.MatalanCompetitorSteal
SELECT	F.CINID
INTO Sandbox.SamW.MatalanCompetitorSteal
FROM	#FB F
JOIN	Relational.ConsumerTransaction_MyRewards CT ON CT.CINID = F.CINID
JOIN	#CC C ON C.ConsumerCombinationID = CT.ConsumerCombinationID
WHERE	TranDate >= @OneYearAgo
AND		AwarenessLevel = '1 - Gold'
GROUP BY F.CINID


DECLARE @SixMonthsAgo DATETIME = DATEADD(MONTH,-6,GETDATE())


IF OBJECT_ID('tempdb..#CC_277') IS NOT NULL DROP TABLE #CC_277
SELECT	ConsumerCombinationID
		,BrandID
INTO #CC_277
FROM	Relational.ConsumerCombination CC
WHERE	BrandID IN (277)

CREATE CLUSTERED INDEX CIX_CC ON #CC_277 (ConsumerCombinationID)


IF OBJECT_ID('tempdb..#Trans') IS NOT NULL DROP TABLE #Trans
SELECT	F.CINID
		,NTILE(10) OVER (ORDER BY SUM(Amount) DESC) SalesRank
		,NTILE(10) OVER (ORDER BY COUNT(*) DESC) TransRank
		,AwarenessLevel
INTO #Trans
FROM	#FB F
JOIN	Relational.ConsumerTransaction_MyRewards CT ON F.CINID = CT.CINID
JOIN	#CC_277 CC ON CC.ConsumerCombinationID = CT.ConsumerCombinationID
WHERE	TranDate >= @SixMonthsAgo
GROUP BY F.CINID
		,AwarenessLevel


IF OBJECT_ID('Sandbox.SamW.MatalanTopSpenders161020') IS NOT NULL DROP TABLE Sandbox.SamW.MatalanTopSpenders161020
SELECT	CINID
INTO Sandbox.SamW.MatalanTopSpenders161020
FROM	#Trans
WHERE	(AwarenessLevel = '1 - Gold'
OR AwarenessLevel = '2 - Silver'
OR AwarenessLevel = '3 - Bronze')
AND	SalesRank < = 4
AND TransRank <= 4



IF OBJECT_ID('tempdb..#Roc_Shopper_Segment_Members') IS NOT NULL DROP TABLE #Roc_Shopper_Segment_Members
SELECT	FanID
	,	ShopperSegmentTypeID
INTO #Roc_Shopper_Segment_Members
FROM [Segmentation].[Roc_Shopper_Segment_Members] sg
WHERE EndDate IS NULL
AND PartnerID = 3421
AND ShopperSegmentTypeID IN (7, 9)

CREATE CLUSTERED INDEX CIX_All ON #Roc_Shopper_Segment_Members (ShopperSegmentTypeID, FanID)
If Object_ID('Warehouse.Selections.ML015_PreSelection') Is Not Null Drop Table Warehouse.Selections.ML015_PreSelectionSelect FanIDINTO Warehouse.Selections.ML015_PreSelectionFROM #FB fbWHERE EXISTS (	SELECT 1				FROM Sandbox.SamW.MatalanCompetitorSteal st				WHERE fb.CINID = st.CINID)
AND EXISTS (	SELECT 1
				FROM #Roc_Shopper_Segment_Members sg
				WHERE sg.ShopperSegmentTypeID = 7
				AND fb.FanID = sg.FanID)INSERT INTO Warehouse.Selections.ML015_PreSelectionSelect FanIDFROM #FB fbWHERE EXISTS (	SELECT 1				FROM Sandbox.SamW.MatalanTopSpenders161020 st				WHERE fb.CINID = st.CINID)
AND EXISTS (	SELECT 1
				FROM #Roc_Shopper_Segment_Members sg
				WHERE sg.ShopperSegmentTypeID = 9
				AND fb.FanID = sg.FanID)

END