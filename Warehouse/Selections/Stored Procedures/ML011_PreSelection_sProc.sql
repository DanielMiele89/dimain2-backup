-- =============================================-- Author:  <Rory Francis>-- Create date: <2020-07-10>-- Description: < sProc to run preselection code per camapign >-- =============================================CREATE PROCEDURE [Selections].[ML011_PreSelection_sProc]ASBEGIN
IF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC
SELECT br.BrandID,
		br.BrandName,
		cc.ConsumerCombinationID
INTO	#CC
FROM	Warehouse.Relational.Brand br
JOIN	Warehouse.Relational.ConsumerCombination cc ON br.BrandID = cc.BrandID
WHERE	br.BrandID in (277,
					 303,355,371,1050,513,304,187,256,2019
					 )
ORDER BY br.BrandName
CREATE CLUSTERED INDEX ix_ComboID ON #cc(BrandID,ConsumerCombinationID)


DECLARE @CYCLESTARTDATE DATE = '2020-07-16'
-- Create Customer Actions Table, with Newsletter Engagement
IF OBJECT_ID('tempdb..#CustomerActions') IS NOT NULL DROP TABLE #CustomerActions
SELECT	DISTINCT ee.FanID
	,	ee.EventDate
INTO	#CustomerActions
FROM	Relational.EmailEvent ee with (nolock)
INNER JOIN Relational.EmailCampaign ec with (nolock) ON ec.CampaignKey = ee.CampaignKey
WHERE	ee.EventDate >= DATEADD(YEAR,-2,@CYCLESTARTDATE)
AND		ee.EventDate <= @CYCLESTARTDATE
AND		ee.EmailEventCodeID IN (1301, 605)
AND		ec.CampaignName LIKE '%Newsletter%'
CREATE CLUSTERED INDEX ix_FanID_EventDate_1 ON #CustomerActions(FanID, EventDate)

-- Create Customer Web Actions Table, with Login Engagement
IF OBJECT_ID('tempdb..#CustomerWebActions') IS NOT NULL DROP TABLE #CustomerWebActions
SELECT	DISTINCT FanID
	,	CONVERT(DATE, TrackDate)	AS EventDate
INTO	#CustomerWebActions
FROM	Relational.WebLogins with (nolock)
WHERE	TrackDate >= DATEADD(YEAR,-2,@CYCLESTARTDATE)
AND		TrackDate <= @CYCLESTARTDATE
CREATE CLUSTERED INDEX ix_FanID_EventDate_2 ON #CustomerWebActions(FanID, EventDate)

SELECT COUNT(DISTINCT FANID)
FROM #CustomerActions

SELECT COUNT(DISTINCT FANID)
FROM #CustomerWebActions

-- Merging Customer Web Actions data into Customer Actions Table
IF OBJECT_ID('tempdb..#CombinedLogIns') IS NOT NULL DROP TABLE #CombinedLogIns
SELECT		DISTINCT FanID, EventDate
INTO		#CombinedLogIns
FROM		#CustomerWebActions with (nolock)
UNION		
SELECT		FanID, EventDate
FROM		#CustomerActions
CREATE CLUSTERED INDEX ix_FanID_EventDate_2 ON #CombinedLogIns(FanID, EventDate)

SELECT MIN(EventDate), MAX(EventDate)
FROM #CustomerActions

SELECT COUNT(DISTINCT FANID)
FROM #CustomerWebActions

IF OBJECT_ID('tempdb..#Max') IS NOT NULL DROP TABLE #Max
SELECT FanID, MAX(EventDate) MaxEventDate
INTO #Max
FROM #CombinedLogIns with (nolock)
GROUP BY fanid

-- Compiliting Customer Awareness Table
IF OBJECT_ID('tempdb..#CustomerAwareness') IS NOT NULL DROP TABLE #CustomerAwareness
SELECT	*
	,	CASE	WHEN DateDiff(Day,MaxEventDate,@CYCLESTARTDATE) <= 28 THEN '1 - Gold'
				WHEN DateDiff(Day,MaxEventDate,@CYCLESTARTDATE) > 28	AND DateDiff(Day,MaxEventDate,@CYCLESTARTDATE) <= 84	THEN '2 - Silver'
				WHEN DateDiff(Day,MaxEventDate,@CYCLESTARTDATE) > 84	AND DateDiff(Day,MaxEventDate,@CYCLESTARTDATE) <= 364	THEN '3 - Bronze'
				ELSE '4 - Blue' END
		AS AwarenessLevel
INTO	#CustomerAwareness
FROM	#Max with (nolock)
CREATE CLUSTERED INDEX ix_FanID ON #CustomerAwareness(FanID)


--Selection of Full Base Customers-- 
IF OBJECT_ID('tempdb..#FullBase') IS NOT NULL DROP TABLE #FullBase
SELECT	CL.CINID,
		cu.FanID,
		AwarenessLevel
INTO	#FullBase
FROM	Relational.Customer cu
JOIN	Relational.CINList cl on cu.SourceUID = cl.CIN
JOIN	#CustomerAwareness c on c.fanid = cu.FanID
WHERE	cu.CurrentlyActive = 1 -- for active customers
AND		cu.sourceuid NOT IN (select distinct sourceuid from warehouse.Staging.Customer_DuplicateSourceUID)
AND		AwarenessLevel IN ('1 - Gold')

--Matalan Shoppers--
IF OBJECT_ID('tempdb..#MatalanShoppersPeriod') IS NOT NULL DROP TABLE #MatalanShoppersPeriod
SELECT	fb.CINID,
		TranDate,
		CASE WHEN TranDate < '2020-03-23' THEN 'Pre' ELSE 'Lockdown' END AS LockdownPeriod,
		SUM(Amount) AS TotalSpend
INTO	#MatalanShoppersPeriod
FROM	#FullBase fb
JOIN	Relational.ConsumerTransaction_MyRewards my on my.CINID = fb.CINID
JOIN	#CC cc on cc.ConsumerCombinationID = my.ConsumerCombinationID
WHERE	TranDate >= '2020-01-01'
AND		Amount > 0
AND		BrandID = 277
GROUP BY fb.CINID,
		 TranDate,
		 CASE WHEN TranDate < '2020-03-23' THEN 'Pre' ELSE 'Lockdown' END
ORDER BY 3,4 DESC

IF OBJECT_ID('tempdb..#MatalanHighPre') IS NOT NULL DROP TABLE #MatalanHighPre
SELECT	CINID, TotalSpend
INTO	#MatalanHighPre
FROM	#MatalanShoppersPeriod
WHERE	LockdownPeriod = 'Pre'
AND		TotalSpend >= 50
ORDER BY 2 DESC

IF OBJECT_ID('tempdb..#MatalanHighLockdown') IS NOT NULL DROP TABLE #MatalanHighLockdown
SELECT	CINID, TotalSpend
INTO	#MatalanHighLockdown
FROM	#MatalanShoppersPeriod
WHERE	LockdownPeriod = 'Lockdown'
AND		TotalSpend >= 50
ORDER BY 2 DESC

--286K Matalan shoppers that spend £50 > pre and since Lockdown--
IF OBJECT_ID('tempdb..#MatalanHighSpenders') IS NOT NULL DROP TABLE #MatalanHighSpenders
SELECT	*
INTO	#MatalanHighSpenders
FROM	(SELECT	CINID FROM #MatalanShoppersPeriod
		UNION
		SELECT	CINID FROM #MatalanHighLockdown
		) a


--FORECAST 1--
DECLARE @MainBrand SMALLINT = 277	 -- Main Brand	

If Object_ID('tempdb..#SegmentAssignment1') IS NOT NULL DROP TABLE #SegmentAssignment1
Select cl.CINID,			-- keep CINID and FANID
		cl.fanid,
		CASE WHEN m.CINID IS NOT NULL THEN 1 ELSE 0 END AS HighShopper,
		MainBrandLapsed,
		Acquired
INTO #SegmentAssignment1

FROM (SELECT CINID, FanID
	 FROM #FullBase
	 ) cl

LEFT JOIN (SELECT CINID FROM #MatalanHighSpenders) m on m.CINID = cl.CINID

LEFT JOIN (SELECT ct.CINID,
				 SUM(ct.Amount) as Sales,

				 MAX(CASE WHEN cc.brandid = @MainBrand AND DATEADD(MONTH,-12,GETDATE()) <= TranDate AND TranDate < DATEADD(MONTH,-6,GETDATE())
 						THEN 1 ELSE 0 END) AS MainBrandLapsed,

				 MAX(CASE WHEN cc.BrandID <> @MainBrand AND TranDate <= DATEADD(MONTH,-12,GETDATE())
 						THEN 1 ELSE 0 END) AS Acquired
						 
			FROM Warehouse.Relational.ConsumerTransaction_MyRewards ct with (nolock)
			JOIN #CC cc on cc.ConsumerCombinationID = ct.ConsumerCombinationID
			
			WHERE 0 < ct.Amount
			AND TranDate >= DATEADD(MONTH,-24,GETDATE())

			GROUP BY ct.CINID) b on cl.CINID = b.CINID

IF OBJECT_ID('Sandbox.Tasfia.Matalan_Forecast1_300620') IS NOT NULL DROP TABLE Sandbox.Tasfia.Matalan_Forecast1_300620
SELECT CINID,
		FanID

INTO Sandbox.Tasfia.Matalan_Forecast1_300620

FROM #SegmentAssignment1
WHERE HighShopper = 1 OR MainBrandLapsed = 1

--Forecast 2--
IF OBJECT_ID('tempdb..#CC2') IS NOT NULL DROP TABLE #CC2
SELECT br.BrandID,
		br.BrandName,
		cc.ConsumerCombinationID
INTO	#CC2
FROM	Warehouse.Relational.Brand br
JOIN	Warehouse.Relational.ConsumerCombination cc ON br.BrandID = cc.BrandID
WHERE br.BrandID IN (2246,935,1307,1330,1334,1321,1737,3006,2540,
					 1332,1043,1335,918,2324,938,1404,1333,1331,
					 1284,1738,2539,1329,1285,1312,1826,1277,1336,2538,1337) --Transport--
OR		br.BrandID IN (204,29,498,385)										 --DIY--
OR		br.BrandID IN (425,379,21,254,5,292,215,485)						 --Supermarkets--
ORDER BY br.BrandName
CREATE CLUSTERED INDEX ix_ComboID ON #CC2(BrandID,ConsumerCombinationID)

IF OBJECT_ID('tempdb..#Transport') IS NOT NULL DROP TABLE #Transport
SELECT	fb.CINID, COUNT(1) AS Trans
INTO	#Transport
FROM	#FullBase fb
JOIN	Relational.ConsumerTransaction_MyRewards my on my.CINID = fb.CINID
JOIN	#CC2 cc on cc.ConsumerCombinationID = my.ConsumerCombinationID
WHERE	BrandID IN (2246,935,1307,1330,1334,1321,1737,3006,2540,
					 1332,1043,1335,918,2324,938,1404,1333,1331,
					 1284,1738,2539,1329,1285,1312,1826,1277,1336,2538,1337) --Transport--
AND		TranDate >= '2020-03-23'
GROUP BY fb.CINID

IF OBJECT_ID('tempdb..#DIY') IS NOT NULL DROP TABLE #DIY
SELECT	fb.CINID, COUNT(1) AS Trans
INTO	#DIY
FROM	#FullBase fb
JOIN	Relational.ConsumerTransaction_MyRewards my on my.CINID = fb.CINID
JOIN	#CC2 cc on cc.ConsumerCombinationID = my.ConsumerCombinationID
WHERE	BrandID IN (204,29,498,385)										 --DIY--
AND		TranDate >= '2020-03-23'
GROUP BY fb.CINID

IF OBJECT_ID('tempdb..#Grocery') IS NOT NULL DROP TABLE #Grocery
SELECT	fb.CINID, COUNT(1) AS Trans
INTO	#Grocery
FROM	#FullBase fb
JOIN	Relational.ConsumerTransaction_MyRewards my on my.CINID = fb.CINID
JOIN	#CC2 cc on cc.ConsumerCombinationID = my.ConsumerCombinationID
WHERE	BrandID IN (425,379,21,254,5,292,215,485)						 --Supermarkets--
AND		TranDate >= '2020-03-23'
GROUP BY fb.CINID

IF OBJECT_ID('tempdb..#Retailers') IS NOT NULL DROP TABLE #Retailers
SELECT	fb.CINID, COUNT(1) AS Trans
INTO	#Retailers
FROM	#FullBase fb
JOIN	Relational.ConsumerTransaction_MyRewards my on my.CINID = fb.CINID
JOIN	Relational.ConsumerCombination cc on cc.ConsumerCombinationID = my.ConsumerCombinationID
JOIN	Relational.Brand b on b.BrandID = cc.BrandID
JOIN	Relational.BrandSector bs on bs.SectorID = b.SectorID
JOIN	Relational.BrandSectorGroup bg on bg.SectorGroupID =bs.SectorGroupID
AND		TranDate >= '2020-06-01'
AND		IsOnline = 0
AND		GroupName = 'General Retail'
GROUP BY fb.CINID

If Object_ID('tempdb..#SegmentAssignment2') IS NOT NULL DROP TABLE #SegmentAssignment2
Select cl.CINID,			-- keep CINID and FANID
		cl.fanid,
		CASE WHEN t.CINID IS NOT NULL THEN 1 ELSE 0 END AS Transport,
		CASE WHEN d.CINID IS NOT NULL THEN 1 ELSE 0 END AS DIY,
		CASE WHEN g.CINID IS NOT NULL THEN 1 ELSE 0 END AS Grocery,
		CASE WHEN h.CINID IS NOT NULL THEN 1 ELSE 0 END AS Retailers
INTO	#SegmentAssignment2
FROM (SELECT CINID, FanID FROM #FullBase) cl
LEFT JOIN (SELECT	CINID
		 FROM		#Transport
		 WHERE	Trans >= 2) t on cl.CINID = t.CINID
LEFT JOIN (SELECT	CINID
		 FROM		#DIY) d on cl.CINID = d.CINID
LEFT JOIN (SELECT	CINID
		 FROM		#Grocery
		 WHERE	Trans >= 25) g on cl.CINID = g.CINID
LEFT JOIN (SELECT	CINID
		 FROM		#Retailers) h on cl.CINID = h.CINID

IF OBJECT_ID('Sandbox.Tasfia.Matalan_Forecast2_300620') IS NOT NULL DROP TABLE Sandbox.Tasfia.Matalan_Forecast2_300620
SELECT CINID,
		FanID

INTO Sandbox.Tasfia.Matalan_Forecast2_300620

FROM #SegmentAssignment2
WHERE Transport = 1 OR DIY = 1 OR Grocery = 1 OR Retailers = 1

If Object_ID('tempdb..#CountDupes') IS NOT NULL DROP TABLE #CountDupes
SELECT	fb.CINID,
		fb.FanID,
		MAX(CASE WHEN s1.CINID IS NOT NULL THEN 1 ELSE 0 END) AS S1,
		MAX(CASE WHEN s2.CINID IS NOT NULL THEN 1 ELSE 0 END) AS S2
INTO	#CountDupes
FROM	#FullBase fb
LEFT JOIN	Sandbox.Tasfia.Matalan_Forecast1_300620 s1 on s1.CINID = fb.CINID
LEFT JOIN	Sandbox.Tasfia.Matalan_Forecast2_300620 s2 on s2.CINID = fb.CINID
GROUP BY fb.CINID,
		fb.FanID
SELECT	S1, S2, COUNT(1)
FROM	#CountDupes
GROUP BY S1, S2

--FINAL CINID TABLES FOR FORECAST 1--
IF OBJECT_ID('Sandbox.Tasfia.Matalan_Reforecast1_010720') IS NOT NULL DROP TABLE Sandbox.Tasfia.Matalan_Reforecast1_010720
SELECT	CINID,
		FanID
INTO	Sandbox.Tasfia.Matalan_Reforecast1_010720
FROM	#CountDupes
WHERE	((S1 = 1 AND S2 = 0) OR (S1 = 1 AND S2 = 1))

--FINAL CINID TABLES FOR FORECAST 2--
IF OBJECT_ID('Sandbox.Tasfia.Matalan_Reforecast2_010720') IS NOT NULL DROP TABLE Sandbox.Tasfia.Matalan_Reforecast2_010720
SELECT	CINID,
		FanID
INTO	Sandbox.Tasfia.Matalan_Reforecast2_010720
FROM	#CountDupes
WHERE	(S1 = 0 AND S2 = 1)If Object_ID('Warehouse.Selections.ML011_PreSelection') Is Not Null Drop Table Warehouse.Selections.ML011_PreSelectionSelect FanIDInto Warehouse.Selections.ML011_PreSelectionFROM SANDBOX.TASFIA.Matalan_Reforecast1_010720UNION ALLSelect FanIDFROM SANDBOX.TASFIA.MATALAN_REFORECAST2_010720END