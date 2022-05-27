-- =============================================-- Author:  <Rory Francis>-- Create date: <2020-11-13>-- Description: < sProc to run preselection code per camapign >-- =============================================CREATE PROCEDURE [Selections].[ML018_PreSelection_sProc]ASBEGIN


-- Capture Customer Actions Table, with Newsletter Engagement
IF OBJECT_ID('tempdb..#CombinedLogIns') IS NOT NULL DROP TABLE #CombinedLogIns
SELECT	 ee.FanID
	,	EventDate = MAX(ee.EventDate)
INTO	#CombinedLogIns
FROM	Relational.EmailEvent ee 
INNER JOIN Relational.EmailCampaign ec 
	ON ec.CampaignKey = ee.CampaignKey
WHERE	ee.EventDate >= DATEADD(DAY, (4 - DATEPART(WEEKDAY, DATEADD(YEAR, -2, GETDATE()))), DATEADD(YEAR, -2, GETDATE()))
	AND ee.EventDate <= GETDATE()
	AND ee.EmailEventCodeID IN (1301, 605)
	AND ec.CampaignName LIKE '%Newsletter%'
GROUP BY ee.FanID



-- Capture Customer Web Actions Table, with Login Engagement
INSERT INTO #CombinedLogIns (FanID, EventDate)
SELECT	FanID
	,	MAX(CAST(TrackDate AS DATE)) AS EventDate
FROM	Relational.WebLogins 
WHERE	TrackDate >= DATEADD(DAY, (4 - DATEPART(WEEKDAY, DATEADD(YEAR, -2, GETDATE()))), DATEADD(YEAR, -2, GETDATE()))
	AND TrackDate <= GETDATE()
GROUP BY FanID



-- Compiliting Customer Awareness Table
IF OBJECT_ID('tempdb..#CustomerAwareness') IS NOT NULL DROP TABLE #CustomerAwareness
SELECT	*
	,	CASE	WHEN DateDiff(Day,MaxEventDate,GETDATE()) <= 28 THEN '1 - Gold'
				WHEN DateDiff(Day,MaxEventDate,GETDATE()) > 28	AND DateDiff(Day,MaxEventDate,GETDATE()) <= 84	THEN '2 - Silver'
				WHEN DateDiff(Day,MaxEventDate,GETDATE()) > 84	AND DateDiff(Day,MaxEventDate,GETDATE()) <= 364	THEN '3 - Bronze'
				ELSE '4 - Blue' END
		AS AwarenessLevel
INTO #CustomerAwareness
FROM (
	SELECT FanID, MAX(EventDate) MaxEventDate
	FROM #CombinedLogIns 
	GROUP BY fanid
) m 



IF OBJECT_ID('tempdb..#FullBase') IS NOT NULL DROP TABLE #FullBase
SELECT	C.FanID
		,CINID
		,AwarenessLevel
		,Region
INTO #FullBase
FROM	Relational.Customer C
JOIN	Relational.CINList CL ON CL.CIN = C.SourceUID
LEFT JOIN	#CustomerAwareness CA ON C.FanID = CA.FanID
WHERE C.CurrentlyActive = 1
	AND SourceUID NOT IN (SELECT SourceUID FROM Staging.Customer_DuplicateSourceUID)


IF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC
SELECT	ConsumerCombinationID
		,BrandID
INTO #CC
FROM	Relational.ConsumerCombination CC
WHERE	BrandID IN (304,505,24,1050,303,187,130)


IF OBJECT_ID('Sandbox.SamW.MatalanCompetitorSteal161020') IS NOT NULL DROP TABLE Sandbox.SamW.MatalanCompetitorSteal161020
SELECT	F.CINID
		,Region
INTO Sandbox.SamW.MatalanCompetitorSteal161020
FROM	#FullBase F
JOIN	Relational.ConsumerTransaction_MyRewards CT ON CT.CINID = F.CINID
JOIN	#CC C ON C.ConsumerCombinationID = CT.ConsumerCombinationID
WHERE	TranDate >= DATEADD(MONTH,-12,GETDATE())
AND		(AwarenessLevel = '1 - Gold'
OR		AwarenessLevel = '2 - Silver'
OR		AwarenessLevel = '1 - Bronze')


IF OBJECT_ID('Sandbox.SamW.MatalanCompetitorStealEng161020') IS NOT NULL DROP TABLE Sandbox.SamW.MatalanCompetitorStealEng161020
SELECT CINID
INTO Sandbox.SamW.MatalanCompetitorStealEng161020
FROM Sandbox.SamW.MatalanCompetitorSteal161020
WHERE Region <> 'Scotland'
AND Region <> 'Wales'
AND Region <> 'Northern Ireland'
AND Region <> 'Null'

--IF OBJECT_ID('Sandbox.SamW.MatalanCompetitorStealScot161020') IS NOT NULL DROP TABLE Sandbox.SamW.MatalanCompetitorStealScot161020
--SELECT CINID
--INTO Sandbox.SamW.MatalanCompetitorStealScot161020
--FROM Sandbox.SamW.MatalanCompetitorSteal161020
--WHERE Region = 'Scotland'


--IF OBJECT_ID('Sandbox.SamW.MatalanCompetitorStealWales161020') IS NOT NULL DROP TABLE Sandbox.SamW.MatalanCompetitorStealWales161020
--SELECT CINID
--INTO Sandbox.SamW.MatalanCompetitorStealWales161020
--FROM Sandbox.SamW.MatalanCompetitorSteal161020
--WHERE Region = 'Wales'

--IF OBJECT_ID('Sandbox.SamW.MatalanCompetitorStealNorhternIreland161020') IS NOT NULL DROP TABLE Sandbox.SamW.MatalanCompetitorStealNorhternIreland161020
--SELECT CINID
--INTO Sandbox.SamW.MatalanCompetitorStealNorhternIreland161020
--FROM Sandbox.SamW.MatalanCompetitorSteal161020
--WHERE Region = 'Norhtern Ireland'



IF OBJECT_ID('tempdb..#Spenders') IS NOT NULL DROP TABLE #Spenders
SELECT	F.CINID
		,AwarenessLevel
		,Region
		,SUM(Amount) Spend
		,NTILE(10) OVER (ORDER BY SUM(Amount) DESC) RankedSpenders
		,COUNT(*) Transactions
		,NTILE(10) OVER (ORDER BY COUNT(*) DESC) RankedTransactions
INTO #Spenders
FROM	#FullBase F
JOIN	Relational.ConsumerTransaction_MyRewards CT ON F.CINID = CT.CINID
JOIN	Relational.ConsumerCombination CC ON CC.ConsumerCombinationID = CT.ConsumerCombinationID
WHERE	BrandID = 277
AND		TranDate >= DATEADD(MONTH,-12,GETDATE())
AND		Amount > 0
GROUP BY F.CINID
		,AwarenessLevel
		,Region

IF OBJECT_ID('Sandbox.SamW.MatalanTopSpenders161020') IS NOT NULL DROP TABLE Sandbox.SamW.MatalanTopSpenders161020
SELECT	S.CINID
		,Region
INTO Sandbox.SamW.MatalanTopSpenders161020
FROM	#Spenders S
WHERE	RankedSpenders <= 1
AND		RankedTransactions <= 1
AND		(AwarenessLevel = '1 - Gold')


IF OBJECT_ID('Sandbox.SamW.MatalanTopSpendersEng161020') IS NOT NULL DROP TABLE Sandbox.SamW.MatalanTopSpendersEng161020
SELECT CINID
INTO Sandbox.SamW.MatalanTopSpendersEng161020
FROM Sandbox.SamW.MatalanTopSpenders161020
WHERE Region <> 'Scotland'
AND Region <> 'Wales'
AND Region <> 'Northern Ireland'
AND Region <> 'Null'

--IF OBJECT_ID('Sandbox.SamW.MatalanTopSpendersScot161020') IS NOT NULL DROP TABLE Sandbox.SamW.MatalanTopSpendersScot161020
--SELECT CINID
--INTO Sandbox.SamW.MatalanTopSpendersScot161020
--FROM Sandbox.SamW.MatalanTopSpenders161020
--WHERE Region = 'Scotland'

--IF OBJECT_ID('Sandbox.SamW.MatalanTopSpendersWales161020') IS NOT NULL DROP TABLE Sandbox.SamW.MatalanTopSpendersWales161020
--SELECT CINID
--INTO Sandbox.SamW.MatalanTopSpendersWales161020
--FROM Sandbox.SamW.MatalanTopSpenders161020
--WHERE Region = 'Wales'

--IF OBJECT_ID('Sandbox.SamW.MatalanTopSpendersNorthernIreland161020') IS NOT NULL DROP TABLE Sandbox.SamW.MatalanTopSpendersNorthernIreland161020
--SELECT CINID
--INTO Sandbox.SamW.MatalanTopSpendersNorthernIreland161020
--FROM Sandbox.SamW.MatalanTopSpenders161020
--WHERE Region = 'Northern Ireland'




IF OBJECT_ID('tempdb..#Roc_Shopper_Segment_Members') IS NOT NULL DROP TABLE #Roc_Shopper_Segment_Members
SELECT	FanID
	,	ShopperSegmentTypeID
INTO #Roc_Shopper_Segment_Members
FROM [Segmentation].[Roc_Shopper_Segment_Members] sg
WHERE EndDate IS NULL
AND PartnerID = 3421
AND ShopperSegmentTypeID IN (7, 9)

CREATE CLUSTERED INDEX CIX_All ON #Roc_Shopper_Segment_Members (ShopperSegmentTypeID, FanID)
If Object_ID('Warehouse.Selections.ML018_PreSelection') Is Not Null Drop Table Warehouse.Selections.ML018_PreSelectionSelect FanIDINTO Warehouse.Selections.ML018_PreSelectionFROM #FullBase fbWHERE EXISTS (	SELECT 1				FROM Sandbox.SamW.MatalanCompetitorStealEng161020 st				WHERE fb.CINID = st.CINID)
AND EXISTS (	SELECT 1
				FROM #Roc_Shopper_Segment_Members sg
				WHERE sg.ShopperSegmentTypeID = 7
				AND fb.FanID = sg.FanID)INSERT INTO Warehouse.Selections.ML018_PreSelectionSelect FanIDFROM #FullBase fbWHERE EXISTS (	SELECT 1				FROM Sandbox.SamW.MatalanTopSpendersEng161020 st				WHERE fb.CINID = st.CINID)
AND EXISTS (	SELECT 1
				FROM #Roc_Shopper_Segment_Members sg
				WHERE sg.ShopperSegmentTypeID = 9
				AND fb.FanID = sg.FanID)END