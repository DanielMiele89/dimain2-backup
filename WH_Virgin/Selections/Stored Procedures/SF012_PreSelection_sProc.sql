
CREATE PROCEDURE [Selections].[SF012_PreSelection_sProc]
AS
BEGIN

IF OBJECT_ID('tempdb..#FB') IS NOT NULL DROP TABLE #FB
SELECT	CINID
		,FanID
INTO #FB
FROM	WH_Virgin.Derived.Customer  C
JOIN	WH_Virgin.Derived.CINList CL ON CL.CIN = C.SourceUID
WHERE	C.CurrentlyActive = 1
and AccountType IS NOT NULL
--AND		SourceUID NOT IN (SELECT SourceUID FROM Staging.Customer_DuplicateSourceUID) 


IF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC
SELECT [WH_Virgin].[trans].[ConsumerCombination].[ConsumerCombinationID]
INTO #CC
FROM	WH_Virgin.trans.ConsumerCombination  CC
WHERE	[WH_Virgin].[trans].[ConsumerCombination].[BrandID] IN (2868,2867)						-- Competitors: Lookiero, Thread

IF OBJECT_ID('tempdb..#Trans') IS NOT NULL DROP TABLE #Trans
SELECT	F.CINID
INTO #Trans
FROM	WH_Virgin.trans.consumertransaction CT
JOIN	#FB F ON F.CINID = #FB.[CT].CINID
JOIN	#CC C 	ON C.ConsumerCombinationID = CT.ConsumerCombinationID
WHERE	TranDate > DATEADD(MONTH, -6, GETDATE())
		AND Amount > 0
GROUP BY F.CINID


IF OBJECT_ID('Sandbox.MichaelM.Stitchfix_VM_CompSteal_23092021') IS NOT NULL DROP TABLE Sandbox.MichaelM.Stitchfix_VM_CompSteal_23092021
SELECT	#Trans.[CINID]
INTO Sandbox.MichaelM.Stitchfix_VM_CompSteal_23092021
FROM  #Trans


	IF OBJECT_ID('[WH_Virgin].[Selections].[SF012_PreSelection]') IS NOT NULL DROP TABLE [WH_Virgin].[Selections].[SF012_PreSelection]
	SELECT [fb].[FanID]
	INTO [WH_Virgin].[Selections].[SF012_PreSelection]
	FROM #FB fb
	WHERE EXISTS (	SELECT 1
					FROM Sandbox.MichaelM.Stitchfix_VM_CompSteal_23092021  st
					WHERE fb.CINID = #FB.[st].CINID)

END