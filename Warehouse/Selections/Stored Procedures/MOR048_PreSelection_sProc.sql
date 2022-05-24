
-- =============================================-- Author:  <Rory Francis>-- Create date: <2020-02-04>-- Description: < sProc to run preselection code per camapign >-- =============================================CREATE PROCEDURE [Selections].[MOR048_PreSelection_sProc]ASBEGIN--DECLARE @CYCLESTARTDATE DATE = GETDATE()
--DECLARE @CYCLEENDDATE DATE =  DATEADD(YEAR,-2,@CYCLESTARTDATE)

---- Create Customer Actions Table, with Newsletter Engagement
--IF OBJECT_ID('tempdb..#CustomerActions') IS NOT NULL DROP TABLE #CustomerActions
--SELECT	DISTINCT ee.FanID
--	,	ee.EventDate
--INTO	#CustomerActions
--FROM	Relational.EmailEvent ee with (nolock)
--INNER JOIN Relational.EmailCampaign ec with (nolock) ON ec.CampaignKey = ee.CampaignKey
--WHERE	ee.EventDate >= @CYCLEENDDATE
--AND		ee.EventDate <= @CYCLESTARTDATE
--AND		ee.EmailEventCodeID IN (1301, 605)
--AND		ec.CampaignName LIKE '%Newsletter%'
--CREATE CLUSTERED INDEX ix_FanID_EventDate_1 ON #CustomerActions(FanID, EventDate)



---- Create Customer Web Actions Table, with Login Engagement
--IF OBJECT_ID('tempdb..#CustomerWebActions') IS NOT NULL DROP TABLE #CustomerWebActions
--SELECT	DISTINCT FanID
--	,	CONVERT(DATE, TrackDate)	AS EventDate
--INTO	#CustomerWebActions
--FROM	Relational.WebLogins with (nolock)
--WHERE	TrackDate >= @CYCLEENDDATE
--AND		TrackDate <= @CYCLESTARTDATE
--CREATE CLUSTERED INDEX ix_FanID_EventDate_2 ON #CustomerWebActions(FanID, EventDate)


---- Merging Customer Web Actions data into Customer Actions Table
--IF OBJECT_ID('tempdb..#CombinedLogIns') IS NOT NULL DROP TABLE #CombinedLogIns
--SELECT		DISTINCT FanID, EventDate
--INTO		#CombinedLogIns
--FROM		#CustomerWebActions with (nolock)
--UNION		
--SELECT		FanID, EventDate
--FROM		#CustomerActions
--CREATE CLUSTERED INDEX ix_FanID_EventDate_2 ON #CombinedLogIns(FanID, EventDate)


--IF OBJECT_ID('tempdb..#Max') IS NOT NULL DROP TABLE #Max
--SELECT FanID, MAX(EventDate) MaxEventDate
--INTO #Max
--FROM #CombinedLogIns with (nolock)
--GROUP BY fanid


---- Compiliting Customer Awareness Table
--IF OBJECT_ID('tempdb..#CustomerAwareness') IS NOT NULL DROP TABLE #CustomerAwareness
--SELECT	*
--	,	CASE	WHEN DateDiff(Day,MaxEventDate,@CYCLESTARTDATE) <= 28 THEN '1 - Gold'
--				WHEN DateDiff(Day,MaxEventDate,@CYCLESTARTDATE) > 28	AND DateDiff(Day,MaxEventDate,@CYCLESTARTDATE) <= 84	THEN '2 - Silver'
--				WHEN DateDiff(Day,MaxEventDate,@CYCLESTARTDATE) > 84	AND DateDiff(Day,MaxEventDate,@CYCLESTARTDATE) <= 364	THEN '3 - Bronze'
--				ELSE '4 - Blue' END
--		AS AwarenessLevel
--INTO	#CustomerAwareness
--FROM	#Max with (nolock)
--CREATE CLUSTERED INDEX ix_FanID ON #CustomerAwareness(FanID)

--IF OBJECT_ID('tempdb..#FB') IS NOT NULL DROP TABLE #FB
--SELECT	C.FanID
--		,CINID
--		,AwarenessLevel
--INTO	#FB
--FROM	Relational.Customer C
--JOIN	Relational.CINList CL ON CL.CIN = C.SourceUID
--LEFT JOIN	#CustomerAwareness CA ON CA.fanid = C.FanID
--WHERE	C.CurrentlyActive = 1
--AND		SourceUID NOT IN (SELECT DISTINCT SourceUID FROM Staging.Customer_DuplicateSourceUID)
--CREATE CLUSTERED INDEX ix_FanID ON #FB(FanID)



--IF OBJECT_ID('Sandbox.SamW.MorrisonsGold130120') IS NOT NULL DROP TABLE Sandbox.SamW.MorrisonsGold130120
--SELECT	DISTINCT F.CINID
--		,FanID
--		, 'Gold' AwarenessLevel
--INTO Sandbox.SamW.MorrisonsGold130120
--FROM	#FB F
--WHERE	AwarenessLevel IN ('1 - Gold')
--CREATE CLUSTERED INDEX ix_FanID ON Sandbox.SamW.MorrisonsGold130120(FanID)

--IF OBJECT_ID('Sandbox.SamW.MorrisonsSilver130120') IS NOT NULL DROP TABLE Sandbox.SamW.MorrisonsSilver130120
--SELECT	DISTINCT F.CINID
--		,FanID
--		, 'Silver' AwarenessLevel
--INTO Sandbox.SamW.MorrisonsSilver130120
--FROM	#FB F
--WHERE	AwarenessLevel IN ('2 - Silver')
--CREATE CLUSTERED INDEX ix_FanID ON Sandbox.SamW.MorrisonsSilver130120(FanID)


--IF OBJECT_ID('Sandbox.SamW.MorrisonsBronze130120') IS NOT NULL DROP TABLE Sandbox.SamW.MorrisonsBronze130120
--SELECT	DISTINCT F.CINID
--		,FanID
--		, 'Bronze' AwarenessLevel
--INTO Sandbox.SamW.MorrisonsBronze130120
--FROM	#FB F
--WHERE	AwarenessLevel IN ('3 - Bronze')
--CREATE CLUSTERED INDEX ix_FanID ON Sandbox.SamW.MorrisonsBronze130120(FanID)

--IF OBJECT_ID('Sandbox.SamW.MorrisonsBlue130120') IS NOT NULL DROP TABLE Sandbox.SamW.MorrisonsBlue130120
--SELECT	DISTINCT F.CINID
--		,FanID
--		, 'Blue' AwarenessLevel
--INTO Sandbox.SamW.MorrisonsBlue130120
--FROM	#FB F
--WHERE	AwarenessLevel IN ('4 - Blue') OR AwarenessLevel IS NULL
--CREATE CLUSTERED INDEX ix_FanID ON Sandbox.SamW.MorrisonsBlue130120(FanID)

--IF OBJECT_ID('Sandbox.SamW.MorrisonsEngagement130120') IS NOT NULL DROP TABLE Sandbox.SamW.MorrisonsEngagement130120
--SELECT CINID
--		,FANID
--		, AwarenessLevel
--INTO Sandbox.SamW.MorrisonsEngagement130120
--FROM Sandbox.SamW.MorrisonsBlue130120
--UNION 
--SELECT CINID
--		,FANID
--		, AwarenessLevel
--FROM Sandbox.SamW.MorrisonsBronze130120
--UNION 
--SELECT CINID
--		,FANID
--		, AwarenessLevel
--FROM Sandbox.SamW.MorrisonsSilver130120
--UNION
--SELECT CINID
--		,FANID
--		, AwarenessLevel
--FROM Sandbox.SamW.MorrisonsGold130120


--IF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC
--Select	br.BrandID
--		,br.BrandName
--		,cc.ConsumerCombinationID
--Into	#CC
--From	Warehouse.Relational.Brand br
--Join	Warehouse.Relational.ConsumerCombination cc
--	on	br.BrandID = cc.BrandID
--Where	br.BrandID in (	292,						-- Morrisons
--						425,21,379,					-- Mainstream - Asda, Sainsburys, Tesco
--						485,275,312,1124,1158,1160,	-- Premium - M&S, Ocado, Waitrose, Planet Organic, Able & Cole, Whole Foods
--						92,399,103,1024,306,1421,	-- Convenience - Co-Op, Costcutter, Nisa, Spar, Londis, Martin Mc Coll
--						5,254,215,2573,102)			-- Discounters - Aldi, Costo, Iceland, Lidl, Jack's
--Order By br.BrandName
--CREATE CLUSTERED INDEX ix_ComboID ON #cc(ConsumerCombinationID)

----if needed to do SoW
--Declare @MainBrand smallint = 292	 -- Main Brand	

----		Assign Shopper segments
--If Object_ID('tempdb..#segmentAssignment') IS NOT NULL DROP TABLE #segmentAssignment
--Select	  cl.CINID			-- keep CINID and FANID
--		, cl.fanid			-- only need these two fields for forecasting / targetting everything else is dependant on requirements

--		-- Transactions
--		, Transactions
--		, Morrions_Transactions

--		-- Brand count
--		, Number_of_Brands_Shopped_At

--		, SoW_Morrisons
--		, Comp_SoW

--		, Morrisons_Shopper
--		, Morrisons_Lapsed
--		, Morrisons_Acquire
--		, ATV_BANDS
--Into		#segmentAssignment

--From		(	select CL.CINID
--						,cu.FanID
--				from warehouse.Relational.Customer cu
--				INNER JOIN  warehouse.Relational.CINList cl 
--					on cu.SourceUID = cl.CIN
--				where cu.CurrentlyActive = 1
--					and fanid not in (select fanid from [InsightArchive].[MorrisonsReward_MatchedCustomers_20190304]) --NOT A MORE CARDHOLDER--
--					and cu.sourceuid 
--						NOT IN (select distinct sourceuid from warehouse.Staging.Customer_DuplicateSourceUID )
--					and cu.PostalSector 
--						in (select distinct dtm.fromsector 
--				from warehouse.relational.DriveTimeMatrix as dtm with (NOLOCK)
--				where dtm.tosector IN (select distinct substring([PostCode],1,charindex(' ',[PostCode],1)+1) 
--						from  warehouse.relational.outlet
--						WHERE 	partnerid = 4263) 
--						AND dtm.DriveTimeMins <= 25)
--				group by CL.CINID, cu.FanID
--			) CL

			
--left Join	(	Select		ct.CINID
--							  -- Transaction Value Info
--							, sum(case when BrandID = @MainBrand then ct.Amount else 0 end) / cast(sum(ct.Amount) as float) as SoW_Morrisons

--							, sum(case when BrandID in (379,5,254) then ct.Amount else 0 end) / cast(sum(ct.Amount) as float) as Comp_SoW
							
--							  --Transaction Count Info
--							, count(1) as Transactions
--							, sum(case when BrandID = @MainBrand then 1 else 0 end) as Morrions_Transactions
											
--							  -- Brand count
--							, count(distinct BrandID) as Number_of_Brands_Shopped_At

--							, max(case when BrandID = @MainBrand 
--									and TranDate >= dateadd(month,-3,GETDATE())
--									then 1 else 0 end) as Morrisons_Shopper
--							, max(case when BrandID = @MainBrand 
--									and TranDate >= dateadd(month,-6,GETDATE()) 
--									and TranDate < dateadd(month,-3,GETDATE())
--									then 1 else 0 end) as Morrisons_Lapsed
--							, max(case when BrandID = @MainBrand 
--									and TranDate > dateadd(month,-6,GETDATE()) OR TranDate IS NULL
--									then 1 else 0 end) as Morrisons_Acquire

--							, CASE	WHEN SUM(Amount)/COUNT(1) IS NULL					THEN '£0'
--								WHEN SUM(Amount)/COUNT(1) >= 0.00  AND SUM(Amount)/COUNT(1) < 5.00	THEN '£0 - £5'
--								WHEN SUM(Amount)/COUNT(1) >= 5.00  AND SUM(Amount)/COUNT(1) < 15.00	THEN '£5 - £15' 
--								WHEN SUM(Amount)/COUNT(1) >= 15.00 AND SUM(Amount)/COUNT(1) < 25.00	THEN '£15 - £25'
--								WHEN SUM(Amount)/COUNT(1) >= 25.00 AND SUM(Amount)/COUNT(1) < 35.00	THEN '£25 - £35'
--								WHEN SUM(Amount)/COUNT(1) >= 35.00 AND SUM(Amount)/COUNT(1) < 45.00	THEN '£35 - £45'
--								WHEN SUM(Amount)/COUNT(1) >= 45.00 AND SUM(Amount)/COUNT(1) < 55.00	THEN '£45 - £55'
--								WHEN SUM(Amount)/COUNT(1) >= 55.00 AND SUM(Amount)/COUNT(1) < 65.00	THEN '£55 - £65'
--								WHEN SUM(Amount)/COUNT(1) >= 65.00 AND SUM(Amount)/COUNT(1) < 75.00	THEN '£65 - £75'
--								WHEN SUM(Amount)/COUNT(1) >= 75.00 AND SUM(Amount)/COUNT(1) < 85.00	THEN '£75 - £85'
--								WHEN SUM(Amount)/COUNT(1) >= 85.00 AND SUM(Amount)/COUNT(1) < 95.00	THEN '£85 - £95'
--								WHEN SUM(Amount)/COUNT(1) >= 95.00 AND SUM(Amount)/COUNT(1) < 105.00	THEN '£95 - £105'
--								WHEN SUM(Amount)/COUNT(1) >= 105.00 AND SUM(Amount)/COUNT(1) < 115.00	THEN '£105 - £115'
--								WHEN SUM(Amount)/COUNT(1) >= 115.00 AND SUM(Amount)/COUNT(1) < 125.00	THEN '£115 - £125'
--								WHEN SUM(Amount)/COUNT(1) > = 125 THEN '£125+'
--								ELSE 'ERROR!'
--								END AS ATV_BANDS
																				
--				From		Warehouse.Relational.ConsumerTransaction_MyRewards ct with (nolock)
--				Join		#cc cc on cc.ConsumerCombinationID = ct.ConsumerCombinationID
--				--  CROSS APPLY (
--				--       SELECT Excluded = CASE WHEN Amount < 10 AND Brandid <> 292 THEN 1 ELSE 0 END
--				--			) x
--				Where		0 < ct.Amount --and x.Excluded = 0 
--							and TranDate  > dateadd(month,-12,GETDATE())
--							and TranDate < GETDATE()
--				group by ct.CINID ) b
--on	cl.CINID = b.CINID



--SELECT COUNT(CINID), Morrisons_Shopper
--		, Morrisons_Lapsed
--		, Morrisons_Acquire
--FROM #segmentAssignment
--GROUP BY Morrisons_Shopper
--		, Morrisons_Lapsed
--		, Morrisons_Acquire


--IF OBJECT_ID('Sandbox.SamW.MorrisonsShopperPreFeb') IS NOT NULL DROP TABLE Sandbox.SamW.MorrisonsShopperPreFeb
--SELECT CINID, FanID, 'Shopper' ShopperCat, ATV_BANDS
--INTO Sandbox.SamW.MorrisonsShopperPreFeb
--FROM #segmentAssignment
--WHERE Morrisons_Shopper = 1 
----AND Transactions > = 50
--AND SoW_Morrisons < = 0.6
	
--IF OBJECT_ID('Sandbox.SamW.MorrisonsLapsedPreFeb') IS NOT NULL DROP TABLE Sandbox.SamW.MorrisonsLapsedPreFeb
--SELECT CINID, FanID, 'Lapsed' ShopperCat,ATV_BANDS
--INTO Sandbox.SamW.MorrisonsLapsedPreFeb
--FROM #segmentAssignment
--WHERE Morrisons_Lapsed = 1 
--AND Morrisons_Shopper <> 1

--IF OBJECT_ID('Sandbox.SamW.MorrisonsAcquirePreFeb') IS NOT NULL DROP TABLE Sandbox.SamW.MorrisonsAcquirePreFeb
--SELECT CINID, FanID, 'Acquire' ShopperCat, ATV_BANDS
--INTO Sandbox.SamW.MorrisonsAcquirePreFeb
--FROM #segmentAssignment
--WHERE (Morrisons_Acquire = 1 
--OR Morrisons_Acquire = 0 OR Morrisons_Acquire IS NULL)
--AND (Morrisons_Lapsed <> 1 OR Morrisons_Lapsed IS NULL)
--AND (Morrisons_Shopper <> 1 OR Morrisons_Shopper IS NULL)


--IF OBJECT_ID('Sandbox.SamW.Morrisons_FebFirstCycle20ComboPreFeb') IS NOT NULL DROP TABLE Sandbox.SamW.Morrisons_FebFirstCycle20ComboPreFeb
--SELECT CINID, FanID, ShopperCat, ATV_BANDS
--INTO Sandbox.SamW.Morrisons_FebFirstCycle20ComboPreFeb
--FROM Sandbox.SamW.MorrisonsAcquirePreFeb
--UNION 
--SELECT CINID, FanID, ShopperCat, ATV_BANDS
--FROM Sandbox.SamW.MorrisonsLapsedPreFeb
--UNION 
--SELECT CINID, FanID, ShopperCat, ATV_BANDS
--FROM Sandbox.SamW.MorrisonsShopperPreFeb


--IF OBJECT_ID('Sandbox.SamW.MorrisonsTotalCombo1501202PreFeb') IS NOT NULL DROP TABLE Sandbox.SamW.MorrisonsTotalCombo1501202PreFeb
--SELECT A.CINID, A.FANID, AwarenessLevel, ShopperCat, ATV_BANDS
--INTO Sandbox.SamW.MorrisonsTotalCombo1501202PreFeb
--FROM Sandbox.SamW.Morrisons_FebFirstCycle20ComboPreFeb A
--JOIN Sandbox.SamW.MorrisonsEngagement130120 B ON A.CINID = B.CINID

--SELECT COUNT(A.CINID)
--	 , ATV_BANDS
--FROM Sandbox.SamW.Morrisons_FebFirstCycle20Combo A
--JOIN Sandbox.SamW.MorrisonsEngagement130120 B ON A.CINID = B.CINID
--GROUP BY ATV_BANDS



--IF OBJECT_ID('Sandbox.SamW.MorrisonsLowATVPreFeb') IS NOT NULL DROP TABLE Sandbox.SamW.MorrisonsLowATVPreFeb
--SELECT CINID, FANID
--INTO Sandbox.SamW.MorrisonsLowATVPreFeb
--FROM Sandbox.SamW.MorrisonsTotalCombo1501202PreFeb
--WHERE --AwarenessLevel IN ('Gold', 'Silver')
----AND 
--ATV_BANDS IN ('£0 - £5', '£5 - £15', '£15 - £25', '£25 - £35', '£35 - £45''£45 - £55','£55 - £65','£65 - £75', '£75 - £85','£85 - £95', '£95 - £105', '£105 - £115','£115 - £125','£125+')
----OR ATV_BANDS IS NULL


--IF OBJECT_ID('Sandbox.SamW.MorrisonsMediumATVPreFeb') IS NOT NULL DROP TABLE Sandbox.SamW.MorrisonsMediumATVPreFeb
--SELECT CINID, FANID
--INTO Sandbox.SamW.MorrisonsMediumATVPreFeb
--FROM Sandbox.SamW.MorrisonsTotalCombo1501202PreFeb
--WHERE ATV_BANDS IN ('£65 - £75')


--IF OBJECT_ID('Sandbox.SamW.MorrisonsHighATVPreFeb') IS NOT NULL DROP TABLE Sandbox.SamW.MorrisonsHighATVPreFeb
--SELECT CINID, FANID
--INTO Sandbox.SamW.MorrisonsHighATVPreFeb
--FROM Sandbox.SamW.MorrisonsTotalCombo1501202PreFeb
--WHERE ATV_BANDS IN ('£75 - £85','£85 - £95', '£95 - £105', '£105 - £115','£115 - £125','£125+')
DECLARE @CYCLESTARTDATE DATE = '2020-02-13'

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

IF OBJECT_ID('tempdb..#FB') IS NOT NULL DROP TABLE #FB
SELECT	C.FanID
		,CINID
		,AwarenessLevel
INTO	#FB
FROM	Relational.Customer C
JOIN	Relational.CINList CL ON CL.CIN = C.SourceUID
LEFT JOIN	#CustomerAwareness CA ON CA.fanid = C.FanID
WHERE	C.CurrentlyActive = 1
AND		SourceUID NOT IN (SELECT DISTINCT SourceUID FROM Staging.Customer_DuplicateSourceUID)
CREATE CLUSTERED INDEX ix_FanID ON #FB(FanID)

SELECT COUNT(DISTINCT FANID)
FROM #FB
WHERE AwarenessLevel IS NULL


IF OBJECT_ID('Sandbox.SamW.MorrisonsGold130120') IS NOT NULL DROP TABLE Sandbox.SamW.MorrisonsGold130120
SELECT	DISTINCT F.CINID
		,FanID
		, 'Gold' AwarenessLevel
INTO Sandbox.SamW.MorrisonsGold130120
FROM	#FB F
WHERE	AwarenessLevel IN ('1 - Gold')
CREATE CLUSTERED INDEX ix_FanID ON Sandbox.SamW.MorrisonsGold130120(FanID)

IF OBJECT_ID('Sandbox.SamW.MorrisonsSilver130120') IS NOT NULL DROP TABLE Sandbox.SamW.MorrisonsSilver130120
SELECT	DISTINCT F.CINID
		,FanID
		, 'Silver' AwarenessLevel
INTO Sandbox.SamW.MorrisonsSilver130120
FROM	#FB F
WHERE	AwarenessLevel IN ('2 - Silver')
CREATE CLUSTERED INDEX ix_FanID ON Sandbox.SamW.MorrisonsSilver130120(FanID)


IF OBJECT_ID('Sandbox.SamW.MorrisonsBronze130120') IS NOT NULL DROP TABLE Sandbox.SamW.MorrisonsBronze130120
SELECT	DISTINCT F.CINID
		,FanID
		, 'Bronze' AwarenessLevel
INTO Sandbox.SamW.MorrisonsBronze130120
FROM	#FB F
WHERE	AwarenessLevel IN ('3 - Bronze')
CREATE CLUSTERED INDEX ix_FanID ON Sandbox.SamW.MorrisonsBronze130120(FanID)

IF OBJECT_ID('Sandbox.SamW.MorrisonsBlue130120') IS NOT NULL DROP TABLE Sandbox.SamW.MorrisonsBlue130120
SELECT	DISTINCT F.CINID
		,FanID
		, 'Blue' AwarenessLevel
INTO Sandbox.SamW.MorrisonsBlue130120
FROM	#FB F
WHERE	AwarenessLevel IN ('4 - Blue') OR AwarenessLevel IS NULL
CREATE CLUSTERED INDEX ix_FanID ON Sandbox.SamW.MorrisonsBlue130120(FanID)

IF OBJECT_ID('Sandbox.SamW.MorrisonsEngagement130120') IS NOT NULL DROP TABLE Sandbox.SamW.MorrisonsEngagement130120
SELECT CINID
		,FANID
		, AwarenessLevel
INTO Sandbox.SamW.MorrisonsEngagement130120
FROM Sandbox.SamW.MorrisonsBlue130120
UNION 
SELECT CINID
		,FANID
		, AwarenessLevel
FROM Sandbox.SamW.MorrisonsBronze130120
UNION 
SELECT CINID
		,FANID
		, AwarenessLevel
FROM Sandbox.SamW.MorrisonsSilver130120
UNION
SELECT CINID
		,FANID
		, AwarenessLevel
FROM Sandbox.SamW.MorrisonsGold130120


IF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC
Select	br.BrandID
		,br.BrandName
		,cc.ConsumerCombinationID
Into	#CC
From	Warehouse.Relational.Brand br
Join	Warehouse.Relational.ConsumerCombination cc
	on	br.BrandID = cc.BrandID
Where	br.BrandID in (	292,						-- Morrisons
						425,21,379,					-- Mainstream - Asda, Sainsburys, Tesco
						485,275,312,1124,1158,1160,	-- Premium - M&S, Ocado, Waitrose, Planet Organic, Able & Cole, Whole Foods
						92,399,103,1024,306,1421,	-- Convenience - Co-Op, Costcutter, Nisa, Spar, Londis, Martin Mc Coll
						5,254,215,2573,102)			-- Discounters - Aldi, Costo, Iceland, Lidl, Jack's
Order By br.BrandName
CREATE CLUSTERED INDEX ix_ComboID ON #cc(ConsumerCombinationID)

--if needed to do SoW
Declare @MainBrand smallint = 292	 -- Main Brand	

--		Assign Shopper segments
If Object_ID('tempdb..#segmentAssignment') IS NOT NULL DROP TABLE #segmentAssignment
Select	  cl.CINID			-- keep CINID and FANID
		, cl.fanid			-- only need these two fields for forecasting / targetting everything else is dependant on requirements

		-- Transactions
		, Transactions
		, Morrions_Transactions

		-- Brand count
		, Number_of_Brands_Shopped_At

		, SoW_Morrisons
		, Comp_SoW

		, Morrisons_Shopper
		, Morrisons_Lapsed
		, Morrisons_Acquire
		, ATV_BANDS
Into		#segmentAssignment

From		(	select CL.CINID
						,cu.FanID
				from warehouse.Relational.Customer cu
				INNER JOIN  warehouse.Relational.CINList cl 
					on cu.SourceUID = cl.CIN
				where cu.CurrentlyActive = 1
					and fanid not in (select fanid from [InsightArchive].[MorrisonsReward_MatchedCustomers_20190304]) --NOT A MORE CARDHOLDER--
					and cu.sourceuid 
						NOT IN (select distinct sourceuid from warehouse.Staging.Customer_DuplicateSourceUID )
					and cu.PostalSector 
						in (select distinct dtm.fromsector 
				from warehouse.relational.DriveTimeMatrix as dtm with (NOLOCK)
				where dtm.tosector IN (select distinct substring([PostCode],1,charindex(' ',[PostCode],1)+1) 
						from  warehouse.relational.outlet
						WHERE 	partnerid = 4263) 
						AND dtm.DriveTimeMins <= 25)
				group by CL.CINID, cu.FanID
			) CL

			
left Join	(	Select		ct.CINID
							  -- Transaction Value Info
							, sum(case when BrandID = @MainBrand then ct.Amount else 0 end) / cast(sum(ct.Amount) as float) as SoW_Morrisons

							, sum(case when BrandID in (379,5,254) then ct.Amount else 0 end) / cast(sum(ct.Amount) as float) as Comp_SoW
							
							  --Transaction Count Info
							, count(1) as Transactions
							, sum(case when BrandID = @MainBrand then 1 else 0 end) as Morrions_Transactions
											
							  -- Brand count
							, count(distinct BrandID) as Number_of_Brands_Shopped_At

							, max(case when BrandID = @MainBrand 
									and TranDate >= dateadd(month,-3,@CYCLESTARTDATE)
									then 1 else 0 end) as Morrisons_Shopper
							, max(case when BrandID = @MainBrand 
									and TranDate >= dateadd(month,-6,@CYCLESTARTDATE) 
									and TranDate < dateadd(month,-3,@CYCLESTARTDATE)
									then 1 else 0 end) as Morrisons_Lapsed
							, max(case when BrandID = @MainBrand 
									and TranDate > dateadd(month,-6,@CYCLESTARTDATE) OR TranDate IS NULL
									then 1 else 0 end) as Morrisons_Acquire

							, CASE	WHEN SUM(Amount)/COUNT(1) IS NULL					THEN '£0'
								WHEN SUM(Amount)/COUNT(1) >= 0.00  AND SUM(Amount)/COUNT(1) < 5.00	THEN '£0 - £5'
								WHEN SUM(Amount)/COUNT(1) >= 5.00  AND SUM(Amount)/COUNT(1) < 15.00	THEN '£5 - £15' 
								WHEN SUM(Amount)/COUNT(1) >= 15.00 AND SUM(Amount)/COUNT(1) < 25.00	THEN '£15 - £25'
								WHEN SUM(Amount)/COUNT(1) >= 25.00 AND SUM(Amount)/COUNT(1) < 35.00	THEN '£25 - £35'
								WHEN SUM(Amount)/COUNT(1) >= 35.00 AND SUM(Amount)/COUNT(1) < 45.00	THEN '£35 - £45'
								WHEN SUM(Amount)/COUNT(1) >= 45.00 AND SUM(Amount)/COUNT(1) < 55.00	THEN '£45 - £55'
								WHEN SUM(Amount)/COUNT(1) >= 55.00 AND SUM(Amount)/COUNT(1) < 65.00	THEN '£55 - £65'
								WHEN SUM(Amount)/COUNT(1) >= 65.00 AND SUM(Amount)/COUNT(1) < 75.00	THEN '£65 - £75'
								WHEN SUM(Amount)/COUNT(1) >= 75.00 AND SUM(Amount)/COUNT(1) < 85.00	THEN '£75 - £85'
								WHEN SUM(Amount)/COUNT(1) >= 85 THEN '£85+'
								ELSE 'ERROR!'
								END AS ATV_BANDS
																				
				From		Warehouse.Relational.ConsumerTransaction_MyRewards ct with (nolock)
				Join		#cc cc on cc.ConsumerCombinationID = ct.ConsumerCombinationID
				--  CROSS APPLY (
				--       SELECT Excluded = CASE WHEN Amount < 10 AND Brandid <> 292 THEN 1 ELSE 0 END
				--			) x
				Where		0 < ct.Amount --and x.Excluded = 0 
							and TranDate  > dateadd(month,-12,@CYCLESTARTDATE)
							and TranDate < @CYCLESTARTDATE
				group by ct.CINID ) b
on	cl.CINID = b.CINID

SELECT COUNT(CINID), Morrisons_Shopper
		, Morrisons_Lapsed
		, Morrisons_Acquire
FROM #segmentAssignment
GROUP BY Morrisons_Shopper
		, Morrisons_Lapsed
		, Morrisons_Acquire


IF OBJECT_ID('Sandbox.SamW.MorrisonsShopper') IS NOT NULL DROP TABLE Sandbox.SamW.MorrisonsShopper
SELECT CINID, FanID, 'Shopper' ShopperCat, ATV_BANDS
INTO Sandbox.SamW.MorrisonsShopper
FROM #segmentAssignment
WHERE Morrisons_Shopper = 1 
AND Transactions > = 100
AND SoW_Morrisons < = 0.1
	
IF OBJECT_ID('Sandbox.SamW.MorrisonsLapsed') IS NOT NULL DROP TABLE Sandbox.SamW.MorrisonsLapsed
SELECT CINID, FanID, 'Lapsed' ShopperCat,ATV_BANDS
INTO Sandbox.SamW.MorrisonsLapsed
FROM #segmentAssignment
WHERE Morrisons_Lapsed = 1 
AND Morrisons_Shopper <> 1


IF OBJECT_ID('Sandbox.SamW.MorrisonsAcquire') IS NOT NULL DROP TABLE Sandbox.SamW.MorrisonsAcquire
SELECT CINID, FanID, 'Acquire' ShopperCat, ATV_BANDS
INTO Sandbox.SamW.MorrisonsAcquire
FROM #segmentAssignment
WHERE (Morrisons_Acquire = 1 
OR Morrisons_Acquire = 0 OR Morrisons_Acquire IS NULL)
AND (Morrisons_Lapsed <> 1 OR Morrisons_Lapsed IS NULL)
AND (Morrisons_Shopper <> 1 OR Morrisons_Shopper IS NULL)


IF OBJECT_ID('Sandbox.SamW.Morrisons_FebFirstCycle20Combo') IS NOT NULL DROP TABLE Sandbox.SamW.Morrisons_FebFirstCycle20Combo
SELECT CINID, FanID, ShopperCat, ATV_BANDS
INTO Sandbox.SamW.Morrisons_FebFirstCycle20Combo
FROM Sandbox.SamW.MorrisonsAcquire
UNION 
SELECT CINID, FanID, ShopperCat, ATV_BANDS
FROM Sandbox.SamW.MorrisonsLapsed
UNION 
SELECT CINID, FanID, ShopperCat, ATV_BANDS
FROM Sandbox.SamW.MorrisonsShopper

IF OBJECT_ID('Sandbox.SamW.MorrisonsTotalCombo1501202') IS NOT NULL DROP TABLE Sandbox.SamW.MorrisonsTotalCombo1501202
SELECT A.CINID, A.FANID, AwarenessLevel, ShopperCat, ATV_BANDS
INTO Sandbox.SamW.MorrisonsTotalCombo1501202
FROM Sandbox.SamW.Morrisons_FebFirstCycle20Combo A
JOIN Sandbox.SamW.MorrisonsEngagement130120 B ON A.CINID = B.CINID

SELECT COUNT(1), AwarenessLevel, ShopperCat, ATV_Bands
FROM Sandbox.SamW.MorrisonsTotalCombo1501202
GROUP BY AwarenessLevel, ShopperCat, ATV_Bands


--IF OBJECT_ID('tempdb..#ControlRandom') IS NOT NULL DROP TABLE #ControlRandom
--SELECT TOP 242112 *
--INTO #ControlRandom
--FROM Sandbox.SamW.MorrisonsTotalCombo1501202

IF OBJECT_ID('Sandbox.SamW.MorrisonsLowATV') IS NOT NULL DROP TABLE Sandbox.SamW.MorrisonsLowATV
SELECT CINID, FANID
INTO Sandbox.SamW.MorrisonsLowATV
FROM Sandbox.SamW.MorrisonsTotalCombo1501202
WHERE AwarenessLevel IN ('Gold', 'Silver')
AND ATV_BANDS IN ('£0 - £5', '£5 - £15', '£15 - £25', '£25 - £35')
OR ATV_BANDS IS NULL

IF OBJECT_ID('Sandbox.SamW.MorrisonsMediumATV') IS NOT NULL DROP TABLE Sandbox.SamW.MorrisonsMediumATV
SELECT CINID, FANID
INTO Sandbox.SamW.MorrisonsMediumATV
FROM Sandbox.SamW.MorrisonsTotalCombo1501202
WHERE ATV_BANDS IN ('£35 - £45', '£45 - £55', '£55 - £65')

IF OBJECT_ID('Sandbox.SamW.MorrisonsHighATV') IS NOT NULL DROP TABLE Sandbox.SamW.MorrisonsHighATV
SELECT CINID, FANID
INTO Sandbox.SamW.MorrisonsHighATV
FROM Sandbox.SamW.MorrisonsTotalCombo1501202
WHERE ATV_BANDS IN ('£65 - £75', '£75 - £85', '£85+')If Object_ID('Warehouse.Selections.MOR048_PreSelection') Is Not Null Drop Table Warehouse.Selections.MOR048_PreSelectionSelect FanIDInto Warehouse.Selections.MOR048_PreSelectionFROM  SANDBOX.SAMW.MorrisonsMediumATVEND