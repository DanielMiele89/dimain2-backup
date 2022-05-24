CREATE PROCEDURE [Selections].[LE032_PreSelection_sProc]
AS
BEGIN

------------------------------------------- RBS - SELECTION CODE ------------------------------------------
--IF OBJECT_ID('tempdb..#FB') IS NOT NULL DROP TABLE #FB
--SELECT	c.FanID
--	,	CL.CINID as CINID
--	, Classification, Engagement_Score
--		,CASE WHEN Classification = 'Gold' THEN 1
--			  WHEN Classification = 'Silver' THEN 2
--			  WHEN Classification = 'Bronze' THEN 3
--			  WHEN Classification = 'Blue' THEN 4
--			 ELSE 5
--		END AS Classification_Score
--INTO	#FB
--FROM	Relational.Customer C
--JOIN	Relational.CINList CL ON CL.CIN = C.SourceUID
--LEFT JOIN InsightArchive.EngagementScore E ON E.FanID = C.FanID
--WHERE	C.CurrentlyActive = 1
--AND		C.SourceUID NOT IN (SELECT SourceUID FROM Staging.Customer_DuplicateSourceUID)
--GROUP BY	c.FanID
--	,	CL.CINID
--	, Classification
--	, Engagement_Score
--		,CASE WHEN Classification = 'Gold' THEN 1
--			  WHEN Classification = 'Silver' THEN 2
--			  WHEN Classification = 'Bronze' THEN 3
--			  WHEN Classification = 'Blue' THEN 4
--			 ELSE 5
--		END
--CREATE CLUSTERED INDEX ix_FanID on #FB(CINID)

--IF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC
--SELECT  ConsumerCombinationID, brandname,b.BrandID,s.SectorGroupID
--INTO	#CC
--FROM	Relational.ConsumerCombination CC
--join Relational.Brand B on cc.BrandID = b.brandid
--join relational.BrandSector S on S.sectorid = b.SectorID
--join relational.BrandSectorGroup sg on sg.SectorGroupID = S.SectorGroupID
--WHERE	b.BrandID IN (56,105,1724,274,116)							
--or  s. SectorGroupID= 9

--DECLARE @DATE_6 DATE = DATEADD(MONTH,-6,GETDATE())
--	,	@DATE_24 DATE = DATEADD(MONTH,-24,GETDATE())

--IF OBJECT_ID('tempdb..#ct') IS NOT NULL DROP TABLE #ct
--SELECT  F.CINID as CINID, 
--		max(case when TranDate >= @DATE_6 and  sectorgroupid = 9 then 1 else 0 end) as fashion_shopper,
--		max(case when brandid in (274,116) then 1 else 0 end) as debenhams_mS,
--		max(case when brandid in (56,105,1724) then 1 else 0 end) as comp_shoppers		
--INTO	#ct
--FROM	#FB F
--LEFT JOIN	Relational.ConsumerTransaction_MyRewards CT	ON CT.CINID = F.CINID
--JOIN #CC CC ON CC.ConsumerCombinationID = CT.ConsumerCombinationID
--WHERE	TranDate >= @DATE_24 
--GROUP BY F.CINID, Classification, Classification_Score, Engagement_Score


--IF OBJECT_ID('tempdb..#Txn2') IS NOT NULL DROP TABLE #Txn2
--SELECT  CINID, Classification, Engagement_Score, Classification_Score
--INTO	#Txn2
--FROM	#fb
--where cinid in (select cinid from #ct where comp_shoppers =1 or (debenhams_mS = 1 and fashion_shopper = 1))


--IF OBJECT_ID('tempdb..#NtileEngaged') IS NOT NULL DROP TABLE #NtileEngaged		
--SELECT	  CINID, Classification, Classification_Score, Engagement_Score
--		, NTILE(2) OVER (ORDER BY Classification_Score ASC, Engagement_Score DESC) AS NTILE_5
--INTO	#NtileEngaged
--FROM	#Txn2 T 

---- ACQUIRE 15% OFFER
--IF OBJECT_ID('Sandbox.bastienc.landsend_top50pct') IS NOT NULL DROP TABLE Sandbox.bastienc.landsend_top50pct
--SELECT	CINID
--INTO	Sandbox.bastienc.landsend_top50pct
--FROM	#NtileEngaged
--WHERE	NTILE_5 IN (1)
--GROUP BY CINID

---- ACQUIRE 10% OFFER
--IF OBJECT_ID('Sandbox.bastienc.landsend_bottom50pct') IS NOT NULL DROP TABLE Sandbox.bastienc.landsend_bottom50pct
--SELECT	CINID
--INTO	Sandbox.bastienc.landsend_bottom50pct
--FROM	#NtileEngaged
--WHERE	NTILE_5 IN (2)
--GROUP BY CINID


------------------------------------------- VIRGIN MONEY - SELECTION CODE ------------------------------------------
IF OBJECT_ID('tempdb..#FB') IS NOT NULL DROP TABLE #FB
SELECT	c.FanID
	,	CL.CINID as CINID, Classification, Engagement_Score
		,CASE WHEN Classification = 'Gold' THEN 1
			  WHEN Classification = 'Silver' THEN 2
			  WHEN Classification = 'Bronze' THEN 3
			  WHEN Classification = 'Blue' THEN 4
			 ELSE 5
		END AS Classification_Score
INTO	#FB
FROM	WH_Virgin.Derived.Customer C
JOIN	WH_Virgin.Derived.CINList CL ON CL.CIN = C.SourceUID
LEFT JOIN Warehouse.InsightArchive.EngagementScore E ON E.FanID = C.FanID
WHERE	C.CurrentlyActive = 1
AND		C.SourceUID NOT IN (SELECT [Derived].[Customer_DuplicateSourceUID].[SourceUID] FROM Derived.Customer_DuplicateSourceUID)
GROUP BY c.FanID
	,	CL.CINID, Classification, Engagement_Score
		,CASE WHEN Classification = 'Gold' THEN 1
			  WHEN Classification = 'Silver' THEN 2
			  WHEN Classification = 'Bronze' THEN 3
			  WHEN Classification = 'Blue' THEN 4
			 ELSE 5
		END
CREATE CLUSTERED INDEX ix_FanID on #FB(CINID)


IF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC
SELECT  ConsumerCombinationID, brandname,b.BrandID,s.SectorGroupID
INTO	#CC
FROM	WH_Virgin.trans.ConsumerCombination CC
join Warehouse.Relational.Brand B on cc.BrandID = b.brandid
join Warehouse.relational.BrandSector S on S.sectorid = b.SectorID
join Warehouse.relational.BrandSectorGroup sg on sg.SectorGroupID = S.SectorGroupID
WHERE	b.BrandID IN (56,105,1724,274,116)							
or  s. SectorGroupID= 9


DECLARE @DATE_6 DATE = DATEADD(MONTH,-6,GETDATE())
	,	@DATE_24 DATE = DATEADD(MONTH,-24,GETDATE())

IF OBJECT_ID('tempdb..#ct') IS NOT NULL DROP TABLE #ct
SELECT  F.CINID as CINID, 
		max(case when TranDate >= @DATE_6 and  sectorgroupid = 9 then 1 else 0 end) as fashion_shopper,
		max(case when brandid in (274,116) then 1 else 0 end) as debenhams_mS,
		max(case when brandid in (56,105,1724) then 1 else 0 end) as comp_shoppers		
INTO	#ct
FROM	#FB F
LEFT JOIN	WH_Virgin.trans.consumertransaction CT	ON #FB.[CT].CINID = F.CINID
JOIN #CC CC ON CC.ConsumerCombinationID = CT.ConsumerCombinationID
WHERE	TranDate >= @DATE_24
GROUP BY F.CINID, Classification, Classification_Score, Engagement_Score


IF OBJECT_ID('tempdb..#Txn2') IS NOT NULL DROP TABLE #Txn2
SELECT  #fb.[CINID], #fb.[Classification], #fb.[Engagement_Score], #fb.[Classification_Score]
INTO	#Txn2
FROM	#fb
where #fb.[CINID] in (select #ct.[CINID] from #ct where #ct.[comp_shoppers] =1 or (#ct.[debenhams_mS] = 1 and #ct.[fashion_shopper] = 1))



IF OBJECT_ID('tempdb..#NtileEngaged') IS NOT NULL DROP TABLE #NtileEngaged		-- to get 20% of the most engaged customers = 5 tiles, pick 1
SELECT	  [T].[CINID], [T].[Classification], [T].[Classification_Score], [T].[Engagement_Score]
		, NTILE(2) OVER (ORDER BY [T].[Classification_Score] ASC, [T].[Engagement_Score] DESC) AS NTILE_5
INTO	#NtileEngaged
FROM	#Txn2 T 

-- ACQUIRE 15% OFFER
IF OBJECT_ID('Sandbox.bastienc.VM_landsend_top50pct') IS NOT NULL DROP TABLE Sandbox.bastienc.VM_landsend_top50pct
SELECT	#NtileEngaged.[CINID]
INTO	Sandbox.bastienc.VM_landsend_top50pct
FROM	#NtileEngaged
WHERE	#NtileEngaged.[NTILE_5] IN (1)
GROUP BY #NtileEngaged.[CINID]

-- ACQUIRE 10% OFFER
IF OBJECT_ID('Sandbox.bastienc.VM_landsend_bottom50pct') IS NOT NULL DROP TABLE Sandbox.bastienc.VM_landsend_bottom50pct
SELECT	#NtileEngaged.[CINID]
INTO	Sandbox.bastienc.VM_landsend_bottom50pct
FROM	#NtileEngaged
WHERE	#NtileEngaged.[NTILE_5] IN (2)
GROUP BY #NtileEngaged.[CINID]


IF OBJECT_ID('[WH_Virgin].[Selections].[LE032_PreSelection]') IS NOT NULL DROP TABLE [WH_Virgin].[Selections].[LE032_PreSelection]
SELECT	fb.FanID
INTO [WH_Virgin].[Selections].[LE032_PreSelection]
FROM #FB fb
WHERE EXISTS (	SELECT 1
				FROM Sandbox.bastienc.VM_landsend_top50pct sb
				WHERE fb.CINID = #FB.[sb].CINID)


END;
