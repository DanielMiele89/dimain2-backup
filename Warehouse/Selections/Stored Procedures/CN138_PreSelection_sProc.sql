CREATE PROCEDURE [Selections].[CN138_PreSelection_sProc]
AS
BEGIN

IF OBJECT_ID('tempdb..#FB') IS NOT NULL DROP TABLE #FB
SELECT	cl.CINID ,c.FanID
INTO #FB
FROM	warehouse.Relational.Customer C
JOIN	warehouse.Relational.CINList CL ON CL.CIN = C.SourceUID
join	warehouse.InsightArchive.EngagementScore E ON E.FanID = C.FanID
WHERE	C.CurrentlyActive = 1
AND		c.SourceUID NOT IN (SELECT SourceUID FROM warehouse.Staging.Customer_DuplicateSourceUID)


------------ CCs FROM AWS COMBO POST CODE (LOCATIONS FOR NON-PARTNER BRANDS)-------------
IF OBJECT_ID('tempdb..#cc1') IS NOT NULL DROP TABLE #cc1
select a.ConsumerCombinationID
INTO #cc1
from Warehouse.AWSFile.ComboPostCode A
JOIN (SELECT * from Warehouse.Relational.DriveTimeMatrix  WHERE fromsector in ('EC1A 7','EC3M 3','WC1V 6','EC2N 2','EC4V 6','EC2M 1','EC3A 8','CT2 7','LE1 6','EH1 2',
																				'SW5 9','WC2E 7','W6 7','SW1W 9','EC4M 8','WC1V 6','W1A 1','G2 5','G1 3','WC2H 7',
																				'WC1V 7','G28','WC1X 8','RG1 1','W11 3','WC2E 7','W2 3','RG1 1','LS1 4','WC2B 6',
																				'WC1B 4','BS1 1','WC2B 6','EH3 9','W1T 5','B2 4','G2 6','SW1P 3','EC3R 7','BA1 1',
																				'M1 3','WC2H 8','B2 5','SW17 9','BT1 3','M1 2','W1J 7','W1D 4','BS8 1','LS1 4',
																				'SW1Y 6','WC2N 4','SE1 8','WC2N 5','M2 3','WC2H 9','W1T 4','CB1 2','L1 4','WC2H 0',
																				'L1 6','M3 3','CF10 2','WC2E 7','B1 2','LL11 1','L2 0','LS1 4','BT2 8','W6 9','NG1 7',
																				'CH1 1','LS1 3','BT7 1','CH1 1','SK1 1','KT6 4','M16 0','BT7 3','CV4 7')
	) b 
	ON concat(left(a.postcode,len(a.postcode)-3),' ',left(right(a.postcode,3),1)) =  b.ToSector
join warehouse.Relational.ConsumerCombination cc on cc.ConsumerCombinationID = a.ConsumerCombinationID
 where DriveTimeMins <= 5
 and brandid in (101,354,407)


 
------------ CCs FROM OUTLET  (LOCATIONS FOR PARTNER BRANDS)-------------
 IF OBJECT_ID('tempdb..#cc2') IS NOT NULL DROP TABLE #cc2
select cc.ConsumerCombinationID
INTO #cc2
from Warehouse.Relational.Outlet A
JOIN (SELECT * from Warehouse.Relational.DriveTimeMatrix  WHERE fromsector in ('EC1A 7','EC3M 3','WC1V 6','EC2N 2','EC4V 6','EC2M 1','EC3A 8','CT2 7','LE1 6','EH1 2',
																				'SW5 9','WC2E 7','W6 7','SW1W 9','EC4M 8','WC1V 6','W1A 1','G2 5','G1 3','WC2H 7',
																				'WC1V 7','G28','WC1X 8','RG1 1','W11 3','WC2E 7','W2 3','RG1 1','LS1 4','WC2B 6',
																				'WC1B 4','BS1 1','WC2B 6','EH3 9','W1T 5','B2 4','G2 6','SW1P 3','EC3R 7','BA1 1',
																				'M1 3','WC2H 8','B2 5','SW17 9','BT1 3','M1 2','W1J 7','W1D 4','BS8 1','LS1 4',
																				'SW1Y 6','WC2N 4','SE1 8','WC2N 5','M2 3','WC2H 9','W1T 4','CB1 2','L1 4','WC2H 0',
																				'L1 6','M3 3','CF10 2','WC2E 7','B1 2','LL11 1','L2 0','LS1 4','BT2 8','W6 9','NG1 7',
																				'CH1 1','LS1 3','BT7 1','CH1 1','SK1 1','KT6 4','M16 0','BT7 3','CV4 7')
	) b 
	ON a.PostalSector =  b.ToSector
join warehouse.Relational.ConsumerCombination cc on cc.MID = a.MerchantID
 where DriveTimeMins <= 5
 and partnerid = 4781


------FINAL CC TABLE (UNION OF THE 2 ABOVE) 
IF OBJECT_ID('tempdb..#cc') IS NOT NULL DROP TABLE #cc
 select distinct ConsumerCombinationID  
 into #cc
 from (
	select * from #cc1
	union
	select * from #cc2) a

 IF OBJECT_ID('tempdb..#eligible') IS NOT NULL DROP TABLE #eligible
SELECT DISTINCT cinid
INTO	#eligible
FROM	warehouse.Relational.ConsumerTransaction_MyRewards CT
JOIN	#CC CC	ON CT.ConsumerCombinationID = CC.ConsumerCombinationID
WHERE	TranDate >= DATEADD(MONTH,-6,GETDATE())
		AND Amount > 0
GROUP BY CT.CINID

-------------------------------------------------------------
--remove shoppers with sow > 0.3
-------------------------------------------------------------

IF OBJECT_ID('tempdb..#CC3') IS NOT NULL DROP TABLE #CC3
SELECT	BrandName 
		,CC.BrandID
		,ConsumerCombinationID
INTO #CC3
FROM	warehouse.Relational.ConsumerCombination CC
JOIN	warehouse.Relational.Brand B ON B.BrandID = CC.BrandID
WHERE	CC.BrandID IN  (101,354,407,75)	

IF OBJECT_ID('tempdb..#shoppper_sow') IS NOT NULL DROP TABLE #shoppper_sow
SELECT DISTINCT CT.CINID
		,1.0 * (CAST(SUM(CASE WHEN BrandID = 75 THEN Amount ELSE 0 END )as float) / NULLIF(SUM(Amount),0)) AS SoW
		,MAX(CASE WHEN BrandID = 75 AND TranDate >= DATEADD(MONTH,-6,GETDATE()) THEN 1 ELSE 0 END) BrandShopper
INTO	#shoppper_sow
FROM	warehouse.Relational.ConsumerTransaction_MyRewards CT
JOIN	#CC3 CC	ON CT.ConsumerCombinationID = CC.ConsumerCombinationID
JOIN	#FB FB	ON CT.CINID = FB.CINID
WHERE	TranDate >= DATEADD(MONTH,-6,GETDATE())
		AND Amount > 0
GROUP BY CT.CINID


 IF OBJECT_ID('tempdb..#not_eligible') IS NOT NULL DROP TABLE #not_eligible
SELECT	F.CINID
INTO	#not_eligible
FROM #shoppper_sow F
WHERE BrandShopper = 1
	  AND SoW > 0.3
--	  AND Transactions >= 55
GROUP BY F.CINID

-------------------------------------------------------------
--final output
-------------------------------------------------------------

IF OBJECT_ID('sandbox.bastienc.caffenero_workerstores') IS NOT NULL DROP TABLE sandbox.bastienc.caffenero_workerstores
select a.CINID 
into sandbox.bastienc.caffenero_workerstores
from #eligible a
join #FB b on a.CINID = b.CINID
where a.CINID not in (select * from #not_eligible)


IF OBJECT_ID('[Warehouse].[Selections].[CN138_PreSelection]') IS NOT NULL DROP TABLE [Warehouse].[Selections].[CN138_PreSelection]
SELECT	FanID
INTO [Warehouse].[Selections].[CN138_PreSelection]
FROM #FB fb
WHERE EXISTS (	SELECT 1
				FROM sandbox.bastienc.caffenero_workerstores cn
				WHERE fb.CINID = cn.CINID)

END;