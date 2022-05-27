-- =============================================-- Author:  <Rory Francis>-- Create date: <2020-10-19>-- Description: < sProc to run preselection code per camapign >-- =============================================CREATE PROCEDURE Selections.MOR070_PreSelection_sProcASBEGIN
DECLARE @TimeStart DATETIME = GETDATE(), @time DATETIME, @RowsAffected INT
EXEC Prototype.oo_TimerMessage_V2 'STARTED', @RowsAffected, @time OUTPUT

-- Capture Customer Actions Table, with Newsletter Engagement
IF OBJECT_ID('tempdb..#CombinedLogIns') IS NOT NULL DROP TABLE #CombinedLogIns
SELECT	 ee.FanID
	,	EventDate = MAX(ee.EventDate)
INTO	#CombinedLogIns
FROM	Relational.EmailEvent ee 
INNER JOIN Relational.EmailCampaign ec 
	ON ec.CampaignKey = ee.CampaignKey
WHERE	ee.EventDate >= DATEADD(DAY, (4 - DATEPART(WEEKDAY, DATEADD(YEAR, -2, GETDATE()))), DATEADD(YEAR, -2, GETDATE()))
	AND ee.EventDate <= GETDATE()
	AND ee.EmailEventCodeID IN (1301, 605)
	AND ec.CampaignName LIKE '%Newsletter%'
GROUP BY ee.FanID
SET @RowsAffected = @@ROWCOUNT -- (2611467 rows affected) / 00:00:15
EXEC Prototype.oo_TimerMessage_V2 '#CombinedLogIns - 1', @RowsAffected, @time OUTPUT


-- Capture Customer Web Actions Table, with Login Engagement
INSERT INTO #CombinedLogIns (FanID, EventDate)
SELECT	FanID
	,	MAX(CAST(TrackDate AS DATE)) AS EventDate
FROM	Relational.WebLogins 
WHERE	TrackDate >= DATEADD(DAY, (4 - DATEPART(WEEKDAY, DATEADD(YEAR, -2, GETDATE()))), DATEADD(YEAR, -2, GETDATE()))
	AND TrackDate <= GETDATE()
GROUP BY FanID
SET @RowsAffected = @@ROWCOUNT -- (1764914 rows affected) / 00:00:20
CREATE CLUSTERED INDEX ix_FanID_EventDate_1 ON #CombinedLogIns (FanID, EventDate)
EXEC Prototype.oo_TimerMessage_V2 '#CombinedLogIns - 2', @RowsAffected, @time OUTPUT


-- Compiliting Customer Awareness Table
IF OBJECT_ID('tempdb..#CustomerAwareness') IS NOT NULL DROP TABLE #CustomerAwareness
SELECT	*
	,	CASE	WHEN DateDiff(Day,MaxEventDate,GETDATE()) <= 28 THEN '1 - Gold'
				WHEN DateDiff(Day,MaxEventDate,GETDATE()) > 28	AND DateDiff(Day,MaxEventDate,GETDATE()) <= 84	THEN '2 - Silver'
				WHEN DateDiff(Day,MaxEventDate,GETDATE()) > 84	AND DateDiff(Day,MaxEventDate,GETDATE()) <= 364	THEN '3 - Bronze'
				ELSE '4 - Blue' END
		AS AwarenessLevel
INTO #CustomerAwareness
FROM (
	SELECT FanID, MAX(EventDate) MaxEventDate
	FROM #CombinedLogIns 
	GROUP BY fanid
) m 
SET @RowsAffected = @@ROWCOUNT -- (2,959,727 rows affected) / 00:00:07
CREATE CLUSTERED INDEX ix_FanID ON #CustomerAwareness(FanID)
EXEC Prototype.oo_TimerMessage_V2 '#CustomerAwareness', @RowsAffected, @time OUTPUT


IF OBJECT_ID('tempdb..#FullBase') IS NOT NULL DROP TABLE #FullBase
SELECT	C.FanID
		,CINID
		,AwarenessLevel
INTO #FullBase
FROM	Relational.Customer C
JOIN	Relational.CINList CL ON CL.CIN = C.SourceUID
LEFT JOIN	#CustomerAwareness CA ON C.FanID = CA.FanID
WHERE C.CurrentlyActive = 1
	AND SourceUID NOT IN (SELECT SourceUID FROM Staging.Customer_DuplicateSourceUID)
SET @RowsAffected = @@ROWCOUNT -- (2775046 rows affected) / 00:00:06
CREATE CLUSTERED INDEX ix_FanID on #FullBase(FANID)
EXEC Prototype.oo_TimerMessage_V2 '#FB', @RowsAffected, @time OUTPUT




IF OBJECT_ID('tempdb..#FB') IS NOT NULL DROP TABLE #FB
SELECT CINID
		,FANID
INTO #FB
FROM	Relational.Customer C
JOIN	Relational.CINList CL ON CL.CIN = C.SourceUID
where	C.CurrentlyActive = 1
					and fanid not in (select fanid from [InsightArchive].[MorrisonsReward_MatchedCustomers_20190304]) --NOT A MORE CARDHOLDER--
					and c.SourceUID 
						NOT IN (select distinct sourceuid from warehouse.Staging.Customer_DuplicateSourceUID )
					and c.PostalSector in (	SELECT ToSector
										FROM Relational.DriveTimeMatrix DTM
										WHERE FromSector = 'NG2 6'
										AND DriveTimeMins <= 20)
CREATE CLUSTERED INDEX IX_CINID ON #FB(CINID)


IF OBJECT_ID('Sandbox.SamW.MorrisonsGamston011020') IS NOT NULL DROP TABLE Sandbox.SamW.MorrisonsGamston011020
SELECT	F.CINID
INTO Sandbox.SamW.MorrisonsGamston011020
FROM	#FB F
JOIN	#FullBase FB ON F.CINID = FB.CINID
WHERE	F.CINID NOT IN (SELECT CINID FROM Sandbox.SamW.Morrisons_HighSoW)
AND		AwarenessLevel = '1 - Gold'
OR		AwarenessLevel = '2 - Silver'
OR		AwarenessLevel = '3 - Bronze'
If Object_ID('Warehouse.Selections.MOR070_PreSelection') Is Not Null Drop Table Warehouse.Selections.MOR070_PreSelectionSelect FanIDInto Warehouse.Selections.MOR070_PreSelectionFROM  SANDBOX.SAMW.MorrisonsGamston011020 f
JOIN	#FullBase FB ON F.CINID = FB.CINIDEND