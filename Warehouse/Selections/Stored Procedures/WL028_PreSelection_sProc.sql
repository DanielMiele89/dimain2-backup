-- =============================================-- Author:  <Rory Francis>-- Create date: <2021-03-19>-- Description: < sProc to run preselection code per camapign >-- =============================================CREATE PROCEDURE Selections.WL028_PreSelection_sProcASBEGINIF OBJECT_ID('tempdb..#FB') IS NOT NULL DROP TABLE #FB
SELECT	CINID
		,FanID
		,AgeCurrent
INTO #FB
FROM	Relational.CINList CL
JOIN	Relational.Customer C ON C.SourceUID = CL.CIN
WHERE	C.CurrentlyActive = 1
AND		SourceUID NOT IN (SELECT SourceUID FROM Staging.Customer_DuplicateSourceUID)

IF OBJECT_ID('tempdb..#TravelCC') IS NOT NULL DROP TABLE #TravelCC
SELECT	ConsumerCombinationID
INTO #TravelCC
FROM	Relational.ConsumerCombination CC
WHERE	BrandID IN (1010,869,1004,1386,3189,2390,3188,3190)


IF OBJECT_ID('tempdb..#HotelsCC') IS NOT NULL DROP TABLE #HotelsCC
SELECT	ConsumerCombinationID
INTO #HotelsCC
FROM	Relational.ConsumerCombination CC
WHERE	BrandID IN (351,2062)



IF OBJECT_ID('Sandbox.SamW.WarnerLeisureTravel161020') IS NOT NULL DROP TABLE Sandbox.SamW.WarnerLeisureTravel161020
SELECT	F.CINID
		,FanID
INTO Sandbox.SamW.WarnerLeisureTravel161020
FROM	#FB F
JOIN	Relational.ConsumerTransaction_MyRewards CT ON F.CINID = CT.CINID
JOIN	#TravelCC T ON CT.ConsumerCombinationID = T.ConsumerCombinationID
WHERE	TranDate >= DATEADD(MONTH,-12,GETDATE())
AND		Amount > 0
AND		FanID NOT IN (SELECT FanID FROM InsightArchive.Haven_CustomerMatches_20200122)


IF OBJECT_ID('Sandbox.SamW.WarnerLeisureHotels161020') IS NOT NULL DROP TABLE Sandbox.SamW.WarnerLeisureHotels161020
SELECT	F.CINID
		,FanID
INTO Sandbox.SamW.WarnerLeisureHotels161020
FROM	#FB F
JOIN	Relational.ConsumerTransaction_MyRewards CT ON F.CINID = CT.CINID
JOIN	#HotelsCC T ON CT.ConsumerCombinationID = T.ConsumerCombinationID
WHERE	TranDate >= DATEADD(MONTH,-12,GETDATE())
AND		Amount > 0
AND		AgeCurrent >= 45
AND		AgeCurrent <= 70
AND		FanID NOT IN (SELECT FanID FROM InsightArchive.Haven_CustomerMatches_20200122)


IF OBJECT_ID('Sandbox.SamW.WarnerLeisureBAU161020') IS NOT NULL DROP TABLE Sandbox.SamW.WarnerLeisureBAU161020
SELECT	CINID
INTO Sandbox.SamW.WarnerLeisureBAU161020
FROM	#FB
WHERE	CINID NOT IN (SELECT CINID FROM Sandbox.SamW.WarnerLeisureHotels161020)
AND		CINID NOT IN (SELECT CINID FROM Sandbox.SamW.WarnerLeisureTravel161020)
AND		FanID NOT IN (SELECT FanID FROM InsightArchive.Haven_CustomerMatches_20200122)

IF OBJECT_ID('Sandbox.SamW.WarnerLeisureKeyTargetting161020') IS NOT NULL DROP TABLE Sandbox.SamW.WarnerLeisureKeyTargetting161020
SELECT A.CINID
INTO Sandbox.SamW.WarnerLeisureKeyTargetting161020
FROM	(SELECT		CINID
		FROM Sandbox.SamW.WarnerLeisureHotels161020
UNION	
SELECT CINID
FROM	Sandbox.SamW.WarnerLeisureTravel161020) A


--SELECT COUNT(DISTINCT S.CINID)
--FROM Sandbox.SamW.WarnerLeisureBAU161020 S
--JOIN Relational.ConsumerTransaction_MyRewards CT ON S.CINID = CT.CINID
--JOIN Relational.ConsumerCombination CC ON CC.CONSUMERCOMBINATIONID = CT.CONSUMERCOMBINATIONID
--WHERE BrandID = 2236
--AND TranDate >= DATEADD(MONTH,-36,GETDATE())

--Shopper 755
--Lapsed 1666
--Acquire 133705
--12
--36


--SELECT COUNT(DISTINCT S.CINID) 
--FROM Sandbox.SamW.WarnerLeisureKeyTargetting161020 S
--JOIN Relational.ConsumerTransaction_MyRewards CT ON S.CINID = CT.CINID
--JOIN Relational.ConsumerCombination CC ON CC.CONSUMERCOMBINATIONID = CT.CONSUMERCOMBINATIONID
--WHERE BrandID = 2236
--AND TranDate >= DATEADD(MONTH,-36,GETDATE())

If Object_ID('Warehouse.Selections.WL028_PreSelection') Is Not Null Drop Table Warehouse.Selections.WL028_PreSelectionSelect FanIDInto Warehouse.Selections.WL028_PreSelection
FROM	#FB
WHERE	CINID  IN (SELECT CINID FROM Sandbox.SamW.WarnerLeisureKeyTargetting161020)END