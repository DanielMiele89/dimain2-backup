﻿-- =============================================
IF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC;
SELECT ConsumerCombinationID
INTO #CC
FROM warehouse.Relational.CONSUMERCOMBINATION
WHERE BRANDID IN (355,116,328,1070,486,130,148);

IF OBJECT_ID('tempdb..#CT') IS NOT NULL DROP TABLE #CT;
SELECT A.CINID,month(trandate) as tran_month,year(trandate) as tran_year,sum(amount) as spend,count(*) as transactions
INTO #CT
FROM warehouse.Relational.ConsumerTransaction_MyRewards AS A
INNER JOIN (
		SELECT Warehouse.Relational.CINList.*, Warehouse.Relational.Customer.CurrentlyActive,Warehouse.Relational.Customer.SourceUID 
		FROM Warehouse.Relational.CINList 
		inner join Warehouse.Relational.Customer 
		on Warehouse.Relational.Customer.SourceUID = Warehouse.Relational.CINList.CIN) as customer_table 
	on A.CINID = customer_table.CINID
WHERE amount >= 0
and CONSUMERCOMBINATIONiD IN (SELECT CONSUMERCOMBINATIONiD FROM #CC)
AND CURRENTLYACTIVE = 1	
AND TranDate >= DATEADD(month,-13,getdate())
group by A.CINID,month(trandate),year(trandate);


IF OBJECT_ID('Sandbox.BastienC.matalan_compsteal') IS NOT NULL DROP TABLE Sandbox.BastienC.matalan_compsteal;
select cinid
into Sandbox.BastienC.matalan_compsteal
from #CT