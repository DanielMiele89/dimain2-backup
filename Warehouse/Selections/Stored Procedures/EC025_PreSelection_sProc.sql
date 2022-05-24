-- =============================================-- Author:  <Rory Francis>-- Create date: <2021-07-24>-- Description: < sProc to run preselection code per camapign >-- =============================================CREATE PROCEDURE [Selections].[EC025_PreSelection_sProc]ASBEGIN
IF OBJECT_ID('tempdb..#FB') IS NOT NULL DROP TABLE #FB
SELECT	CINID
		,FanID
INTO #FB
FROM	Relational.Customer C
JOIN	Relational.CINList CL ON CL.CIN = C.SourceUID
WHERE	C.CurrentlyActive = 1
AND		SourceUID NOT IN (SELECT SourceUID FROM Staging.Customer_DuplicateSourceUID) 

CREATE CLUSTERED INDEX CIX_CINID ON #FB (CINID)
CREATE NONCLUSTERED INDEX IX_FanID ON #FB (FanID)

IF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC
SELECT	 CC.ConsumerCombinationID AS ConsumerCombinationID
		, B.BrandName AS BrandName
INTO #CC 
FROM Relational.ConsumerCombination CC
JOIN Relational.Brand B ON CC.BrandID = B.BrandID
WHERE B.BrandID IN (1831,1093,2414,1495,2388,2453,2161,2625,1504,2544,2516,3360,3362,3363,3359,3366,3376)	-- Competitor: airbnb, Center Parcs, Forest Holidays, Haven Holidays, Holiday Cottages, HomeAway, National Trust, Park Holidays, Parkdean Resorts
			

CREATE CLUSTERED INDEX CIX_ConsumerCombinationID ON #CC (ConsumerCombinationID)																								-- Pontins UK, Sykes Cottage, Heart of the Lakes, Lakelovers,Rural Retreats, The Landmark Trust,Toad Hall Cottages,The Original Cottage


DECLARE @DATE_24 DATE = DATEADD(MONTH, -24, GETDATE())

IF OBJECT_ID('tempdb..#Trans') IS NOT NULL DROP TABLE #Trans
SELECT	 CT.CINID as CINID
		, SUM(Amount) AS Total_Spend
INTO #Trans
FROM Relational.ConsumerTransaction_MyRewards CT
JOIN #CC CC 
	ON CT.ConsumerCombinationID = CC.ConsumerCombinationID
JOIN #FB F 
	ON F.CINID = CT.CINID
WHERE TranDate > @DATE_24
GROUP BY CT.CINID
HAVING SUM(Amount) <> 0;


IF OBJECT_ID('Sandbox.RukanK.Europcar_compsteal') IS NOT NULL DROP TABLE Sandbox.RukanK.Europcar_compsteal
SELECT	CINID
INTO Sandbox.RukanK.Europcar_compsteal
FROM #Trans

--select count(*) from Sandbox.RukanK.Europcar_compstealIf Object_ID('Warehouse.Selections.EC025_PreSelection') Is Not Null Drop Table Warehouse.Selections.EC025_PreSelectionSelect FanIDInto Warehouse.Selections.EC025_PreSelectionFROM #FB fbWHERE EXISTS (	SELECT 1				FROM SANDBOX.RUKANK.EUROPCAR_COMPSTEAL st				WHERE fb.CINID = st.CINID)END