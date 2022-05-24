-- =============================================-- Author:  <Rory Francis>-- Create date: <2021-02-20>-- Description: < sProc to run preselection code per camapign >-- =============================================CREATE PROCEDURE [Selections].[BTS003_PreSelection_sProc]ASBEGIN/*select top 100 * from Warehouse.Relational.Brand */
--where brandid in (61,2644,2018,1567,1858,2662,2459,1569,2667,2839,2467,2179,2374,1634,1365,1458,2923,843,1568,2262,933,57,202,265,381,414)

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

-- debenhams cc table
	IF OBJECT_ID('tempdb..#ccDeb') IS NOT NULL DROP TABLE #ccDeb
						SELECT	ccc.BrandID,
								brandname,
								ccc.ConsumerCombinationID
						INTO	#ccDeb
						FROM	Warehouse.Relational.ConsumerCombination ccc 
						join	Warehouse.Relational.Brand b
							on	ccc.BrandID = b.BrandID
						WHERE	CCC.BrandID in (116)
						GROUP BY ccc.BrandID,
									BrandName,
									ccc.ConsumerCombinationID
						CREATE CLUSTERED INDEX ix_ComboID ON #ccDeb(ConsumerCombinationID)


IF OBJECT_ID('tempdb..#all_shoppers_hb') IS NOT NULL DROP TABLE #all_shoppers_hb
select distinct CINID,
sum (amount) as spend
into #all_shoppers_hb
from Warehouse.Relational.ConsumerTransaction_MyRewards ct
join #CCfull cc
	on ct.ConsumerCombinationID = cc.ConsumerCombinationID
where trandate between dateadd(month,-12,getdate()) and getdate() 
group by CINID

IF OBJECT_ID('tempdb..#db_shoppers') IS NOT NULL DROP TABLE #db_shoppers
select distinct CINID,
sum (amount) as spend
into #db_shoppers
from Warehouse.Relational.ConsumerTransaction_MyRewards ct
join #ccDeb cc
	on ct.ConsumerCombinationID = cc.ConsumerCombinationID
where trandate between dateadd(month,-12,getdate()) and getdate() 
and amount > 0
group by CINID


--select count(cinid) from #db_shoppers
--where cinid not in (select cinid from #all_shoppers_hb)

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
				FROM #db_shoppers ct
				WHERE cl.CINID = ct.CINID)
AND NOT EXISTS (	SELECT 1
					FROM #all_shoppers_hb ct
					WHERE cl.CINID = ct.CINID)
/*SELECT	Segment
	,	COUNT(*)
FROM Sandbox.Rory.BootsCustomers bc
INNER JOIN #Customers c
	ON bc.FanID = c.FanID
GROUP BY Segment
ORDER BY Segment*/If Object_ID('Warehouse.Selections.BTS003_PreSelection') Is Not Null Drop Table Warehouse.Selections.BTS003_PreSelectionSelect FanIDInto Warehouse.Selections.BTS003_PreSelectionFROM  #CUSTOMERSEND