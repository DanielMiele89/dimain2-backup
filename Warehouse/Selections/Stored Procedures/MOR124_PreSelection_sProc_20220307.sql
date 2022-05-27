
CREATE PROCEDURE [Selections].[MOR124_PreSelection_sProc_20220307]
AS
BEGIN

	---------- RBS - ACQUIRE AND LAPSED ----------
	IF OBJECT_ID('tempdb..#FB1') IS NOT NULL DROP TABLE #FB1
	SELECT	CINID, FanID
	INTO	#FB1
	FROM	Relational.Customer C
	JOIN	Relational.CINList CL ON CL.CIN = C.SourceUID
	WHERE	C.CurrentlyActive = 1
	AND		C.SourceUID NOT IN (SELECT SourceUID FROM Staging.Customer_DuplicateSourceUID)
	GROUP BY CL.CINID, FanID
	CREATE CLUSTERED INDEX ix_FanID on #FB1(CINID)

	IF OBJECT_ID('Sandbox.RukanK.Morrisons_BAU_AL_EXCL_21012022_CH') IS NOT NULL DROP TABLE Sandbox.RukanK.Morrisons_BAU_AL_EXCL_21012022_CH
	SELECT	CINID
	INTO	Sandbox.RukanK.Morrisons_BAU_AL_EXCL_21012022_CH
	FROM	#FB1
	WHERE	CINID NOT IN (SELECT CINID FROM Sandbox.RukanK.Morrisons_TOP10pct_Spenders_10012022_CH)
	GROUP BY CINID


	---------- RBS - LOW SOW ----------
	IF OBJECT_ID('tempdb..#FB') IS NOT NULL DROP TABLE #FB
	SELECT	CINID ,FanID
	INTO	#FB
	FROM	Relational.Customer C
	JOIN	Relational.CINList CL ON CL.CIN = C.SourceUID
	WHERE	C.CurrentlyActive = 1
	AND		SourceUID NOT IN (SELECT SourceUID FROM Staging.Customer_DuplicateSourceUID)
	AND		FANID NOT IN (SELECT FANID FROM [InsightArchive].[MorrisonsReward_MatchedCustomers_20190304])		--NOT A MORECARD OWNER--
	CREATE CLUSTERED INDEX ix_CINID on #FB(CINID)


	IF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC
	SELECT	 CC.BrandID
			,ConsumerCombinationID
	INTO	#CC
	FROM	warehouse.Relational.ConsumerCombination CC
	JOIN	warehouse.Relational.Brand B ON B.BrandID = CC.BrandID
	WHERE	CC.BrandID IN  (292,21,379,425,2541,5,254)		-- Morrisons 292, Asda 21, Sainsburys 379, Tesco 425, Amazon Fresh 2541, Aldi 5, Lidl 254
	CREATE CLUSTERED INDEX ix_CCID on #cc (ConsumerCombinationID)


	IF OBJECT_ID('tempdb..#shoppper_sow') IS NOT NULL DROP TABLE #shoppper_sow
	SELECT DISTINCT CT.CINID
			,1.0 * (CAST(SUM(CASE WHEN BrandID = 292 THEN Amount ELSE 0 END )as float) / NULLIF(SUM(Amount),0)) AS SoW
			,MAX(CASE WHEN BrandID = 292 AND TranDate >= DATEADD(MONTH,-3,GETDATE()) THEN 1 ELSE 0 END) BrandShopper
			,COUNT(1) as Transactions
	INTO	#shoppper_sow
	FROM	Relational.ConsumerTransaction_MyRewards CT
	JOIN	#CC CC	ON CT.ConsumerCombinationID = CC.ConsumerCombinationID
	JOIN	#FB FB	ON CT.CINID = FB.CINID
	WHERE	TranDate >= DATEADD(MONTH,-6,GETDATE())
			AND Amount > 0
	GROUP BY CT.CINID
	CREATE CLUSTERED INDEX ix_CINID on #shoppper_sow (CINID)


	IF OBJECT_ID('Sandbox.rukank.Morrisons_LoW_SoW_12012022') IS NOT NULL DROP TABLE Sandbox.rukank.Morrisons_LoW_SoW_12012022		
	SELECT	F.CINID
	INTO	Sandbox.rukank.Morrisons_LoW_SoW_12012022
	FROM	#shoppper_sow F
	WHERE	BrandShopper = 1
			AND SoW < 0.30
			AND Transactions >= 15
			AND CINID NOT IN (SELECT CINID FROM Sandbox.rukank.Morrisons_Aldi_Lidl_11012022)
	GROUP BY F.CINID

	IF OBJECT_ID('[Warehouse].[Selections].[MOR124_PreSelection]') IS NOT NULL DROP TABLE [Warehouse].[Selections].[MOR124_PreSelection]
	SELECT FanID
	INTO [Warehouse].[Selections].[MOR124_PreSelection]
	FROM #FB1 fb
	WHERE EXISTS (	SELECT 1
					FROM Sandbox.RukanK.Morrisons_BAU_AL_EXCL_21012022_CH st
					WHERE fb.CINID = st.CINID)
	AND EXISTS (	SELECT 1
					FROM [Segmentation].[Roc_Shopper_Segment_Members] sg
					WHERE fb.FanID = sg.FanID
					AND sg.EndDate IS NULL
					AND sg.PartnerID = 4263
					AND sg.ShopperSegmentTypeID IN (7, 8))
	UNION ALL
	SELECT FanID
	FROM #FB fb
	WHERE EXISTS (	SELECT 1
					FROM Sandbox.RukanK.Morrisons_LoW_SoW_12012022 st
					WHERE fb.CINID = st.CINID)
	AND EXISTS (	SELECT 1
					FROM [Segmentation].[Roc_Shopper_Segment_Members] sg
					WHERE fb.FanID = sg.FanID
					AND sg.EndDate IS NULL
					AND sg.PartnerID = 4263
					AND sg.ShopperSegmentTypeID IN (9))

END



