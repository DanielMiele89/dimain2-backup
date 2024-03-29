﻿-- =============================================
-- Author:  <Rory Francis>
-- Create date: <2021-04-18>
-- Description: < sProc to run preselection code per camapign >
-- =============================================
CREATE PROCEDURE [Selections].[FFX009_PreSelection_sProc]
AS
BEGIN

--	FFX009

IF OBJECT_ID('tempdb..#FB') IS NOT NULL DROP TABLE #FB
SELECT	CINID, FanID
INTO	#FB
FROM	WH_Virgin.Derived.Customer  C
JOIN	WH_Virgin.Derived.CINList CL ON CL.CIN = C.SourceUID
WHERE	C.CurrentlyActive = 1
and AccountType IS NOT NULL
AND		SourceUID NOT IN (SELECT [Derived].[Customer_DuplicateSourceUID].[SourceUID] FROM Derived.Customer_DuplicateSourceUID) 


IF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC
SELECT [WH_Virgin].[trans].[ConsumerCombination].[ConsumerCombinationID]
INTO	#CC
FROM	WH_Virgin.trans.ConsumerCombination  CC
WHERE	[WH_Virgin].[trans].[ConsumerCombination].[BrandID] IN (383,456,29,498,3410,3413,3415,469)			-- Competitors: Screwfix, Toolstation, B&Q, Wickes, ITS Tools, 
																-- Axminster Tools, Powertoolmate, Travis Perkins

IF OBJECT_ID('tempdb..#Trans') IS NOT NULL DROP TABLE #Trans
SELECT	F.CINID
INTO	#Trans
FROM	#FB F
JOIN	WH_Virgin.trans.consumertransaction CT ON F.CINID = #FB.[CT].CINID
JOIN	#CC C ON C.ConsumerCombinationID = CT.ConsumerCombinationID
WHERE	TranDate >= DATEADD(MONTH,-24,GETDATE())
		AND Amount > 0
GROUP BY F.CINID

IF OBJECT_ID('Sandbox.rukank.VM_FFX_CompSteal_17092021') IS NOT NULL DROP TABLE Sandbox.rukank.VM_FFX_CompSteal_17092021
SELECT	#Trans.[CINID]
INTO Sandbox.rukank.VM_FFX_CompSteal_17092021
FROM	#Trans


If Object_ID('WH_Virgin.Selections.FFX009_PreSelection') Is Not Null Drop Table WH_Virgin.Selections.FFX009_PreSelection
Select [fb].[FanID]
Into WH_Virgin.Selections.FFX009_PreSelection
From #FB fb
WHERE EXISTS (	SELECT 1
				FROM Sandbox.rukank.VM_FFX_CompSteal_17092021 cs
				WHERE fb.CINID = #FB.[cs].CINID)



END