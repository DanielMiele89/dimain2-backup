
CREATE PROCEDURE [Selections].[MOR158_PreSelection_sProc]
AS
BEGIN

--- Top Grocery Spenders - Acquire and Lapsed ---
IF OBJECT_ID('tempdb..#FB1') IS NOT NULL DROP TABLE #FB1
SELECT	CINID, FanID
INTO	#FB1
FROM	Relational.Customer C
JOIN	Relational.CINList CL ON CL.CIN = C.SourceUID
WHERE	C.CurrentlyActive = 1
AND		C.SourceUID NOT IN (SELECT SourceUID FROM Staging.Customer_DuplicateSourceUID)
GROUP BY CL.CINID, FanID
CREATE CLUSTERED INDEX ix_FanID on #FB1(CINID)


IF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC
SELECT  ConsumerCombinationID, CC.BrandID
INTO	#CC
FROM	Relational.ConsumerCombination CC
JOIN	Relational.Brand B ON B.BrandID = CC.BrandID
WHERE	CC.BrandID IN  (292,21,379,425,2541,5,254,485)		-- Morrisons 292, Asda 21, Sainsburys 379, Tesco 425, Amazon Fresh 2541, Aldi 5, Lidl 254, Waitrose 485
GROUP BY CC.BrandID, ConsumerCombinationID
CREATE CLUSTERED INDEX ix_ConsumerCombinationID on #CC(ConsumerCombinationID)


IF OBJECT_ID('tempdb..#Txn') IS NOT NULL DROP TABLE #Txn		
SELECT  CT.CINID as CINID
		,COUNT(1) AS Txn
		,SUM(Amount) as Spend
INTO	#Txn
FROM	Relational.ConsumerTransaction_MyRewards CT	
JOIN	#CC CC ON CC.ConsumerCombinationID = CT.ConsumerCombinationID
JOIN	#FB1 FB	ON CT.CINID = FB.CINID
WHERE	TranDate >= DATEADD(MONTH,-6,GETDATE()) 
GROUP BY CT.CINID
CREATE CLUSTERED INDEX ix_CINID on #Txn(CINID)

IF OBJECT_ID('tempdb..#Txn_Morrisons') IS NOT NULL DROP TABLE #Txn_Morrisons		-- 1,075,655
SELECT  CT.CINID as CINID
INTO	#Txn_Morrisons
FROM	Relational.ConsumerTransaction_MyRewards CT	
JOIN	#CC CC ON CC.ConsumerCombinationID = CT.ConsumerCombinationID
JOIN	#FB1 FB	ON CT.CINID = FB.CINID
WHERE	TranDate >= DATEADD(MONTH,-3,GETDATE()) 
		AND BrandID = 292
GROUP BY CT.CINID
CREATE CLUSTERED INDEX ix_CINID on #Txn_Morrisons(CINID)


IF OBJECT_ID('tempdb..#NtileEngaged') IS NOT NULL DROP TABLE #NtileEngaged		--	1,985,652
SELECT	  CINID, Txn, Spend
		, NTILE(4) OVER (ORDER BY Spend DESC, Txn DESC) AS NTILE_4
INTO	#NtileEngaged
FROM	#Txn T 
WHERE	CINID NOT IN (SELECT CINID FROM #Txn_Morrisons)


IF OBJECT_ID('Sandbox.RukanK.Morrisons_TOP25pct_Spenders_06052022_CH') IS NOT NULL DROP TABLE Sandbox.RukanK.Morrisons_TOP25pct_Spenders_06052022_CH		-- 489,771
SELECT	CINID
INTO	Sandbox.RukanK.Morrisons_TOP25pct_Spenders_06052022_CH
FROM	#NtileEngaged
WHERE	NTILE_4 IN (1)
GROUP BY CINID



--- Low SoW Shopper - ALDI/LIDL ---
IF OBJECT_ID('tempdb..#FB2') IS NOT NULL DROP TABLE #FB2
SELECT	CINID, FanID
INTO	#FB2
FROM	Relational.Customer C
JOIN	Relational.CINList CL ON CL.CIN = C.SourceUID
WHERE	C.CurrentlyActive = 1
AND		SourceUID NOT IN (SELECT SourceUID FROM Staging.Customer_DuplicateSourceUID)
AND		FANID NOT IN (SELECT FANID FROM [InsightArchive].[MorrisonsReward_MatchedCustomers_20190304])		--NOT A MORECARD OWNER--
CREATE CLUSTERED INDEX ix_FanID on #FB2(CINID)


IF OBJECT_ID('tempdb..#CC2') IS NOT NULL DROP TABLE #CC2
SELECT	CC.BrandID, ConsumerCombinationID
INTO	#CC2
FROM	Relational.ConsumerCombination CC
JOIN	Relational.Brand B ON B.BrandID = CC.BrandID
WHERE	CC.BrandID IN  (292,21,379,425,2541,5,254,485)		-- Morrisons 292, Asda 21, Sainsburys 379, Tesco 425, Amazon Fresh 2541, Aldi 5, Lidl 254, Waitrose 485
CREATE CLUSTERED INDEX ix_CCID on #CC2(ConsumerCombinationID)


IF OBJECT_ID('tempdb..#shoppper_sow') IS NOT NULL DROP TABLE #shoppper_sow
SELECT   CT.CINID
		,1.0 * (CAST(SUM(CASE WHEN BrandID IN (5,254) THEN Amount ELSE 0 END )as float) / NULLIF(SUM(Amount),0)) AS Aldi_Lidl_SoW
		,1.0 * (CAST(SUM(CASE WHEN BrandID = 292 THEN Amount ELSE 0 END )as float) / NULLIF(SUM(Amount),0)) AS Morrisons_SoW
		,SUM(Amount) AS Spend
INTO	#shoppper_sow
FROM	Relational.ConsumerTransaction_MyRewards CT
JOIN	#CC2 CC	ON CT.ConsumerCombinationID = CC.ConsumerCombinationID
JOIN	#FB2 FB	ON CT.CINID = FB.CINID
WHERE	TranDate BETWEEN '2021-06-15' AND '2021-12-14'
		AND Amount > 0
GROUP BY CT.CINID
HAVING	1.0 * (CAST(SUM(CASE WHEN BrandID IN (5,254) THEN Amount ELSE 0 END )as float) / NULLIF(SUM(Amount),0)) >= 0.50
CREATE CLUSTERED INDEX ix_CINID on #shoppper_sow(CINID)


IF OBJECT_ID('tempdb..#shoppper_sow_XMAS') IS NOT NULL DROP TABLE #shoppper_sow_XMAS
SELECT   CT.CINID AS CINID_XMAS
		,1.0 * (CAST(SUM(CASE WHEN BrandID = 292 THEN Amount ELSE 0 END )as float) / NULLIF(SUM(Amount),0)) AS Morrisons_SoW_XMAS
		,1.0 * (CAST(SUM(CASE WHEN BrandID IN (5,254) THEN Amount ELSE 0 END )as float) / NULLIF(SUM(Amount),0)) AS Aldi_Lidl_SoW_XMAS
		,MAX(CASE WHEN BrandID = 292 AND (TranDate BETWEEN '2021-12-15' AND '2021-12-30') THEN 1 ELSE 0 END) BrandShopper_Morrisons
		,SUM(Amount) AS Spend
INTO	#shoppper_sow_XMAS
FROM	Relational.ConsumerTransaction_MyRewards CT
JOIN	#CC2 CC	ON CT.ConsumerCombinationID = CC.ConsumerCombinationID
JOIN	#FB2 FB	ON CT.CINID = FB.CINID
WHERE	TranDate BETWEEN '2021-12-15' AND '2021-12-30'
		AND Amount > 0
GROUP BY CT.CINID
HAVING	MAX(CASE WHEN BrandID = 292 AND (TranDate BETWEEN '2021-12-15' AND '2021-12-30') THEN 1 ELSE 0 END) = 1
CREATE CLUSTERED INDEX ix_CINID on #shoppper_sow_XMAS(CINID_XMAS)


IF OBJECT_ID('tempdb..#Aldi_Lidl') IS NOT NULL DROP TABLE #Aldi_Lidl																
SELECT	SX.CINID_XMAS AS CINID, Aldi_Lidl_SoW_XMAS, Aldi_Lidl_SoW
		,Morrisons_SoW_XMAS, Morrisons_SoW, (Morrisons_SoW_XMAS - Morrisons_SoW) AS Morrisons_SoW_diff
INTO	#Aldi_Lidl
FROM	#shoppper_sow_XMAS SX
JOIN	#shoppper_sow S ON S.CINID = SX.CINID_XMAS


IF OBJECT_ID('Sandbox.rukank.Morrisons_Aldi_Lidl_03052022') IS NOT NULL DROP TABLE Sandbox.rukank.Morrisons_Aldi_Lidl_03052022		
SELECT	F.CINID
INTO	Sandbox.rukank.Morrisons_Aldi_Lidl_03052022
FROM	#Aldi_Lidl F
WHERE	Morrisons_SoW_diff >= 0.20
		and CINID NOT IN (SELECT CINID FROM					
										(SELECT CINID  FROM	Sandbox.rukank.Morrisons_Medium_SoW_ATV_0_15_03052022
										  UNION
										  SELECT CINID  FROM	Sandbox.rukank.Morrisons_Medium_SoW_ATV_15_35_03052022
										  UNION
										  SELECT CINID  FROM	Sandbox.rukank.Morrisons_Medium_SoW_ATV_35_03052022
										  ) A
						)
GROUP BY F.CINID


----- NURSERY OFFER ---
--IF OBJECT_ID('tempdb..#FB3') IS NOT NULL DROP TABLE #FB3
--SELECT	CINID ,FanID
--INTO	#FB3
--FROM	Relational.Customer C
--JOIN	Relational.CINList CL ON CL.CIN = C.SourceUID
--WHERE	C.CurrentlyActive = 1
--AND		SourceUID NOT IN (SELECT SourceUID FROM Staging.Customer_DuplicateSourceUID)
----AND FANID NOT IN (SELECT FANID FROM [InsightArchive].[MorrisonsReward_MatchedCustomers_20190304])		--NOT A MORECARD OWNER--


--IF OBJECT_ID('tempdb..#Responders') IS NOT NULL DROP TABLE #Responders			
--SELECT   F.CINID
--INTO	#Responders
--FROM	#FB3 F
--JOIN	Relational.PartnerTrans PT on Pt.FanID = F.FanID
--WHERE	PT.PartnerID = 4263
--		AND TransactionDate >= '2021-12-30'
--		AND TransactionAmount > 0
--		AND PT.IronOfferID IN (25076)						
--CREATE CLUSTERED INDEX cix_CINID ON #Responders(CINID)


--IF OBJECT_ID('Sandbox.rukank.Morrisons_Nursery_Acquire_03052022') IS NOT NULL DROP TABLE Sandbox.rukank.Morrisons_Nursery_Acquire_03052022		
--SELECT	F.CINID																														
--INTO	Sandbox.rukank.Morrisons_Nursery_Acquire_03052022
--FROM	#Responders F
--WHERE	CINID NOT IN (SELECT CINID FROM Sandbox.rukank.Morrisons_Aldi_Lidl_03052022)															
--		AND CINID NOT IN (SELECT CINID FROM					
--												( SELECT CINID  FROM	Sandbox.rukank.Morrisons_Medium_SoW_ATV_0_15_03052022
--												  UNION
--												  SELECT CINID  FROM	Sandbox.rukank.Morrisons_Medium_SoW_ATV_15_35_03052022
--												  UNION
--												  SELECT CINID  FROM	Sandbox.rukank.Morrisons_Medium_SoW_ATV_35_03052022
--												 ) A
--								)
--GROUP BY F.CINID

					
	IF OBJECT_ID('[Warehouse].[Selections].[MOR158_PreSelection]') IS NOT NULL DROP TABLE [Warehouse].[Selections].[MOR158_PreSelection]
	Select FanID
	Into [Warehouse].[Selections].[MOR158_PreSelection]
	FROM [Segmentation].[Roc_Shopper_Segment_Members] sg
	WHERE PartnerID = 4263
	AND EndDate IS NULL
	AND ShopperSegmentTypeID IN (7, 8)
	AND EXISTS (    SELECT 1
					FROM #FB1 fb
					INNER JOIN Sandbox.RukanK.Morrisons_TOP25pct_Spenders_06052022_CH sb
						ON fb.CINID = sb.CINID
					WHERE sg.FanID = fb.FanID)

	INSERT Into [Warehouse].[Selections].[MOR158_PreSelection]
	Select FanID
	FROM [Segmentation].[Roc_Shopper_Segment_Members] sg
	WHERE PartnerID = 4263
	AND EndDate IS NULL
	AND ShopperSegmentTypeID IN (9)
	AND EXISTS (    SELECT 1
					FROM #FB2 fb
					INNER JOIN Sandbox.rukank.Morrisons_Aldi_Lidl_03052022 sb
						ON fb.CINID = sb.CINID
					WHERE sg.FanID = fb.FanID)

	--INSERT Into [Warehouse].[Selections].[MOR158_PreSelection]
	--Select FanID
	--FROM [Segmentation].[Roc_Shopper_Segment_Members] sg
	--WHERE PartnerID = 4263
	--AND EndDate IS NULL
	--AND ShopperSegmentTypeID IN (9)
	--AND EXISTS (    SELECT 1
	--				FROM #FB3 fb
	--				INNER JOIN Sandbox.rukank.Morrisons_Nursery_Acquire_03052022 sb
	--					ON fb.CINID = sb.CINID)




END