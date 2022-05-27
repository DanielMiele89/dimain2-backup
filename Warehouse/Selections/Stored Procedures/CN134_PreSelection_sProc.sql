-- =============================================-- Author:  <Rory Francis>-- Create date: <2021-04-18>-- Description: < sProc to run preselection code per camapign >-- =============================================CREATE PROCEDURE [Selections].[CN134_PreSelection_sProc]ASBEGINIF OBJECT_ID('tempdb..#FB') IS NOT NULL DROP TABLE #FB
SELECT	CINID ,FanID
INTO #FB
FROM	Relational.Customer C
JOIN	Relational.CINList CL ON CL.CIN = C.SourceUID
WHERE	C.CurrentlyActive = 1
AND		SourceUID NOT IN (SELECT SourceUID FROM Staging.Customer_DuplicateSourceUID)

CREATE CLUSTERED INDEX ix_CINID on #FB(CINID)

IF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC
SELECT	ConsumerCombinationID
INTO #CC
FROM	warehouse.Relational.ConsumerCombination CC
WHERE	CC.BrandID = 75


IF OBJECT_ID('tempdb..#Txn') IS NOT NULL DROP TABLE #Txn
SELECT  CT.CINID
		,COUNT(1) AS Old_Txn
INTO	#Txn
FROM	Relational.ConsumerTransaction_MyRewards CT
JOIN	#CC CC	ON ct.ConsumerCombinationID = cc.ConsumerCombinationID
JOIN	#FB FB	ON ct.CINID = fb.CINID
WHERE	TranDate BETWEEN '2019-08-01' AND '2020-08-31'
		AND Amount > 0
GROUP BY CT.CINID


IF OBJECT_ID('tempdb..#Txn2') IS NOT NULL DROP TABLE #Txn2
SELECT  CT.CINID
		,COUNT(1) AS New_Txn
INTO	#Txn2
FROM	Relational.ConsumerTransaction_MyRewards CT
JOIN	#CC CC	ON CT.ConsumerCombinationID = CC.ConsumerCombinationID
JOIN	#FB FB	ON CT.CINID = FB.CINID
WHERE	TranDate >= '2020-09-01' 
		AND Amount > 0
GROUP BY CT.CINID;


IF OBJECT_ID('tempdb..#Txn3') IS NOT NULL DROP TABLE #Txn3
SELECT  t2.CINID
		,Old_Txn
		,New_Txn
		,100.00 * (New_Txn -  Old_Txn) / Old_Txn AS Txn_Change
INTO	#Txn3
FROM	#Txn2 t2
JOIN	#Txn t1 on t1.CINID = t2.CINID
WHERE	New_Txn <> 0

-- Lapsed & Shopper: 50% atf drop Sep 2019 - Aug 2020 vs Sep 2020 - Aug 2021
IF OBJECT_ID('Sandbox.rukank.CaffeNero_Lapsed_Shopper_31082021') IS NOT NULL DROP TABLE Sandbox.rukank.CaffeNero_Lapsed_Shopper_31082021
SELECT	t3.CINID
INTO	Sandbox.rukank.CaffeNero_Lapsed_Shopper_31082021
FROM	#Txn3 t3
WHERE   Txn_Change <= -50.0
GROUP BY t3.CINIDIf Object_ID('Warehouse.Selections.CN134_PreSelection') Is Not Null Drop Table Warehouse.Selections.CN134_PreSelectionSelect FanIDInto Warehouse.Selections.CN134_PreSelectionFROM #FB fbWHERE EXISTS (	SELECT 1				FROM Sandbox.rukank.CaffeNero_Lapsed_Shopper_31082021 cl				WHERE fb.CINID = cl.CINID)END