CREATE PROCEDURE [Selections].[HAV015_PreSelection_sProc]
AS
BEGIN

IF OBJECT_ID('tempdb..#FB') IS NOT NULL DROP TABLE #FB
SELECT	CINID
		,FanID
		,AgeCurrent
INTO #FB
FROM	Relational.Customer C
JOIN	Relational.CINList CL ON CL.CIN = C.SourceUID
WHERE	C.CurrentlyActive = 1
AND		SourceUID NOT IN (SELECT SourceUID FROM Staging.Customer_DuplicateSourceUID) 
--and AgeCurrent >= 55

IF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC
SELECT	BrandName
		,CC.BrandID
		,ConsumerCombinationID
INTO #CC
FROM	warehouse.Relational.ConsumerCombination CC
JOIN	warehouse.Relational.Brand B ON B.BrandID = CC.BrandID
WHERE	CC.BrandID IN (1495)

DECLARE @DATE_24 DATE = dateadd(month,-24,getdate())

IF OBJECT_ID('tempdb..#shoppers') IS NOT NULL DROP TABLE #shoppers
select  ct.CINID
INTO #shoppers
from Warehouse.Relational.ConsumerTransaction_MyRewards ct
join #CC cc
	on ct.ConsumerCombinationID = cc.ConsumerCombinationID
join #FB fb
	on ct.CINID = fb.CINID
where trandate >= @DATE_24
and amount > 0
group by ct.CINID

DECLARE @DATE_36 DATE = dateadd(month,-36,getdate())

IF OBJECT_ID('Sandbox.bastienc.havenreengage') IS NOT NULL DROP TABLE Sandbox.bastienc.havenreengage
select  ct.CINID
INTO Sandbox.bastienc.havenreengage
from Warehouse.Relational.ConsumerTransaction_MyRewards ct
join #CC cc
	on ct.ConsumerCombinationID = cc.ConsumerCombinationID
join #FB fb
	on ct.CINID = fb.CINID
where trandate >= @DATE_36
and amount > 0
and ct.cinid not in (select * from #shoppers)
group by ct.CINID

IF OBJECT_ID('[Warehouse].[Selections].[HAV015_PreSelection]') IS NOT NULL DROP TABLE [Warehouse].[Selections].[HAV015_PreSelection]
SELECT	fb.FanID
INTO [Warehouse].[Selections].[HAV015_PreSelection]
FROM #FB fb
WHERE EXISTS (	SELECT 1
				FROM Sandbox.bastienc.havenreengage sb
				WHERE fb.CINID = sb.CINID)


END;
