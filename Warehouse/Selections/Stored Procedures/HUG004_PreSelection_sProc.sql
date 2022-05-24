-- =============================================-- Author:  <Rory Francis>-- Create date: <2020-10-18>-- Description: < sProc to run preselection code per camapign >-- =============================================CREATE PROCEDURE Selections.HUG004_PreSelection_sProcASBEGINSELECT *
FROM Relational.Brand
WHERE BrandName LIKE '%Hughes%'

IF OBJECT_ID('tempdb..#FB') IS NOT NULL DROP TABLE #FB
SELECT	CINID
		,FANID
INTO #FB
FROM	Relational.Customer C
JOIN	Relational.CINList CL ON CL.CIN = C.SourceUID
WHERE	C.CurrentlyActive = 1
AND		SourceUID NOT IN (SELECT SourceUID FROM Staging.Customer_DuplicateSourceUID)

IF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC
SELECT	ConsumerCombinationID
INTO #CC
FROM	Relational.ConsumerCombination CC
WHERE	BrandID IN (110,327,1360,370)


IF OBJECT_ID('Sandbox.SamW.HughesDirectBlackFriday210920') IS NOT NULL DROP TABLE Sandbox.SamW.HughesDirectBlackFriday210920
SELECT	CINID
INTO Sandbox.SamW.HughesDirectBlackFriday210920
FROM	Relational.ConsumerTransaction_MyRewards CT
JOIN	#CC C ON C.ConsumerCombinationID = CT.ConsumerCombinationID
WHERE	TranDate >= DATEADD(MONTH,-12,GETDATE())
GROUP BY CINID


SELECT COUNT(dISTINCT F.CINID)
FROM Sandbox.SamW.HughesDirectBlackFriday210920 F
JOIN Relational.ConsumerTransaction_MyRewards CT ON F.CINID = CT.CINID
JOIN Relational.ConsumerCombination CC ON CC.ConsumerCombinationID = CT.ConsumerCombinationID
WHERE BrandID = 1455
AND TranDate >= DATEADD(MONTH,-24,GETDATE())
AND	TranDate <= DATEADD(MONTH,-12,GETDATE())
If Object_ID('Warehouse.Selections.HUG004_PreSelection') Is Not Null Drop Table Warehouse.Selections.HUG004_PreSelectionSelect FanIDInto Warehouse.Selections.HUG004_PreSelectionFROM  SANDBOX.SAMW.HUGHESDIRECTBLACKFRIDAY210920 bfINNER JOIN Relational.CINList cl	ON bf.CINID = cl.CINIDINNER JOIN Relational.Customer cu	ON cl.CIN = cu.SourceUIDEND