-- =============================================-- Author:  <Rory Francis>-- Create date: <2021-08-18>-- Description: < sProc to run preselection code per camapign >-- =============================================CREATE PROCEDURE [Selections].[MOR104_PreSelection_sProc]ASBEGINIF OBJECT_ID('tempdb..#FB') IS NOT NULL DROP TABLE #FB
SELECT	CINID
		,FanID
INTO #FB
FROM	WH_Visa.Derived.Customer C
JOIN	WH_Visa.Derived.CINList CL ON CL.CIN = C.SourceUID
WHERE	C.CurrentlyActive = 1
AND FANID NOT IN (SELECT FANID FROM Warehouse.[InsightArchive].[MorrisonsReward_MatchedCustomers_20190304])		--NOT A MORECARD OWNER----AND		SourceUID NOT IN (SELECT SourceUID FROM Derived.Customer_DuplicateSourceUID) 
If Object_ID('WH_Visa.Selections.MOR104_PreSelection') Is Not Null Drop Table WH_Visa.Selections.MOR104_PreSelectionSelect FanIDInto WH_Visa.Selections.MOR104_PreSelectionFROM  #FBEND
