-- =============================================-- Author:  <Rory Francis>-- Create date: <2021-04-18>-- Description: < sProc to run preselection code per camapign >-- =============================================CREATE PROCEDURE [Selections].[FFX009_PreSelection_sProc]ASBEGIN--	FFX009------------------------------------------------------- RBS Selection -------------------------------------------------------
IF OBJECT_ID('tempdb..#FB') IS NOT NULL DROP TABLE #FB
SELECT	CINID, FanID
INTO	#FB
FROM	Relational.Customer C
JOIN	Relational.CINList CL ON CL.CIN = C.SourceUID
WHERE	C.CurrentlyActive = 1
AND		SourceUID NOT IN (SELECT SourceUID FROM Staging.Customer_DuplicateSourceUID) 

CREATE CLUSTERED INDEX CIX_CINID ON #FB (CINID)

IF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC
SELECT	  CC.ConsumerCombinationID AS ConsumerCombinationID
INTO	#CC 
FROM	Relational.ConsumerCombination CC
WHERE	BrandID IN (383,456,29,498,3410,3413,3415,469)			-- Competitors: Screwfix, Toolstation, B&Q, Wickes, ITS Tools, 
																-- Axminster Tools, Powertoolmate, Travis Perkins

CREATE CLUSTERED INDEX CIX_ConsumerCombinationID ON #CC (ConsumerCombinationID)

DECLARE @DATE_24 DATE = DATEADD(MONTH,-24,GETDATE())

IF OBJECT_ID('tempdb..#Trans') IS NOT NULL DROP TABLE #Trans
SELECT	CT.CINID as CINID
INTO	#Trans
FROM	Relational.ConsumerTransaction_MyRewards CT
JOIN	#CC CC ON CT.ConsumerCombinationID = CC.ConsumerCombinationID
JOIN	#FB F ON F.CINID = CT.CINID
WHERE	TranDate > @DATE_24
		AND Amount > 0
GROUP BY CT.CINID


IF OBJECT_ID('Sandbox.RukanK.FFX_CompSteal_17092021') IS NOT NULL DROP TABLE Sandbox.RukanK.FFX_CompSteal_17092021
SELECT	CINID
INTO Sandbox.RukanK.FFX_CompSteal_17092021
FROM  #Trans
If Object_ID('Warehouse.Selections.FFX009_PreSelection') Is Not Null Drop Table Warehouse.Selections.FFX009_PreSelectionSelect FanIDInto Warehouse.Selections.FFX009_PreSelectionFROM #FB fbWHERE EXISTS (	SELECT 1				FROM Sandbox.RukanK.FFX_CompSteal_17092021 cu				WHERE fb.CINID = cu.CINID)END