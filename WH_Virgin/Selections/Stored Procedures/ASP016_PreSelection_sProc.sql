-- =============================================
-- Author:  <Rory Francis>
-- Create date: <2020-12-11>
-- Description: < sProc to run preselection code per camapign >
-- =============================================
CREATE PROCEDURE [Selections].[ASP016_PreSelection_sProc]
AS
BEGIN

IF OBJECT_ID('tempdb..#FB') IS NOT NULL DROP TABLE #FB
SELECT	CINID
		,FanID
		,AgeCurrent
INTO #FB
FROM	Derived.Customer C
JOIN	Derived.CINList CL ON CL.CIN = C.SourceUID
WHERE	C.CurrentlyActive = 1
AND		SourceUID NOT IN (SELECT SourceUID FROM Derived.Customer_DuplicateSourceUID) 


IF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC
SELECT	BrandName
		,CC.BrandID
		,ConsumerCombinationID
INTO #CC
FROM	Trans.ConsumerCombination CC
JOIN	warehouse.Relational.Brand B ON B.BrandID = CC.BrandID
WHERE	CC.BrandID IN (2665,2085,2660,2107,1651)


IF OBJECT_ID('tempdb..#shoppper') IS NOT NULL DROP TABLE #shoppper
select  ct.CINID
into #shoppper
from Trans.ConsumerTransaction ct
join #CC cc
	on ct.ConsumerCombinationID = cc.ConsumerCombinationID
join #FB fb
	on ct.CINID = fb.CINID
where trandate >= DATEADD(MONTH,-24,GETDATE())
and amount > 0
group by ct.CINID


-- shoppers - SOW
IF OBJECT_ID('Sandbox.vernon.VM_aspinal_comp_steal_090821') IS NOT NULL DROP TABLE Sandbox.vernon.VM_aspinal_comp_steal_090821
SELECT	F.CINID
INTO Sandbox.vernon.VM_aspinal_comp_steal_090821
FROM #shoppper F

If Object_ID('WH_Virgin.Selections.ASP016_PreSelection') Is Not Null Drop Table WH_Virgin.Selections.ASP016_PreSelection
Select FanID
Into WH_Virgin.Selections.ASP016_PreSelection
From #FB fb
WHERE EXISTS (	SELECT 1
				FROM Sandbox.vernon.VM_aspinal_comp_steal_090821 cs
				WHERE fb.CINID = cs.CINID)


END