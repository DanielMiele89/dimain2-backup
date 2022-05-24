﻿-- =============================================
IF OBJECT_ID('tempdb..#FB') IS NOT NULL DROP TABLE #FB
SELECT	CINID, FanID
INTO #FB
FROM	WH_Virgin.Derived.Customer C
JOIN	WH_Virgin.Derived.CINList CL ON CL.CIN = C.SourceUID
WHERE	C.CurrentlyActive = 1
and AccountType IS NOT NULL
AND		SourceUID NOT IN (SELECT SourceUID FROM Derived.Customer_DuplicateSourceUID) 
AND FANID NOT IN (SELECT FANID FROM Warehouse.[InsightArchive].[MorrisonsReward_MatchedCustomers_20190304])		--NOT A MORECARD OWNER--


IF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC
SELECT ConsumerCombinationID
		,BrandID
INTO #CC
FROM	WH_Virgin.trans.ConsumerCombination CC
WHERE	BrandID IN (292,21,379,425,2541,5,254)		-- Morrisons 292, Asda 21, Sainsburys 379, Tesco 425, Amazon Fresh 2541, Aldi 5, Lidl 254

IF OBJECT_ID('tempdb..#Trans') IS NOT NULL DROP TABLE #Trans
SELECT	F.CINID
		,1.0 * (CAST(SUM(CASE WHEN BrandID = 292 THEN Amount ELSE 0 END )as float) / NULLIF(SUM(Amount),0)) AS SoW
		,MAX(CASE WHEN BrandID = 292 AND TranDate >= DATEADD(MONTH,-3,GETDATE()) THEN 1 ELSE 0 END) BrandShopper
		,COUNT(1) as Transactions
INTO #Trans
FROM	#FB F
JOIN	WH_Virgin.trans.consumertransaction CT ON F.CINID = CT.CINID
JOIN	#CC C ON C.ConsumerCombinationID = CT.ConsumerCombinationID
WHERE	TranDate >= DATEADD(MONTH,-6,GETDATE())
		AND Amount > 0
GROUP BY F.CINID


IF OBJECT_ID('Sandbox.rukank.VM_Morrisons_LoW_SoW_17082021') IS NOT NULL DROP TABLE Sandbox.rukank.VM_Morrisons_LoW_SoW_17082021
SELECT	CINID
INTO Sandbox.rukank.VM_Morrisons_LoW_SoW_17082021
FROM	#Trans
WHERE BrandShopper = 1
	 AND SoW < 0.3
	 AND Transactions >= 55
GROUP BY CINID