
CREATE PROCEDURE [Selections].[CT063_PreSelection_sProc]
AS
BEGIN

	IF OBJECT_ID('tempdb..#FB') IS NOT NULL DROP TABLE #FB
	SELECT	CINID
			,FanID
	INTO	#FB
	FROM	WH_Virgin.Derived.Customer  C
	JOIN	WH_Virgin.Derived.CINList CL ON CL.CIN = C.SourceUID
	WHERE	C.CurrentlyActive = 1
	AND		SourceUID NOT IN (SELECT SourceUID FROM WH_Virgin.Derived.Customer_DuplicateSourceUID)

	IF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC
	SELECT [WH_Virgin].[Trans].[ConsumerCombination].[ConsumerCombinationID]
	INTO	#CC
	FROM	WH_Virgin.Trans.ConsumerCombination  CC
	WHERE	[WH_Virgin].[Trans].[ConsumerCombination].[BrandID] IN (195,294,366,417)			-- Competitors:  Hawes & Curtis, TM Lewin, Moss Bros and Reiss.

	IF OBJECT_ID('tempdb..#Trans') IS NOT NULL DROP TABLE #Trans
	SELECT	F.CINID
	INTO	#Trans
	FROM	WH_Virgin.Trans.Consumertransaction CT
	JOIN	#FB F ON F.CINID = #FB.[CT].CINID
	JOIN	#CC C 	ON C.ConsumerCombinationID = CT.ConsumerCombinationID
	WHERE	TranDate > DATEADD(MONTH, -6, GETDATE())
			AND Amount > 0
	GROUP BY F.CINID

	IF OBJECT_ID('Sandbox.SamH.VM_CharlesTyrwhitt_CS_210921') IS NOT NULL DROP TABLE Sandbox.SamH.VM_CharlesTyrwhitt_CS_210921
	SELECT	#Trans.[CINID]
	INTO Sandbox.SamH.VM_CharlesTyrwhitt_CS_210921
	FROM  #Trans

	IF OBJECT_ID('[WH_Virgin].[Selections].[CT063_PreSelection]') IS NOT NULL DROP TABLE [WH_Virgin].[Selections].[CT063_PreSelection]
	SELECT [fb].[FanID]
	INTO [WH_Virgin].[Selections].[CT063_PreSelection]
	FROM #FB fb
	WHERE EXISTS (	SELECT 1
					FROM Sandbox.SamH.VM_CharlesTyrwhitt_CS_210921 st
					WHERE fb.CINID = #FB.[st].CINID)

END



