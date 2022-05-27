﻿-- =============================================
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
										WHERE FromSector = 'TR18 3'
										AND DriveTimeMins <= 30)
CREATE CLUSTERED INDEX IX_CINID ON #FB(CINID)


IF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC
SELECT	CC.ConsumerCombinationID
		,BrandID
INTO	#CC
FROM	Relational.ConsumerCombination CC
WHERE	BrandID = 5


IF OBJECT_ID('Sandbox.SamW.MorrisonsStIves011020') IS NOT NULL DROP TABLE Sandbox.SamW.MorrisonsStIves011020
SELECT	DISTINCT F.CINID
INTO Sandbox.SamW.MorrisonsStIves011020
FROM	#FB F
JOIN	Relational.ConsumerTransaction_MyRewards CT ON F.CINID = CT.CINID
JOIN	#CC C ON C.ConsumerCombinationID = CT.ConsumerCombinationID 
WHERE	TranDate >= DATEADD(MONTH,-12,GETDATE())
--AND		F.CINID NOT IN (SELECT F.CINID FROM Sandbox.SamW.Morrisons_HighSoW)

JOIN	#FB F ON S.CINID = F.CINID