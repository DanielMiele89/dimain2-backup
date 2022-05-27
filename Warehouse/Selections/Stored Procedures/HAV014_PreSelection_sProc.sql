CREATE PROCEDURE [Selections].[HAV014_PreSelection_sProc]
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
WHERE	CC.BrandID IN (2203,3465,3466,3467,3469,3470,3471,3473,1093,2625,1504)

DECLARE @DATE_36 DATE = DATEADD(MONTH,-36,GETDATE())

IF OBJECT_ID('Sandbox.bastienc.havencompsteal') IS NOT NULL DROP TABLE Sandbox.bastienc.havencompsteal
select  ct.CINID
INTO Sandbox.bastienc.havencompsteal
from Warehouse.Relational.ConsumerTransaction_MyRewards ct
join #CC cc
	on ct.ConsumerCombinationID = cc.ConsumerCombinationID
join #FB fb
	on ct.CINID = fb.CINID
where trandate >= @DATE_36
and amount > 0
group by ct.CINID


IF OBJECT_ID('[Warehouse].[Selections].[HAV014_PreSelection]') IS NOT NULL DROP TABLE [Warehouse].[Selections].[HAV014_PreSelection]
SELECT FanID
INTO [Warehouse].[Selections].[HAV014_PreSelection]
FROM #FB fb
WHERE EXISTS (	SELECT 1
				FROM Sandbox.bastienc.havencompsteal hcs
				WHERE fb.CINID = hcs.CINID)

END
