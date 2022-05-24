CREATE PROCEDURE [Selections].[STW027_PreSelection_sProc]
AS
BEGIN

IF OBJECT_ID('tempdb..#FB') IS NOT NULL DROP TABLE #FB
SELECT	CINID ,FanID
INTO #FB
FROM	Relational.Customer C
JOIN	Relational.CINList CL ON CL.CIN = C.SourceUID
WHERE	C.CurrentlyActive = 1
AND		SourceUID NOT IN (SELECT SourceUID FROM Staging.Customer_DuplicateSourceUID) 


IF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC
SELECT	BrandName 
		,CC.BrandID
		,ConsumerCombinationID
INTO #CC
FROM	Relational.ConsumerCombination CC
JOIN	Relational.Brand B ON B.BrandID = CC.BrandID
WHERE	CC.BrandID IN (2648)

DECLARE @DATE_12 DATE = DATEADD(MONTH,-12,GETDATE())

IF OBJECT_ID('tempdb..#shoppper') IS NOT NULL DROP TABLE #shoppper
SELECT DISTINCT ct.CINID
		,COUNT(CT.CINID) Txn
INTO	#shoppper
FROM	Relational.ConsumerTransaction_MyRewards ct
JOIN	#CC cc	ON ct.ConsumerCombinationID = cc.ConsumerCombinationID
JOIN	#FB fb	ON ct.CINID = fb.CINID
WHERE	TranDate >= @DATE_12
		AND Amount > 0
GROUP BY ct.CINID

IF OBJECT_ID('Sandbox.rukank.STWC_shopper_2txn') IS NOT NULL DROP TABLE Sandbox.rukank.STWC_shopper_2txn
SELECT	F.CINID
INTO Sandbox.rukank.STWC_shopper_2txn
FROM #shoppper F
WHERE Txn >= 2
GROUP BY F.CINID

IF OBJECT_ID('[Warehouse].[Selections].[STW027_PreSelection]') IS NOT NULL DROP TABLE [Warehouse].[Selections].[STW027_PreSelection]
SELECT	fb.FanID
INTO [Warehouse].[Selections].[STW027_PreSelection]
FROM #FB fb
WHERE EXISTS (	SELECT 1
				FROM Sandbox.rukank.STWC_shopper_2txn sb
				WHERE fb.CINID = sb.CINID)


END;