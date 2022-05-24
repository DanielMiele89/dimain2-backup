
CREATE PROCEDURE [Selections].[MV015_PreSelection_sProc]
AS
BEGIN

IF OBJECT_ID('tempdb..#FB') IS NOT NULL DROP TABLE #FB
SELECT	CL.CINID as CINID, C.FanID, Classification, Engagement_Score
		,CASE WHEN Classification = 'Gold' THEN 1
			  WHEN Classification = 'Silver' THEN 2
			  WHEN Classification = 'Bronze' THEN 3
			  WHEN Classification = 'Blue' THEN 4
			 ELSE 5
		END AS Classification_Score
INTO	#FB
FROM	Relational.Customer C
JOIN	Relational.CINList CL ON CL.CIN = C.SourceUID
LEFT JOIN InsightArchive.EngagementScore E ON E.FanID = C.FanID
WHERE	C.CurrentlyActive = 1
AND		C.SourceUID NOT IN (SELECT SourceUID FROM Staging.Customer_DuplicateSourceUID)
GROUP BY CL.CINID, C.FanID, Classification, Engagement_Score
		,CASE WHEN Classification = 'Gold' THEN 1
			  WHEN Classification = 'Silver' THEN 2
			  WHEN Classification = 'Bronze' THEN 3
			  WHEN Classification = 'Blue' THEN 4
			 ELSE 5
		END
CREATE CLUSTERED INDEX ix_FanID on #FB(CINID)


--IF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC
--SELECT  ConsumerCombinationID
--INTO	#CC
--FROM	Relational.ConsumerCombination CC
--WHERE	BrandID IN (292)							-- Morrisons
IF OBJECT_ID('tempdb..#Txn') IS NOT NULL DROP TABLE #Txn
SELECT  F.CINID as CINID, Classification, Classification_Score, Engagement_Score
--		,COUNT(1) AS Txn
--		,SUM(Amount) as Spend
INTO	#Txn
FROM	#FB F
--LEFT JOIN	Relational.ConsumerTransaction_MyRewards CT	ON CT.CINID = F.CINID
--JOIN #CC CC ON CC.ConsumerCombinationID = CT.ConsumerCombinationID
--WHERE	TranDate >= DATEADD(MONTH,-6,GETDATE()) 
GROUP BY F.CINID, Classification, Classification_Score, Engagement_Score
CREATE CLUSTERED INDEX ix_CINID on #Txn(CINID)


--IF OBJECT_ID('tempdb..#Txn2') IS NOT NULL DROP TABLE #Txn2
--SELECT  CINID, Classification, Engagement_Score, Txn, Spend
--		,CASE WHEN Txn <= 2 THEN 5
--			Else Classification_Score
--		END Classification_Score
--INTO	#Txn2
--FROM	#Txn
--CREATE CLUSTERED INDEX ix_CINID on #Txn2(CINID)

IF OBJECT_ID('tempdb..#NtileEngaged') IS NOT NULL DROP TABLE #NtileEngaged		-- to get 75% of the most engaged customers = 4 tiles, pick 1
SELECT	  CINID, Classification, Classification_Score, Engagement_Score
--		, Txn, Spend
		, NTILE(4) OVER (ORDER BY Classification_Score ASC, Engagement_Score DESC) AS NTILE_4
INTO	#NtileEngaged
FROM	#Txn T 


IF OBJECT_ID('Sandbox.GunayS.MVEngagementB25160322') IS NOT NULL DROP TABLE Sandbox.GunayS.MVEngagementB25160322
SELECT	CINID
INTO	Sandbox.GunayS.MVEngagementB25160322
FROM	#NtileEngaged
WHERE	NTILE_4 IN (4)
GROUP BY CINID

	IF OBJECT_ID('[Warehouse].[Selections].[MV015_PreSelection]') IS NOT NULL DROP TABLE [Warehouse].[Selections].[MV015_PreSelection]
	SELECT FanID
	INTO [Warehouse].[Selections].[MV015_PreSelection]
	FROM #FB fb
	WHERE EXISTS (SELECT 1 FROM Sandbox.GunayS.MVEngagementB25160322 s WHERE fb.CINID = s.CINID)

END