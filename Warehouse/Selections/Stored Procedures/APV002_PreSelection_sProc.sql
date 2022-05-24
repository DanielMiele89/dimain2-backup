-- =============================================-- Author:  <Rory Francis>-- Create date: <2021-06-25>-- Description: < sProc to run preselection code per camapign >-- =============================================CREATE PROCEDURE [Selections].[APV002_PreSelection_sProc]ASBEGIN
IF OBJECT_ID('tempdb..#FB') IS NOT NULL DROP TABLE #FB
SELECT	CINID
		,FanID
INTO #FB
FROM	Relational.Customer C
JOIN	Relational.CINList CL ON CL.CIN = C.SourceUID
WHERE	C.CurrentlyActive = 1
AND		SourceUID NOT IN (SELECT SourceUID FROM Staging.Customer_DuplicateSourceUID)

CREATE CLUSTERED INDEX CIX_CINID ON #FB (CINID)
CREATE NONCLUSTERED INDEX IX_FanID ON #FB (FanID)


IF OBJECT_ID('tempdb..#CCIDs') IS NOT NULL DROP TABLE #CCIDs
SELECT	ConsumerCombinationID
INTO #CCIDs
FROM Relational.ConsumerCombination cc WITH (NOLOCK)
JOIN Relational.Brand B ON B.BrandID = CC.BrandID
JOIN Relational.BrandSector S ON S.SectorID = B.SectorID
WHERE S.SectorGroupID <> 1

CREATE CLUSTERED INDEX CIX_ConsumerCombinationID ON #CCIDs (ConsumerCombinationID)




IF OBJECT_ID('tempdb..#FB1') IS NOT NULL DROP TABLE #FB1
SELECT	F.CINID as CINID, Classification, Engagement_Score
		,CASE WHEN Classification = 'Gold' THEN 1
			  WHEN Classification = 'Silver' THEN 2
			  WHEN Classification = 'Bronze' THEN 3
			  WHEN Classification = 'Blue' THEN 4
			 ELSE 5
		END AS Classification_Score
INTO #FB1
FROM #FB F
LEFT JOIN InsightArchive.EngagementScore E ON E.FanID = F.FanID
GROUP BY F.CINID, Classification, Engagement_Score
		,CASE WHEN Classification = 'Gold' THEN 1
			  WHEN Classification = 'Silver' THEN 2
			  WHEN Classification = 'Bronze' THEN 3
			  WHEN Classification = 'Blue' THEN 4
			 ELSE 5
		END
CREATE CLUSTERED INDEX ix_CINID on #FB1(CINID)


DECLARE @SixMonthsAgo DATE = DATEADD(MONTH,-6,GETDATE()) 

IF OBJECT_ID('tempdb..#Txn') IS NOT NULL DROP TABLE #Txn
SELECT  F.CINID as CINID, Classification, Classification_Score, Engagement_Score
		,COUNT(1) AS Txn
		,SUM(Amount) as Spend
INTO	#Txn
FROM	#FB1 F
LEFT JOIN	Relational.ConsumerTransaction_MyRewards CT	ON CT.CINID = F.CINID
JOIN #CCIDs CC ON CC.ConsumerCombinationID = CT.ConsumerCombinationID
WHERE	TranDate >= @SixMonthsAgo
GROUP BY F.CINID, Classification, Classification_Score, Engagement_Score
CREATE CLUSTERED INDEX ix_CINID on #Txn(CINID)


IF OBJECT_ID('tempdb..#Txn2') IS NOT NULL DROP TABLE #Txn2
SELECT  CINID, Classification, Engagement_Score, Txn, Spend
		,CASE WHEN Txn <= 5 THEN 5
			Else Classification_Score
		END Classification_Score
INTO	#Txn2
FROM	#Txn
CREATE CLUSTERED INDEX ix_CINID on #Txn2(CINID)



IF OBJECT_ID('tempdb..#CCIDs_Prime') IS NOT NULL DROP TABLE #CCIDs_Prime
SELECT	ConsumerCombinationID
INTO #CCIDs_Prime
FROM Relational.ConsumerCombination cc WITH (NOLOCK)
WHERE BrandID IN (2606, 2704)

CREATE CLUSTERED INDEX CIX_CCID_CCID ON #CCIDs_Prime (ConsumerCombinationID)

DECLARE @SixMonthsAgo2 DATE = DATEADD(MONTH,-6,GETDATE()) 

IF OBJECT_ID('tempdb..#CT_Prime') IS NOT NULL DROP TABLE #CT_Prime
SELECT	CINID
INTO #CT_Prime
FROM Relational.ConsumerTransaction_MyRewards CT
WHERE EXISTS (	SELECT 1
				FROM #CCIDs_Prime cc
				WHERE CC.ConsumerCombinationID = CT.ConsumerCombinationID)
AND TranDate >= @SixMonthsAgo2

CREATE CLUSTERED INDEX CIX_CINID ON #CT_Prime (CINID)


IF OBJECT_ID('tempdb..#NtileEngaged') IS NOT NULL DROP TABLE #NtileEngaged		
SELECT	  CINID, Classification, Classification_Score, Engagement_Score, Txn, Spend
		, NTILE(5) OVER (ORDER BY Classification_Score ASC, Engagement_Score DESC, Txn DESC) AS NTILE_5
INTO	#NtileEngaged
FROM	#Txn2 T
WHERE NOT EXISTS (	SELECT 1
					FROM #CT_Prime ct
					WHERE t.CINID = ct.CINID)


IF OBJECT_ID('Sandbox.RukanK.AmazonPrimeTOP20pct') IS NOT NULL DROP TABLE Sandbox.RukanK.AmazonPrimeTOP20pct
SELECT	CINID
INTO	Sandbox.RukanK.AmazonPrimeTOP20pct
FROM	#NtileEngaged
WHERE	NTILE_5 IN (1)
GROUP BY CINIDIf Object_ID('Warehouse.Selections.APV002_PreSelection') Is Not Null Drop Table Warehouse.Selections.APV002_PreSelectionSelect FanIDInto Warehouse.Selections.APV002_PreSelectionFROM #FB fbWHERE EXISTS (	SELECT 1				FROM Sandbox.RukanK.AmazonPrimeTOP20pct r				WHERE fb.CINID = r.CINID)END