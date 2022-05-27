﻿-- =============================================-- Author:  <Rory Francis>-- Create date: <2019-09-06>-- Description: < sProc to run preselection code per camapign >-- =============================================Create Procedure Selections.BT044_PreSelection_sProcASBEGIN

--CC Competitors--
IF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC
SELECT br.BrandID,
		br.BrandName,
		cc.ConsumerCombinationID

INTO	#CC

FROM	Warehouse.Relational.Brand br
JOIN	Warehouse.Relational.ConsumerCombination cc on br.BrandID = cc.BrandID

WHERE	br.BrandID IN (1001, --Barrhead Travel--
					 66,2452,1093,95,1385,651,1527,1495,1002,2320,849,230,248,1773,318,1504,376,405,424,440,2634,466,1505,477, --Main Competitors--
					 1765,2385,47,2392,1006,1018,1751,1010,2382,1004,2396,1002,1761,217,2381,240,273,2390,1989,1171,1017,1991,1289,2403,1990,1833,938,1832,2147,2389,2398,1964 --Luxury Competitors--
					 )

CREATE CLUSTERED INDEX ix_ComboID ON #CC(ConsumerCombinationID)


DECLARE @MainBrand SMALLINT = 1001	 -- Main Brand	

DECLARE @MinDate DATE = DATEADD(MONTH,-24,GETDATE())

IF OBJECT_ID('tempdb..#HistoricTranDate') IS NOT NULL DROP TABLE #HistoricTranDate
SELECT	CINID,
		MAX(CASE WHEN BrandID = @MainBrand THEN TranDate ELSE NULL END) AS MainBrand_LastTran,
		MAX(CASE WHEN BrandID IN (66,2452,1093,95,1385,651,1527,1495,1002,2320,849,230,248,1773,318,1504,376,405,424,440,2634,466,1505,477) THEN TranDate ELSE NULL END) AS CompBrand_LastTran,
		MAX(CASE WHEN BrandID IN (1765,2385,47,2392,1006,1018,1751,1010,2382,1004,2396,1002,1761,217,2381,240,273,2390,1989,1171,1017,1991,1289,2403,1990,1833,938,1832,2147,2389,2398,1964) THEN TranDate ELSE NULL END) AS LuxuryBrand_LastTran
INTO	#HistoricTranDate
FROM	Warehouse.Relational.ConsumerTransaction_MyRewards ct WITH (NOLOCK)
JOIN	#CC cc
	ON	ct.ConsumerCombinationID = cc.ConsumerCombinationID
WHERE	0 < ct.Amount
	AND @MinDate <= TranDate
GROUP BY CINID

CREATE CLUSTERED INDEX cix_CINID ON #HistoricTranDate (CINID)

--Spend more than £2500--
IF OBJECT_ID('tempdb..#Spend') IS NOT NULL DROP TABLE #Spend
SELECT CINID,
		SUM(Amount) AS 'Spend'

INTO #Spend

FROM Warehouse.Relational.ConsumerTransaction_MyRewards ct with (nolock)
JOIN #CC cc on cc.ConsumerCombinationID = ct.ConsumerCombinationID

WHERE BrandID = 1001
AND TranDate >= DATEADD(MONTH,-15,GETDATE())

GROUP BY CINID

--Segment Assignment--
If Object_ID('tempdb..#SegmentAssignment') IS NOT NULL DROP TABLE #SegmentAssignment
Select cl.CINID,			-- keep CINID and FANID
		cl.fanid,
		Spend
	
INTO #SegmentAssignment

FROM (SELECT CL.CINID,
				cu.FanID
	
		FROM warehouse.Relational.Customer cu
		JOIN warehouse.Relational.CINList cl on cu.SourceUID = cl.CIN

		WHERE cu.CurrentlyActive = 1
		AND cu.sourceuid NOT IN (select distinct sourceuid from warehouse.Staging.Customer_DuplicateSourceUID )
					
		GROUP BY CL.CINID, cu.FanID) CL

LEFT JOIN (SELECT CINID,
				 MAX(CASE WHEN Spend >= 2500 THEN 1 ELSE 0 END) AS Spend

			FROM #Spend

			GROUP BY CINID) spend on spend.CINID = cl.CINID


IF OBJECT_ID('tempdb..#Customers') IS NOT NULL DROP TABLE #Customers
SELECT	cl.CINID,
		cl.FanID,
		t.MainBrand_LastTran,
		t.CompBrand_LastTran,
		t.LuxuryBrand_LastTran,
		Spend

INTO	#Customers
FROM (	SELECT cl.CINID,
				 cu.FanID
		FROM Warehouse.Relational.Customer cu
		JOIN Warehouse.Relational.CINList cl on cu.SourceUID = cl.CIN

		WHERE cu.CurrentlyActive = 1
			AND cu.sourceuid NOT IN (select distinct sourceuid from warehouse.Staging.Customer_DuplicateSourceUID )
	) CL
LEFT JOIN #HistoricTranDate t
	ON	cl.CINID = t.CINID

LEFT JOIN #SegmentAssignment sa
	ON sa.CINID = cl.CINID

CREATE CLUSTERED INDEX cix_CINID ON #Customers (CINID)

DECLARE @LapsedDate DATE = DATEADD(MONTH,-15,GETDATE())

IF OBJECT_ID('tempdb..#CustomersSegmented') IS NOT NULL DROP TABLE #CustomersSegmented
SELECT	CINID,
		FanID,
		CASE WHEN MainBrand_LastTran IS NULL THEN 1 ELSE 0 END MainBrand_Acquired,
		CASE WHEN MainBrand_LastTran < @LapsedDate THEN 1 ELSE 0 END MainBrand_Lapsed,
		CASE WHEN @LapsedDate <= MainBrand_LastTran THEN 1 ELSE 0 END MainBrand_Shopper,
		CASE WHEN CompBrand_LastTran IS NULL THEN 1 ELSE 0 END Comp_Acquired,
		CASE WHEN CompBrand_LastTran < @LapsedDate THEN 1 ELSE 0 END Comp_Lapsed,
		CASE WHEN @LapsedDate <= CompBrand_LastTran THEN 1 ELSE 0 END Comp_Shopper,
		CASE WHEN LuxuryBrand_LastTran IS NULL THEN 1 ELSE 0 END Comp_Luxury_Acquired,
		CASE WHEN LuxuryBrand_LastTran < @LapsedDate THEN 1 ELSE 0 END Comp_Luxury_Lapsed,
		CASE WHEN @LapsedDate <= LuxuryBrand_LastTran THEN 1 ELSE 0 END Comp_Luxury_Shopper,
		CASE WHEN Spend = 1 THEN 1 ELSE 0 END Spender

INTO	#CustomersSegmented
FROM	#Customers

CREATE CLUSTERED INDEX cix_CINID ON #CustomersSegmented (CINID)


IF OBJECT_ID('Sandbox.Tasfia.Barrhead_Lux_CH_150319') IS NOT NULL DROP TABLE Sandbox.Tasfia.Barrhead_Lux_CH_150319
SELECT	CINID,	
		Fanid

INTO Sandbox.Tasfia.Barrhead_Lux_CH_150319

FROM	#CustomersSegmented	
WHERE	MainBrand_Shopper = 0
AND		Comp_Luxury_Shopper =1If Object_ID('Warehouse.Selections.BT044_PreSelection') Is Not Null Drop Table Warehouse.Selections.BT044_PreSelectionSelect FanIDInto Warehouse.Selections.BT044_PreSelection
FROM	#CustomersSegmented	
WHERE	MainBrand_Shopper = 0
AND		Comp_Luxury_Shopper =1END