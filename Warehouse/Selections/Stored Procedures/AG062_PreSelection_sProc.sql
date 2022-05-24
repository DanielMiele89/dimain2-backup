
CREATE PROCEDURE [Selections].[AG062_PreSelection_sProc]
AS
BEGIN

IF OBJECT_ID('tempdb..#FB') IS NOT NULL DROP TABLE #FB
SELECT	CINID
	,	FanID
		,AgeCurrent
INTO	#FB
FROM	Relational.Customer C
JOIN	Relational.CINList CL ON CL.CIN = C.SourceUID
WHERE	C.CurrentlyActive = 1
AND		SourceUID NOT IN (SELECT SourceUID FROM Staging.Customer_DuplicateSourceUID) 
--and AgeCurrent >= 55
CREATE CLUSTERED INDEX ix_CINID on #FB(CINID)


IF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC
SELECT	CC.BrandID
		,ConsumerCombinationID
INTO	#CC
FROM	Relational.ConsumerCombination CC
join	Relational.brand b on cc.brandid = b.brandid
WHERE	b.sectorID IN (59,44,40)
and cc.brandid <> 12
CREATE CLUSTERED INDEX ix_ConsumerCombinationID on #CC(ConsumerCombinationID)


IF OBJECT_ID('tempdb..#CT') IS NOT NULL DROP TABLE #CT
SELECT ct.CINID
INTO #CT
FROM #CC CC
JOIN Relational.ConsumerTransaction_MyRewards ct
    ON CC.ConsumerCombinationID = ct.ConsumerCombinationID
JOIN #FB F
	ON F.CINID = CT.CINID
WHERE TranDate > DATEADD(MONTH, -6, GETDATE())
	AND Amount > 0
GROUP BY CT.CINID
	

IF OBJECT_ID('Sandbox.bastienc.americangolf') IS NOT NULL DROP TABLE Sandbox.bastienc.americangolf
SELECT	F.CINID
INTO	Sandbox.bastienc.americangolf
FROM	#ct F
GROUP BY F.CINID

	IF OBJECT_ID('[Warehouse].[Selections].[AG062_PreSelection]') IS NOT NULL DROP TABLE [Warehouse].[Selections].[AG062_PreSelection]
	SELECT FanID
	INTO [Warehouse].[Selections].[AG062_PreSelection]
	FROM #FB fb
	WHERE EXISTS (SELECT 1 FROM Sandbox.bastienc.americangolf s WHERE fb.CINID = s.CINID)

END