﻿-- =============================================
SELECT ConsumerCombinationID
INTO #CC
FROM warehouse.Relational.CONSUMERCOMBINATION
WHERE BRANDID IN (1523,1734,2848);

CREATE CLUSTERED INDEX CIX_CC ON #CC (ConsumerCombinationID)
SELECT	Warehouse.Relational.CINList.*
	,	Warehouse.Relational.Customer.CurrentlyActive
	,	Warehouse.Relational.Customer.SourceUID
INTO #Customers
FROM Warehouse.Relational.CINList 
inner join Warehouse.Relational.Customer 
on Warehouse.Relational.Customer.SourceUID = Warehouse.Relational.CINList.CIN
where region = 'London'
AND CURRENTLYACTIVE = 1

CREATE CLUSTERED INDEX CIX_CINID ON #Customers (CINID)

DECLARE @TwoYearsAgo DATE = DATEADD(month,-24,getdate())

IF OBJECT_ID('tempdb..#CT') IS NOT NULL DROP TABLE #CT;
SELECT	A.CINID
	,	month(trandate) as tran_month
	,	year(trandate) as tran_year
	,	sum(amount) as spend
	,	count(*) as transactions
INTO #CT
FROM warehouse.Relational.ConsumerTransaction_MyRewards AS A
INNER JOIN #Customers as customer_table 
	on A.CINID = customer_table.CINID
WHERE amount >= 15
AND EXISTS (SELECT 1
			FROM #CC cc
			WHERE a.ConsumerCombinationID = cc.ConsumerCombinationID)
AND TranDate >= @TwoYearsAgo
group by A.CINID,month(trandate),year(trandate);


IF OBJECT_ID('Sandbox.BastienC.gett_v2_15') IS NOT NULL DROP TABLE Sandbox.BastienC.gett_v2_15;
select cinid
into Sandbox.BastienC.gett_v2_15
from #CT
where transactions >= 2