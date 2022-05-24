CREATE PROCEDURE [Selections].[CT059_PreSelection_sProc]
AS
BEGIN

---VIRGIN CODE: -----------------------------------------------------------------------

--IF OBJECT_ID('tempdb..#FB') IS NOT NULL DROP TABLE #FB
--SELECT	CINID
--		,FanID
--INTO	#FB
--FROM	WH_Virgin.Derived.Customer  C
--JOIN	WH_Virgin.Derived.CINList CL ON CL.CIN = C.SourceUID
--WHERE	C.CurrentlyActive = 1
--and AccountType IS NOT NULL


--IF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC
--SELECT ConsumerCombinationID
--INTO	#CC
--FROM	WH_Virgin.trans.ConsumerCombination  CC
--WHERE	BrandID IN (195,294,366,417)			-- Competitors:  Hawes & Curtis, TM Lewin, Moss Bros and Reiss.


--DECLARE @DATE_6 DATE = DATEADD(MONTH, -6, GETDATE())

--IF OBJECT_ID('tempdb..#Trans') IS NOT NULL DROP TABLE #Trans
--SELECT	F.CINID
--INTO #Trans
--FROM	WH_Virgin.trans.consumertransaction CT
--JOIN	#FB F ON F.CINID = CT.CINID
--JOIN	#CC C 	ON C.ConsumerCombinationID = CT.ConsumerCombinationID
--WHERE	TranDate > @DATE_6
--		AND Amount > 0
--GROUP BY F.CINID


--IF OBJECT_ID('Sandbox.SamH.VM_CharlesTyrwhitt_CS_210921') IS NOT NULL DROP TABLE Sandbox.SamH.VM_CharlesTyrwhitt_CS_210921
--SELECT	CINID
--INTO Sandbox.SamH.VM_CharlesTyrwhitt_CS_210921
--FROM	#Trans 
--GROUP BY CINID

--RBS CODE: --------------------------------------------------------------------------------
IF OBJECT_ID('tempdb..#FB') IS NOT NULL DROP TABLE #FB
SELECT	CINID, FanID
INTO	#FB
FROM	Relational.Customer C
JOIN	Relational.CINList CL ON CL.CIN = C.SourceUID
WHERE	C.CurrentlyActive = 1
AND		SourceUID NOT IN (SELECT SourceUID FROM Staging.Customer_DuplicateSourceUID) 


IF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC
SELECT	  CC.ConsumerCombinationID AS ConsumerCombinationID
INTO	#CC 
FROM	Relational.ConsumerCombination CC
WHERE	BrandID IN (195,294,366,417)			-- Competitors:  Hawes & Curtis, TM Lewin, Moss Bros and Reiss.

DECLARE @DATE_6 DATE = DATEADD(MONTH, -6, GETDATE())

IF OBJECT_ID('tempdb..#Trans') IS NOT NULL DROP TABLE #Trans
SELECT	CT.CINID as CINID
		,COUNT(CT.CINID) AS Txn
INTO	#Trans
FROM	Relational.ConsumerTransaction_MyRewards CT
JOIN	#CC CC ON CT.ConsumerCombinationID = CC.ConsumerCombinationID
JOIN	#FB F ON F.CINID = CT.CINID
WHERE	TranDate > @DATE_6
		AND Amount > 0
GROUP BY CT.CINID


IF OBJECT_ID('Sandbox.SamH.RBS_CharlesTyrwhitt_CS_210921') IS NOT NULL DROP TABLE Sandbox.SamH.RBS_CharlesTyrwhitt_CS_210921
SELECT	CINID
INTO Sandbox.SamH.RBS_CharlesTyrwhitt_CS_210921
FROM  #Trans

--BARCLAYS CODE:-------------------------------

--IF OBJECT_ID('tempdb..#FB') IS NOT NULL DROP TABLE #FB
--SELECT	CINID
--		,FanID
--INTO	#FB
--FROM	WH_Visa.Derived.Customer  C
--JOIN	WH_Visa.Derived.CINList CL ON CL.CIN = C.SourceUID
--WHERE	C.CurrentlyActive = 1
--AND		SourceUID NOT IN (SELECT SourceUID FROM Staging.Customer_DuplicateSourceUID) 


--IF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC
--SELECT ConsumerCombinationID
--INTO	#CC
--FROM	WH_Visa.Trans.ConsumerCombination  CC
--WHERE	BrandID IN (195,294,366,417)			-- Competitors:  Hawes & Curtis, TM Lewin, Moss Bros and Reiss.

--DECLARE @DATE_6 DATE = DATEADD(MONTH, -6, GETDATE())

--IF OBJECT_ID('tempdb..#Trans') IS NOT NULL DROP TABLE #Trans
--SELECT	F.CINID
--INTO	#Trans
--FROM	WH_Visa.Trans.Consumertransaction CT
--JOIN	#FB F ON F.CINID = CT.CINID
--JOIN	#CC C 	ON C.ConsumerCombinationID = CT.ConsumerCombinationID
--WHERE	TranDate > @DATE_6
--		AND Amount > 0
--GROUP BY F.CINID


--IF OBJECT_ID('Sandbox.SamH.BC_CharlesTyrwhitt_CS_210921') IS NOT NULL DROP TABLE Sandbox.SamH.BC_CharlesTyrwhitt_CS_210921
--SELECT	CINID
--INTO Sandbox.SamH.BC_CharlesTyrwhitt_CS_210921
--FROM  #Trans

IF OBJECT_ID('[Warehouse].[Selections].[CT059_PreSelection]') IS NOT NULL DROP TABLE [Warehouse].[Selections].[CT059_PreSelection]
SELECT	fb.FanID
INTO [Warehouse].[Selections].[CT059_PreSelection]
FROM #FB fb
WHERE EXISTS (	SELECT 1
				FROM Sandbox.SamH.RBS_CharlesTyrwhitt_CS_210921 sb
				WHERE fb.CINID = sb.CINID)


END;