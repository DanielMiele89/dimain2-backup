
CREATE PROCEDURE [Selections].[SDY016_PreSelection_sProc]
AS
BEGIN

	IF OBJECT_ID('tempdb..#FB') IS NOT NULL DROP TABLE #FB
	SELECT	CINID, FanID
	INTO	#FB
	FROM	Relational.Customer C
	JOIN	Relational.CINList CL ON CL.CIN = C.SourceUID
	WHERE	C.CurrentlyActive = 1
	AND		SourceUID NOT IN (SELECT SourceUID FROM Staging.Customer_DuplicateSourceUID) 
	CREATE CLUSTERED INDEX ix_FanID on #FB(CINID)


	IF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC
	SELECT	CC.BrandID
			,ConsumerCombinationID
	INTO	#CC
	FROM	Relational.ConsumerCombination CC
	WHERE	CC.BrandID IN (472,496,1083,1226,1718)
	CREATE CLUSTERED INDEX ix_FanID on #CC(ConsumerCombinationID)


	IF OBJECT_ID('tempdb..#shoppper_sow') IS NOT NULL DROP TABLE #shoppper_sow
	SELECT  ct.CINID, FanID
			,1.0 * (CAST(SUM(CASE WHEN BrandID = 1226 THEN Amount ELSE 0 END )as float) / NULLIF(SUM(Amount),0)) AS SuperdrySoW
			,MAX(CASE WHEN BrandID = 1226 AND TranDate >= DATEADD(MONTH,-6,GETDATE()) THEN 1 ELSE 0 END) SuperdryShopper
	INTO	#shoppper_sow
	FROM	Relational.ConsumerTransaction_MyRewards ct
	JOIN	#CC cc	ON ct.ConsumerCombinationID = cc.ConsumerCombinationID
	JOIN	#FB fb	ON ct.CINID = fb.CINID
	WHERE	TranDate >= DATEADD(MONTH,-12,GETDATE())
			AND Amount > 0
	GROUP BY ct.CINID, FanID
	CREATE CLUSTERED INDEX ix_FanID on #shoppper_sow(CINID)

	-- shoppers - SOW - >= 66%
	IF OBJECT_ID('Sandbox.samh.superdry_sow66_25012021') IS NOT NULL DROP TABLE Sandbox.samh.superdry_sow66_25012021
	SELECT	F.CINID, FanID
	INTO	Sandbox.samh.superdry_sow66_25012021
	FROM	#shoppper_sow F
	WHERE	SuperdryShopper = 1
			AND SuperdrySoW >= 0.6666
	GROUP BY F.CINID, FanID


	IF OBJECT_ID('[Warehouse].[Selections].[SDY016_PreSelection]') IS NOT NULL DROP TABLE [Warehouse].[Selections].[SDY016_PreSelection]
	SELECT FanID
	INTO [Warehouse].[Selections].[SDY016_PreSelection]
	FROM Sandbox.samh.superdry_sow66_25012021

END


