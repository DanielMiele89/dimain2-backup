-- =============================================-- Author:  <Rory Francis>-- Create date: <2021-08-05>-- Description: < sProc to run preselection code per camapign >-- =============================================CREATE PROCEDURE Selections.MV010_PreSelection_sProcASBEGINIF OBJECT_ID('tempdb..#FB') IS NOT NULL DROP TABLE #FB
SELECT	CINID
		,FanID
INTO #FB
FROM	Relational.Customer C
JOIN	Relational.CINList CL ON CL.CIN = C.SourceUID
WHERE	C.CurrentlyActive = 1
AND		SourceUID NOT IN (SELECT SourceUID FROM Staging.Customer_DuplicateSourceUID)


IF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC
SELECT	ConsumerCombinationID
		,BrandID
INTO #CC
FROM	Relational.ConsumerCombination CC
WHERE	BrandID IN (2656,2657,3295,3244)

DECLARE @Date DATE = DATEADD(MONTH,-24,GETDATE())

IF OBJECT_ID('Sandbox.SamW.MonicaVinander150521') IS NOT NULL DROP TABLE Sandbox.SamW.MonicaVinander150521
SELECT	F.CINID
	,	f.FanID
INTO Sandbox.SamW.MonicaVinander150521
FROM	#FB F
JOIN	Relational.ConsumerTransaction_MyRewards CT ON F.CINID = CT.CINID
JOIN	#CC C ON C.ConsumerCombinationID = CT.ConsumerCombinationID
WHERE	Amount > 0 
AND		TranDate >= @DateIf Object_ID('Warehouse.Selections.MV010_PreSelection') Is Not Null Drop Table Warehouse.Selections.MV010_PreSelectionSelect FanIDInto Warehouse.Selections.MV010_PreSelectionFROM  SANDBOX.SAMW.MONICAVINANDER150521END