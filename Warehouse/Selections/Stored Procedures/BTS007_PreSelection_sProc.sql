-- =============================================-- Author:  <Rory Francis>-- Create date: <2021-03-22>-- Description: < sProc to run preselection code per camapign >-- =============================================CREATE PROCEDURE Selections.BTS007_PreSelection_sProcASBEGIN

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


IF OBJECT_ID('tempdb..#SegmentAsignment') IS NOT NULL DROP TABLE #SegmentAsignment
SELECT	cinid
INTO #SegmentAsignment
from #all_shoppers_hb
where cinid not in (select cinid from #boots_customers_48m) 


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

CREATE UNIQUE CLUSTERED INDEX CIX_FanID ON #Customers (FanID)If Object_ID('Warehouse.Selections.BTS007_PreSelection') Is Not Null Drop Table Warehouse.Selections.BTS007_PreSelectionSelect FanIDInto Warehouse.Selections.BTS007_PreSelectionFROM  #CUSTOMERSEND