﻿-- =============================================

IF OBJECT_ID('tempdb..#FB') IS NOT NULL DROP TABLE #FB
SELECT	CINID
		,FanID
INTO	#FB
FROM	WH_Visa.Derived.Customer  C
JOIN	WH_Visa.Derived.CINList CL ON CL.CIN = C.SourceUID
WHERE	C.CurrentlyActive = 1

IF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC
SELECT ConsumerCombinationID
INTO	#CC
FROM	WH_Visa.trans.ConsumerCombination  CC
WHERE	CC.BrandID IN (2648)


IF OBJECT_ID('tempdb..#Trans') IS NOT NULL DROP TABLE #Trans
SELECT	F.CINID
		,COUNT(CT.CINID) Txn
INTO	#Trans
FROM	WH_Visa.trans.consumertransaction CT
JOIN	#FB F ON F.CINID = CT.CINID
JOIN	#CC C 	ON C.ConsumerCombinationID = CT.ConsumerCombinationID
WHERE	TranDate > DATEADD(MONTH, -12, GETDATE())
		AND Amount > 0
GROUP BY F.CINID


IF OBJECT_ID('Sandbox.rukank.STWCshopper') IS NOT NULL DROP TABLE Sandbox.rukank.STWCshopper
SELECT	CINID
INTO Sandbox.rukank.STWCshopper
FROM	#Trans 
WHERE Txn = 1
GROUP BY CINID
