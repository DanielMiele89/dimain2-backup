
CREATE PROCEDURE [Selections].[SDY018_PreSelection_sProc]
AS
BEGIN

	-----BARCLAYS-----------------------------------------------------------------
	IF OBJECT_ID('tempdb..#FB') IS NOT NULL DROP TABLE #FB
	SELECT	CINID, FanID
	INTO	#FB
	FROM	WH_Visa.Derived.Customer  C
	JOIN	WH_Visa.Derived.CINList CL ON CL.CIN = C.SourceUID
	WHERE	C.CurrentlyActive = 1
	AND		SourceUID NOT IN (SELECT SourceUID FROM Derived.Customer_DuplicateSourceUID) 
	CREATE CLUSTERED INDEX ix_CINID on #FB(CINID)


	IF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC
	SELECT  ConsumerCombinationID, brandid
	INTO	#CC
	FROM	WH_Visa.Trans.ConsumerCombination
	WHERE	BrandID IN (472,496,1083,1226,1718)	
	CREATE CLUSTERED INDEX ix_ConsumerCombinationID on #CC(ConsumerCombinationID)


	IF OBJECT_ID('tempdb..#shoppper_sow') IS NOT NULL DROP TABLE #shoppper_sow
	SELECT  ct.CINID, FanID
			,1.0 * (CAST(SUM(CASE WHEN BrandID = 1226 THEN Amount ELSE 0 END )as float) / NULLIF(SUM(Amount),0)) AS SuperdrySoW
			,MAX(CASE WHEN BrandID = 1226 AND TranDate >= DATEADD(MONTH,-6,GETDATE()) THEN 1 ELSE 0 END) SuperdryShopper
	INTO	#shoppper_sow
	FROM	WH_Visa.Trans.Consumertransaction CT
	JOIN	#CC CC	ON ct.ConsumerCombinationID = CC.ConsumerCombinationID
	JOIN	#FB fb	ON ct.CINID = fb.CINID
	WHERE	TranDate >= DATEADD(MONTH,-12,GETDATE())
			AND Amount > 0
	GROUP BY ct.CINID, FanID
	CREATE CLUSTERED INDEX ix_FanID on #shoppper_sow(CINID)


	-- shoppers - SOW - < 33%
	IF OBJECT_ID('Sandbox.samh.superdry_sow33_BC_25012021') IS NOT NULL DROP TABLE Sandbox.samh.superdry_sow33_BC_25012021
	SELECT	F.CINID, FanID
	INTO	Sandbox.samh.superdry_sow33_BC_25012021
	FROM	#shoppper_sow F
	WHERE	SuperdryShopper = 1
			AND SuperdrySoW < 0.3333
	GROUP BY F.CINID, FanID


	IF OBJECT_ID('[WH_Visa].[Selections].[SDY018_PreSelection]') IS NOT NULL DROP TABLE [WH_Visa].[Selections].[SDY018_PreSelection]
	SELECT FanID
	INTO [WH_Visa].[Selections].[SDY018_PreSelection]
	FROM Sandbox.samh.superdry_sow33_BC_25012021

END


