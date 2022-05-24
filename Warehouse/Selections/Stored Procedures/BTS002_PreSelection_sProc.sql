-- =============================================-- Author:  <Rory Francis>-- Create date: <2021-02-08>-- Description: < sProc to run preselection code per camapign >-- =============================================CREATE PROCEDURE [Selections].[BTS002_PreSelection_sProc]ASBEGIN
/*

SELECT *
FROM Relational.Partner
WHERE PartnerName LIKE '%Boot%'

*/

--IF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC
--SELECT	ConsumerCombinationID
--INTO #CC
--FROM [Relational].[ConsumerCombination] cc
--WHERE cc.BrandID = 61

--CREATE UNIQUE CLUSTERED INDEX CIX_CCID ON #CC (ConsumerCombinationID)

--IF OBJECT_ID('tempdb..#CC_HandB') IS NOT NULL DROP TABLE #CC_HandB
--SELECT	ConsumerCombinationID
--INTO #CC_HandB
--FROM [Relational].[ConsumerCombination] cc
--WHERE cc.BrandID IN (2644,2018,1567,1858,2662,2459,1569,2667,2839,2467,2179,2374,1634,1365,1458,2923,843,1568,2262,933,57,202,265,381,414)

--CREATE UNIQUE CLUSTERED INDEX CIX_CCID ON #CC_HandB (ConsumerCombinationID)

--DECLARE @Today DATE = GETDATE()
--	,	@MonthsSinceShopped_Lapsed INT = 12
--	,	@MonthsSinceShopped_LongLapsed INT = 300
--	,	@MonthsSinceShopped_HealthAndBeauty_Lapsed INT = 6
--	,	@MonthsSinceShopped_HealthAndBeauty_LongLapsed INT = 12

--DECLARE @Date_Lapsed DATE = DATEADD(MONTH, - @MonthsSinceShopped_Lapsed, @Today)
--	,	@Date_LongLapsed DATE = DATEADD(MONTH, - @MonthsSinceShopped_LongLapsed, @Today)
--	,	@Date_HealthAndBeauty_Lapsed DATE = DATEADD(MONTH, - @MonthsSinceShopped_HealthAndBeauty_Lapsed, @Today)
--	,	@Date_HealthAndBeauty_LongLapsed DATE = DATEADD(MONTH, - @MonthsSinceShopped_HealthAndBeauty_LongLapsed, @Today)
	
--IF OBJECT_ID('tempdb..#CT') IS NOT NULL DROP TABLE #CT
--SELECT	ct.CINID
--	,	MAX(ct.TranDate) AS LastTran
--INTO #CT
--FROM [Relational].[ConsumerTransaction_MyRewards] ct
--WHERE @Date_Lapsed < ct.TranDate
--AND EXISTS (	SELECT 1
--				FROM #CC cc
--				WHERE ct.ConsumerCombinationID = cc.ConsumerCombinationID)
--GROUP BY ct.CINID
	
--IF OBJECT_ID('tempdb..#CT_HandB') IS NOT NULL DROP TABLE #CT_HandB
--SELECT	ct.CINID
--	,	MAX(ct.TranDate) AS LastTran
--INTO #CT_HandB
--FROM [Relational].[ConsumerTransaction_MyRewards] ct
--WHERE @Date_HealthAndBeauty_LongLapsed < ct.TranDate
--AND EXISTS (	SELECT 1
--				FROM #CC_HandB cc
--				WHERE ct.ConsumerCombinationID = cc.ConsumerCombinationID)
--GROUP BY ct.CINID

--/*
--SELECT	LastTran
--	,	COUNT(*) AS Customers
--FROM #CT
--GROUP BY LastTran
--ORDER BY LastTran
--*/

--IF OBJECT_ID('tempdb..#Customers') IS NOT NULL DROP TABLE #Customers
--SELECT	cu.FanID
--INTO #Customers
--FROM [Relational].[Customer] cu
--INNER JOIN [Relational].[CINList] cl
--	ON cu.SourceUID = cl.CIN
--WHERE NOT EXISTS (	SELECT 1
--					FROM [Staging].[Customer_DuplicateSourceUID] ds
--					WHERE cu.SourceUID = ds.SourceUID)
--AND NOT EXISTS (SELECT 1
--				FROM #CT ct
--				WHERE cl.CINID = ct.CINID)
--AND EXISTS (	SELECT 1
--				FROM #CT_HandB ct
--				WHERE cl.CINID = ct.CINID)

--CREATE UNIQUE CLUSTERED INDEX CIX_FanID ON #Customers (FanID)

-- full CC list of Health and beauty --
	IF OBJECT_ID('tempdb..#CCfull') IS NOT NULL DROP TABLE #CCfull
						SELECT	ccc.BrandID,
								brandname,
								ccc.ConsumerCombinationID
						INTO	#CCfull
						FROM	Warehouse.Relational.ConsumerCombination ccc 
						join	Warehouse.Relational.Brand b
							on	ccc.BrandID = b.BrandID
						WHERE	CCC.BrandID in (61,2644,2018,1567,1858,2662,2459,1569,2667,2839,2467,2179,2374,1634,1365,1458,2923,843,1568,2262,933,57,202,265,381,414)
						GROUP BY ccc.BrandID,
									BrandName,
									ccc.ConsumerCombinationID
						CREATE CLUSTERED INDEX ix_ComboID ON #ccfull(ConsumerCombinationID)


DECLARE @Date_Today DATE = GETDATE()
	,	@Date_12Months DATE = DATEADD(MONTH, -12, GETDATE())
	,	@Date_48Months DATE = DATEADD(MONTH, -48, GETDATE())
	
IF OBJECT_ID('tempdb..#all_shoppers_hb') IS NOT NULL DROP TABLE #all_shoppers_hb
SELECT	CINID
	,	MAX(TranDate) AS MaxTran
	,	SUM(Amount) AS Spend
INTO #all_shoppers_hb
FROM Warehouse.Relational.ConsumerTransaction_MyRewards ct
WHERE TranDate BETWEEN @Date_12Months and @Date_Today	--	where trandate between @Date_SixMonths and @Date_Today
AND Amount > 0
AND EXISTS (SELECT 1
			FROM #CCfull cc
			WHERE ct.ConsumerCombinationID = cc.ConsumerCombinationID
			AND cc.BrandID != 61)
GROUP BY CINID

IF OBJECT_ID('tempdb..#boots_customers_48m') IS NOT NULL DROP TABLE #boots_customers_48m
SELECT	CINID
	,	MAX(TranDate) AS MaxTran
	,	SUM(Amount) AS Spend
INTO #boots_customers_48m
FROM Warehouse.Relational.ConsumerTransaction_MyRewards ct
WHERE TranDate BETWEEN @Date_48Months and @Date_Today
AND Amount > 0
AND EXISTS (SELECT 1
			FROM #CCfull cc
			WHERE ct.ConsumerCombinationID = cc.ConsumerCombinationID
			AND cc.BrandID = 61)
GROUP BY CINID

IF OBJECT_ID('tempdb..#boots_customers_12m') IS NOT NULL DROP TABLE #boots_customers_12m
SELECT	CINID
	,	MAX(TranDate) AS MaxTran
	,	SUM(Amount) AS Spend
into #boots_customers_12m
from Warehouse.Relational.ConsumerTransaction_MyRewards ct
join #CCfull cc
	on ct.ConsumerCombinationID = cc.ConsumerCombinationID
where trandate between @Date_12Months and @Date_Today
AND Amount > 0
AND EXISTS (SELECT 1
			FROM #CCfull cc
			WHERE ct.ConsumerCombinationID = cc.ConsumerCombinationID
			AND cc.BrandID = 61)
GROUP BY CINID

IF OBJECT_ID('tempdb..#SegmentAsignment') IS NOT NULL DROP TABLE #SegmentAsignment
SELECT	cinid
INTO #SegmentAsignment
from #all_shoppers_hb
where cinid not in (select CINID from #boots_customers_12m)
and cinid in (select cinid from #boots_customers_48m) 


IF OBJECT_ID('tempdb..#Customers') IS NOT NULL DROP TABLE #Customers
SELECT	cu.FanID
INTO #Customers
FROM [Relational].[Customer] cu
INNER JOIN [Relational].[CINList] cl
	ON cu.SourceUID = cl.CIN
WHERE NOT EXISTS (	SELECT 1
					FROM [Staging].[Customer_DuplicateSourceUID] ds
					WHERE cu.SourceUID = ds.SourceUID)
AND EXISTS (	SELECT 1
				FROM #SegmentAsignment ct
				WHERE cl.CINID = ct.CINID)

CREATE UNIQUE CLUSTERED INDEX CIX_FanID ON #Customers (FanID)

/*SELECT	Segment
	,	COUNT(*)
FROM Sandbox.Rory.BootsCustomers bc
INNER JOIN #Customers c
	ON bc.FanID = c.FanID
GROUP BY Segment
ORDER BY SegmentSELECT	Segment
	,	COUNT(*)
FROM Sandbox.Rory.BootsCustomers bc
INNER JOIN Relational.Customer cu
	ON bc.FanID = cu.FanID
INNER JOIN Relational.CINList cl
	ON cu.SourceUID = cl.CIN
INNER JOIN #all_shoppers_hb c
	ON cl.CINID = c.CINID
GROUP BY Segment
ORDER BY Segment#SELECT	ShopperSegmentTypeID
	,	COUNT(*)
FROM Segmentation.Roc_Shopper_Segment_Members sg
WHERE PartnerID = 4036
AND EXISTS (	SELECT 1
				FROM #Customers cu
				WHERE cu.FanID = sg.FanID)
GROUP BY ShopperSegmentTypeID
ORDER BY ShopperSegmentTypeID

*/

If Object_ID('Warehouse.Selections.BTS002_PreSelection') Is Not Null Drop Table Warehouse.Selections.BTS002_PreSelectionSelect FanIDInto Warehouse.Selections.BTS002_PreSelectionFROM  #CustomersEND