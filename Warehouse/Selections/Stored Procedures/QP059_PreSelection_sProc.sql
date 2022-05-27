﻿-- =============================================
IF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC;
SELECT ConsumerCombinationID
INTO #CC
FROM warehouse.Relational.CONSUMERCOMBINATION
WHERE BRANDID IN (1909,15,1486,299);

DECLARE @Date DATE = DATEADD(month,-24,getdate())

IF OBJECT_ID('Sandbox.BastienC.QPark') IS NOT NULL DROP TABLE Sandbox.BastienC.QPark;
SELECT DISTINCT A.CINID
INTO Sandbox.BastienC.QPark
FROM warehouse.Relational.ConsumerTransaction_MyRewards AS A
INNER JOIN (
		SELECT Warehouse.Relational.CINList.*, Warehouse.Relational.Customer.CurrentlyActive,Warehouse.Relational.Customer.SourceUID 
		FROM Warehouse.Relational.CINList 
		inner join Warehouse.Relational.Customer 
		on Warehouse.Relational.Customer.SourceUID = Warehouse.Relational.CINList.CIN) as customer_table 
	on A.CINID = customer_table.CINID
WHERE amount >0
and CONSUMERCOMBINATIONiD IN (SELECT * FROM #CC)
AND CURRENTLYACTIVE = 1	
AND TranDate >= @Date;

