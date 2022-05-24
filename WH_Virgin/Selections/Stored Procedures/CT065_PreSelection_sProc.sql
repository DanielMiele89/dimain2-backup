﻿
CREATE PROCEDURE [Selections].[CT065_PreSelection_sProc]
AS
BEGIN

IF OBJECT_ID('tempdb..#FB') IS NOT NULL DROP TABLE #FB
SELECT	CINID
		,FanID
INTO	#FB
FROM	WH_Virgin.Derived.Customer  C
JOIN	WH_Virgin.Derived.CINList CL ON CL.CIN = C.SourceUID
WHERE	C.CurrentlyActive = 1
and AccountType IS NOT NULL


IF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC
SELECT ConsumerCombinationID
INTO	#CC
FROM	WH_Virgin.trans.ConsumerCombination  CC
WHERE	BrandID IN (195,294,366,417)			-- Competitors:  Hawes & Curtis, TM Lewin, Moss Bros and Reiss.


IF OBJECT_ID('tempdb..#Trans') IS NOT NULL DROP TABLE #Trans
SELECT	F.CINID
INTO #Trans
FROM	WH_Virgin.trans.consumertransaction CT
JOIN	#FB F ON F.CINID = CT.CINID
JOIN	#CC C 	ON C.ConsumerCombinationID = CT.ConsumerCombinationID
WHERE	TranDate > DATEADD(MONTH, -6, GETDATE())
		AND Amount > 0
GROUP BY F.CINID


IF OBJECT_ID('Sandbox.SamH.VM_CharlesTyrwhitt_CS_210921') IS NOT NULL DROP TABLE Sandbox.SamH.VM_CharlesTyrwhitt_CS_210921
SELECT	CINID
INTO Sandbox.SamH.VM_CharlesTyrwhitt_CS_210921
FROM	#Trans 
GROUP BY CINID


	IF OBJECT_ID('[WH_Virgin].[Selections].[CT065_PreSelection]') IS NOT NULL DROP TABLE [WH_Virgin].[Selections].[CT065_PreSelection]
	SELECT FanID
	INTO [WH_Virgin].[Selections].[CT065_PreSelection]
	FROM #FB fb
	WHERE EXISTS (	SELECT 1
					FROM Sandbox.SamH.VM_CharlesTyrwhitt_CS_210921  st
					WHERE fb.CINID = st.CINID)

END
