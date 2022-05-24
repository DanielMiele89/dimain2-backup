
CREATE PROCEDURE [Selections].[MOR125_PreSelection_sProc_20220307]
AS
BEGIN

	-- ACQUIRE AND LAPSED CUSTOMERS
	IF OBJECT_ID('tempdb..#FB') IS NOT NULL DROP TABLE #FB
	SELECT	CINID
		,	FanID
	INTO	#FB
	FROM	Relational.Customer C
	JOIN	Relational.CINList CL ON CL.CIN = C.SourceUID
	WHERE	C.CurrentlyActive = 1
	AND		C.SourceUID NOT IN (SELECT SourceUID FROM Staging.Customer_DuplicateSourceUID)
	GROUP BY CL.CINID, FanID
	CREATE CLUSTERED INDEX ix_FanID on #FB(CINID)


	IF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC
	SELECT  ConsumerCombinationID, CC.BrandID
	INTO	#CC
	FROM	Relational.ConsumerCombination CC
	JOIN	Relational.Brand B ON B.BrandID = CC.BrandID
	WHERE	CC.BrandID IN  (292,21,379,425,2541,5,254)		-- Morrisons 292, Asda 21, Sainsburys 379, Tesco 425, Amazon Fresh 2541, Aldi 5, Lidl 254
	CREATE CLUSTERED INDEX ix_ConsumerCombinationID on #CC(ConsumerCombinationID)


	IF OBJECT_ID('tempdb..#Txn') IS NOT NULL DROP TABLE #Txn
	SELECT  CT.CINID as CINID
			,COUNT(1) AS Txn
			,SUM(Amount) as Spend
	INTO	#Txn
	FROM	Relational.ConsumerTransaction_MyRewards CT	
	JOIN	#CC CC ON CC.ConsumerCombinationID = CT.ConsumerCombinationID
	JOIN	#FB FB	ON CT.CINID = FB.CINID
	WHERE	TranDate >= DATEADD(MONTH,-6,GETDATE()) 
	GROUP BY CT.CINID
	CREATE CLUSTERED INDEX ix_CINID on #Txn(CINID)

	IF OBJECT_ID('tempdb..#Txn_Morrisons') IS NOT NULL DROP TABLE #Txn_Morrisons
	SELECT  CT.CINID as CINID
	INTO	#Txn_Morrisons
	FROM	Relational.ConsumerTransaction_MyRewards CT	
	JOIN	#CC CC ON CC.ConsumerCombinationID = CT.ConsumerCombinationID
	JOIN	#FB FB	ON CT.CINID = FB.CINID
	WHERE	TranDate >= DATEADD(MONTH,-3,GETDATE()) 
			AND BrandID = 292
	GROUP BY CT.CINID
	CREATE CLUSTERED INDEX ix_CINID on #Txn_Morrisons(CINID)


	IF OBJECT_ID('tempdb..#NtileEngaged') IS NOT NULL DROP TABLE #NtileEngaged		
	SELECT	  CINID, Txn, Spend
			, NTILE(10) OVER (ORDER BY Spend DESC, Txn DESC) AS NTILE_10
	INTO	#NtileEngaged
	FROM	#Txn T 
	WHERE	CINID NOT IN (SELECT CINID FROM #Txn_Morrisons)


	IF OBJECT_ID('Sandbox.RukanK.Morrisons_TOP10pct_Spenders_10012022_CH') IS NOT NULL DROP TABLE Sandbox.RukanK.Morrisons_TOP10pct_Spenders_10012022_CH
	SELECT	CINID
	INTO	Sandbox.RukanK.Morrisons_TOP10pct_Spenders_10012022_CH
	FROM	#NtileEngaged
	WHERE	NTILE_10 IN (1)
	GROUP BY CINID

	--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	-- NURSERY OFFER
	--IF OBJECT_ID('tempdb..#FB') IS NOT NULL DROP TABLE #FB
	--SELECT	CINID ,FanID
	--INTO	#FB
	--FROM	Relational.Customer C
	--JOIN	Relational.CINList CL ON CL.CIN = C.SourceUID
	--WHERE	C.CurrentlyActive = 1
	--AND		SourceUID NOT IN (SELECT SourceUID FROM Staging.Customer_DuplicateSourceUID)


	IF OBJECT_ID('tempdb..#Responders') IS NOT NULL DROP TABLE #Responders
	SELECT   F.CINID
	INTO	#Responders
	FROM	#FB F
	JOIN	Relational.PartnerTrans PT on Pt.FanID = F.FanID
	WHERE	PT.PartnerID = 4263
			AND TransactionDate >= '2021-12-30'
			AND TransactionAmount > 0
			AND PT.IronOfferID IN (24581)
	CREATE CLUSTERED INDEX cix_CINID ON #Responders(CINID)

	-- 24,664 cardholders
	IF OBJECT_ID('Sandbox.rukank.Morrisons_Nursery_Acquire_21012022') IS NOT NULL DROP TABLE Sandbox.rukank.Morrisons_Nursery_Acquire_21012022
	SELECT	F.CINID
	INTO	Sandbox.rukank.Morrisons_Nursery_Acquire_21012022
	FROM	#Responders F

	IF OBJECT_ID('[Warehouse].[Selections].[MOR125_PreSelection]') IS NOT NULL DROP TABLE [Warehouse].[Selections].[MOR125_PreSelection]
	SELECT FanID
	INTO [Warehouse].[Selections].[MOR125_PreSelection]
	FROM #FB fb
	WHERE EXISTS (	SELECT 1
					FROM Sandbox.RukanK.Morrisons_TOP10pct_Spenders_10012022_CH st
					WHERE fb.CINID = st.CINID)
	AND EXISTS (	SELECT 1
					FROM [Segmentation].[Roc_Shopper_Segment_Members] sg
					WHERE fb.FanID = sg.FanID
					AND sg.EndDate IS NULL
					AND sg.PartnerID = 4263
					AND sg.ShopperSegmentTypeID IN (7,8))
	UNION ALL
	SELECT FanID
	FROM #FB fb
	WHERE EXISTS (	SELECT 1
					FROM Sandbox.RukanK.Morrisons_Nursery_Acquire_21012022 st
					WHERE fb.CINID = st.CINID)
	AND EXISTS (	SELECT 1
					FROM [Segmentation].[Roc_Shopper_Segment_Members] sg
					WHERE fb.FanID = sg.FanID
					AND sg.EndDate IS NULL
					AND sg.PartnerID = 4263
					AND sg.ShopperSegmentTypeID IN (9))

END
	


							
							
							
							
							
							
