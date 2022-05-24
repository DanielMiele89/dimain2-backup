-- =============================================-- Author:  <Rory Francis>-- Create date: <2021-08-05>-- Description: < sProc to run preselection code per camapign >-- =============================================CREATE PROCEDURE [Selections].[SWB010_PreSelection_sProc]ASBEGINIF OBJECT_ID('tempdb..#FB') IS NOT NULL DROP TABLE #FB
SELECT	CINID, FanID
INTO	#FB
FROM	Relational.Customer C
JOIN	Relational.CINList CL ON CL.CIN = C.SourceUID
WHERE	C.CurrentlyActive = 1
AND		SourceUID NOT IN (SELECT SourceUID FROM Staging.Customer_DuplicateSourceUID) 

CREATE CLUSTERED INDEX CIX_CINID ON #FB (CINID)
CREATE NONCLUSTERED INDEX IX_FanID ON #FB (FanID)

IF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC
SELECT	 CC.ConsumerCombinationID AS ConsumerCombinationID
INTO	#CC 
FROM	Relational.ConsumerCombination CC
WHERE	BrandID IN (2434,2592,2777,3165,574,568)						-- Competitors: Lu Lu Lemon, Gym shark and Fabletics	--- The Sports Edit, Under Armour and Nike

CREATE CLUSTERED INDEX CIX_ConsumerCombinationID ON #CC (ConsumerCombinationID)

DECLARE @DATE_24 DATE = DATEADD(MONTH, -24, GETDATE())

IF OBJECT_ID('tempdb..#Trans') IS NOT NULL DROP TABLE #Trans
SELECT		 CT.CINID as CINID
			, Classification
			, Engagement_Score
			, CASE	WHEN Classification = 'Gold' THEN 1
					WHEN Classification = 'Silver' THEN 2
					WHEN Classification = 'Bronze' THEN 3
					WHEN Classification = 'Blue' THEN 4
					ELSE 5
			 END AS Classification_Score
INTO		#Trans
FROM		Relational.ConsumerTransaction_MyRewards CT
JOIN		#CC CC	ON CT.ConsumerCombinationID = CC.ConsumerCombinationID
JOIN		#FB F	ON F.CINID = CT.CINID
LEFT JOIN	InsightArchive.EngagementScore E ON E.FanID = F.FanID
WHERE		TranDate > @DATE_24
			AND Amount > 0
GROUP BY	 CT.CINID
			, Classification
			, Engagement_Score
			, CASE	WHEN Classification = 'Gold' THEN 1
					WHEN Classification = 'Silver' THEN 2
					WHEN Classification = 'Bronze' THEN 3
					WHEN Classification = 'Blue' THEN 4
					ELSE 5
			 END;


IF OBJECT_ID('tempdb..#NtileEngaged') IS NOT NULL DROP TABLE #NtileEngaged	
SELECT	 CINID
		, NTILE(2) OVER (ORDER BY Classification_Score ASC, Engagement_Score DESC) AS NTILE_2
INTO	#NtileEngaged
FROM	#Trans


IF OBJECT_ID('Sandbox.RukanK.SweatyBetty_CompSteal_15pct_20072021') IS NOT NULL DROP TABLE Sandbox.RukanK.SweatyBetty_CompSteal_15pct_20072021
SELECT	CINID
INTO	Sandbox.RukanK.SweatyBetty_CompSteal_15pct_20072021
FROM	#Trans
WHERE	CINID IN (SELECT CINID FROM #NtileEngaged WHERE NTILE_2 IN (2))If Object_ID('Warehouse.Selections.SWB010_PreSelection') Is Not Null Drop Table Warehouse.Selections.SWB010_PreSelectionSelect FanIDInto Warehouse.Selections.SWB010_PreSelectionFROM Relational.Customer cuWHERE EXISTS (	SELECT 1				FROM [Relational].[CINList] cl				INNER JOIN Sandbox.RukanK.SweatyBetty_CompSteal_15pct_20072021 fo					ON cl.CINID = fo.CINID				WHERE cu.SourceUID = cl.CIN)END