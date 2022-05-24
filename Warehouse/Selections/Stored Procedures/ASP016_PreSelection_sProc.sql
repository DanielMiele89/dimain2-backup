-- =============================================-- Author:  <Rory Francis>-- Create date: <2019-11-29>-- Description: < sProc to run preselection code per camapign >-- =============================================CREATE Procedure [Selections].[ASP016_PreSelection_sProc]ASBEGIN

IF OBJECT_ID('tempdb..#FB') IS NOT NULL DROP TABLE #FB
SELECT	CINID
		,FanID
		,AgeCurrent
INTO #FB
FROM	Relational.Customer C
JOIN	Relational.CINList CL ON CL.CIN = C.SourceUID
WHERE	C.CurrentlyActive = 1
AND		SourceUID NOT IN (SELECT SourceUID FROM Staging.Customer_DuplicateSourceUID) 

CREATE CLUSTERED INDEX CIX_CINID ON #FB (CINID)
CREATE NONCLUSTERED INDEX IX_FanID ON #FB (FanID)

IF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC
SELECT	BrandName
		,CC.BrandID
		,ConsumerCombinationID
INTO #CC
FROM	warehouse.Relational.ConsumerCombination CC
JOIN	warehouse.Relational.Brand B ON B.BrandID = CC.BrandID
WHERE	CC.BrandID IN (2665,2085,2660,2107,1651)

CREATE CLUSTERED INDEX CIX_ConsumerCombinationID ON #CC (ConsumerCombinationID)

DECLARE @DATE_24 DATE = DATEADD(MONTH, -24, GETDATE())

IF OBJECT_ID('tempdb..#shoppper') IS NOT NULL DROP TABLE #shoppper
select  ct.CINID
into #shoppper
from Warehouse.Relational.ConsumerTransaction_MyRewards ct
join #CC cc
	on ct.ConsumerCombinationID = cc.ConsumerCombinationID
join #FB fb
	on ct.CINID = fb.CINID
where trandate >= @DATE_24
and amount > 0
group by ct.CINID


-- shoppers - SOW
IF OBJECT_ID('Sandbox.vernon.aspinal_comp_steal_090821') IS NOT NULL DROP TABLE Sandbox.vernon.aspinal_comp_steal_090821
SELECT	F.CINID
INTO Sandbox.vernon.aspinal_comp_steal_090821
FROM #shoppper F

If Object_ID('Warehouse.Selections.ASP016_PreSelection') Is Not Null Drop Table Warehouse.Selections.ASP016_PreSelectionSelect DISTINCT FanIDInto Warehouse.Selections.ASP016_PreSelectionFrom #FB fbWHERE EXISTS (	SELECT 1				FROM Sandbox.vernon.aspinal_comp_steal_090821 cs				WHERE fb.CINID = cs.CINID)END