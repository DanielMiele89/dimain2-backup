
CREATE PROCEDURE [Selections].[SDY016_PreSelection_sProc]
AS
BEGIN

	-----BARCLAYS-----------------------------------------------------------------
	IF OBJECT_ID('tempdb..#FB') IS NOT NULL DROP TABLE #FB
	SELECT	CINID, FanID
	INTO	#FB
	FROM	WH_Virgin.Derived.Customer  C
	JOIN	WH_Virgin.Derived.CINList CL ON CL.CIN = C.SourceUID
	WHERE	C.CurrentlyActive = 1
	AND		SourceUID NOT IN (SELECT [Derived].[Customer_DuplicateSourceUID].[SourceUID] FROM Derived.Customer_DuplicateSourceUID) 
	CREATE CLUSTERED INDEX ix_CINID on #FB(CINID)


	IF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC
	SELECT  [WH_Virgin].[Trans].[ConsumerCombination].[ConsumerCombinationID], [WH_Virgin].[Trans].[ConsumerCombination].[brandid]
	INTO	#CC
	FROM	WH_Virgin.Trans.ConsumerCombination
	WHERE	[WH_Virgin].[Trans].[ConsumerCombination].[BrandID] IN (472,496,1083,1226,1718)	
	CREATE CLUSTERED INDEX ix_ConsumerCombinationID on #CC(ConsumerCombinationID)


	IF OBJECT_ID('tempdb..#shoppper_sow') IS NOT NULL DROP TABLE #shoppper_sow
	SELECT  ct.CINID, FanID
			,1.0 * (CAST(SUM(CASE WHEN BrandID = 1226 THEN Amount ELSE 0 END )as float) / NULLIF(SUM(Amount),0)) AS SuperdrySoW
			,MAX(CASE WHEN BrandID = 1226 AND TranDate >= DATEADD(MONTH,-6,GETDATE()) THEN 1 ELSE 0 END) SuperdryShopper
	INTO	#shoppper_sow
	FROM	WH_Virgin.Trans.Consumertransaction CT
	JOIN	#CC CC	ON #CC.[ct].ConsumerCombinationID = CC.ConsumerCombinationID
	JOIN	#FB fb	ON ct.CINID = fb.CINID
	WHERE	TranDate >= DATEADD(MONTH,-12,GETDATE())
			AND Amount > 0
	GROUP BY ct.CINID, FanID
	CREATE CLUSTERED INDEX ix_FanID on #shoppper_sow(CINID)

	-- shoppers - SOW - >= 66%
	IF OBJECT_ID('Sandbox.samh.superdry_sow66_VM_25012021') IS NOT NULL DROP TABLE Sandbox.samh.superdry_sow66_VM_25012021
	SELECT	F.CINID, [F].[FanID]
	INTO	Sandbox.samh.superdry_sow66_VM_25012021
	FROM	#shoppper_sow F
	WHERE	[F].[SuperdryShopper] = 1
			AND [F].[SuperdrySoW] >= 0.6666
	GROUP BY F.CINID, [F].[FanID]

	IF OBJECT_ID('[WH_Virgin].[Selections].[SDY016_PreSelection]') IS NOT NULL DROP TABLE [WH_Virgin].[Selections].[SDY016_PreSelection]
	SELECT [Sandbox].[samh].[superdry_sow66_VM_25012021].[FanID]
	INTO [WH_Virgin].[Selections].[SDY016_PreSelection]
	FROM Sandbox.samh.superdry_sow66_VM_25012021

END


