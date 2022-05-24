CREATE PROCEDURE [Selections].[SIC009_PreSelection_sProc]
AS
BEGIN

IF OBJECT_ID('tempdb..#FB') IS NOT NULL DROP TABLE #FB
SELECT	CINID ,FanID
INTO	#FB
FROM	Relational.Customer C
JOIN	Relational.CINList CL ON CL.CIN = C.SourceUID
WHERE	C.CurrentlyActive = 1
AND		SourceUID NOT IN (SELECT SourceUID FROM Staging.Customer_DuplicateSourceUID)

IF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC
SELECT	ConsumerCombinationID
INTO	#CC
FROM	Relational.ConsumerCombination CC
WHERE	CC.BrandID = 2526		

DECLARE @DATE_12 DATE = DATEADD(MONTH,-12,GETDATE())

IF OBJECT_ID('tempdb..#Txn') IS NOT NULL DROP TABLE #Txn
SELECT  CT.CINID
INTO	#Txn
FROM	Relational.ConsumerTransaction_MyRewards CT
JOIN	#CC CC	ON CT.ConsumerCombinationID = CC.ConsumerCombinationID
JOIN	#FB FB	ON CT.CINID = FB.CINID
WHERE	TranDate >= @DATE_12
		AND Amount >= 9.99
GROUP BY CT.CINID

IF OBJECT_ID('Sandbox.rukank.SimplyCook_05112021') IS NOT NULL DROP TABLE Sandbox.rukank.SimplyCook_05112021
SELECT	F.CINID
INTO	Sandbox.rukank.SimplyCook_05112021
FROM	#FB F
WHERE	CINID NOT IN (SELECT * FROM #Txn)
GROUP BY F.CINID

IF OBJECT_ID('[Warehouse].[Selections].[SIC009_PreSelection]') IS NOT NULL DROP TABLE [Warehouse].[Selections].[SIC009_PreSelection]
SELECT	fb.FanID
INTO [Warehouse].[Selections].[SIC009_PreSelection]
FROM #FB fb
WHERE EXISTS (	SELECT 1
				FROM Sandbox.RukanK.SimplyCook_05112021 sb
				WHERE fb.CINID = sb.CINID)

END;