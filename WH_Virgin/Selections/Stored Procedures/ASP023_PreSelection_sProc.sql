﻿
CREATE PROCEDURE [Selections].[ASP023_PreSelection_sProc]
AS
BEGIN

IF OBJECT_ID('tempdb..#FB') IS NOT NULL DROP TABLE #FB
SELECT	CINID, FanID
INTO	#FB
FROM	[WH_Virgin].Derived.Customer  C
JOIN	[WH_Virgin].Derived.CINList CL ON CL.CIN = C.SourceUID
WHERE	C.CurrentlyActive = 1
and AccountType IS NOT NULL
--AND		SourceUID NOT IN (SELECT SourceUID FROM Staging.Customer_DuplicateSourceUID) 
CREATE CLUSTERED INDEX ix_CINID on #FB(CINID)


	IF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC
	SELECT [WH_Virgin].[trans].[ConsumerCombination].[ConsumerCombinationID]
	INTO	#CC
	FROM	WH_Virgin.trans.ConsumerCombination  CC
	WHERE	[WH_Virgin].[trans].[ConsumerCombination].[BrandID] IN (2107,2660,2665,2085,1651)							-- Kate Spade, Mulberry, Coach, Burberry and Smythson
	CREATE CLUSTERED INDEX ix_ConsumerCombinationID on #CC(ConsumerCombinationID)


	IF OBJECT_ID('tempdb..#Trans') IS NOT NULL DROP TABLE #Trans
	SELECT	F.CINID
	INTO	#Trans
	FROM	WH_Virgin.trans.consumertransaction CT
	JOIN	#FB F ON F.CINID = #FB.[CT].CINID
	JOIN	#CC C 	ON C.ConsumerCombinationID = CT.ConsumerCombinationID
	WHERE	TranDate > DATEADD(MONTH, -24, GETDATE())
			AND Amount > 0
	GROUP BY F.CINID
	CREATE CLUSTERED INDEX ix_CINID on #Trans(CINID)


	IF OBJECT_ID('Sandbox.LeoP.VM_Aspinal_CompSteal010422') IS NOT NULL DROP TABLE Sandbox.LeoP.VM_Aspinal_CompSteal010422
	SELECT	#Trans.[CINID]
	INTO	Sandbox.LeoP.VM_Aspinal_CompSteal010422
	FROM	#Trans

	IF OBJECT_ID('[WH_Virgin].[Selections].[ASP023_PreSelection]') IS NOT NULL DROP TABLE [WH_Virgin].[Selections].[ASP023_PreSelection]
	SELECT [fb].[FanID]
	INTO [WH_Virgin].[Selections].[ASP023_PreSelection]
	FROM #FB fb
	WHERE EXISTS (	SELECT 1
					FROM Sandbox.LeoP.VM_Aspinal_CompSteal010422  st
					WHERE fb.CINID = #FB.[st].CINID)

END

