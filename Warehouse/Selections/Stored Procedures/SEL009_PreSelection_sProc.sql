-- =============================================-- Author:  <Rory Francis>-- Create date: <2021-05-30>-- Description: < sProc to run preselection code per camapign >-- =============================================CREATE PROCEDURE Selections.SEL009_PreSelection_sProcASBEGINIF OBJECT_ID('tempdb..#FB') IS NOT NULL DROP TABLE #FB
SELECT	CINID, FanID
INTO #FB
FROM	Relational.Customer C
JOIN	Relational.CINList CL ON CL.CIN = C.SourceUID
WHERE	C.CurrentlyActive = 1
AND		SourceUID NOT IN (SELECT SourceUID FROM Staging.Customer_DuplicateSourceUID) 

IF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC
SELECT 		CC.ConsumerCombinationID AS ConsumerCombinationID
		, CASE
			WHEN CC.BrandID IN (386) THEN 'Target'				-- Selfridges customers
			WHEN CC.BrandID IN (116) THEN 'DebCustomer'			-- Debenhams customers
			ELSE 'Rest'
		 END as Selection
INTO #CC 
FROM Relational.ConsumerCombination CC
WHERE CC.BrandID IN (386,253,192,234,194,207,116)				
IF OBJECT_ID('tempdb..#CCbeauty') IS NOT NULL DROP TABLE #CCbeauty
SELECT CC.ConsumerCombinationID AS ConsumerCombinationID
INTO #CCbeauty 
FROM Relational.ConsumerCombination CC
WHERE CC.BrandID IN (2466,933,1570,1365,1634,2262)									
IF OBJECT_ID('tempdb..#beauty') IS NOT NULL DROP TABLE #beauty
SELECT	 CT.CINID as CINID
		,COUNT(CT.CINID) AS Txn
INTO #beauty
FROM Relational.ConsumerTransaction_MyRewards CT
JOIN #CCbeauty CC ON CT.ConsumerCombinationID = CC.ConsumerCombinationID
JOIN #FB F ON F.CINID = CT.CINID
WHERE	TranDate > DATEADD(MONTH, -12, GETDATE())
GROUP BY	 CT.CINID

IF OBJECT_ID('tempdb..#beauty2') IS NOT NULL DROP TABLE #beauty2
SELECT	CINID
INTO #beauty2
FROM #beauty
WHERE Txn >= 2

IF OBJECT_ID('tempdb..#deb') IS NOT NULL DROP TABLE #deb
SELECT	 CT.CINID as CINID
		,SUM(Amount) AS Total_Spend
		,COUNT(CT.CINID) AS Txn
		,SUM(Amount) / COUNT(CT.CINID) as ATV
INTO #deb
FROM Relational.ConsumerTransaction_MyRewards CT
JOIN #CC CC ON CT.ConsumerCombinationID = CC.ConsumerCombinationID
JOIN #FB F ON F.CINID = CT.CINID
WHERE	
		TranDate > DATEADD(MONTH, -12, GETDATE())
		AND CC.Selection = 'DebCustomer'
GROUP BY	 CT.CINID
HAVING SUM(Amount) <> 0;

IF OBJECT_ID('tempdb..#deb2') IS NOT NULL DROP TABLE #deb2
SELECT	D.CINID
INTO #deb2
FROM #deb D
JOIN #beauty2 B ON D.CINID = B.CINID
WHERE ATV BETWEEN 30.0 AND 80.0

DECLARE @Date DATE = DATEADD(MONTH, -12, GETDATE())

IF OBJECT_ID('tempdb..#Trans') IS NOT NULL DROP TABLE #Trans
SELECT	CT.CINID as CINID
		, SUM(CASE WHEN CC.Selection = 'Target' THEN Amount ELSE 0.0 END ) AS Target_Spend
		, SUM(Amount) AS Total_Spend
		,COUNT(CT.CINID) AS Txn
INTO #Trans
FROM Relational.ConsumerTransaction_MyRewards CT
JOIN #CC CC ON CT.ConsumerCombinationID = CC.ConsumerCombinationID
JOIN #FB F ON F.CINID = CT.CINID
WHERE TranDate > @Date
GROUP BY	 CT.CINID
HAVING SUM(Amount) <> 0;

IF OBJECT_ID('Sandbox.RukanK.selfridges_compStealDEB_lowSoW') IS NOT NULL DROP TABLE Sandbox.RukanK.selfridges_compStealDEB_lowSoW
SELECT	CINID
INTO Sandbox.RukanK.selfridges_compStealDEB_lowSoW
FROM (	SELECT	 CINID
		, Target_Spend / Total_Spend * 100 as pct
		,Txn
		FROM #Trans T) AS tmp
WHERE pct < 30
		AND Txn >=2
		AND CINID in (SELECT CINID FROM #deb2)
;If Object_ID('Warehouse.Selections.SEL009_PreSelection') Is Not Null Drop Table Warehouse.Selections.SEL009_PreSelectionSelect FanIDInto Warehouse.Selections.SEL009_PreSelectionFROM Relational.Customer cuWHERE EXISTS (	SELECT 1				FROM Sandbox.RukanK.selfridges_compStealDEB_lowSoW st				INNER JOIN Relational.CINList cl					ON st.CINID = cl.CINID				WHERE cu.SourceUID = cl.CIN)END