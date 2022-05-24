-- =============================================-- Author:  <Rory Francis>-- Create date: <2021-04-18>-- Description: < sProc to run preselection code per camapign >-- =============================================CREATE PROCEDURE [Selections].[LE025_PreSelection_sProc]ASBEGIN--	LE025IF OBJECT_ID('tempdb..#FB') IS NOT NULL DROP TABLE #FB
SELECT	CINID ,FanID
INTO #FB
FROM	Relational.Customer C
JOIN	Relational.CINList CL ON CL.CIN = C.SourceUID
WHERE	C.CurrentlyActive = 1
AND		SourceUID NOT IN (SELECT SourceUID FROM Staging.Customer_DuplicateSourceUID)
CREATE CLUSTERED INDEX ix_CINID on #FB(CINID)

-- boden, cotton & joules
IF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC;
SELECT ConsumerCombinationID
INTO #CC
FROM warehouse.Relational.CONSUMERCOMBINATION
WHERE BRANDID IN (56,105,1724);

-- m&S and debenhams
IF OBJECT_ID('tempdb..#CC1') IS NOT NULL DROP TABLE #CC1;
SELECT ConsumerCombinationID
INTO #CC1
FROM warehouse.Relational.CONSUMERCOMBINATION
WHERE BRANDID IN (116,274);

-- fashion brands
IF OBJECT_ID('tempdb..#CC2') IS NOT NULL DROP TABLE #CC2;
SELECT ConsumerCombinationID
INTO #CC2
FROM warehouse.Relational.CONSUMERCOMBINATION
WHERE BRANDID IN (select BrandID from Warehouse.Relational.Brand where SectorID between 51 and 59);

DECLARE @DATE_24 DATE = DATEADD(MONTH,-24,GETDATE())

--customer who shopped at boden, cotton & joules
IF OBJECT_ID('tempdb..#Txn') IS NOT NULL DROP TABLE #Txn
SELECT  CT.CINID AS CINID
INTO	#Txn
FROM	Relational.ConsumerTransaction_MyRewards CT
JOIN	#CC CC	ON ct.ConsumerCombinationID = cc.ConsumerCombinationID
JOIN	#FB FB	ON ct.CINID = fb.CINID
WHERE	TranDate >= @DATE_24
		AND Amount > 0
GROUP BY CT.CINID

DECLARE @DATE_6 DATE = DATEADD(MONTH,-6,GETDATE())

-- customers who shopped at a fashion brand
IF OBJECT_ID('tempdb..#Txn_fashion') IS NOT NULL DROP TABLE #Txn_fashion
SELECT  CT.CINID AS CINID
INTO	#Txn_fashion
FROM	Relational.ConsumerTransaction_MyRewards CT
JOIN	#CC2 CC	ON ct.ConsumerCombinationID = cc.ConsumerCombinationID
JOIN	#FB FB	ON ct.CINID = fb.CINID
WHERE	TranDate >= @DATE_6
		AND Amount > 0
GROUP BY CT.CINID

DECLARE @DATE_24_2 DATE = DATEADD(MONTH,-24,GETDATE())

-----customers who shopped m&S and debenhams
IF OBJECT_ID('tempdb..#Txn_MS_DEB') IS NOT NULL DROP TABLE #Txn_MS_DEB
SELECT  CT.CINID AS CINID
INTO	#Txn_MS_DEB
FROM	Relational.ConsumerTransaction_MyRewards CT
JOIN	#CC1 CC	ON CT.ConsumerCombinationID = cc.ConsumerCombinationID
JOIN	#FB FB	ON CT.CINID = FB.CINID
JOIN	#Txn_fashion FAS ON FAS.CINID = CT.CINID
WHERE	TranDate >= @DATE_24_2
		AND Amount > 0
GROUP BY CT.CINID


IF OBJECT_ID('tempdb..#Ntile') IS NOT NULL DROP TABLE #Ntile
SELECT	  CINID 
		, NTILE(2) OVER (ORDER BY CINID ASC) AS NTILE_2
INTO	#Ntile
FROM	(SELECT CINID FROM #Txn
			UNION 
		 SELECT CINID FROM #Txn_MS_DEB 
		) a

IF OBJECT_ID('Sandbox.RukanK.Landsend_CompSteal_10pct') IS NOT NULL DROP TABLE Sandbox.RukanK.Landsend_CompSteal_10pct;
SELECT CINID
INTO Sandbox.RukanK.Landsend_CompSteal_10pct
FROM #Ntile
WHERE	NTILE_2 IN (2)If Object_ID('Warehouse.Selections.LE025_PreSelection') Is Not Null Drop Table Warehouse.Selections.LE025_PreSelectionSelect FanIDInto Warehouse.Selections.LE025_PreSelectionFROM #FB fbWHERE EXISTS (	SELECT 1				FROM Sandbox.RukanK.Landsend_CompSteal_10pct cl				WHERE fb.CINID = cl.CINID)END