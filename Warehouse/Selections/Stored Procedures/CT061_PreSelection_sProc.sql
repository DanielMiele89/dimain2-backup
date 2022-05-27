CREATE PROCEDURE [Selections].[CT061_PreSelection_sProc]
AS
BEGIN

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
--WHERE Txn >= 3

IF OBJECT_ID('[Warehouse].[Selections].[CT061_PreSelection]') IS NOT NULL DROP TABLE [Warehouse].[Selections].[CT061_PreSelection]
SELECT	fb.FanID
INTO [Warehouse].[Selections].[CT061_PreSelection]
FROM #FB fb
WHERE EXISTS (	SELECT 1
				FROM Sandbox.SamH.RBS_CharlesTyrwhitt_CS_210921 sb
				WHERE fb.CINID = sb.CINID)

END;
