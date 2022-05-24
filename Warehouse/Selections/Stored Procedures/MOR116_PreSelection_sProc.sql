CREATE PROCEDURE [Selections].[MOR116_PreSelection_sProc] AS BEGIN IF OBJECT_ID('[Warehouse].[Selections].[MOR116_PreSelection]') IS NOT NULL DROP TABLE [Warehouse].[Selections].[MOR116_PreSelection] 
--SELECT CONVERT(INT, 0) AS FanID INTO [Warehouse].[Selections].[MOR116_PreSelection] WHERE 1 = 2 END

--SELECT * FROM Relational.Brand WHERE BrandName LIKE '%aldi%'



IF OBJECT_ID('tempdb..#FB') IS NOT NULL DROP TABLE #FB
SELECT	CINID ,FanID
INTO #FB
FROM	warehouse.Relational.Customer C
JOIN	warehouse.Relational.CINList CL ON CL.CIN = C.SourceUID
WHERE	C.CurrentlyActive = 1
AND		SourceUID NOT IN (SELECT SourceUID FROM warehouse.Staging.Customer_DuplicateSourceUID)
--AND FANID NOT IN (SELECT FANID FROM [InsightArchive].[MorrisonsReward_MatchedCustomers_20190304])		--NOT A MORECARD OWNER--

-- ALL THE POSTCODES WITHIN 10 MINS OF L32 8 (NEW MORRISONS STORE)

IF OBJECT_ID('tempdb..#cc') IS NOT NULL DROP TABLE #cc
select ConsumerCombinationID
INTO #cc
from Warehouse.AWSFile.ComboPostCode A
JOIN (SELECT * from Warehouse.Relational.DriveTimeMatrix  WHERE fromsector = 'L32 8') b 
	ON concat(left(a.postcode,len(a.postcode)-3),' ',left(right(a.postcode,3),1)) =  b.ToSector
 where DriveTimeMins <= 10

 IF OBJECT_ID('tempdb..#eligible') IS NOT NULL DROP TABLE #eligible
SELECT DISTINCT cinid
INTO	#eligible
FROM	warehouse.Relational.ConsumerTransaction_MyRewards CT
JOIN	#CC CC	ON CT.ConsumerCombinationID = CC.ConsumerCombinationID
WHERE	TranDate >= DATEADD(MONTH,-3,GETDATE())
		AND Amount > 0
GROUP BY CT.CINID

--
--select top 10 * from Warehouse.Relational.Outlet where PartnerID = 4263 and postcode = 'L31 2PH'

 IF OBJECT_ID('tempdb..#not_eligible') IS NOT NULL DROP TABLE #not_eligible
SELECT DISTINCT cinid
INTO	#not_eligible
FROM	warehouse.Relational.ConsumerTransaction_MyRewards CT
JOIN	(select * from  warehouse.relational.ConsumerCombination where MID in ('6143564','06143564')) CC	ON CT.ConsumerCombinationID = CC.ConsumerCombinationID
WHERE	TranDate >= DATEADD(MONTH,-3,GETDATE())
		AND Amount > 0
GROUP BY CT.CINID



IF OBJECT_ID('sandbox.bastienc.morrisons_store_AL') IS NOT NULL DROP TABLE sandbox.bastienc.morrisons_store_AL
select cinid 
into sandbox.bastienc.morrisons_store_AL
from #eligible
where CINID not in (select * from #not_eligible)

--select * from Warehouse.Relational.Brand where brandname like'%morrisons%'
--or brandname like'%home bargains%'
--or brandname like'%b&m%'
--or brandname like'%poundland%'
--or brandname like'%iceland%'
--or brandname like'%aldi%'
--or brandname = 'asda'



IF OBJECT_ID('tempdb..#CC1') IS NOT NULL DROP TABLE #CC1
SELECT	BrandName 
		,CC.BrandID
		,ConsumerCombinationID
INTO #CC1
FROM	warehouse.Relational.ConsumerCombination CC
JOIN	warehouse.Relational.Brand B ON B.BrandID = CC.BrandID
WHERE	CC.BrandID IN  (292,915,1110,346,215,5,21)	

IF OBJECT_ID('tempdb..#shoppper_sow') IS NOT NULL DROP TABLE #shoppper_sow
SELECT DISTINCT CT.CINID
		,1.0 * (CAST(SUM(CASE WHEN BrandID = 292 THEN Amount ELSE 0 END) as float) / NULLIF(SUM(Amount),0)) AS SoW
		,MAX(CASE WHEN BrandID = 292 AND TranDate >= DATEADD(MONTH,-3,GETDATE()) THEN 1 ELSE 0 END) BrandShopper
		,COUNT(1) as Transactions
INTO	#shoppper_sow
FROM	warehouse.Relational.ConsumerTransaction_MyRewards CT
JOIN	#CC1 CC	ON CT.ConsumerCombinationID = CC.ConsumerCombinationID
JOIN	#FB FB	ON CT.CINID = FB.CINID
WHERE	TranDate >= DATEADD(MONTH,-3,GETDATE())
		AND Amount > 0
		and ct.cinid in (select * from #eligible)
		and ct.CINID not in (select * from #not_eligible)
GROUP BY CT.CINID


IF OBJECT_ID('sandbox.bastienc.morrisons_store_S') IS NOT NULL DROP TABLE sandbox.bastienc.morrisons_store_S
SELECT	F.CINID
INTO sandbox.bastienc.morrisons_store_S
FROM #shoppper_sow F
WHERE BrandShopper = 1
	  AND SoW < 0.3
GROUP BY F.CINID


If Object_ID('Selections.MOR116_PreSelection') Is Not Null Drop Table Selections.MOR116_PreSelection
Select FanID
Into Selections.MOR116_PreSelection
FROM #FB F
INNER JOIN sandbox.bastienc.morrisons_store_AL R
ON R.CINID = F.CINID

END