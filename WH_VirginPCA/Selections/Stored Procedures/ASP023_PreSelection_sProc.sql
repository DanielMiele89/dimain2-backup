
CREATE PROCEDURE [Selections].[ASP023_PreSelection_sProc]
AS
BEGIN

IF OBJECT_ID('tempdb..#FB') IS NOT NULL DROP TABLE #FB
SELECT	CINID, FanID
INTO	#FB
FROM	WH_VirginPCA.Derived.Customer  C
JOIN	WH_VirginPCA.Derived.CINList CL ON CL.CIN = C.SourceUID
WHERE	C.CurrentlyActive = 1
and AccountType IS NOT NULL
--AND		SourceUID NOT IN (SELECT SourceUID FROM Staging.Customer_DuplicateSourceUID) 
CREATE CLUSTERED INDEX ix_CINID on #FB(CINID)


IF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC
SELECT ConsumerCombinationID
INTO	#CC
FROM	WH_VirginPCA.trans.ConsumerCombination  CC
WHERE	BrandID IN (2107,2660,2665,2085,1651)							-- Kate Spade, Mulberry, Coach, Burberry and Smythson
CREATE CLUSTERED INDEX ix_ConsumerCombinationID on #CC(ConsumerCombinationID)


IF OBJECT_ID('tempdb..#Trans') IS NOT NULL DROP TABLE #Trans
SELECT	F.CINID
INTO	#Trans
FROM	WH_VirginPCA.trans.consumertransaction CT
JOIN	#FB F ON F.CINID = CT.CINID
JOIN	#CC C 	ON C.ConsumerCombinationID = CT.ConsumerCombinationID
WHERE	TranDate > DATEADD(MONTH, -24, GETDATE())
		AND Amount > 0
GROUP BY F.CINID
CREATE CLUSTERED INDEX ix_CINID on #Trans(CINID)


IF OBJECT_ID('Sandbox.LeoP.VM_Aspinal_CompSteal010422') IS NOT NULL DROP TABLE Sandbox.LeoP.VM_Aspinal_CompSteal010422
SELECT	CINID
INTO	Sandbox.LeoP.VM_Aspinal_CompSteal010422
FROM	#Trans



	IF OBJECT_ID('[WH_VirginPCA].[Selections].[ASP023_PreSelection]') IS NOT NULL DROP TABLE [WH_VirginPCA].[Selections].[ASP023_PreSelection]
	SELECT FanID
	INTO [WH_VirginPCA].[Selections].[ASP023_PreSelection]
	FROM #FB fb
	WHERE EXISTS (	SELECT 1
					FROM Sandbox.LeoP.VM_Aspinal_CompSteal010422  st
					WHERE fb.CINID = st.CINID)

END
