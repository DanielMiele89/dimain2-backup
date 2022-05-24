
CREATE PROCEDURE [Selections].[ASP023_PreSelection_sProc]
AS
BEGIN

IF OBJECT_ID('tempdb..#FB') IS NOT NULL DROP TABLE #FB
SELECT	CINID, FanID
INTO	#FB
FROM	WH_Visa.Derived.Customer  C
JOIN	WH_Visa.Derived.CINList CL ON CL.CIN = C.SourceUID
WHERE	C.CurrentlyActive = 1
	--	AND		SourceUID NOT IN (SELECT SourceUID FROM Staging.Customer_DuplicateSourceUID) 
CREATE CLUSTERED INDEX ix_CINID on #FB(CINID)


IF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC
SELECT  ConsumerCombinationID
INTO	#CC
FROM	WH_Visa.Trans.ConsumerCombination  CC
WHERE	BrandID IN (2434,2592,2777)							-- Competitors: Lu Lu Lemon, Gym shark and Fabletics
CREATE CLUSTERED INDEX ix_ConsumerCombinationID on #CC(ConsumerCombinationID)


IF OBJECT_ID('tempdb..#Trans') IS NOT NULL DROP TABLE #Trans
SELECT	F.CINID
INTO	#Trans
FROM	WH_Visa.Trans.Consumertransaction CT
JOIN	#FB F ON F.CINID = CT.CINID
JOIN	#CC C 	ON C.ConsumerCombinationID = CT.ConsumerCombinationID
WHERE	TranDate > DATEADD(MONTH, -24, GETDATE())
		AND Amount > 0
GROUP BY F.CINID
CREATE CLUSTERED INDEX ix_CINID on #Trans(CINID)


IF OBJECT_ID('Sandbox.RukanK.Barclays_Aspinal_CompSteal010422') IS NOT NULL DROP TABLE Sandbox.RukanK.Barclays_Aspinal_CompSteal010422
SELECT	CINID
INTO	Sandbox.RukanK.Barclays_Aspinal_CompSteal010422
FROM	#Trans

	IF OBJECT_ID('[WH_Visa].[Selections].[ASP023_PreSelection]') IS NOT NULL DROP TABLE [WH_Visa].[Selections].[ASP023_PreSelection]
	SELECT FanID
	INTO [WH_Visa].[Selections].[ASP023_PreSelection]
	FROM #FB fb
	WHERE EXISTS (	SELECT 1
					FROM Sandbox.LeoP.Barclays_Aspinal_CompSteal010422  st
					WHERE fb.CINID = st.CINID)

END

