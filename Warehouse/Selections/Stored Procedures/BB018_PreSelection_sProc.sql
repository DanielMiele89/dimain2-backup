-- =============================================-- Author:  <Rory Francis>-- Create date: <2019-11-04>-- Description: < sProc to run preselection code per camapign >-- =============================================Create Procedure Selections.BB018_PreSelection_sProcASBEGIN--CC--
IF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC
SELECT ConsumerCombinationID
		,CC.BrandID
		,BrandName
INTO #CC

FROM	Relational.ConsumerCombination CC 

JOIN	Relational.Brand B ON B.BrandID = CC.BrandID

WHERE CC.BrandID IN (2240,2429,1098)

CREATE CLUSTERED INDEX ix_ComboID ON #CC(ConsumerCombinationID)


--FULL BASE--
IF OBJECT_ID('tempdb..#FB') IS NOT NULL DROP TABLE #FB
SELECT	CINID
		,FANID

INTO #FB
FROM	Relational.Customer C

JOIN	Relational.CINList CL ON CL.CIN = C.SourceUID

WHERE	C.CurrentlyActive = 1 

AND		SourceUID NOT IN (SELECT SourceUID FROM Staging.Customer_DuplicateSourceUID)

CREATE CLUSTERED INDEX ix_ComboID ON #FB(CINID) 


--SEGMENT ASSIGNMENT--
IF OBJECT_ID('tempdb..#SA') IS NOT NULL DROP TABLE #SA
SELECT	DISTINCT #FB.CINID
		,FANID

INTO #SA

FROM	#FB

JOIN	Relational.ConsumerTransaction_MyRewards CTMR ON CTMR.CINID = #FB.CINID

JOIN	#CC ON #CC.ConsumerCombinationID = CTMR.ConsumerCombinationID

WHERE	TranDate BETWEEN '2018-11-01' AND '2018-12-31'

IF OBJECT_ID('Sandbox.SamW.ByronCompSteal101019') IS NOT NULL DROP TABLE Sandbox.Samw.ByronCompSteal101019
SELECT *
INTO Sandbox.Samw.ByronCompSteal101019
FROM #SAIf Object_ID('Warehouse.Selections.BB018_PreSelection') Is Not Null Drop Table Warehouse.Selections.BB018_PreSelectionSelect FanIDInto Warehouse.Selections.BB018_PreSelectionFrom Sandbox.Samw.ByronCompSteal101019END