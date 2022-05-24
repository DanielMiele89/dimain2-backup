-- =============================================-- Author:  <Rory Francis>-- Create date: <2021-08-05>-- Description: < sProc to run preselection code per camapign >-- =============================================CREATE PROCEDURE Selections.SWB010_PreSelection_sProcASBEGIN


--------------------------------------------------- VIRGIN MONEY SELECTION CODE ---------------------------------------------------


IF OBJECT_ID('tempdb..#FB') IS NOT NULL DROP TABLE #FB
SELECT	CINID
		,FanID
INTO #FB
FROM	WH_Virgin.Derived.Customer C
JOIN	WH_Virgin.Derived.CINList CL ON CL.CIN = C.SourceUID
WHERE	C.CurrentlyActive = 1
and AccountType IS NOT NULL


IF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC
SELECT ConsumerCombinationID
INTO #CC
FROM	WH_Virgin.trans.ConsumerCombination CC
WHERE	BrandID IN (2434,2592,2777,3165,574,568)			


IF OBJECT_ID('tempdb..#Trans') IS NOT NULL DROP TABLE #Trans
SELECT	 F.CINID, Classification, Engagement_Score
		, CASE	WHEN Classification = 'Gold' THEN 1
				WHEN Classification = 'Silver' THEN 2
				WHEN Classification = 'Bronze' THEN 3
				WHEN Classification = 'Blue' THEN 4
				ELSE 5
			END AS Classification_Score
INTO #Trans
FROM	WH_Virgin.trans.consumertransaction CT
JOIN	#FB F ON F.CINID = CT.CINID
JOIN	#CC C 	ON C.ConsumerCombinationID = CT.ConsumerCombinationID
LEFT JOIN	Derived.Customer_EngagementScore E ON E.FanID = F.FanID
WHERE	TranDate > DATEADD(MONTH, -24, GETDATE())
		AND Amount > 0
GROUP BY F.CINID, Classification, Engagement_Score
		, CASE	WHEN Classification = 'Gold' THEN 1
				WHEN Classification = 'Silver' THEN 2
				WHEN Classification = 'Bronze' THEN 3
				WHEN Classification = 'Blue' THEN 4
				ELSE 5
			END


IF OBJECT_ID('tempdb..#NtileEngaged') IS NOT NULL DROP TABLE #NtileEngaged	
SELECT	 CINID
		, NTILE(2) OVER (ORDER BY Classification_Score ASC, Engagement_Score DESC) AS NTILE_2
INTO	#NtileEngaged
FROM	#Trans


IF OBJECT_ID('Sandbox.RukanK.VM_SweatyBetty_CompSteal_15pct_20072021') IS NOT NULL DROP TABLE Sandbox.RukanK.VM_SweatyBetty_CompSteal_15pct_20072021
SELECT	CINID
INTO Sandbox.RukanK.VM_SweatyBetty_CompSteal_15pct_20072021
FROM #Trans
WHERE	CINID IN (SELECT CINID FROM #NtileEngaged WHERE NTILE_2 IN (2))If Object_ID('WH_Virgin.Selections.SWB010_PreSelection') Is Not Null Drop Table WH_Virgin.Selections.SWB010_PreSelectionSelect FanIDInto WH_Virgin.Selections.SWB010_PreSelectionFROM WH_Virgin.derived.Customer cuWHERE EXISTS (	SELECT 1				FROM WH_Virgin.derived.[CINList] cl				INNER JOIN Sandbox.RukanK.VM_SweatyBetty_CompSteal_15pct_20072021 fo					ON cl.CINID = fo.CINID				WHERE cu.SourceUID = cl.CIN)END