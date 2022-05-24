
CREATE PROCEDURE [Selections].[SP025_PreSelection_sProc]
AS
BEGIN

IF OBJECT_ID('tempdb..#FB_bc') IS NOT NULL DROP TABLE #FB_bc
SELECT	CINID,FanID
INTO	#FB_bc
FROM	WH_Visa.Derived.Customer  C
JOIN	WH_Visa.Derived.CINList CL ON CL.CIN = C.SourceUID
WHERE	C.CurrentlyActive = 1
CREATE CLUSTERED INDEX ix_CINID on #FB_bc(CINID)


IF OBJECT_ID('tempdb..#CC_bc') IS NOT NULL DROP TABLE #CC_bc
SELECT ConsumerCombinationID
INTO	#CC_bc
FROM	WH_Visa.Trans.ConsumerCombination  CC
WHERE	BrandID IN (1458)																		-- Space NK


IF OBJECT_ID('tempdb..#Trans_bc') IS NOT NULL DROP TABLE #Trans_bc			-- 868
SELECT	F.CINID
INTO	#Trans_bc
FROM	WH_Visa.Trans.Consumertransaction CT
JOIN	#FB_bc F ON F.CINID = CT.CINID
JOIN	#CC_bc C 	ON C.ConsumerCombinationID = CT.ConsumerCombinationID
WHERE	TranDate > DATEADD(MONTH, -9, GETDATE())
		AND Amount > 0
GROUP BY F.CINID
CREATE CLUSTERED INDEX ix_CINID on #Trans_bc(CINID)



IF OBJECT_ID('tempdb..#Trans_lapsed_bc') IS NOT NULL DROP TABLE #Trans_lapsed_bc	--	453
SELECT	F.CINID
INTO	#Trans_lapsed_bc
FROM	#FB_bc F
JOIN	WH_Visa.Trans.Consumertransaction CT ON F.CINID = CT.CINID
JOIN	#CC_bc	 C 	ON C.ConsumerCombinationID = CT.ConsumerCombinationID
WHERE	Amount > 0
AND		TranDate BETWEEN DATEADD(MONTH,-24,GETDATE()) AND  DATEADD(MONTH,-9,GETDATE())
GROUP BY F.CINID
CREATE CLUSTERED INDEX ix_CINID on #Trans_lapsed_bc(CINID)


IF OBJECT_ID('Sandbox.RukanK.BC_SpaceNK_Lapsed_Customers2') IS NOT NULL DROP TABLE Sandbox.RukanK.BC_SpaceNK_Lapsed_Customers2		--258
SELECT	CINID
INTO	Sandbox.RukanK.BC_SpaceNK_Lapsed_Customers2
FROM	#Trans_lapsed_bc
WHERE	CINID NOT IN (SELECT CINID FROM #Trans_bc)



	IF OBJECT_ID('[WH_Visa].[Selections].[SP025_PreSelection]') IS NOT NULL DROP TABLE [WH_Visa].[Selections].[SP025_PreSelection]
	SELECT FanID
	INTO [WH_Visa].[Selections].[SP025_PreSelection]
	FROM #FB_bc fb
	WHERE EXISTS (	SELECT 1
					FROM Sandbox.rukank.Barclays_Morrisons_LoW_SoW_06052022  st
					WHERE fb.CINID = st.CINID)

END
