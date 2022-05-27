-- =============================================-- Author:  <Rory Francis>-- Create date: <2021-05-30>-- Description: < sProc to run preselection code per camapign >-- =============================================CREATE PROCEDURE [Selections].[SIC007_PreSelection_sProc]ASBEGIN
IF OBJECT_ID('tempdb..#FB') IS NOT NULL DROP TABLE #FB
SELECT	C.FanID
		,CINID
INTO #FB
FROM	Relational.Customer C
JOIN	Relational.CINList CL ON CL.CIN = C.SourceUID
WHERE C.CurrentlyActive = 1
	AND SourceUID NOT IN (SELECT SourceUID FROM Staging.Customer_DuplicateSourceUID)

CREATE CLUSTERED INDEX CIX_CINID ON #FB (CINID)
CREATE NONCLUSTERED INDEX IX_FanID ON #FB (FanID)

IF OBJECT_ID('tempdb..#CCIDs') IS NOT NULL DROP TABLE #CCIDs
SELECT	ConsumerCombinationID
		,CC.BrandID
		,BrandName
INTO #CCIDs
FROM Relational.ConsumerCombination cc WITH (NOLOCK)
JOIN Relational.Brand B ON B.BrandID = CC.BrandID
WHERE CC.BrandID = 2526

CREATE CLUSTERED INDEX CIX_ConsumerCombinationID ON #CCIDs (ConsumerCombinationID)

IF OBJECT_ID('tempdb..#Customers') IS NOT NULL DROP TABLE #Customers
SELECT	F.CINID
INTO #Customers
FROM	#FB F
JOIN	Relational.ConsumerTransaction_MyRewards CT ON F.CINID = CT.CINID
JOIN	#CCIDs C ON CT.ConsumerCombinationID = C.ConsumerCombinationID
GROUP BY F.CINID

DECLARE @DATE_12 DATE = DATEADD(MONTH, -12, GETDATE())

IF OBJECT_ID('tempdb..#UnderSpend') IS NOT NULL DROP TABLE #UnderSpend
SELECT	F.CINID
INTO #UnderSpend
FROM	#FB F
JOIN	Relational.ConsumerTransaction_MyRewards CT ON CT.CINID = F.CINID
JOIN	#CCIDs C ON C.ConsumerCombinationID = CT.ConsumerCombinationID
WHERE	TranDate >= @DATE_12
AND		Amount > 9.99
GROUP BY F.CINID

IF OBJECT_ID('Sandbox.SamW.SimplyCook020221') IS NOT NULL DROP TABLE Sandbox.SamW.SimplyCook020221
SELECT F.CINID
INTO Sandbox.SamW.SimplyCook020221
FROM #FB F
WHERE F.CINID NOT IN (SELECT CINID FROM #Customers)
OR F.CINID NOT IN (SELECT CINID FROM #UnderSpend)If Object_ID('Warehouse.Selections.SIC007_PreSelection') Is Not Null Drop Table Warehouse.Selections.SIC007_PreSelectionSelect FanIDInto Warehouse.Selections.SIC007_PreSelectionFROM Relational.Customer cuWHERE EXISTS (	SELECT 1				FROM Sandbox.SamW.SimplyCook020221 st				INNER JOIN Relational.CINList cl					ON st.CINID = cl.CINID				WHERE cu.SourceUID = cl.CIN)END