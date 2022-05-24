-- =============================================-- Author:  <Rory Francis>-- Create date: <2021-07-24>-- Description: < sProc to run preselection code per camapign >-- =============================================CREATE PROCEDURE [Selections].[FFX003_PreSelection_sProc]ASBEGIN

IF OBJECT_ID('tempdb..#FB') IS NOT NULL DROP TABLE #FB
SELECT	CINID
		,FanID
INTO	#FB
FROM	WH_Virgin.Derived.Customer  C
JOIN	WH_Virgin.Derived.CINList CL ON CL.CIN = C.SourceUID
WHERE	C.CurrentlyActive = 1
and AccountType IS NOT NULL


IF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC
SELECT [WH_Virgin].[trans].[ConsumerCombination].[ConsumerCombinationID]
INTO	#CC
FROM	WH_Virgin.trans.ConsumerCombination  CC
WHERE	[WH_Virgin].[trans].[ConsumerCombination].[BrandID] IN (29,204,383,456,469,498,3410,3412,3413,3414,3415,3416,3417,3418,3419,3420,3421,3422,3423,3424,3425,3426,3427,3428,3429,3430,3431,3432)


IF OBJECT_ID('tempdb..#Trans') IS NOT NULL DROP TABLE #Trans
SELECT	F.CINID
INTO #Trans
FROM	WH_Virgin.trans.consumertransaction CT
JOIN	#FB F ON F.CINID = #FB.[CT].CINID
JOIN	#CC C 	ON C.ConsumerCombinationID = CT.ConsumerCombinationID
WHERE	TranDate > DATEADD(MONTH, -6, GETDATE())
		AND Amount > 0
GROUP BY F.CINID


IF OBJECT_ID('Sandbox.SamH.VM_FFXTools_CompSteal06072021') IS NOT NULL DROP TABLE Sandbox.SamH.VM_FFXTools_CompSteal06072021
SELECT	#Trans.[CINID]
INTO Sandbox.SamH.VM_FFXTools_CompSteal06072021
FROM	#Trans 
GROUP BY #Trans.[CINID]If Object_ID('WH_Virgin.Selections.FFX003_PreSelection') Is Not Null Drop Table WH_Virgin.Selections.FFX003_PreSelectionSelect [fb].[FanID]Into WH_Virgin.Selections.FFX003_PreSelectionFROM #FB fbWHERE EXISTS (	SELECT 1				FROM Sandbox.SamH.VM_FFXTools_CompSteal06072021 cs				WHERE fb.CINID = #FB.[cs].CINID)END