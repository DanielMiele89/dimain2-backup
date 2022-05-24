-- =============================================-- Author:  <Rory Francis>-- Create date: <2021-05-30>-- Description: < sProc to run preselection code per camapign >-- =============================================CREATE PROCEDURE [Selections].[UE003_PreSelection_sProc]ASBEGIN

IF OBJECT_ID('tempdb..#FB') IS NOT NULL DROP TABLE #FB
SELECT	CINID
		,FanID
INTO #FB
FROM	Relational.Customer C
JOIN	Relational.CINList CL ON CL.CIN = C.SourceUID
WHERE	C.CurrentlyActive = 1
AND		SourceUID NOT IN (SELECT SourceUID FROM Staging.Customer_DuplicateSourceUID) 


IF OBJECT_ID('tempdb..#Trans') IS NOT NULL DROP TABLE #Trans
SELECT	F.CINID as CINID, f.FanID, Classification, Engagement_Score, Engagement_Rank
		,CASE WHEN Classification = 'Gold' THEN 1
			  WHEN Classification = 'Silver' THEN 2
			  WHEN Classification = 'Bronze' THEN 3
			  WHEN Classification = 'Blue' THEN 4
			 ELSE 5
		END AS Classification_Score
INTO #Trans
FROM	#FB F
LEFT JOIN InsightArchive.EngagementScore E ON E.FanID = F.FanID
GROUP BY F.CINID, f.FanID, Classification, Engagement_Score, Engagement_Rank
		,CASE WHEN Classification = 'Gold' THEN 1
			  WHEN Classification = 'Silver' THEN 2
			  WHEN Classification = 'Bronze' THEN 3
			  WHEN Classification = 'Blue' THEN 4
			 ELSE 5
		END


IF OBJECT_ID('tempdb..#NtileEngaged') IS NOT NULL DROP TABLE #NtileEngaged		-- to get 30% of the most engaged customers = 10 tiles, pick 3 of them
SELECT	  CINID, FanID
		, NTILE(10) OVER (ORDER BY Classification_Score ASC, Engagement_Score DESC) AS NTILE_10
INTO	#NtileEngaged
FROM	#Trans


IF OBJECT_ID('Sandbox.RukanK.UberEatsEngagementBOTTOM70pct') IS NOT NULL DROP TABLE Sandbox.RukanK.UberEatsEngagementBOTTOM70pct
SELECT	F.FanID
INTO Sandbox.RukanK.UberEatsEngagementBOTTOM70pct
FROM	#FB F
JOIN	#Trans T 	ON F.CINID = T.CINID
WHERE	F.CINID IN (SELECT CINID FROM #NtileEngaged WHERE NTILE_10 IN (4,5,6,7,8,9,10))
GROUP BY F.FanID


IF OBJECT_ID('Warehouse.Selections.UE003_PreSelection') IS NOT NULL DROP TABLE Warehouse.Selections.UE003_PreSelection
SELECT	FanID
INTO Warehouse.Selections.UE003_PreSelection
FROM	Sandbox.RukanK.UberEatsEngagementBOTTOM70pct
END

