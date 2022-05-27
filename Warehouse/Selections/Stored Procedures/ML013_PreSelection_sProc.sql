-- =============================================-- Author:  <Rory Francis>-- Create date: <2020-08-21>-- Description: < sProc to run preselection code per camapign >-- =============================================CREATE PROCEDURE [Selections].[ML013_PreSelection_sProc]ASBEGIN
--SELECT BrandID,
--		BrandName
--FROM	Relational.Brand
--WHERE	BrandName LIKE '%Ryman%'
--OR		BrandName = 'WH Smith'
--OR		BrandName LIKE '%Paperchase%'
--OR		BrandName = 'TFL'
--OR		BrandName LIKE '%Petrol%'
--OR		BrandName = 'BP'
--OR		BrandName = 'Esso'
--OR		BrandName = 'Shell'
--OR		BrandName LIKE '%Texaco%'
--OR		BrandName LIKE '%Rail%'
--ORDER BY 2

IF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC
SELECT br.BrandID,
		br.BrandName,
		cc.ConsumerCombinationID
INTO	#CC
FROM	Warehouse.Relational.Brand br
JOIN	Warehouse.Relational.ConsumerCombination cc ON br.BrandID = cc.BrandID
WHERE	br.BrandID in (277)
ORDER BY br.BrandName
CREATE CLUSTERED INDEX ix_ComboID ON #cc(BrandID,ConsumerCombinationID)

IF OBJECT_ID('tempdb..#CC2') IS NOT NULL DROP TABLE #CC2
SELECT br.BrandID,
		br.BrandName,
		cc.ConsumerCombinationID
INTO	#CC2
FROM	Warehouse.Relational.Brand br
JOIN	Warehouse.Relational.ConsumerCombination cc ON br.BrandID = cc.BrandID
WHERE	BrandName LIKE '%Ryman%'
OR		BrandName = 'WH Smith'
OR		BrandName LIKE '%Paperchase%'
OR		BrandName = 'TFL'
OR		BrandName LIKE '%Petrol%'
OR		BrandName = 'BP'
OR		BrandName = 'Esso'
OR		BrandName = 'Shell'
OR		BrandName LIKE '%Texaco%'
OR		BrandName LIKE '%Rail%'
OR		br.BrandID = '277'
ORDER BY br.BrandName
CREATE CLUSTERED INDEX ix_ComboID ON #cc2(BrandID,ConsumerCombinationID)

--SELECT	DISTINCT BrandID,BrandName FROM #CC2
--ORDER BY 2

--Transactions--
--SELECT	TranDate,
--		IsOnline,
--		SUM(Amount) AS Spend,
--		COUNT(1) AS Transactions,
--		COUNT(DISTINCT CINID) AS Spenders

--FROM	Relational.ConsumerTransaction_MyRewards my
--JOIN	#CC cc on cc.ConsumerCombinationID = my.ConsumerCombinationID
--WHERE	TranDate >= '2020-01-01'
--AND		Amount > 0
--AND		BrandID = 277
--GROUP BY TranDate,
--		 IsOnline
--ORDER BY 1

--Selection of Full Base Customers-- 
IF OBJECT_ID('tempdb..#FullBase') IS NOT NULL DROP TABLE #FullBase
SELECT	CL.CINID,
		cu.FanID
INTO	#FullBase
FROM	Relational.Customer cu
JOIN	Relational.CINList cl on cu.SourceUID = cl.CIN
WHERE	cu.CurrentlyActive = 1 -- for active customers
AND		cu.sourceuid NOT IN (select distinct sourceuid from warehouse.Staging.Customer_DuplicateSourceUID)

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


IF OBJECT_ID('tempdb..#Matalan_SectorShopper_Work') IS NOT NULL DROP TABLE #Matalan_SectorShopper_Work
SELECT	fb.CINID,
		SUM(Amount)/COUNT(1) AS ATV
INTO	#Matalan_SectorShopper_Work
FROM	#FullBase fb
JOIN	Warehouse.Relational.ConsumerTransaction_MyRewards ct with (nolock) on ct.CINID = fb.CINID
JOIN	#CC2 cc on cc.ConsumerCombinationID = ct.ConsumerCombinationID
WHERE	0 < ct.Amount
AND		cc.BrandID IN ('1826','22','62','1321','1217','1660','1333','144','838','2538','1330',
											 '1284','1331','1332','1738','1043','1307','1334','1312','1329','293',
											 '2246','918','1404','3006','380','1335','2539','388','935','2324',
											 '1285','778','426','427','1277','1737','1336','1886','938','795',
											 '1337','2540')
AND TranDate >= DATEADD(MONTH,-2,GETDATE())
GROUP BY fb.CINID

--SELECT	TOP 615000 *
--FROM #Matalan_SectorShopper_Work
--ORDER BY 2 DESC

--FORECAST 1--
DECLARE @MainBrand SMALLINT = 277	 -- Main Brand	

If Object_ID('tempdb..#SegmentAssignment1') IS NOT NULL DROP TABLE #SegmentAssignment1
Select cl.CINID,			-- keep CINID and FANID
		cl.fanid,
		CASE WHEN m.CINID IS NOT NULL THEN 1 ELSE 0 END AS HighShopper,
		MainBrandLapsed,
		Acquired,
		Acquired_NeverShopped,
		SectorShopper_Work,
		SectorShopper_School,
		ATV
INTO	#SegmentAssignment1

FROM	#FullBase cl

LEFT JOIN (SELECT CINID FROM #MatalanHighSpenders) m on m.CINID = cl.CINID

LEFT JOIN (SELECT ct.CINID,
				 SUM(ct.Amount) as Sales,

				 MAX(CASE WHEN cc.brandid = @MainBrand AND DATEADD(MONTH,-12,GETDATE()) <= TranDate AND TranDate < DATEADD(MONTH,-6,GETDATE())
 						THEN 1 ELSE 0 END) AS MainBrandLapsed,

				 MAX(CASE WHEN cc.BrandID = @MainBrand AND TranDate <= DATEADD(MONTH,-12,GETDATE())
 						THEN 1 ELSE 0 END) AS Acquired,

				 MAX(CASE WHEN cc.BrandID <> @MainBrand
 						THEN 1 ELSE 0 END) AS Acquired_NeverShopped,

				 MAX(CASE WHEN cc.BrandID IN ('1826','22',' 62','1321','1217','1660','1333','144','838','2538','1330',
											 '1284','1331','1332','1738','1043','1307','1334','1312','1329','293',
											 '2246','918','1404','3006','380','1335','2539','388','935','2324',
											 '1285','778','426','427','1277','1737','1336','1886','938','795',
											 '1337','2540')
											 AND TranDate >= DATEADD(MONTH,-2,GETDATE())
						THEN 1 ELSE 0 END) AS SectorShopper_Work,
					
				 MAX(CASE WHEN cc.BrandID IN ('326','375','492')
											 AND TranDate >= DATEADD(MONTH,-13,GETDATE()) AND TranDate <= DATEADD(MONTH,-10,GETDATE())
						THEN 1 ELSE 0 END) AS SectorShopper_School
						 
			FROM Warehouse.Relational.ConsumerTransaction_MyRewards ct with (nolock)
			JOIN #CC2 cc on cc.ConsumerCombinationID = ct.ConsumerCombinationID
			
			WHERE 0 < ct.Amount
			AND TranDate >= DATEADD(MONTH,-24,GETDATE())

			GROUP BY ct.CINID) b on cl.CINID = b.CINID
LEFT JOIN	#Matalan_SectorShopper_Work sw on sw.CINID = cl.CINID

--SELECT	TOP 100 * FROM #SegmentAssignment1

--SELECT	HighShopper,
--		MainBrandLapsed,
--		Acquired,
--		Acquired_NeverShopped,
--		SectorShopper_Work,
--		SectorShopper_School,
--		COUNT(1)
--FROM	#SegmentAssignment1
--GROUP BY HighShopper,
--		 MainBrandLapsed,
--		 Acquired,
--		 Acquired_NeverShopped,
--		 SectorShopper_Work,
--		 SectorShopper_School

--SELECT	COUNT(1) FROM Sandbox.Tasfia.Matalan_Forecast1_250620


SELECT COUNT(*)
FROM #SegmentAssignment1
WHERE HighShopper = 1

IF OBJECT_ID('Sandbox.Tasfia.Matalan_Forecast1_050820') IS NOT NULL DROP TABLE Sandbox.Tasfia.Matalan_Forecast1_050820
SELECT CINID,
		FanID

INTO Sandbox.Tasfia.Matalan_Forecast1_050820

FROM #SegmentAssignment1
WHERE HighShopper = 1 OR MainBrandLapsed = 1
OR	 (SectorShopper_Work = 1 AND (Acquired = 1 OR Acquired_NeverShopped = 1) AND ATV >= 20)
OR	 (SectorShopper_School = 1 AND (Acquired = 1 OR Acquired_NeverShopped = 1) AND ATV >= 20)

--SELECT	COUNT(1) FROM Sandbox.Tasfia.Matalan_Forecast1_300620If Object_ID('Warehouse.Selections.ML013_PreSelection') Is Not Null Drop Table Warehouse.Selections.ML013_PreSelectionSelect FanIDInto Warehouse.Selections.ML013_PreSelectionFROM  SANDBOX.TASFIA.MATALAN_FORECAST1_050820END