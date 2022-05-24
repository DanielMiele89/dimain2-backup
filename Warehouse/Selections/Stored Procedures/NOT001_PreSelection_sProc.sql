-- =============================================-- Author:  <Rory Francis>-- Create date: <2020-10-02>-- Description: < sProc to run preselection code per camapign >-- =============================================CREATE PROCEDURE Selections.NOT001_PreSelection_sProcASBEGINIF OBJECT_ID('tempdb..#FB') IS NOT NULL DROP TABLE #FB
SELECT CINID
		,FANID
INTO #FB
FROM	Relational.Customer C
JOIN	Relational.CINList CL 
	ON CL.CIN = C.SourceUID
WHERE	C.CurrentlyActive = 1
AND		C.SourceUID NOT IN (SELECT SourceUID FROM Staging.Customer_DuplicateSourceUID)
CREATE CLUSTERED INDEX ix_CINID ON #FB(CINID)


IF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC
SELECT ConsumerCombinationID
INTO #CC
FROM	Relational.ConsumerCombination CC
WHERE	BrandID = 1426
CREATE CLUSTERED INDEX ix_ConsumerCombinationID ON #CC(ConsumerCombinationID)


IF OBJECT_ID('tempdb..#PreApril19') IS NOT NULL DROP TABLE #PreApril19
SELECT	F.CINID
		,MAX(TranDate) LastTranDate
INTO	#PreApril19
FROM	#FB F
JOIN	Relational.ConsumerTransaction_MyRewards CT
	ON F.CINID = CT.CINID
JOIN	#CC C 
	ON C.ConsumerCombinationID = CT.ConsumerCombinationID
WHERE	TranDate < '2019-04-01'
GROUP BY F.CINID

IF OBJECT_ID('tempdb..#PostApril19') IS NOT NULL DROP TABLE #PostApril19
SELECT	F.CINID
INTO	#PostApril19
FROM	#FB F
JOIN	Relational.ConsumerTransaction_MyRewards CT
	ON F.CINID = CT.CINID
JOIN	#CC C 
	ON C.ConsumerCombinationID = CT.ConsumerCombinationID
WHERE	TranDate BETWEEN '2019-04-01' AND '2020-03-31'

IF OBJECT_ID('tempdb..#Lockdown') IS NOT NULL DROP TABLE #Lockdown
SELECT	DISTINCT F.CINID, F.FanID
INTO	#Lockdown
FROM	#FB F
JOIN	Relational.ConsumerTransaction_MyRewards CT
	ON F.CINID = CT.CINID
JOIN	#CC C 
	ON C.ConsumerCombinationID = CT.ConsumerCombinationID
WHERE	TranDate >= '2020-04-01'

IF OBJECT_ID('Sandbox.SamW.NOTHSShoppers200720') IS NOT NULL DROP TABLE Sandbox.SamW.NOTHSShoppers200720
SELECT CINID, FanID
INTO Sandbox.SamW.NOTHSShoppers200720
FROM	#Lockdown
WHERE	CINID NOT IN (SELECT CINID FROM #PostApril19)
If Object_ID('Warehouse.Selections.NOT001_PreSelection') Is Not Null Drop Table Warehouse.Selections.NOT001_PreSelectionSelect FanIDInto Warehouse.Selections.NOT001_PreSelectionFROM  SANDBOX.SAMW.NOTHSSHOPPERS200720END