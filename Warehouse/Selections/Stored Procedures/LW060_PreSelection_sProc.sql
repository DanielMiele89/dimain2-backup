-- =============================================-- Author:  <Rory Francis>-- Create date: <2020-10-04>-- Description: < sProc to run preselection code per camapign >-- =============================================CREATE PROCEDURE Selections.LW060_PreSelection_sProcASBEGIN-- Capture Customer Actions Table, with Newsletter Engagement
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

 IF OBJECT_ID('tempdb..#LapsedandShoppers') IS NOT NULL DROP TABLE #LapsedandShoppers
 SELECT DISTINCT F.CINID
 INTO #LapsedandShoppers
 FROM #FB F
 JOIN Relational.ConsumerTransaction_MyRewards CT ON CT.CINID = F.CINID
 JOIN Relational.ConsumerCombination CC ON CC.ConsumerCombinationID = CT.ConsumerCombinationID
 WHERE TranDate >= DATEADD(MONTH,-24,GETDATE())
 AND BrandID = 246

 IF OBJECT_ID('Sandbox.SamW.LaithwaitesAcquiredEngaged02072020') IS NOT NULL DROP TABLE Sandbox.SamW.LaithwaitesAcquiredEngaged02072020
 SELECT DISTINCT CINID, FanID
 INTO Sandbox.SamW.LaithwaitesAcquiredEngaged02072020
 FROM	#FB F
 WHERE	AwarenessLevel = '1 - Gold'
 AND CINID NOT IN (SELECT CINID FROM #LapsedandShoppers)

 -- IF OBJECT_ID('Sandbox.SamW.LaithwaitesAcquiredNotEngaged02072020') IS NOT NULL DROP TABLE Sandbox.SamW.LaithwaitesAcquiredNotEngaged02072020
 --SELECT DISTINCT CINID, FanID
 --INTO Sandbox.SamW.LaithwaitesAcquiredNotEngaged02072020
 --FROM	#FB F
 --WHERE	AwarenessLevel <> '1 - Gold'
 --AND CINID NOT IN (SELECT CINID FROM #LapsedandShoppers)






If Object_ID('Warehouse.Selections.LW060_PreSelection') Is Not Null Drop Table Warehouse.Selections.LW060_PreSelectionSelect FanIDInto Warehouse.Selections.LW060_PreSelectionFROM  SANDBOX.SAMW.LaithwaitesAcquiredEngaged02072020END