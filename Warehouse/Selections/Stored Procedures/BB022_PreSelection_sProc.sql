-- =============================================-- Author:  <Rory Francis>-- Create date: <2020-03-06>-- Description: < sProc to run preselection code per camapign >-- =============================================CREATE PROCEDURE Selections.BB022_PreSelection_sProcASBEGIN

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
WHERE ct.TranDate BETWEEN '2019-03-01' AND '2020-02-29'
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

IF OBJECT_ID('Sandbox.SamW.ByronMVC020320') IS NOT NULL DROP TABLE Sandbox.SamW.ByronMVC020320
SELECT
CINID,FANID
INTO Sandbox.SamW.ByronMVC020320
FROM #MostValuableCustomer
WHERE CINID NOT IN (SELECT CINID FROM Sandbox.SamW.Byron_DTLT_190220)If Object_ID('Warehouse.Selections.BB022_PreSelection') Is Not Null Drop Table Warehouse.Selections.BB022_PreSelectionSelect FanIDInto Warehouse.Selections.BB022_PreSelectionFROM  SANDBOX.SAMW.BYRONMVC020320END