
CREATE PROCEDURE [Selections].[BIC005_PreSelection_sProc]
AS
BEGIN

	IF OBJECT_ID('tempdb..#FB') IS NOT NULL DROP TABLE #FB
		SELECT	C.FanID
				,CINID
		INTO #FB
		FROM	Relational.Customer C
		JOIN	Relational.CINList CL ON CL.CIN = C.SourceUID
		WHERE C.CurrentlyActive = 1
		AND SourceUID NOT IN (SELECT SourceUID FROM Staging.Customer_DuplicateSourceUID)
		CREATE CLUSTERED INDEX ix_FanID on #FB(FANID)


---------------------------------------------------------------------------------------------------------------------------------------
-- Consumer Combinations for chosen Brand
---------------------------------------------------------------------------------------------------------------------------------------
		IF OBJECT_ID('tempdb..#CCIDs') IS NOT NULL DROP TABLE #CCIDs
		SELECT ConsumerCombinationID
		INTO #CCIDs
		FROM Relational.ConsumerCombination cc WITH (NOLOCK)
		WHERE MID IN (SELECT MerchantID FROM relational.outlet WHERE PartnerID = 4938)

		CREATE CLUSTERED INDEX CIX_CCID_CCID ON #CCIDs (ConsumerCombinationID)



	IF OBJECT_ID('tempdb..#CT') IS NOT NULL DROP TABLE #CT
		SELECT ct.CINID
			 , ct.TranDate
			 , sum(amount) as sales
			 , count(*) as transactions
		INTO #CT
		FROM #CCIDs CCs
		INNER JOIN Relational.ConsumerTransaction_MyRewards ct
			ON CCs.ConsumerCombinationID = ct.ConsumerCombinationID
		INNER JOIN #FB F
			ON F.CINID = CT.CINID
		WHERE TranDate >= DATEADD(MONTH,-36 , GETDATE())
			  AND Amount > 0																			-- To ignore Returns
		GROUP BY CT.CINID
				,TranDate
		CREATE CLUSTERED INDEX ix_CINID ON #CT(CINID)


	IF OBJECT_ID('tempdb..#temp1') IS NOT NULL DROP TABLE #temp1
		select trandate
			,cinid
		,sales
		,transactions
		into #temp1
		from #CT 
		where sales >= 200

IF OBJECT_ID('Sandbox.SamH.BicesterBAU_200inday_28032022') IS NOT NULL DROP TABLE Sandbox.SamH.BicesterBAU_200inday_28032022

		select DISTINCT CINID
		INTO Sandbox.SamH.BicesterBAU_200inday_28032022
		from #temp1

	IF OBJECT_ID('[Warehouse].[Selections].[BIC005_PreSelection]') IS NOT NULL DROP TABLE [Warehouse].[Selections].[BIC005_PreSelection]
	SELECT FanID
	INTO [Warehouse].[Selections].[BIC005_PreSelection]
	FROM #FB fb
	WHERE EXISTS (	SELECT 1
					FROM Sandbox.SamH.BicesterBAU_200inday_28032022  st
					WHERE fb.CINID = st.CINID)

END






















