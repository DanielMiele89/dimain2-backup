
CREATE PROCEDURE [Selections].[MOR157_PreSelection_sProc]
AS
BEGIN

---------- RBS - ACQUIRE AND LAPSED ----------
IF OBJECT_ID('tempdb..#FB1') IS NOT NULL DROP TABLE #FB1
SELECT	CINID,fanid
INTO	#FB1
FROM	Relational.Customer C
JOIN	Relational.CINList CL ON CL.CIN = C.SourceUID
WHERE	C.CurrentlyActive = 1
AND		C.SourceUID NOT IN (SELECT SourceUID FROM Staging.Customer_DuplicateSourceUID)
GROUP BY CL.CINID,FanID
CREATE CLUSTERED INDEX ix_FanID on #FB1(CINID)

IF OBJECT_ID('Sandbox.RukanK.Morrisons_BAU_AL_EXCL_06052022_CH') IS NOT NULL DROP TABLE Sandbox.RukanK.Morrisons_BAU_AL_EXCL_06052022_CH		
SELECT	CINID
INTO	Sandbox.RukanK.Morrisons_BAU_AL_EXCL_06052022_CH
FROM	#FB1
WHERE	CINID NOT IN (SELECT CINID FROM Sandbox.RukanK.Morrisons_TOP25pct_Spenders_06052022_CH)
GROUP BY CINID

---------- RBS - LOW SOW Shopper----------
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
WHERE	CC.BrandID IN  (292,21,379,425,2541,5,254,485)		-- Morrisons 292, Asda 21, Sainsburys 379, Tesco 425, Amazon Fresh 2541, Aldi 5, Lidl 254, Waitrose 485
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


-- shoppers - SOW - < 30%
IF OBJECT_ID('Sandbox.rukank.Morrisons_LoW_SoW_03052022') IS NOT NULL DROP TABLE Sandbox.rukank.Morrisons_LoW_SoW_03052022		-- 449,729 (03.05.2022 run), 412,308 (05.04.2022 run), 460,109 (01.03.2022 run)
SELECT	F.CINID
INTO	Sandbox.rukank.Morrisons_LoW_SoW_03052022
FROM	#shoppper_sow F
WHERE	BrandShopper = 1
		AND SoW < 0.30
		AND Transactions >= 15
		AND CINID NOT IN (SELECT CINID FROM 
											(SELECT CINID  FROM	Sandbox.rukank.Morrisons_Aldi_Lidl_03052022
											UNION
											SELECT CINID  FROM	Sandbox.rukank.Morrisons_Nursery_Acquire_03052022
											) A
						)
GROUP BY F.CINID

If Object_ID('Warehouse.Selections.MOR157_PreSelection') Is Not Null Drop Table Warehouse.Selections.MOR157_PreSelection
Select FanID
Into Warehouse.Selections.MOR157_PreSelection
FROM [Segmentation].[Roc_Shopper_Segment_Members] sg
WHERE PartnerID = 4263
AND EndDate IS NULL
AND ShopperSegmentTypeID IN (7, 8)
AND EXISTS (    SELECT 1
                FROM #FB1 fb
                INNER JOIN Sandbox.RukanK.Morrisons_BAU_AL_EXCL_06052022_CH sb
                    ON fb.CINID = sb.CINID
				WHERE sg.FanID = fb.FanID)


INSERT Into Warehouse.Selections.MOR157_PreSelection
Select FanID
FROM [Segmentation].[Roc_Shopper_Segment_Members] sg
WHERE PartnerID = 4263
AND EndDate IS NULL
AND ShopperSegmentTypeID IN (9)
AND EXISTS (    SELECT 1
                FROM #FB fb
                INNER JOIN Sandbox.rukank.Morrisons_LoW_SoW_03052022 sb
                    ON fb.CINID = sb.CINID
				WHERE sg.FanID = fb.FanID)



END
