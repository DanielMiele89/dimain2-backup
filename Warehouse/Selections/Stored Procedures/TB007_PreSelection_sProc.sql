-- =============================================-- Author:  <Rory Francis>-- Create date: <2020-06-15>-- Description: < sProc to run preselection code per camapign >-- =============================================CREATE PROCEDURE Selections.TB007_PreSelection_sProcASBEGIN
IF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC
SELECT br.BrandID,
		br.BrandName,
		cc.ConsumerCombinationID,
		MID
INTO	#CC
FROM	Warehouse.Relational.Brand br
JOIN	Warehouse.Relational.ConsumerCombination cc ON br.BrandID = cc.BrandID
WHERE	br.BrandID in (423)
ORDER BY br.BrandName
CREATE CLUSTERED INDEX ix_ComboID ON #cc(BrandID,ConsumerCombinationID)

IF OBJECT_ID('tempdb..#TDPostcodes') IS NOT NULL DROP TABLE #TDPostcodes
SELECT	PostCode, REPLACE(PostCode,' ','') AS PostcodeFormat, City
INTO	#TDPostcodes
FROM	Relational.Outlet
WHERE	PartnerID = '4724'
AND		MerchantID IN ('96168822','96169132','96170322','96170662','96171212','96173252','96174302','96174482','96175532','15902523','66070962','69126792','83865492','48397362','13348923','89448682','48398092','48397522','34481342','55422353','55124682','13348263','57796622','62343983','14986203','14986703','15903593','27726033','27727263','40728633','67634023','20473673','27726953','78572883','89687493','88743983','73659143','72618853','05929683','21234645','22876745','19204735','19204315','22876585')


IF OBJECT_ID('tempdb..#CCOnline') IS NOT NULL DROP TABLE #CCOnline
SELECT br.BrandID,
		br.BrandName,
		cc.ConsumerCombinationID,
		MID
INTO	#CCOnline
FROM	Warehouse.Relational.Brand br
JOIN	Warehouse.Relational.ConsumerCombination cc ON br.BrandID = cc.BrandID
WHERE	br.BrandID in (423)
AND		MID IN ('30673865','81807493')
ORDER BY br.BrandName
CREATE CLUSTERED INDEX ix_ComboID ON #CCOnline(BrandID,ConsumerCombinationID)

IF OBJECT_ID('tempdb..#FullBase') IS NOT NULL DROP TABLE #FullBase
SELECT	CL.CINID,
		cu.FanID
INTO	#FullBase
FROM	Relational.Customer cu
JOIN	Relational.CINList cl on cu.SourceUID = cl.CIN
WHERE	cu.CurrentlyActive = 1
AND		cu.sourceuid NOT IN (SELECT DISTINCT sourceuid FROM Warehouse.Staging.Customer_DuplicateSourceUID )
GROUP BY CL.CINID, cu.FanID


If Object_ID('tempdb..#SegmentAssignment2') IS NOT NULL DROP TABLE #SegmentAssignment2
Select cl.CINID,			-- keep CINID and FANID
		cl.fanid,
		MainBrandShopper6M,
		MainBrandShopper6M12M

INTO #SegmentAssignment2

FROM (SELECT CINID,
			 FanID
	 FROM	Relational.Customer cu
	 JOIN	Relational.CINList cl on cu.SourceUID = cl.CIN
	 WHERE	cu.CurrentlyActive = 1
	 AND	cu.sourceuid NOT IN (SELECT DISTINCT sourceuid FROM Warehouse.Staging.Customer_DuplicateSourceUID )
	 AND	cu.PostalSector IN (SELECT	DISTINCT dtm.fromsector 
								FROM	Relational.DriveTimeMatrix as dtm with (NOLOCK)
								WHERE	dtm.tosector IN (SELECT	DISTINCT substring([PostCode],1,charindex(' ',[PostCode],1)+1) 
														 FROM	#TDPostcodes
														 
														 WHERE	dtm.DriveTimeMins <= 30))
	 ) cl

LEFT JOIN (SELECT	ct.CINID,
					MAX(CASE WHEN DATEADD(WEEK,-26,GETDATE()) <= TranDate AND TranDate <= GETDATE() THEN 1 ELSE 0 END) AS MainBrandShopper6M,
					MAX(CASE WHEN DATEADD(WEEK,-52,GETDATE()) <= TranDate AND TranDate < DATEADD(WEEK,-26,GETDATE()) THEN 1 ELSE 0 END) AS MainBrandShopper6M12M

			FROM Warehouse.Relational.ConsumerTransaction_MyRewards ct with (nolock)
			JOIN #CC cc on cc.ConsumerCombinationID = ct.ConsumerCombinationID
			
			WHERE 0 < ct.Amount
			AND TranDate >= DATEADD(WEEK,-52,GETDATE())

			GROUP BY ct.CINID) b on cl.CINID = b.CINID

IF OBJECT_ID('Sandbox.Tasfia.TedBakerF2_0106') IS NOT NULL DROP TABLE Sandbox.Tasfia.TedBakerF2_0106
SELECT CINID,
		FanID
INTO	Sandbox.Tasfia.TedBakerF2_0106
FROM	#SegmentAssignment2
WHERE	((MainBrandShopper6M = 0 AND	MainBrandShopper6M12M = 1)
			OR (MainBrandShopper6M = 0 AND	MainBrandShopper6M12M = 0)
			OR (MainBrandShopper6M IS NULL AND	MainBrandShopper6M12M IS NULL))

--Spent within 10 mins of TB Stores--
--Consum combination for TB Stores--
IF OBJECT_ID('TEMPDB..#PCDTM') IS NOT NULL DROP TABLE #PCDTM
SELECT	AWS.ConsumerCombinationID, -- COME BACK TO REVIEW
		LEFT(AWS.PostCode,LEN(AWS.Postcode) - 2) AS Postcode
INTO	#PCDTM
FROM	Warehouse.AWSFile.ComboPostCode aws
WHERE	EXISTS
		(SELECT 1
		 FROM	#TDPostcodes t
		 WHERE	LEFT(PostcodeFormat,LEN(PostcodeFormat) - 2) = LEFT(AWS.PostCode,LEN(AWS.Postcode) - 2)
		 )
CREATE CLUSTERED INDEX ix_ComboID ON #PCDTM(ConsumerCombinationID)


--All Postcodes within 10 mins dtm of TB stores--
IF OBJECT_ID('tempdb..#TDPostcodesLondon') IS NOT NULL DROP TABLE #TDPostcodesLondon
SELECT	PostCode, REPLACE(PostCode,' ','') AS PostcodeFormat
INTO	#TDPostcodesLondon
FROM	Relational.Outlet
WHERE	PartnerID = '4724'
AND		MerchantID IN ('55422353','62343983','96173252','14986703','66070962','22876585','48398092','19204315','27727263')

DECLARE @MinThreshold INT = 10
IF OBJECT_ID ('tempdb..#LocalPostcodes') IS NOT NULL DROP TABLE #LocalPostcodes
SELECT dtm.ToSector, dtm.FromSector
INTO #LocalPostcodes
FROM Warehouse.Relational.DriveTimeMatrix dtm

WHERE EXISTS
	( SELECT 1
	 FROM #PCDTM s
	 WHERE	REPLACE(FromSector,' ','') = s.POSTCODE
	)
AND DriveTimeMins <= @MinThreshold

IF OBJECT_ID('tempdb..#ComboPostCode') IS NOT NULL DROP TABLE #ComboPostCode
SELECT	cpc.ConsumerCombinationID,
		b.BrandID,
		BrandName,
		LEFT(cpc.PostCode,LEN(Postcode) - 2) PostalSector
INTO	#ComboPostCode
FROM	AWSFile.ComboPostCode cpc
JOIN	Relational.ConsumerCombination cc on cc.ConsumerCombinationID = cpc.ConsumerCombinationID
JOIN	Relational.Brand b on b.BrandID = cc.BrandID
WHERE	cc.BrandID <> 944

CREATE CLUSTERED INDEX cix_PostalSector ON #ComboPostCode (PostalSector)

--Consumer Combination for local shopper postcodes used for transactons in #segment assighment--
IF OBJECT_ID('tempdb..#LocalStores') IS NOT NULL DROP TABLE #LocalStores
SELECT	ConsumerCombinationID,
		BrandID,
		BrandName,
		FromSector
INTO	#LocalStores
FROM	#ComboPostCode cp
JOIN	#LocalPostcodes lp ON cp.PostalSector = REPLACE(lp.ToSector,' ','')
WHERE BrandID NOT IN (1397,1490, 2057, 844,2452, 2567,1415,2120,2229,402,1023,944,2009,1293,11,299,1763,2500,1748,1869,800,791,1224,1036,2142,2027,773,418,447,129,668)
CREATE CLUSTERED INDEX cix_ConsumerCombinationID ON #LocalStores (ConsumerCombinationID)

--GET RID OF THE ONLINE STORES AND ONLINE TRANSACTIONS & TRANSACTIONS WITHIN THE LAST YEAR WITHIN 10 MINS DRIVE--
DECLARE @StartDate DATE = DATEADD(MONTH,-12,GETDATE())
DECLARE @EndDate DATE = GETDATE()
IF OBJECT_ID('TEMPDB..#NONLINE') IS NOT NULL DROP TABLE #NONLINE
SELECT	CTMR.CINID,
		COUNT(*) FREQUENCY,
		FromSector
INTO	#NONLINE
FROM	Warehouse.Relational.ConsumerTransaction_MyRewards CTMR
JOIN	#LocalStores LS ON ls.ConsumerCombinationID = CTMR.ConsumerCombinationID
WHERE	ls.BrandID NOT IN (943,1397,1490, 2057, 844,2452, 2567,1415,2120,2229,402,1023,944,2009,1293,11,299,1763,2500,1748,1869,800,791,1224,1036,2142,2027,773,418,447,129,668)
AND		CTMR.IsOnline = 0
AND		CTMR.Amount > 0 
AND		CTMR.TranDate < @EndDate AND CTMR.TranDate >= @StartDate
GROUP BY CTMR.CINID, FromSector
		 
CREATE CLUSTERED INDEX ix_ComboID ON #NONLINE(CINID)

IF OBJECT_ID('TEMPDB..#F2CustomerBase') IS NOT NULL DROP TABLE #F2CustomerBase
SELECT	fb.CINID,
		FanID,
		FREQUENCY,
		FromSector
INTO	#F2CustomerBase
FROM	(SELECT CINID,
				FanID,
				PostalSector
		 FROM	Relational.Customer cu
		 JOIN	Relational.CINList cl on cu.SourceUID = cl.CIN
		 WHERE	cu.CurrentlyActive = 1
		 AND	cu.sourceuid NOT IN (SELECT DISTINCT sourceuid FROM Warehouse.Staging.Customer_DuplicateSourceUID )
		 ) fb
JOIN	#NONLINE #NO ON #NO.CINID = fb.CINID
WHERE	FREQUENCY >= 2

SELECT	DISTINCT FromSector FROM #F2CustomerBase


If Object_ID('tempdb..#SegmentAssignment3') IS NOT NULL DROP TABLE #SegmentAssignment3
Select cl.CINID,			-- keep CINID and FANID
		cl.fanid,
		MainBrandShopper6M,
		MainBrandShopper6M12M

INTO #SegmentAssignment3

FROM (SELECT DISTINCT
			 CINID,
			 FanID
	 FROM	 #F2CustomerBase
	 ) cl

LEFT JOIN (SELECT	ct.CINID,
					MAX(CASE WHEN DATEADD(WEEK,-26,GETDATE()) <= TranDate AND TranDate <= GETDATE() THEN 1 ELSE 0 END) AS MainBrandShopper6M,
					MAX(CASE WHEN DATEADD(WEEK,-52,GETDATE()) <= TranDate AND TranDate < DATEADD(WEEK,-26,GETDATE()) THEN 1 ELSE 0 END) AS MainBrandShopper6M12M

			FROM Warehouse.Relational.ConsumerTransaction_MyRewards ct with (nolock)
			JOIN #CC cc on cc.ConsumerCombinationID = ct.ConsumerCombinationID
			
			WHERE 0 < ct.Amount
			AND TranDate >= DATEADD(WEEK,-52,GETDATE())

			GROUP BY ct.CINID) b on cl.CINID = b.CINID

IF OBJECT_ID('Sandbox.Tasfia.TedBakerF3_0106') IS NOT NULL DROP TABLE Sandbox.Tasfia.TedBakerF3_0106
SELECT CINID,
		FanID
INTO	Sandbox.Tasfia.TedBakerF3_0106
FROM	#SegmentAssignment3
WHERE	((MainBrandShopper6M = 0 AND	MainBrandShopper6M12M = 1)
			OR (MainBrandShopper6M = 0 AND	MainBrandShopper6M12M = 0)
			OR (MainBrandShopper6M IS NULL AND	MainBrandShopper6M12M IS NULL))

If Object_ID('tempdb..#RemoveDupes') IS NOT NULL DROP TABLE #RemoveDupes
SELECT	fb.CINID,
		CASE WHEN f2.CINID IS NOT NULL THEN 1 ELSE 0 END AS Forecast2,
		CASE WHEN f3.CINID IS NOT NULL THEN 1 ELSE 0 END AS Forecast3
INTO	#RemoveDupes
FROM	#FullBase fb
LEFT JOIN	Sandbox.Tasfia.TedBakerF2_0106 f2 on f2.CINID = fb.CINID
LEFT JOIN	Sandbox.Tasfia.TedBakerF3_0106 f3 on f3.CINID = fb.CINID

SELECT	Forecast2, Forecast3, COUNT(1)
FROM	#RemoveDupes
GROUP BY Forecast2, Forecast3

IF OBJECT_ID('Sandbox.Tasfia.TedBakerF4_0106') IS NOT NULL DROP TABLE Sandbox.Tasfia.TedBakerF4_0106
SELECT	*
INTO	Sandbox.Tasfia.TedBakerF4_0106
FROM	(SELECT CINID, FanID FROM Sandbox.Tasfia.TedBakerF2_0106
		UNION
		SELECT CINID, FanID FROM Sandbox.Tasfia.TedBakerF3_0106
		) a
If Object_ID('Warehouse.Selections.TB007_PreSelection') Is Not Null Drop Table Warehouse.Selections.TB007_PreSelectionSelect FanIDInto Warehouse.Selections.TB007_PreSelectionFROM SANDBOX.TASFIA.TEDBAKERF4_0106END