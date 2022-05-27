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
										WHERE FromSector = 'SR7 9'
										AND DriveTimeMins <= 15)
CREATE CLUSTERED INDEX IX_CINID ON #FB(CINID)



IF OBJECT_ID('Sandbox.SamW.MorrisonsDaltonPark151220') IS NOT NULL DROP TABLE Sandbox.SamW.MorrisonsDaltonPark151220
SELECT	DISTINCT F.CINID
INTO Sandbox.SamW.MorrisonsDaltonPark151220
FROM	#FB F
