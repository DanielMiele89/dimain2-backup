-- =============================================-- Author:  <Rory Francis>-- Create date: <2019-11-04>-- Description: < sProc to run preselection code per camapign >-- =============================================Create Procedure Selections.BB017_PreSelection_sProcASBEGIN

IF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC
SELECT 
 ConsumerCombinationID
INTO #CC
FROM Warehouse.Relational.ConsumerCombination cc
WHERE BrandID IN (298, 1077, 1098, 1434, 2240, 2429, 2612)

CREATE CLUSTERED INDEX cix_ConsumerCombinationID ON #CC (ConsumerCombinationID)

IF OBJECT_ID('tempdb..#SectorShoppers') IS NOT NULL DROP TABLE #SectorShoppers
SELECT
 CT.CINID,
 FANID,
 SUM(Amount) AS Sales
INTO #SectorShoppers
FROM Warehouse.Relational.ConsumerTransaction_MyRewards ct WITH (NOLOCK)
JOIN #CC cc
 ON cc.ConsumerCombinationID = ct.ConsumerCombinationID
JOIN Relational.CINList CL ON CT.CINID = CL.CINID
JOIN Relational.Customer C ON C.SourceUID = CL.CIN
WHERE ct.TranDate BETWEEN '2018-10-01' AND '2019-09-30'
 AND 0 < Amount
GROUP BY
 CT.CINID, FanID

CREATE CLUSTERED INDEX cix_CINID ON #SectorShoppers (CINID)

IF OBJECT_ID('tempdb..#MostValuableCustomer') IS NOT NULL DROP TABLE #MostValuableCustomer
SELECT 
 *
INTO #MostValuableCustomer
FROM (
		SELECT
		 CINID,
		 FanID,
		 Sales,
		 NTILE(2) OVER (ORDER BY Sales DESC) AS MostValuableCustomer
		FROM #SectorShoppers
	 ) a
WHERE MostValuableCustomer = 1

CREATE CLUSTERED INDEx cix_CINID ON #MostValuableCustomer (CINID)

SELECT COUNT(*) FROM #MostValuableCustomer

IF OBJECT_ID('Sandbox.SamW.ByronMVC101019') IS NOT NULL DROP TABLE Sandbox.SamW.ByronMVC101019
SELECT
CINID,FANID
INTO Sandbox.SamW.ByronMVC101019
FROM #MostValuableCustomer
WHERE CINID NOT IN (SELECT CINID FROM Sandbox.Samw.ByronCompSteal101019)If Object_ID('Warehouse.Selections.BB017_PreSelection') Is Not Null Drop Table Warehouse.Selections.BB017_PreSelectionSelect FanIDInto Warehouse.Selections.BB017_PreSelectionFrom Sandbox.SamW.ByronMVC101019END