-- =============================================-- Author:  <Rory Francis>-- Create date: <2021-04-18>-- Description: < sProc to run preselection code per camapign >-- =============================================CREATE PROCEDURE [Selections].[ICH006_PreSelection_sProc]ASBEGIN--	ICH006IF OBJECT_ID('tempdb..#FB') IS NOT NULL DROP TABLE #FB
SELECT [CL].[CINID]
		,[C].[FanID]
INTO #FB
FROM	Derived.Customer C 
JOIN	Derived.CINList CL ON CL.CIN = C.SourceUID
WHERE	C.CurrentlyActive = 1
AND 1 = 2If Object_ID('WH_Virgin.Selections.ICH006_PreSelection') Is Not Null Drop Table WH_Virgin.Selections.ICH006_PreSelectionSelect [fb].[FANID]Into WH_Virgin.Selections.ICH006_PreSelectionFROM #FB fbWHERE EXISTS (	SELECT 1				FROM Derived.Customer cu				INNER JOIN Derived.CINList cl					ON cu.SourceUID = cl.CIN				WHERE fb.CINID = cl.CINID)END