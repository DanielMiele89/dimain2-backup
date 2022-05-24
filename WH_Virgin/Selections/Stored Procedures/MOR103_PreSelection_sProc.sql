-- =============================================-- Author:  <Rory Francis>-- Create date: <2021-08-18>-- Description: < sProc to run preselection code per camapign >-- =============================================CREATE PROCEDURE [Selections].[MOR103_PreSelection_sProc]ASBEGIN------------------------------- VIRGIN -------------------------------------
IF OBJECT_ID('tempdb..#FB') IS NOT NULL DROP TABLE #FB
SELECT	CINID, FanID
INTO #FB
FROM	WH_Virgin.Derived.Customer C
JOIN	WH_Virgin.Derived.CINList CL ON CL.CIN = C.SourceUID
WHERE	C.CurrentlyActive = 1
and AccountType IS NOT NULL
AND		SourceUID NOT IN (SELECT SourceUID FROM Derived.Customer_DuplicateSourceUID) 
AND FANID NOT IN (SELECT FANID FROM Warehouse.[InsightArchive].[MorrisonsReward_MatchedCustomers_20190304])		--NOT A MORECARD OWNER--
If Object_ID('WH_Virgin.Selections.MOR103_PreSelection') Is Not Null Drop Table WH_Virgin.Selections.MOR103_PreSelectionSelect FanIDInto WH_Virgin.Selections.MOR103_PreSelectionFROM  #FBEND